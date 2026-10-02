class_name Inimigo
extends CharacterBody2D
## Base de todos os inimigos: vida em unidades, dano, knockback, piscar branco,
## quadradinhos de vida embaixo do sprite, parry (atordoa 0,5 s; depois o chute
## empurra e atordoa por mais 1,5 s),
## entrada pulando nos encontros e morte (o corpo fica no chão, a não ser
## em cima de um ponto de interesse). A origem fica nos pés, no centro da hitbox.

signal morreu(inimigo: Inimigo)

const PISCAR_DURACAO := 0.1
const KNOCKBACK_DURACAO := 0.1
const ENTRADA_DURACAO := 0.35
const ENTRADA_ALTURA := 40.0
const DISTANCIA_INTERESSE := 24.0

@export var vida_maxima := 3
@export var cor := Color(0.35, 0.62, 0.3)

var vida := 0
var morto := false
## Durante um avanço (investida) o knockback dos golpes não se aplica.
var em_avanco := false
## Tempo restante de atordoamento. Atordoado, o inimigo não age.
var atordoado := 0.0
## Esperando o gatilho do encontro: invisível, sem colisão e parado.
var dormindo := false

var _piscar := 0.0
var _empurrao := Vector2.ZERO  # velocidade do knockback em andamento
var _empurrao_restante := 0.0  # segundos
var _atordoar_depois := false  # o parry atordoa quando o empurrão termina
var _relogio := 0.0
var _entrada := 0.0  # tempo restante da entrada pulando
var _atraso_entrada := 0.0
var _pedido_de_acordar := false

@onready var colisao: CollisionShape2D = $Colisao


func _ready() -> void:
	vida = vida_maxima
	add_to_group("inimigos")
	if dormindo:
		visible = false
		colisao.disabled = true


## Chamado pelo gatilho do encontro. O inimigo entra pulando depois do atraso.
func acordar(atraso := 0.0) -> void:
	if not dormindo:
		return
	_pedido_de_acordar = true
	_atraso_entrada = atraso


func _comecar_entrada() -> void:
	dormindo = false
	visible = true
	_entrada = ENTRADA_DURACAO
	Som.tocar("salto")


## Aplica dano. "empurrao" é a distância do knockback na direção dada (0 = sem knockback).
func receber_dano(dano: int, direcao := Vector2.ZERO, empurrao := 0.0) -> void:
	if morto or dormindo or _entrada > 0.0:
		return
	vida = maxi(vida - dano, 0)
	_piscar = PISCAR_DURACAO
	if empurrao > 0.0 and not em_avanco and direcao != Vector2.ZERO:
		_empurrar(direcao, empurrao, empurrao / KNOCKBACK_DURACAO)
	if vida == 0:
		_morrer()
	queue_redraw()


## Parry do jogador, primeira ação: a defesa com a espada interrompe o ataque e
## deixa o inimigo atordoado até o chute (0,5 s). Vale mesmo no meio de um avanço.
## Devolve true: o chute vem depois (a língua do sapo muda isso).
func receber_parry(_direcao: Vector2) -> bool:
	if morto:
		return false
	_interromper()
	em_avanco = false
	atordoado = Valores.GATO_PARRY_ESPERA_CHUTE
	return true


## Parry, segunda ação: o chute lança o inimigo para trás (1 dash padrão) e, no
## fim do empurrão, deixa ele atordoado por mais 1,5 s.
func receber_chute(direcao: Vector2) -> void:
	if morto:
		return
	atordoado = 0.0
	_empurrar(direcao, Valores.GATO_PARRY_KNOCKBACK, Valores.PARRY_KNOCKBACK_VELOCIDADE)
	_atordoar_depois = true


func _empurrar(direcao: Vector2, distancia: float, velocidade: float) -> void:
	_empurrao = direcao.normalized() * velocidade
	_empurrao_restante = distancia / velocidade


func _morrer() -> void:
	morto = true
	atordoado = 0.0
	_interromper()
	colisao.set_deferred("disabled", true)
	get_parent().move_child.call_deferred(self, 0)  # corpo caído fica embaixo dos vivos
	Som.tocar("morte")
	_particulas()
	morreu.emit(self)
	# Em cima de um ponto de interesse (estátua, flor, elemento, entrada), o corpo some.
	for ponto in get_tree().get_nodes_in_group("interesse"):
		if (ponto as Node2D).global_position.distance_to(global_position) <= DISTANCIA_INTERESSE:
			var sumir := create_tween()
			sumir.tween_property(self, "modulate:a", 0.0, 0.4)
			sumir.tween_callback(queue_free)
			break


func _particulas() -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = 14
	p.lifetime = 0.45
	p.explosiveness = 1.0
	p.direction = Vector2.UP
	p.spread = 180.0
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 80.0
	p.gravity = Vector2(0, 160)
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	p.color = cor.lightened(0.2)
	p.position = Vector2(0, -4)
	add_child(p)
	p.finished.connect(p.queue_free)


func _physics_process(delta: float) -> void:
	_relogio += delta
	if dormindo:
		if _pedido_de_acordar:
			_atraso_entrada -= delta
			if _atraso_entrada <= 0.0:
				_comecar_entrada()
		return
	if _entrada > 0.0:
		_entrada = maxf(_entrada - delta, 0.0)
		if _entrada == 0.0:
			colisao.disabled = false
		queue_redraw()
		return
	_piscar = maxf(_piscar - delta, 0.0)
	if _empurrao_restante > 0.0:
		var passo := minf(delta, _empurrao_restante)
		_empurrao_restante -= passo
		# Parede e obstáculo seguram o empurrão.
		if move_and_collide(_empurrao * passo) != null:
			_empurrao_restante = 0.0
		if _empurrao_restante <= 0.0 and _atordoar_depois:
			_atordoar_depois = false
			atordoado = Valores.GATO_PARRY_ATORDOAMENTO
	elif atordoado > 0.0:
		atordoado = maxf(atordoado - delta, 0.0)
	elif not morto:
		_agir(delta)
	queue_redraw()


## Comportamento de cada inimigo. A base fica parada (alvo de treino).
func _agir(_delta: float) -> void:
	pass


## Cancela a ação em andamento (chamado pelo parry, pela morte e pelos golpes no salto).
func _interromper() -> void:
	pass


## Cor do corpo neste quadro. Os inimigos podem mudar (por exemplo, no telegraph).
func _cor_do_corpo() -> Color:
	return cor


## Deslocamento do desenho neste quadro (vibração do telegraph, altura do salto).
func _tremor() -> Vector2:
	return Vector2.ZERO


## Escala do corpo neste quadro (achatado no telegraph).
func _escala() -> Vector2:
	return Vector2.ONE


func _draw() -> void:
	var tamanho: Vector2 = (colisao.shape as RectangleShape2D).size
	if morto:
		# Corpo caído: achatado e escuro.
		draw_rect(Rect2(-tamanho.x / 2.0 - 2.0, -3.0, tamanho.x + 4.0, 5.0), cor.darkened(0.55))
		return
	var o := _tremor()
	if _entrada > 0.0:
		# Entrando: cai do alto, com sombra no chão.
		var p := 1.0 - _entrada / ENTRADA_DURACAO
		o += Vector2(0, -ENTRADA_ALTURA * (1.0 - p * p))
	if o.y < -0.5:
		draw_rect(Rect2(-tamanho.x / 2.0, tamanho.y / 2.0 - 3.0, tamanho.x, 4.0), Color(0, 0, 0, 0.3))
	var medida := tamanho * _escala()
	var canto := Vector2(-medida.x / 2.0, tamanho.y / 2.0 - medida.y) + o
	var corpo_cor := Color.WHITE if _piscar > 0.0 else _cor_do_corpo()
	draw_rect(Rect2(canto, medida), corpo_cor)
	draw_rect(Rect2(canto + Vector2(3.0, -2.0), Vector2(3, 3)), Color.WHITE)
	draw_rect(Rect2(canto + Vector2(medida.x - 6.0, -2.0), Vector2(3, 3)), Color.WHITE)
	if atordoado > 0.0:
		# Atordoado: três pontinhos girando em cima da cabeça.
		for i in 3:
			var a := _relogio * 8.0 + i * TAU / 3.0
			var ponto := Vector2(0, -tamanho.y / 2.0 - 6.0) + Vector2(cos(a) * 8.0, sin(a) * 2.5)
			draw_rect(Rect2(ponto - Vector2(1, 1), Vector2(2, 2)), Color(1, 0.95, 0.4))
	# Vida: um quadradinho por unidade, embaixo do sprite.
	var lado := 3.0
	var largura := vida_maxima * (lado + 1.0) - 1.0
	for i in vida_maxima:
		var q := Rect2(-largura / 2.0 + i * (lado + 1.0), tamanho.y / 2.0 + 3.0, lado, lado)
		draw_rect(q.grow(0.5), Color(0, 0, 0, 0.7))
		draw_rect(q, Color(0.95, 0.3, 0.3) if i < vida else Color(0.2, 0.2, 0.2))
