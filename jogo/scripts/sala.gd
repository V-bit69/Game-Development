@tool
class_name SalaBlockout
extends Node2D
## Monta um blockout a partir de um mapa em texto, com a mesma legenda de
## docs/02-level-design-demo.md. Cada caractere vale 2 × 2 tiles (32 × 32 px).
##   T  vegetação densa (parede)     #  parede da ruína       o  obstáculo
##   .  chão livre                   :  trilha                @  início do jogador
##   X  Xennar                       F  fogueira              L  flor de lírio azul
##   G  estátua da Guardiã           t  elemento tecnológico  K  peça da KLM-99
##   s  sapo comum (posição)         l  sapo com língua       !  gatilho de encontro
##   =  entrada da ruína             D  trecho escalável      v  descida
##   x  alvo de treino (sala de teste)
## O desenho também aparece no editor (aba 2D) e se atualiza ao mudar o mapa.

const V := preload("res://scripts/valores.gd")
const ENTIDADES := {
	"x": preload("res://cenas/alvo.tscn"),
}

const SOLIDOS := {
	"T": Color(0.13, 0.27, 0.17),
	"#": Color(0.36, 0.35, 0.4),
	"o": Color(0.45, 0.36, 0.26),
}
## Marcadores do blockout: cor, tamanho da base (px) e se bloqueia a passagem.
## "altura" desenha um retângulo mais alto para dar noção do tamanho na tela.
const MARCADORES := {
	"X": {"cor": Color(0.62, 0.45, 0.85), "base": Vector2(16, 12), "solido": true, "altura": 50.0},
	"F": {"cor": Color(1.0, 0.55, 0.15), "base": Vector2(14, 14), "solido": true},
	"G": {"cor": Color(0.65, 0.72, 0.8), "base": Vector2(24, 20), "solido": true, "altura": 64.0},
	"t": {"cor": Color(0.3, 0.85, 0.9), "base": Vector2(20, 16), "solido": true},
	"=": {"cor": Color(0.08, 0.06, 0.1), "base": Vector2(32, 32), "solido": true},
	"L": {"cor": Color(0.45, 0.6, 1.0), "base": Vector2(8, 8), "solido": false},
	"K": {"cor": Color(1.0, 0.9, 0.3), "base": Vector2(8, 8), "solido": false},
	"s": {"cor": Color(0.35, 0.62, 0.3), "base": Vector2(18, 14), "solido": false},
	"l": {"cor": Color(0.85, 0.4, 0.55), "base": Vector2(18, 14), "solido": false},
	"v": {"cor": Color(1.0, 1.0, 1.0), "base": Vector2(12, 12), "solido": false},
}
const COR_CHAO := Color(0.25, 0.4, 0.26)
const COR_TRILHA := Color(0.47, 0.42, 0.3)
const COR_GRADE := Color(0, 0, 0, 0.08)
const COR_GATILHO := Color(1.0, 0.25, 0.25, 0.55)
const COR_ESCALADA := Color(1.0, 0.6, 0.2)

@export_multiline var mapa := "":
	set(valor):
		mapa = valor
		_ler_mapa()
		queue_redraw()
## Nomes das áreas, no formato "linha:nome", da linha em que cada uma começa.
@export var areas := PackedStringArray()

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
	_criar_entidades()
	_posicionar_jogador()
	_limitar_camera()


func _criar_entidades() -> void:
	for y in _linhas.size():
		for x in _linhas[y].length():
			var cena: PackedScene = ENTIDADES.get(_linhas[y][x])
			if cena == null:
				continue
			var entidade: Node2D = cena.instantiate()
			entidade.position = _centro(x, y)
			add_child(entidade)


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
	var texto := "Setas: mover · A: atacar · D: dash · S: trocar dash · R: recomeçar\n"
	var area := area_em(jogador.position)
	if area != "":
		texto += area + " · "
	info.text = texto + "Velocidade: %d px/s · Tile: %d, %d" % [
		roundi(jogador.velocity.length()), int(tile.x), int(tile.y)]


## Nome da área em que um ponto está, pela lista "areas".
func area_em(ponto: Vector2) -> String:
	var linha := int(ponto.y / celula)
	var nome := ""
	for item in areas:
		var partes := item.split(":", true, 1)
		if partes.size() == 2 and linha >= int(partes[0]):
			nome = partes[1]
	return nome


# Junta as células sólidas vizinhas de cada linha num retângulo só.
# Marcadores sólidos (Xennar, fogueira, estátua...) ganham uma caixa do tamanho da base.
func _criar_colisoes() -> void:
	var paredes := StaticBody2D.new()
	paredes.name = "Paredes"
	add_child(paredes)
	for y in _linhas.size():
		var linha := _linhas[y]
		var x := 0
		while x < linha.length():
			var c := linha[x]
			if MARCADORES.has(c) and MARCADORES[c].solido:
				_adicionar_caixa(paredes, _centro(x, y), MARCADORES[c].base)
			if not SOLIDOS.has(c):
				x += 1
				continue
			var inicio := x
			while x < linha.length() and SOLIDOS.has(linha[x]):
				x += 1
			var largura := Vector2(x - inicio, 1) * celula
			_adicionar_caixa(paredes, Vector2(inicio, y) * celula + largura / 2.0, largura)


func _adicionar_caixa(corpo: StaticBody2D, centro: Vector2, medida: Vector2) -> void:
	var forma := RectangleShape2D.new()
	forma.size = medida
	var colisao := CollisionShape2D.new()
	colisao.shape = forma
	colisao.position = centro
	corpo.add_child(colisao)


func _posicionar_jogador() -> void:
	for y in _linhas.size():
		var x := _linhas[y].find("@")
		if x >= 0:
			jogador.position = _centro(x, y)
			return
	push_warning("O mapa não tem o início do jogador (@).")


func _limitar_camera() -> void:
	var camera: Camera2D = jogador.camera
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(tamanho.x)
	camera.limit_bottom = int(tamanho.y)
	camera.reset_smoothing()


func _centro(x: int, y: int) -> Vector2:
	return (Vector2(x, y) + Vector2(0.5, 0.5)) * celula


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, tamanho), COR_CHAO)
	for y in _linhas.size():
		var linha := _linhas[y]
		for x in linha.length():
			var area := Rect2(Vector2(x, y) * celula, Vector2(celula, celula))
			var c := linha[x]
			if SOLIDOS.has(c):
				draw_rect(area, SOLIDOS[c])
			elif c == ":":
				draw_rect(area, COR_TRILHA)
			elif c == "D":
				# Trecho escalável: parede da ruína com faixas laranja. Passável até o M8.
				draw_rect(area, SOLIDOS["#"].lightened(0.1))
				for i in 4:
					draw_line(area.position + Vector2(0, 4 + i * 8), area.position + Vector2(celula, 4 + i * 8), COR_ESCALADA, 1.0)
			elif c == "!":
				_desenhar_gatilho(linha, y)
			elif ENTIDADES.has(c) and Engine.is_editor_hint():
				draw_rect(Rect2(area.get_center() - Vector2(9, 7), Vector2(18, 14)), Color(0.55, 0.5, 0.35, 0.8))
			elif c == "@" and Engine.is_editor_hint():
				# No editor, marca o início com o tamanho do gato.
				var pes := area.get_center()
				var topo := pes.y + V.GATO_RAIO_HITBOX - V.GATO_ALTURA
				draw_rect(Rect2(pes.x - 9.0, topo, 18.0, V.GATO_ALTURA), Color(0.93, 0.6, 0.25, 0.6))
	# Marcadores por último, para ficarem por cima do chão e da trilha.
	for y in _linhas.size():
		for x in _linhas[y].length():
			if MARCADORES.has(_linhas[y][x]):
				_desenhar_marcador(_linhas[y][x], _centro(x, y))
	var passo := V.TILE
	var gx := 0.0
	while gx <= tamanho.x:
		draw_line(Vector2(gx, 0), Vector2(gx, tamanho.y), COR_GRADE)
		gx += passo
	var gy := 0.0
	while gy <= tamanho.y:
		draw_line(Vector2(0, gy), Vector2(tamanho.x, gy), COR_GRADE)
		gy += passo


## Gatilho: linha vermelha tracejada atravessando a área livre da linha do mapa.
func _desenhar_gatilho(linha: String, y: int) -> void:
	var meio_y := (y + 0.5) * celula
	for x in linha.length():
		if SOLIDOS.has(linha[x]):
			continue
		var x0 := x * celula
		var t := 0.0
		while t < celula:
			draw_line(Vector2(x0 + t, meio_y), Vector2(x0 + t + 4.0, meio_y), COR_GATILHO, 2.0)
			t += 8.0


func _desenhar_marcador(c: String, centro: Vector2) -> void:
	var m: Dictionary = MARCADORES[c]
	var base: Vector2 = m.base
	var cor: Color = m.cor
	match c:
		"s", "l":
			# Posição de inimigo: contorno do tamanho da hitbox do sapo.
			draw_rect(Rect2(centro - base / 2.0, base), cor, false, 1.0)
			draw_rect(Rect2(centro - base / 2.0 + Vector2(2, 2), base - Vector2(4, 4)), Color(cor, 0.35))
		"F":
			draw_circle(centro, base.x / 2.0, cor)
			draw_circle(centro + Vector2(0, -2), base.x / 4.0, Color(1, 0.9, 0.4))
		"L", "K":
			draw_colored_polygon(PackedVector2Array([centro + Vector2(0, -5), centro + Vector2(5, 0), centro + Vector2(0, 5), centro + Vector2(-5, 0)]), cor)
		"v":
			draw_colored_polygon(PackedVector2Array([centro + Vector2(-6, -3), centro + Vector2(6, -3), centro + Vector2(0, 6)]), Color(cor, 0.8))
		_:
			draw_rect(Rect2(centro - base / 2.0, base), cor)
			if m.has("altura"):
				# Silhueta com a altura real, para dar noção do tamanho na tela.
				var altura: float = m.altura
				draw_rect(Rect2(centro.x - base.x / 2.0, centro.y + base.y / 2.0 - altura, base.x, altura), Color(cor, 0.45))
	var fonte := ThemeDB.fallback_font
	draw_string_outline(fonte, centro + Vector2(-3, 4), c, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, Color.BLACK)
	draw_string(fonte, centro + Vector2(-3, 4), c, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
