class_name Inimigo
extends CharacterBody2D
## Base de todos os inimigos: vida em unidades, dano, knockback, piscar branco,
## quadradinhos de vida embaixo do sprite, parry (empurrão + atordoamento) e
## morte (o corpo fica no chão). A origem fica nos pés, no centro da hitbox.

signal morreu(inimigo: Inimigo)

const PISCAR_DURACAO := 0.1
const KNOCKBACK_DURACAO := 0.1

@export var vida_maxima := 3
@export var cor := Color(0.35, 0.62, 0.3)

var vida := 0
var morto := false
## Durante um avanço (salto, investida) o knockback dos golpes não se aplica.
var em_avanco := false
## Tempo restante de atordoamento. Atordoado, o inimigo não age.
var atordoado := 0.0

var _piscar := 0.0
var _empurrao := Vector2.ZERO  # velocidade do knockback em andamento
var _empurrao_restante := 0.0  # segundos
var _atordoar_depois := false  # o parry atordoa quando o empurrão termina
var _relogio := 0.0

@onready var colisao: CollisionShape2D = $Colisao


func _ready() -> void:
	vida = vida_maxima
	add_to_group("inimigos")


## Aplica dano. "empurrao" é a distância do knockback na direção dada (0 = sem knockback).
func receber_dano(dano: int, direcao := Vector2.ZERO, empurrao := 0.0) -> void:
	if morto:
		return
	vida = maxi(vida - dano, 0)
	_piscar = PISCAR_DURACAO
	if empurrao > 0.0 and not em_avanco and direcao != Vector2.ZERO:
		_empurrar(direcao, empurrao, empurrao / KNOCKBACK_DURACAO)
	if vida == 0:
		_morrer()
	queue_redraw()


## Parry do jogador: interrompe a ação, lança o inimigo para trás e, no fim do
## empurrão, deixa ele atordoado. Vale mesmo no meio de um avanço.
func receber_parry(direcao: Vector2) -> void:
	if morto:
		return
	_interromper()
	em_avanco = false
	_empurrar(direcao, Valores.GATO_PARRY_KNOCKBACK, Valores.PARRY_KNOCKBACK_VELOCIDADE)
	_atordoar_depois = true


func _empurrar(direcao: Vector2, distancia: float, velocidade: float) -> void:
	_empurrao = direcao.normalized() * velocidade
	_empurrao_restante = distancia / velocidade


func _morrer() -> void:
	morto = true
	atordoado = 0.0
	colisao.set_deferred("disabled", true)
	get_parent().move_child.call_deferred(self, 0)  # corpo caído fica embaixo dos vivos
	Som.tocar("morte")
	morreu.emit(self)


func _physics_process(delta: float) -> void:
	_relogio += delta
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


## Cancela a ação em andamento (chamado pelo parry). Cada inimigo limpa o próprio estado.
func _interromper() -> void:
	pass


## Cor do corpo neste quadro. Os inimigos podem mudar (por exemplo, no telegraph).
func _cor_do_corpo() -> Color:
	return cor


## Deslocamento do desenho neste quadro (vibração do telegraph).
func _tremor() -> Vector2:
	return Vector2.ZERO


func _draw() -> void:
	var tamanho: Vector2 = (colisao.shape as RectangleShape2D).size
	if morto:
		# Corpo caído: achatado e escuro.
		draw_rect(Rect2(-tamanho.x / 2.0 - 2.0, -3.0, tamanho.x + 4.0, 5.0), cor.darkened(0.55))
		return
	var o := _tremor()
	var corpo_cor := Color.WHITE if _piscar > 0.0 else _cor_do_corpo()
	draw_rect(Rect2(-tamanho / 2.0 + o, tamanho), corpo_cor)
	draw_rect(Rect2(o + Vector2(-tamanho.x / 2.0 + 3.0, -tamanho.y / 2.0 - 2.0), Vector2(3, 3)), Color.WHITE)
	draw_rect(Rect2(o + Vector2(tamanho.x / 2.0 - 6.0, -tamanho.y / 2.0 - 2.0), Vector2(3, 3)), Color.WHITE)
	if atordoado > 0.0:
		# Atordoado: três pontinhos girando em cima da cabeça.
		for i in 3:
			var a := _relogio * 8.0 + i * TAU / 3.0
			var p := Vector2(0, -tamanho.y / 2.0 - 6.0) + Vector2(cos(a) * 8.0, sin(a) * 2.5)
			draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), Color(1, 0.95, 0.4))
	# Vida: um quadradinho por unidade, embaixo do sprite.
	var lado := 3.0
	var largura := vida_maxima * (lado + 1.0) - 1.0
	for i in vida_maxima:
		var q := Rect2(-largura / 2.0 + i * (lado + 1.0), tamanho.y / 2.0 + 3.0, lado, lado)
		draw_rect(q.grow(0.5), Color(0, 0, 0, 0.7))
		draw_rect(q, Color(0.95, 0.3, 0.3) if i < vida else Color(0.2, 0.2, 0.2))
