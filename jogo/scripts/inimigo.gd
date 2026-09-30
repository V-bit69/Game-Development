class_name Inimigo
extends CharacterBody2D
## Base de todos os inimigos: vida em unidades, dano, knockback, piscar branco,
## quadradinhos de vida embaixo do sprite e morte (o corpo fica no chão).
## A origem fica nos pés, no centro da hitbox.

signal morreu(inimigo: Inimigo)

const PISCAR_DURACAO := 0.1
const KNOCKBACK_DURACAO := 0.1

@export var vida_maxima := 3
@export var cor := Color(0.35, 0.62, 0.3)

var vida := 0
var morto := false
## Durante um avanço (salto, investida) o knockback dos golpes não se aplica.
var em_avanco := false

var _piscar := 0.0
var _empurrao := Vector2.ZERO  # velocidade do knockback em andamento
var _empurrao_restante := 0.0

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
		_empurrao = direcao.normalized() * (empurrao / KNOCKBACK_DURACAO)
		_empurrao_restante = KNOCKBACK_DURACAO
	if vida == 0:
		_morrer()
	queue_redraw()


func _morrer() -> void:
	morto = true
	colisao.set_deferred("disabled", true)
	get_parent().move_child.call_deferred(self, 0)  # corpo caído fica embaixo dos vivos
	Som.tocar("morte")
	morreu.emit(self)


func _physics_process(delta: float) -> void:
	_piscar = maxf(_piscar - delta, 0.0)
	if _empurrao_restante > 0.0:
		var passo := minf(delta, _empurrao_restante)
		_empurrao_restante -= passo
		# Parede e obstáculo seguram o empurrão.
		if move_and_collide(_empurrao * passo) != null:
			_empurrao_restante = 0.0
	elif not morto:
		_agir(delta)
	queue_redraw()


## Comportamento de cada inimigo. A base fica parada (alvo de treino).
func _agir(_delta: float) -> void:
	pass


func _draw() -> void:
	var tamanho: Vector2 = (colisao.shape as RectangleShape2D).size
	if morto:
		# Corpo caído: achatado e escuro.
		draw_rect(Rect2(-tamanho.x / 2.0 - 2.0, -3.0, tamanho.x + 4.0, 5.0), cor.darkened(0.55))
		return
	var corpo_cor := Color.WHITE if _piscar > 0.0 else cor
	draw_rect(Rect2(-tamanho / 2.0, tamanho), corpo_cor)
	draw_rect(Rect2(-tamanho.x / 2.0 + 3.0, -tamanho.y / 2.0 - 2.0, 3.0, 3.0), Color.WHITE)
	draw_rect(Rect2(tamanho.x / 2.0 - 6.0, -tamanho.y / 2.0 - 2.0, 3.0, 3.0), Color.WHITE)
	# Vida: um quadradinho por unidade, embaixo do sprite.
	var lado := 3.0
	var largura := vida_maxima * (lado + 1.0) - 1.0
	for i in vida_maxima:
		var q := Rect2(-largura / 2.0 + i * (lado + 1.0), tamanho.y / 2.0 + 3.0, lado, lado)
		draw_rect(q.grow(0.5), Color(0, 0, 0, 0.7))
		draw_rect(q, Color(0.95, 0.3, 0.3) if i < vida else Color(0.2, 0.2, 0.2))
