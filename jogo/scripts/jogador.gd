extends CharacterBody2D
## Homem-gato.
## M1: movimento em 8 direções e colisão.
## M2: dash padrão e dash de rolamento (troca com S), stamina.
## M3: combo de 3 golpes (A), dano do dash padrão, knockback e hitstop.
## M4: parry (Q) com janela de 0,2 s, chute, e dano recebido quando erra.
## M7: pede interação com E (a sala decide com o quê) e mostra o indicador E/D.
## M8: escalada com o dash padrão nos trechos D da ruína.
## M9: vida, morte.
## v1.3: dash ofensivo (2 de stamina), rolamento esquiva projéteis, combo cíclico,
## área de ataque em arco, parry em dois tempos (defesa, 0,5 s, chute) e
## 1,5 s de invulnerabilidade depois de tomar dano.
## A origem do nó fica nos pés, no centro do círculo de colisão.

signal stamina_mudou(atual: int)
signal sem_stamina
signal dash_trocado(tipo: Dash)
signal golpe_iniciado(numero: int)
signal vida_mudou(atual: int)
signal parry_acertado
signal morreu
signal interagir_pedido

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
var morto := false
## Letra do balãozinho em cima da cabeça ("E" ou "D"); vazio = sem balão. A sala define.
var indicador := ""
var em_escalada := false
var _escalada_de := Vector2.ZERO
var _escalada_para := Vector2.ZERO
var _escalada_t := 0.0
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

# Parry: janela aberta, recuperação depois de errar, e efeitos visuais.
var parry_janela := 0.0
var parry_recuperacao := 0.0
var _chute := 0.0
var _chute_espera := 0.0  # entre a defesa e o chute do parry; só o dash cancela
var _chute_alvo: Node2D = null
var invulneravel := 0.0  # recuperação depois de tomar dano
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
	if morto:
		return
	if evento.is_action_pressed("interagir"):
		interagir_pedido.emit()
	elif evento.is_action_pressed("dash"):
		pedir_dash()
	elif evento.is_action_pressed("trocar_dash"):
		trocar_dash()
	elif evento.is_action_pressed("atacar"):
		pedir_ataque()
	elif evento.is_action_pressed("parry"):
		pedir_parry()


func _physics_process(delta: float) -> void:
	_tempo += delta
	if morto:
		queue_redraw()
		return
	_recuperar_stamina(delta)
	_atualizar_parry(delta)
	if em_escalada:
		_mover_escalada(delta)
	elif em_dash:
		_mover_dash(delta)
	elif parry_janela > 0.0 or _chute_espera > 0.0:
		velocity = Vector2.ZERO  # com a janela aberta ou esperando o chute, o gato fica no lugar
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
	if em_dash or em_escalada or parry_janela > 0.0:
		return false
	var custo := _custo_do_dash(dash_equipado)
	if custo > stamina:
		Som.tocar("falha")
		sem_stamina.emit()
		return false
	if golpe_atual != 0 or _intervalo > 0.0:
		_cancelar_combo()  # o dash interrompe o golpe, mas a sequência continua
	if _chute_espera > 0.0:
		_cancelar_chute()  # o dash cancela o chute do parry
	var direcao := _ler_direcao()
	if direcao != Vector2.ZERO:
		direcao_olhar = direcao
	if dash_equipado == Dash.PADRAO and _tentar_escalada():
		_gastar_stamina(custo)
		return true
	if dash_equipado == Dash.ROLAMENTO:
		if custo > 0:
			_rolamentos.clear()  # gastou: a contagem recomeça no próximo rolamento
		else:
			_rolamentos.append(_tempo)
	_gastar_stamina(custo)
	_dash_direcao = direcao_olhar
	_dash_tipo = dash_equipado
	_dash_restante = Valores.GATO_DASH_COMPRIMENTO if _dash_tipo == Dash.PADRAO else Valores.GATO_ROLAMENTO_COMPRIMENTO
	em_dash = true
	_atingidos_no_dash.clear()
	set_collision_mask_value(3, false)  # no dash, atravessa inimigos
	Som.tocar("dash" if _dash_tipo == Dash.PADRAO else "rolamento")
	return true


## Dash ofensivo custa 2 unidades. Rolamento é grátis, a não ser que já tenham
## acontecido 2 rolamentos nos últimos 5 s: aí este é o terceiro e custa 1.
func _custo_do_dash(tipo: Dash) -> int:
	if tipo == Dash.PADRAO:
		return Valores.GATO_DASH_CUSTO
	while not _rolamentos.is_empty() and _tempo - _rolamentos[0] >= Valores.GATO_ROLAMENTO_JANELA:
		_rolamentos.pop_front()
	return 0 if _rolamentos.size() < Valores.GATO_ROLAMENTOS_GRATIS else Valores.GATO_ROLAMENTO_CUSTO


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


## O dash ofensivo fere cada inimigo atravessado uma vez (1 de dano), sem knockback.
func _dano_do_dash() -> void:
	for inimigo in _inimigos_em(global_position, Valores.GATO_RAIO_HITBOX):
		if inimigo in _atingidos_no_dash:
			continue
		_atingidos_no_dash.append(inimigo)
		_acertar(inimigo, Valores.GATO_DANO_DASH, 0.0)


# --- Escalada -----------------------------------------------------------

## Dash padrão perto de um trecho escalável (D) e na direção dele: sobe (ou desce)
## a parede da ruína, com a mesma duração do dash. A sala diz para onde.
func _tentar_escalada() -> bool:
	var sala := get_tree().get_first_node_in_group("sala")
	if sala == null or not sala.has_method("destino_escalada"):
		return false
	var destino: Variant = sala.destino_escalada(global_position, direcao_olhar)
	if destino == null:
		return false
	atravessar_para(destino)
	return true


## Passa por cima da parede até o destino, com a duração do dash (escalada e descida).
func atravessar_para(destino: Vector2) -> void:
	em_escalada = true
	_escalada_de = global_position
	_escalada_para = destino
	_escalada_t = 0.0
	collision_mask = 0  # atravessa a parede durante a subida
	Som.tocar("escalada")


func _mover_escalada(delta: float) -> void:
	var duracao := Valores.GATO_DASH_COMPRIMENTO / Valores.GATO_DASH_VELOCIDADE
	_escalada_t = minf(_escalada_t + delta / duracao, 1.0)
	_rastro.append({"pos": global_position, "t": _tempo})
	global_position = _escalada_de.lerp(_escalada_para, _escalada_t)
	velocity = Vector2.ZERO
	if _escalada_t >= 1.0:
		em_escalada = false
		collision_mask = CAMADA_CENARIO | CAMADA_INIMIGOS


# --- Combo --------------------------------------------------------------

## A começa o próximo golpe. Se um golpe ou intervalo estiver em andamento, fica guardado.
func pedir_ataque() -> void:
	if em_dash or parry_janela > 0.0 or _chute_espera > 0.0:
		return
	if golpe_atual != 0 or _intervalo > 0.0:
		_ataque_guardado = true
		return
	_comecar_golpe()


## "sobra" é o tempo que já passou do fim do intervalo neste quadro, para o ritmo não atrasar.
func _comecar_golpe(sobra := 0.0) -> void:
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
	if _intervalo <= 0.0:
		sobra = -_intervalo
		_intervalo = 0.0
		if _ataque_guardado:
			_comecar_golpe(sobra)


## O combo é cíclico e nunca volta ao golpe 1: um golpe interrompido conta como dado.
func _cancelar_combo() -> void:
	if golpe_atual != 0:
		_proximo_golpe = golpe_atual % 3 + 1
	golpe_atual = 0
	_intervalo = 0.0
	_ataque_guardado = false


func _golpe_impacto() -> void:
	var espada := golpe_atual == 3
	var dano := Valores.GATO_DANO_ESPADA if espada else Valores.GATO_DANO_GARRA
	var alcance := Valores.GATO_ALCANCE_GOLPE_3 if espada else Valores.GATO_ALCANCE_ATAQUE
	var angulo := Valores.GATO_ANGULO_GOLPE_3 if espada else Valores.GATO_ANGULO_ATAQUE
	for inimigo in _inimigos_em(global_position, alcance):
		if not _dentro_do_angulo(inimigo, angulo) or _obstaculo_entre(inimigo):
			continue
		_acertar(inimigo, dano, Valores.KNOCKBACK_PADRAO)


## A área de ataque é um arco à frente do gato. Vale o ponto do inimigo mais
## perto da linha do golpe, para um inimigo grande não escapar pela borda.
func _dentro_do_angulo(inimigo: Node2D, graus: float) -> bool:
	var ponto := inimigo.global_position
	var forma: Variant = inimigo.colisao.shape if "colisao" in inimigo else null
	if forma is RectangleShape2D:
		var metade: Vector2 = (forma as RectangleShape2D).size / 2.0
		var mira := global_position + direcao_olhar * Valores.GATO_ALCANCE_ATAQUE
		ponto = inimigo.global_position + (mira - inimigo.global_position).clamp(-metade, metade)
	var para := ponto - global_position
	if para.length() < 0.5:
		return true
	return absf(rad_to_deg(direcao_olhar.angle_to(para))) <= graus / 2.0


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
	if em_dash or parry_janela > 0.0 or parry_recuperacao > 0.0 or _chute_espera > 0.0:
		return false
	if golpe_atual != 0 or _intervalo > 0.0:
		_cancelar_combo()
	parry_janela = Valores.GATO_PARRY_JANELA
	Som.tocar("parry")
	return true


func _atualizar_parry(delta: float) -> void:
	_chute = maxf(_chute - delta, 0.0)
	_dano_piscar = maxf(_dano_piscar - delta, 0.0)
	invulneravel = maxf(invulneravel - delta, 0.0)
	if _chute_espera > 0.0:
		_chute_espera -= delta
		if _chute_espera <= 0.0:
			_chutar()
	if parry_recuperacao > 0.0:
		parry_recuperacao = maxf(parry_recuperacao - delta, 0.0)
	if parry_janela > 0.0:
		parry_janela -= delta
		if parry_janela <= 0.0:
			# A janela fechou sem defender nada: parry errado.
			parry_janela = 0.0
			parry_recuperacao = Valores.GATO_PARRY_RECUPERACAO


## Todo ataque inimigo passa por aqui. Com a janela aberta, é defendido com a
## espada: o atacante fica atordoado 0,5 s e só então leva o chute, que lança e
## atordoa por mais 1,5 s. A língua é rebatida com o chute na hora.
## Sem a janela, o gato toma o dano e fica 1,5 s invulnerável.
## Devolve true se o ataque foi defendido (ou não fez efeito).
func receber_ataque(atacante: Node2D, dano: int) -> bool:
	if morto or em_escalada:
		return false
	var direcao := (atacante.global_position - global_position).normalized()
	if parry_janela > 0.0:
		parry_janela = 0.0
		direcao_olhar = Vector2.from_angle(snappedf(direcao.angle(), PI / 4.0))
		_chute_direcao = direcao
		var chute_depois := true
		if atacante.has_method("receber_parry"):
			chute_depois = atacante.receber_parry(direcao)
		if chute_depois:
			_chute_espera = Valores.GATO_PARRY_ESPERA_CHUTE
			_chute_alvo = atacante
		else:
			_chute = CHUTE_DURACAO  # língua: chute imediato
		Som.tocar("clang")
		_hitstop()
		parry_acertado.emit()
		return true
	if invulneravel > 0.0:
		return true
	vida = maxi(vida - dano, 0)
	invulneravel = Valores.GATO_INVULNERAVEL
	_dano_piscar = DANO_PISCAR
	_tremor = TREMOR_DURACAO
	Som.tocar("dano")
	vida_mudou.emit(vida)
	if vida == 0:
		_morrer()
	return false


## Segunda ação do parry: o chute lança o inimigo e o deixa atordoado.
func _chutar() -> void:
	_chute_espera = 0.0
	_chute = CHUTE_DURACAO
	if is_instance_valid(_chute_alvo) and not _chute_alvo.morto and _chute_alvo.has_method("receber_chute"):
		_chute_direcao = (_chute_alvo.global_position - global_position).normalized()
		_chute_alvo.receber_chute(_chute_direcao)
		Som.tocar("impacto")
	_chute_alvo = null


## Dash no meio da espera: o chute não sai e o inimigo fica só com os 0,5 s.
func _cancelar_chute() -> void:
	_chute_espera = 0.0
	_chute_alvo = null


## O rolamento esquiva de ataques com a tag "projétil" (a língua do sapo).
func esquivando_projetil() -> bool:
	return em_dash and _dash_tipo == Dash.ROLAMENTO


## Tempo que ainda resta do piscar de dano (a HUD usa para a borda vermelha).
func piscar_de_dano() -> float:
	return _dano_piscar / DANO_PISCAR


func _morrer() -> void:
	morto = true
	em_dash = false
	em_escalada = false
	parry_janela = 0.0
	_cancelar_chute()
	_cancelar_combo()
	velocity = Vector2.ZERO
	Som.tocar("morte_gato")
	morreu.emit()


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

## Chute do parry: perna esticada na direção do atacante e uma faísca no contato.
func _desenhar_chute(raio: float) -> void:
	var p := 1.0 - _chute / CHUTE_DURACAO
	var quadril := Vector2(0, -raio * 0.6)
	var pe := quadril + _chute_direcao * (raio + 12.0)
	draw_line(quadril, pe, COR_CORPO.darkened(0.2), 4.0)
	var brilho := Color(1, 1, 0.7, 1.0 - p)
	for i in 6:
		var a := i * TAU / 6.0 + p
		draw_line(pe + Vector2.from_angle(a) * 2.0, pe + Vector2.from_angle(a) * (4.0 + 8.0 * p), brilho, 1.0)


## Balãozinho com a tecla da ação disponível (E para interagir, D para escalar).
func _desenhar_indicador(topo: float) -> void:
	var centro := Vector2(0, topo - 10.0 + sin(_tempo * 6.0) * 1.0)
	var caixa := Rect2(centro - Vector2(6, 6), Vector2(12, 12))
	draw_rect(caixa.grow(1.0), Color.BLACK)
	draw_rect(caixa, Color.WHITE)
	var fonte := ThemeDB.fallback_font
	draw_string(fonte, centro + Vector2(-3.5, 4), indicador, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.BLACK)

## Golpes 1 e 2: três riscos de garra, um de cada lado. Golpe 3: corte largo da espada.
func _desenhar_golpe(raio: float) -> void:
	var p := clampf(_golpe_tempo / Valores.GATO_GOLPE_DURACAO, 0.0, 1.0)
	var alpha := 1.0 - p * 0.7
	var angulo := direcao_olhar.angle()
	var centro := direcao_olhar * raio
	var alcance := Valores.GATO_ALCANCE_ATAQUE
	if golpe_atual == 3:
		# Corte vertical: arco estreito (60°) e mais comprido (25 px).
		var abertura := deg_to_rad(Valores.GATO_ANGULO_GOLPE_3)
		var ini := angulo - abertura / 2.0
		var r3 := Valores.GATO_ALCANCE_GOLPE_3
		draw_arc(Vector2.ZERO, r3, ini, ini + abertura * minf(p * 2.0, 1.0), 12, Color(1, 1, 1, alpha), 3.0)
		draw_line(Vector2.ZERO, Vector2.from_angle(angulo) * r3 * minf(p * 2.0, 1.0), Color(0.8, 0.9, 1, alpha * 0.6), 1.0)
		return
	# Contorno da área (120°), bem fraco, para conferir o alcance no protótipo.
	var meia := deg_to_rad(Valores.GATO_ANGULO_ATAQUE) / 2.0
	draw_arc(Vector2.ZERO, alcance, angulo - meia, angulo + meia, 12, Color(1, 1, 1, alpha * 0.25), 1.0)
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
		var resto: float = 1.0 - (_tempo - fantasma.t) / RASTRO_DURACAO
		var cor := Color(1, 0.85, 0.6, 0.35 * resto)
		var local := to_local(fantasma.pos)
		if _dash_tipo == Dash.ROLAMENTO:
			draw_circle(local + Vector2(0, -raio), raio + 2.0, cor)
		else:
			draw_rect(Rect2(corpo.position + local, corpo.size), cor)
	if morto:
		# Caído de lado.
		draw_rect(Rect2(-Valores.GATO_ALTURA / 2.0, -8.0, Valores.GATO_ALTURA, 14.0), COR_CORPO.darkened(0.35))
		return
	var cor_corpo := COR_CORPO
	if _dano_piscar > 0.0 and int(_dano_piscar * 20.0) % 2 == 0:
		cor_corpo = Color(1, 0.3, 0.3)
	elif invulneravel > 0.0 and int(invulneravel * 12.0) % 2 == 0:
		cor_corpo = Color(cor_corpo, 0.35)  # piscando enquanto está invulnerável
	elif _chute_espera > 0.0:
		cor_corpo = COR_CORPO.lerp(Color(0.6, 0.9, 1.0), 0.35)
	elif parry_janela > 0.0:
		cor_corpo = COR_CORPO.lerp(Color(0.6, 0.9, 1.0), 0.6)
	if em_escalada:
		# Subindo: o corpo estica um pouco na direção da parede.
		draw_rect(Rect2(corpo.position + Vector2(2, -4), corpo.size + Vector2(-4, 8)), cor_corpo)
	elif em_dash and _dash_tipo == Dash.ROLAMENTO:
		# Rolamento: o gato vira uma bola, com uma faixa girando.
		var centro := Vector2(0, -raio)
		draw_circle(centro, raio + 2.0, COR_CORPO)
		var giro := Vector2.from_angle(_tempo * 40.0) * (raio + 1.0)
		draw_line(centro - giro, centro + giro, COR_CORPO.darkened(0.4), 2.0)
	else:
		draw_rect(corpo, cor_corpo)
	draw_arc(Vector2.ZERO, raio, 0.0, TAU, 24, COR_HITBOX, 1.0)
	if parry_janela > 0.0:
		draw_arc(Vector2(0, -raio), raio + 6.0, 0.0, TAU, 24, Color(0.6, 0.9, 1.0, 0.9), 1.0)
	if _chute > 0.0:
		_desenhar_chute(raio)
	if indicador != "":
		_desenhar_indicador(topo)
	if golpe_atual != 0:
		_desenhar_golpe(raio)
	var ponta := direcao_olhar * (raio + 7.0)
	var lado := direcao_olhar.orthogonal() * 3.0
	var base := direcao_olhar * (raio + 2.0)
	draw_colored_polygon(PackedVector2Array([ponta, base + lado, base - lado]), Color.WHITE)
