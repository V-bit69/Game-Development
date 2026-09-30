@tool
class_name SalaBlockout
extends Node2D
## Monta um blockout a partir de um mapa em texto, com a mesma legenda de
## docs/02-level-design-demo.md. Cada caractere vale 2 × 2 tiles (32 × 32 px).
##   T  vegetação densa (parede)     #  parede da ruína     o  obstáculo
##   .  chão livre                   :  trilha              @  início do jogador
## O desenho também aparece no editor (aba 2D) e se atualiza ao mudar o mapa.

const V := preload("res://scripts/valores.gd")

const SOLIDOS := {
	"T": Color(0.13, 0.27, 0.17),
	"#": Color(0.36, 0.35, 0.4),
	"o": Color(0.45, 0.36, 0.26),
}
const COR_CHAO := Color(0.25, 0.4, 0.26)
const COR_TRILHA := Color(0.47, 0.42, 0.3)
const COR_GRADE := Color(0, 0, 0, 0.08)

@export_multiline var mapa := "":
	set(valor):
		mapa = valor
		_ler_mapa()
		queue_redraw()

var celula := V.TILE * 2.0
var tamanho := Vector2.ZERO
var _linhas: Array[String] = []

@onready var jogador: CharacterBody2D = $Jogador
@onready var info: Label = $HUD/Info


func _ready() -> void:
	_ler_mapa()
	queue_redraw()
	if Engine.is_editor_hint():
		return
	_criar_colisoes()
	_posicionar_jogador()
	_limitar_camera()


func _ler_mapa() -> void:
	_linhas.clear()
	for linha in mapa.split("\n"):
		linha = linha.strip_edges()
		if linha != "":
			_linhas.append(linha)
	var colunas := 0
	for linha in _linhas:
		colunas = maxi(colunas, linha.length())
	tamanho = Vector2(colunas, _linhas.size()) * celula


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var tile := (jogador.position / V.TILE).floor()
	info.text = "Setas: mover · D: dash · S: trocar dash\nVelocidade: %d px/s · Tile: %d, %d" % [
		roundi(jogador.velocity.length()), int(tile.x), int(tile.y)]


# Junta as células sólidas vizinhas de cada linha num retângulo só.
func _criar_colisoes() -> void:
	var paredes := StaticBody2D.new()
	paredes.name = "Paredes"
	add_child(paredes)
	for y in _linhas.size():
		var linha := _linhas[y]
		var x := 0
		while x < linha.length():
			if not SOLIDOS.has(linha[x]):
				x += 1
				continue
			var inicio := x
			while x < linha.length() and SOLIDOS.has(linha[x]):
				x += 1
			var forma := RectangleShape2D.new()
			forma.size = Vector2(x - inicio, 1) * celula
			var colisao := CollisionShape2D.new()
			colisao.shape = forma
			colisao.position = Vector2(inicio, y) * celula + forma.size / 2.0
			paredes.add_child(colisao)


func _posicionar_jogador() -> void:
	for y in _linhas.size():
		var x := _linhas[y].find("@")
		if x >= 0:
			jogador.position = (Vector2(x, y) + Vector2(0.5, 0.5)) * celula
			return
	push_warning("O mapa não tem o início do jogador (@).")


func _limitar_camera() -> void:
	var camera: Camera2D = jogador.camera
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(tamanho.x)
	camera.limit_bottom = int(tamanho.y)
	camera.reset_smoothing()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, tamanho), COR_CHAO)
	for y in _linhas.size():
		var linha := _linhas[y]
		for x in linha.length():
			var area := Rect2(Vector2(x, y) * celula, Vector2(celula, celula))
			if SOLIDOS.has(linha[x]):
				draw_rect(area, SOLIDOS[linha[x]])
			elif linha[x] == ":":
				draw_rect(area, COR_TRILHA)
			elif linha[x] == "@" and Engine.is_editor_hint():
				# No editor, marca o início com o tamanho do gato.
				var pes := area.get_center()
				var topo := pes.y + V.GATO_RAIO_HITBOX - V.GATO_ALTURA
				draw_rect(Rect2(pes.x - 9.0, topo, 18.0, V.GATO_ALTURA), Color(0.93, 0.6, 0.25, 0.6))
	var passo := V.TILE
	var gx := 0.0
	while gx <= tamanho.x:
		draw_line(Vector2(gx, 0), Vector2(gx, tamanho.y), COR_GRADE)
		gx += passo
	var gy := 0.0
	while gy <= tamanho.y:
		draw_line(Vector2(0, gy), Vector2(tamanho.x, gy), COR_GRADE)
		gy += passo
