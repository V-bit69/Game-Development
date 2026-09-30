extends CharacterBody2D
## Homem-gato.
## M1: movimento em 8 direções e colisão.
## M2: dash padrão e dash de rolamento (troca com S), stamina.
## A origem do nó fica nos pés, no centro do círculo de colisão.

signal stamina_mudou(atual: int)
signal sem_stamina
signal dash_trocado(tipo: Dash)

enum Dash { PADRAO, ROLAMENTO }

const COR_CORPO := Color(0.93, 0.6, 0.25)
const COR_HITBOX := Color(1, 1, 1, 0.35)
const LARGURA := 18.0
const RASTRO_DURACAO := 0.15

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

@onready var colisao: CollisionShape2D = $Colisao
@onready var camera: Camera2D = $Camera


func _ready() -> void:
	add_to_group("jogador")
	(colisao.shape as CircleShape2D).radius = Valores.GATO_RAIO_HITBOX


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("dash"):
		pedir_dash()
	elif evento.is_action_pressed("trocar_dash"):
		trocar_dash()


func _physics_process(delta: float) -> void:
	_tempo += delta
	_recuperar_stamina(delta)
	if em_dash:
		_mover_dash(delta)
	else:
		_andar()
	_atualizar_rastro()
	queue_redraw()


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
	if em_dash:
		return false
	var custo := _custo_do_dash(dash_equipado)
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
	# Parede ou obstáculo interrompe o dash no contato.
	if batida != null or _dash_restante <= 0.001:
		em_dash = false
		velocity = Vector2.ZERO


func _atualizar_rastro() -> void:
	while not _rastro.is_empty() and _tempo - _rastro[0].t > RASTRO_DURACAO:
		_rastro.pop_front()


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
	var ponta := direcao_olhar * (raio + 7.0)
	var lado := direcao_olhar.orthogonal() * 3.0
	var base := direcao_olhar * (raio + 2.0)
	draw_colored_polygon(PackedVector2Array([ponta, base + lado, base - lado]), Color.WHITE)
