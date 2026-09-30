extends CharacterBody2D
## Homem-gato.
## M1: movimento em 8 direções e colisão.
## M2: dash padrão e dash de rolamento (troca com S), stamina.
## M3: combo de 3 golpes (A), dano do dash padrão, knockback e hitstop.
## M4: parry (Q) com janela de 0,2 s, chute, e dano recebido quando erra.
## A origem do nó fica nos pés, no centro do círculo de colisão.

signal stamina_mudou(atual: int)
signal sem_stamina
signal dash_trocado(tipo: Dash)
signal golpe_iniciado(numero: int)
signal vida_mudou(atual: int)
signal parry_acertado

enum Dash { PADRAO, ROLAMENTO }

const CAMADA_CENARIO := 1
const CAMADA_INIMIGOS := 4  # camada 3 ("inimigos"), em bits

const COR_CORPO := Color(0.93, 0.6, 0.25)
const COR_HITBOX := Color(1, 1, 1, 0.35)
const LARGURA := 18.0
const RASTRO_DURACAO := 0.15
const CHUTE_DURACAO := 0.18
const DANO_PISCAR := 0.3
const TREMOR_DURACAO := 0.2
const TREMOR_FORCA := 3.0

var vida := Valores.GATO_VIDA
var direcao_olhar := Vector2.DOWN
var dash_equipado := Dash.PADRAO
var stamina := Valores.STAMINA_MAXIMA
var em_dash := false

var _tempo := 0.0  # relógio próprio, em segundos de física
var _recarga := 0.0
var _dash_tipo := Dash.PADRAO
var _dash_direcao := Vector2.ZERO
var _dash_restante := 0.0
var _rolamentos: Array[float] = []  # momentos dos rolamentos dentro da janela
var _rastro: Array[Dictionary] = []  # {pos, t}
var _atingidos_no_dash: Array[Node] = []

# Combo: golpe em andamento (0 = nenhum), tempo dentro dele, intervalo até o próximo.
var golpe_atual := 0
var _proximo_golpe := 1
var _golpe_tempo := 0.0
var _golpe_acertou := false
var _intervalo := 0.0
var _ataque_guardado := false  # A apertado durante um golpe: sai assim que puder
var _fim_do_ultimo_golpe := -INF

# Parry: janela aberta, recuperação depois de errar, e efeitos visuais.
var parry_janela := 0.0
var parry_recuperacao := 0.0
var _chute := 0.0
var _chute_direcao := Vector2.RIGHT
var _dano_piscar := 0.0
var _tremor := 0.0

@onready var colisao: CollisionShape2D = $Colisao
@onready var camera: Camera2D = $Camera
@onready var _camera_offset := camera.offset


func _ready() -> void:
	add_to_group("jogador")
	(colisao.shape as CircleShape2D).radius = Valores.GATO_RAIO_HITBOX


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("dash"):
		pedir_dash()
	elif evento.is_action_pressed("trocar_dash"):
		trocar_dash()
	elif evento.is_action_pressed("atacar"):
		pedir_ataque()
	elif evento.is_action_pressed("parry"):
		pedir_parry()


func _physics_process(delta: float) -> void:
	_tempo += delta
	_recuperar_stamina(delta)
	_atualizar_parry(delta)
	if em_dash:
		_mover_dash(delta)
	elif parry_janela > 0.0:
		velocity = Vector2.ZERO  # com a janela aberta, o gato fica no lugar
	else:
		_atualizar_combo(delta)
		if golpe_atual == 0:
			_andar()
		else:
			_avancar_no_golpe()
	_atualizar_rastro()
	queue_redraw()


func _process(delta: float) -> void:
	# Tremor de tela ao tomar dano.
	_tremor = maxf(_tremor - delta, 0.0)
	var forca := TREMOR_FORCA * (_tremor / TREMOR_DURACAO)
	camera.offset = _camera_offset + Vector2(randf_range(-forca, forca), randf_range(-forca, forca))


func _andar() -> void:
	var direcao := _ler_direcao()
	if direcao != Vector2.ZERO:
		direcao_olhar = direcao
	velocity = direcao * Valores.GATO_CAMINHADA
	move_and_slide()


## Devolve a direção do movimento travada em 8 direções, já normalizada.
func _ler_direcao() -> Vector2:
	var entrada := Input.get_vector("mover_esquerda", "mover_direita", "mover_cima", "mover_baixo")
	if entrada == Vector2.ZERO:
		return Vector2.ZERO
	return Vector2.from_angle(snappedf(entrada.angle(), PI / 4.0))


# --- Dash ---------------------------------------------------------------

func trocar_dash() -> void:
	dash_equipado = Dash.ROLAMENTO if dash_equipado == Dash.PADRAO else Dash.PADRAO
	Som.tocar("troca")
	dash_trocado.emit(dash_equipado)


## Começa o dash equipado, se houver stamina. Sem direção apertada, vai para onde o gato olha.
func pedir_dash() -> bool:
	if em_dash or parry_janela > 0.0:
		return false
	var custo := _custo_do_dash(dash_equipado)
	if golpe_atual != 0 or _intervalo > 0.0:
		_cancelar_combo()  # o dash cancela o ataque
	if custo > stamina:
		Som.tocar("falha")
		sem_stamina.emit()
		return false
	if dash_equipado == Dash.ROLAMENTO:
		_rolamentos.append(_tempo)
	_gastar_stamina(custo)
	var direcao := _ler_direcao()
	if direcao != Vector2.ZERO:
		direcao_olhar = direcao
	_dash_direcao = direcao_olhar
	_dash_tipo = dash_equipado
	_dash_restante = Valores.GATO_DASH_COMPRIMENTO if _dash_tipo == Dash.PADRAO else Valores.GATO_ROLAMENTO_COMPRIMENTO
	em_dash = true
	_atingidos_no_dash.clear()
	set_collision_mask_value(3, false)  # no dash, atravessa inimigos
	Som.tocar("dash" if _dash_tipo == Dash.PADRAO else "rolamento")
	return true


## Dash padrão custa 1 unidade. Rolamento é grátis, a não ser que já tenham
## acontecido 2 rolamentos nos últimos 4 s: aí este é o terceiro e custa 1.
func _custo_do_dash(tipo: Dash) -> int:
	if tipo == Dash.PADRAO:
		return Valores.GATO_DASH_CUSTO
	while not _rolamentos.is_empty() and _tempo - _rolamentos[0] >= Valores.GATO_ROLAMENTO_JANELA:
		_rolamentos.pop_front()
	return 0 if _rolamentos.size() < Valores.GATO_ROLAMENTOS_GRATIS else Valores.GATO_DASH_CUSTO


func _mover_dash(delta: float) -> void:
	var veloc := Valores.GATO_DASH_VELOCIDADE if _dash_tipo == Dash.PADRAO else Valores.GATO_ROLAMENTO_VELOCIDADE
	var passo := minf(veloc * delta, _dash_restante)
	velocity = _dash_direcao * veloc
	_rastro.append({"pos": global_position, "t": _tempo})
	var batida := move_and_collide(_dash_direcao * passo)
	_dash_restante -= passo
	if _dash_tipo == Dash.PADRAO:
		_dano_do_dash()
	# Parede ou obstáculo interrompe o dash no contato.
	if batida != null or _dash_restante <= 0.001:
		em_dash = false
		velocity = Vector2.ZERO
		set_collision_mask_value(3, true)


## O dash padrão fere cada inimigo atravessado uma vez (dano do 3º golpe), sem knockback.
func _dano_do_dash() -> void:
	for inimigo in _inimigos_em(global_position, Valores.GATO_RAIO_HITBOX):
		if inimigo in _atingidos_no_dash:
			continue
		_atingidos_no_dash.append(inimigo)
		_acertar(inimigo, Valores.GATO_DANO_DASH, 0.0)


# --- Combo --------------------------------------------------------------

## A começa o próximo golpe. Se um golpe ou intervalo estiver em andamento, fica guardado.
func pedir_ataque() -> void:
	if em_dash or parry_janela > 0.0:
		return
	if golpe_atual != 0 or _intervalo > 0.0:
		_ataque_guardado = true
		return
	_comecar_golpe()


## "sobra" é o tempo que já passou do fim do intervalo neste quadro, para o ritmo não atrasar.
func _comecar_golpe(sobra := 0.0) -> void:
	if _tempo - _fim_do_ultimo_golpe > Valores.GATO_COMBO_ESQUECE:
		_proximo_golpe = 1
	golpe_atual = _proximo_golpe
	_golpe_tempo = sobra
	_golpe_acertou = false
	_ataque_guardado = false
	var direcao := _ler_direcao()
	if direcao != Vector2.ZERO:
		direcao_olhar = direcao
	Som.tocar("espada" if golpe_atual == 3 else "garra")
	golpe_iniciado.emit(golpe_atual)


func _atualizar_combo(delta: float) -> void:
	if golpe_atual != 0:
		_golpe_tempo += delta
		if not _golpe_acertou and _golpe_tempo >= Valores.GATO_GOLPE_DURACAO * Valores.GATO_GOLPE_IMPACTO:
			_golpe_acertou = true
			_golpe_impacto()
		if _golpe_tempo >= Valores.GATO_GOLPE_DURACAO:
			_terminar_golpe()
	elif _intervalo > 0.0:
		_intervalo -= delta
		if _intervalo <= 0.0:
			var sobra := -_intervalo
			_intervalo = 0.0
			if _ataque_guardado:
				_comecar_golpe(sobra)


## Cada golpe dá um passo curto para a frente até o impacto e depois fica parado.
## O passo compensa o knockback, para o combo continuar alcançando o inimigo.
func _avancar_no_golpe() -> void:
	var tempo_ate_impacto := Valores.GATO_GOLPE_DURACAO * Valores.GATO_GOLPE_IMPACTO
	if _golpe_tempo < tempo_ate_impacto:
		velocity = direcao_olhar * (Valores.GATO_GOLPE_AVANCO / tempo_ate_impacto)
	else:
		velocity = Vector2.ZERO
	move_and_slide()


func _terminar_golpe() -> void:
	var sobra := _golpe_tempo - Valores.GATO_GOLPE_DURACAO
	match golpe_atual:
		1: _intervalo = Valores.GATO_INTERVALO_GOLPE_1_2 - sobra
		2: _intervalo = Valores.GATO_INTERVALO_GOLPE_2_3 - sobra
		_: _intervalo = -sobra  # depois do golpe 3 não há intervalo
	_proximo_golpe = golpe_atual % 3 + 1
	golpe_atual = 0
	_fim_do_ultimo_golpe = _tempo
	if _intervalo <= 0.0:
		sobra = -_intervalo
		_intervalo = 0.0
		if _ataque_guardado:
			_comecar_golpe(sobra)


func _cancelar_combo() -> void:
	golpe_atual = 0
	_intervalo = 0.0
	_ataque_guardado = false
	_proximo_golpe = 1


func _golpe_impacto() -> void:
	var dano := Valores.GATO_DANO_ESPADA if golpe_atual == 3 else Valores.GATO_DANO_GARRA
	var centro := global_position + direcao_olhar * Valores.GATO_RAIO_HITBOX
	for inimigo in _inimigos_em(centro, Valores.GATO_ALCANCE_ATAQUE / 2.0):
		if _obstaculo_entre(inimigo):
			continue
		_acertar(inimigo, dano, Valores.KNOCKBACK_PADRAO)


## Árvores e obstáculos bloqueiam ataques físicos.
func _obstaculo_entre(alvo: Node2D) -> bool:
	var consulta := PhysicsRayQueryParameters2D.create(global_position, alvo.global_position, CAMADA_CENARIO)
	return not get_world_2d().direct_space_state.intersect_ray(consulta).is_empty()


func _inimigos_em(centro: Vector2, raio: float) -> Array[Node]:
	var forma := CircleShape2D.new()
	forma.radius = raio
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma
	consulta.transform = Transform2D(0.0, centro)
	consulta.collision_mask = CAMADA_INIMIGOS
	var achados: Array[Node] = []
	for resultado in get_world_2d().direct_space_state.intersect_shape(consulta):
		var corpo: Node = resultado.collider
		if corpo.has_method("receber_dano") and not corpo.morto and corpo not in achados:
			achados.append(corpo)
	return achados


func _acertar(inimigo: Node, dano: int, empurrao: float) -> void:
	inimigo.receber_dano(dano, inimigo.global_position - global_position, empurrao)
	Som.tocar("impacto")
	_hitstop()


func _hitstop() -> void:
	if Valores.HITSTOP <= 0.0:
		return
	Engine.time_scale = 0.0
	await get_tree().create_timer(Valores.HITSTOP, true, false, true).timeout
	Engine.time_scale = 1.0


func _atualizar_rastro() -> void:
	while not _rastro.is_empty() and _tempo - _rastro[0].t > RASTRO_DURACAO:
		_rastro.pop_front()


# --- Parry --------------------------------------------------------------

## Q abre a janela de parry. Não abre durante o dash, nem na recuperação de um parry errado.
## Abrir o parry cancela o golpe em andamento.
func pedir_parry() -> bool:
	if em_dash or parry_janela > 0.0 or parry_recuperacao > 0.0:
		return false
	if golpe_atual != 0 or _intervalo > 0.0:
		_cancelar_combo()
	parry_janela = Valores.GATO_PARRY_JANELA
	Som.tocar("parry")
	return true


func _atualizar_parry(delta: float) -> void:
	_chute = maxf(_chute - delta, 0.0)
	_dano_piscar = maxf(_dano_piscar - delta, 0.0)
	if parry_recuperacao > 0.0:
		parry_recuperacao = maxf(parry_recuperacao - delta, 0.0)
	if parry_janela > 0.0:
		parry_janela -= delta
		if parry_janela <= 0.0:
			# A janela fechou sem defender nada: parry errado.
			parry_janela = 0.0
			parry_recuperacao = Valores.GATO_PARRY_RECUPERACAO


## Todo ataque inimigo passa por aqui. Com a janela aberta, é defendido: o gato
## chuta e o atacante é lançado e atordoado. Sem a janela, o gato toma o dano.
## Devolve true se o ataque foi defendido.
func receber_ataque(atacante: Node2D, dano: int) -> bool:
	var direcao := (atacante.global_position - global_position).normalized()
	if parry_janela > 0.0:
		parry_janela = 0.0
		_chute = CHUTE_DURACAO
		_chute_direcao = direcao
		direcao_olhar = Vector2.from_angle(snappedf(direcao.angle(), PI / 4.0))
		if atacante.has_method("receber_parry"):
			atacante.receber_parry(direcao)
		Som.tocar("clang")
		_hitstop()
		parry_acertado.emit()
		return true
	vida = maxi(vida - dano, 0)
	_dano_piscar = DANO_PISCAR
	_tremor = TREMOR_DURACAO
	Som.tocar("dano")
	vida_mudou.emit(vida)
	return false


# --- Stamina ------------------------------------------------------------

func _gastar_stamina(quanto: int) -> void:
	if quanto <= 0:
		return
	if stamina >= Valores.STAMINA_MAXIMA:
		_recarga = 0.0  # a contagem começa quando a stamina sai do máximo
	stamina -= quanto
	stamina_mudou.emit(stamina)


## Com a stamina abaixo do máximo, recupera 1 unidade a cada GATO_STAMINA_RECUPERACAO segundos.
func _recuperar_stamina(delta: float) -> void:
	if stamina >= Valores.STAMINA_MAXIMA:
		_recarga = 0.0
		return
	_recarga += delta
	if _recarga >= Valores.GATO_STAMINA_RECUPERACAO:
		_recarga -= Valores.GATO_STAMINA_RECUPERACAO
		stamina += 1
		stamina_mudou.emit(stamina)


## Quanto falta para a próxima unidade, de 0 a 1 (para a HUD).
func progresso_recarga() -> float:
	return _recarga / Valores.GATO_STAMINA_RECUPERACAO


# --- Desenho provisório -------------------------------------------------

## Golpes 1 e 2: três riscos de garra, um de cada lado. Golpe 3: corte largo da espada.
func _desenhar_golpe(raio: float) -> void:
	var p := clampf(_golpe_tempo / Valores.GATO_GOLPE_DURACAO, 0.0, 1.0)
	var alpha := 1.0 - p * 0.7
	var angulo := direcao_olhar.angle()
	var centro := direcao_olhar * raio
	var alcance := Valores.GATO_ALCANCE_ATAQUE
	if golpe_atual == 3:
		var abertura := PI * 0.9
		var ini := angulo - abertura / 2.0
		draw_arc(centro, alcance * 0.75, ini, ini + abertura * minf(p * 2.0, 1.0), 16, Color(1, 1, 1, alpha), 3.0)
		draw_arc(centro, alcance * 0.5, ini, ini + abertura * minf(p * 2.0, 1.0), 16, Color(0.8, 0.9, 1, alpha * 0.6), 1.0)
		return
	var lado := -1.0 if golpe_atual == 1 else 1.0
	for i in 3:
		var desvio := (i - 1) * 0.3
		var a := angulo + lado * 0.5 + desvio
		var b := angulo - lado * 0.5 + desvio
		var r := alcance * (0.55 + i * 0.1)
		draw_line(centro + Vector2.from_angle(a) * r * 0.4, centro + Vector2.from_angle(lerpf(a, b, minf(p * 2.0, 1.0))) * r, Color(1, 1, 1, alpha), 1.0)

func _draw() -> void:
	var raio := Valores.GATO_RAIO_HITBOX
	var topo := raio - Valores.GATO_ALTURA
	var corpo := Rect2(-LARGURA / 2.0, topo, LARGURA, Valores.GATO_ALTURA)
	# Rastro do dash: cópias do corpo que somem.
	for fantasma in _rastro:
		var vida: float = 1.0 - (_tempo - fantasma.t) / RASTRO_DURACAO
		var cor := Color(1, 0.85, 0.6, 0.35 * vida)
		var local := to_local(fantasma.pos)
		if _dash_tipo == Dash.ROLAMENTO:
			draw_circle(local + Vector2(0, -raio), raio + 2.0, cor)
		else:
			draw_rect(Rect2(corpo.position + local, corpo.size), cor)
	if em_dash and _dash_tipo == Dash.ROLAMENTO:
		# Rolamento: o gato vira uma bola, com uma faixa girando.
		var centro := Vector2(0, -raio)
		draw_circle(centro, raio + 2.0, COR_CORPO)
		var giro := Vector2.from_angle(_tempo * 40.0) * (raio + 1.0)
		draw_line(centro - giro, centro + giro, COR_CORPO.darkened(0.4), 2.0)
	else:
		draw_rect(corpo, COR_CORPO)
	draw_arc(Vector2.ZERO, raio, 0.0, TAU, 24, COR_HITBOX, 1.0)
	if golpe_atual != 0:
		_desenhar_golpe(raio)
	var ponta := direcao_olhar * (raio + 7.0)
	var lado := direcao_olhar.orthogonal() * 3.0
	var base := direcao_olhar * (raio + 2.0)
	draw_colored_polygon(PackedVector2Array([ponta, base + lado, base - lado]), Color.WHITE)
