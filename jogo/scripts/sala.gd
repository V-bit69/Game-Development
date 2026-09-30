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
##   x  alvo de treino (sala de teste)   a  alvo de treino que ataca (sala de teste)
## O desenho também aparece no editor (aba 2D) e se atualiza ao mudar o mapa.
## No jogo, a sala também cuida dos encontros (gatilhos acordam os sapos),
## das interações com E (M7), da escalada nos trechos D (M8) e da morte (M9).

const V := preload("res://scripts/valores.gd")
const T := preload("res://scripts/textos.gd")
const ENTIDADES := {
	"x": preload("res://cenas/alvo.tscn"),
	"a": preload("res://cenas/alvo_atacante.tscn"),
	"s": preload("res://cenas/sapo.tscn"),
	"l": preload("res://cenas/sapo_lingua.tscn"),
}
## Interações com E: se mostra o indicador e se some depois de usar.
const INTERATIVOS := {
	"X": {"id": "xennar", "indicador": true, "some": false},
	"G": {"id": "estatua", "indicador": true, "some": false},
	"t": {"id": "elemento", "indicador": true, "some": false},
	"L": {"id": "flor", "indicador": false, "some": true},  # interação oculta
	"K": {"id": "peca", "indicador": true, "some": true},
	"v": {"id": "descida", "indicador": true, "some": false},
}
## Pontos de interesse: inimigo que morre em cima deles não deixa o corpo.
const INTERESSE := "XFGtL="

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
var objetivo := ""
var falou_com_xennar := false
var _linhas: Array[String] = []
var _gatilhos := {}  # linha do gatilho -> sapos que ele acorda
var _interativos: Array[Dictionary] = []  # {id, celula, centro, base, indicador, some}

@onready var jogador: CharacterBody2D = $Jogador
@onready var info: Label = $HUD/Info


func _ready() -> void:
	_ler_mapa()
	queue_redraw()
	if Engine.is_editor_hint():
		return
	add_to_group("sala")
	_criar_colisoes()
	_criar_entidades()
	_criar_interativos()
	_posicionar_jogador()
	_limitar_camera()
	jogador.interagir_pedido.connect(_interagir)
	jogador.morreu.connect(Tela.mostrar_morte)


## Cria os inimigos. Sapos numa área com gatilho (!) ficam dormindo até o
## jogador cruzar a linha do gatilho: o primeiro gatilho abaixo deles na mesma
## área (ou o mais perto, se não houver nenhum abaixo).
func _criar_entidades() -> void:
	var linhas_gatilho: Array[int] = []
	for y in _linhas.size():
		if _linhas[y].contains("!"):
			linhas_gatilho.append(y)
			_gatilhos[y] = []
	for y in _linhas.size():
		for x in _linhas[y].length():
			var cena: PackedScene = ENTIDADES.get(_linhas[y][x])
			if cena == null:
				continue
			var entidade: Node2D = cena.instantiate()
			entidade.position = _centro(x, y)
			var gatilho := _gatilho_de(y, linhas_gatilho)
			if gatilho >= 0 and "dormindo" in entidade:
				entidade.dormindo = true
				_gatilhos[gatilho].append(entidade)
			add_child(entidade)


func _gatilho_de(linha: int, linhas_gatilho: Array[int]) -> int:
	var area := _area_da_linha(linha)
	var abaixo := -1
	var mais_perto := -1
	for g in linhas_gatilho:
		if _area_da_linha(g) != area:
			continue
		if g >= linha and (abaixo < 0 or g < abaixo):
			abaixo = g
		if mais_perto < 0 or absi(g - linha) < absi(mais_perto - linha):
			mais_perto = g
	return abaixo if abaixo >= 0 else mais_perto


func _criar_interativos() -> void:
	for y in _linhas.size():
		for x in _linhas[y].length():
			var c := _linhas[y][x]
			if INTERESSE.contains(c):
				var ponto := Node2D.new()
				ponto.position = _centro(x, y)
				ponto.add_to_group("interesse")
				add_child(ponto)
			if INTERATIVOS.has(c):
				var item: Dictionary = INTERATIVOS[c].duplicate()
				item["celula"] = Vector2i(x, y)
				item["centro"] = _centro(x, y)
				item["base"] = MARCADORES[c].base
				_interativos.append(item)


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


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or jogador.morto:
		return
	# Gatilhos: cruzar a linha (subindo) acorda os sapos do encontro.
	for linha in _gatilhos.keys():
		if jogador.position.y < (linha + 0.5) * celula:
			for sapo in _gatilhos[linha]:
				if is_instance_valid(sapo):
					sapo.acordar(randf() * V.ENCONTRO_ATRASO_MAXIMO)
					sapo.alerta = true
			if not _gatilhos[linha].is_empty():
				Som.tocar("alerta")
			_gatilhos.erase(linha)
	# Primeiro encontro com Xennar: o gato para e o diálogo começa sozinho.
	if not falou_com_xennar:
		var xennar := _interativo_por_id("xennar")
		if not xennar.is_empty() and _distancia_ate(xennar) <= V.XENNAR_DISTANCIA_AUTO:
			_falar_com_xennar()
	# Indicador em cima da cabeça: E para interagir, D para escalar.
	var perto := _interativo_mais_perto()
	if not perto.is_empty() and perto.indicador and (perto.id != "xennar" or falou_com_xennar):
		jogador.indicador = "E"
	elif perto_da_escalada(jogador.global_position):
		jogador.indicador = "D"
	else:
		jogador.indicador = ""


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
	return _area_da_linha(int(ponto.y / celula))


func _area_da_linha(linha: int) -> String:
	var nome := ""
	for item in areas:
		var partes := item.split(":", true, 1)
		if partes.size() == 2 and linha >= int(partes[0]):
			nome = partes[1]
	return nome


# --- Interações (M7) ----------------------------------------------------

## Distância dos pés do gato até a borda da base do objeto.
func _distancia_ate(item: Dictionary) -> float:
	var metade: Vector2 = item.base / 2.0
	var local: Vector2 = jogador.global_position - item.centro
	return local.distance_to(local.clamp(-metade, metade))


func _interativo_mais_perto() -> Dictionary:
	var melhor := {}
	var menor := V.INTERACAO_DISTANCIA
	for item in _interativos:
		var d := _distancia_ate(item)
		if d <= menor:
			menor = d
			melhor = item
	return melhor


func _interativo_por_id(id: String) -> Dictionary:
	for item in _interativos:
		if item.id == id:
			return item
	return {}


func _interagir() -> void:
	var item := _interativo_mais_perto()
	if item.is_empty() or Dialogo.ativo:
		return
	get_viewport().set_input_as_handled()
	Som.tocar("interacao")
	match item.id:
		"xennar":
			if falou_com_xennar:
				Dialogo.mostrar(T.XENNAR_DEPOIS)
			else:
				_falar_com_xennar()
		"estatua":
			Dialogo.mostrar(T.ESTATUA)
		"elemento":
			Dialogo.mostrar(T.ELEMENTO)
		"flor":
			_coletar(item, T.FLOR_COLETA, T.FLOR)
		"peca":
			_coletar(item, T.PECA_COLETA, T.PECA)
		"descida":
			var destino: Variant = destino_descida(item.celula)
			if destino != null:
				jogador.atravessar_para(destino)


func _falar_com_xennar() -> void:
	falou_com_xennar = true
	jogador.velocity = Vector2.ZERO
	Dialogo.mostrar(T.XENNAR_PRIMEIRA, func() -> void:
		objetivo = T.OBJETIVO
		_avisar("Novo objetivo: " + T.OBJETIVO)
		Som.tocar("jingle"))


## Coleta: o item some do mapa, toca o jingle, aparece o nome e o gato comenta.
func _coletar(item: Dictionary, nome: String, falas: Array) -> void:
	_interativos.erase(item)
	var linha := _linhas[item.celula.y]
	_linhas[item.celula.y] = linha.substr(0, item.celula.x) + "." + linha.substr(item.celula.x + 1)
	queue_redraw()
	Som.tocar("jingle")
	_avisar(nome)
	Dialogo.mostrar(falas)


func _avisar(texto: String) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null:
		hud.avisar(texto)


# --- Escalada (M8) ------------------------------------------------------

## Trechos escaláveis: colunas de D seguidas. Devolve [coluna, primeira linha, última linha].
func _trechos_escalaveis() -> Array:
	var trechos := []
	for x in int(tamanho.x / celula):
		var y := 0
		while y < _linhas.size():
			if x < _linhas[y].length() and _linhas[y][x] == "D":
				var inicio := y
				while y < _linhas.size() and x < _linhas[y].length() and _linhas[y][x] == "D":
					y += 1
				trechos.append([x, inicio, y - 1])
			else:
				y += 1
	return trechos


## O gato está encostado num trecho escalável, embaixo ou em cima dele? (indicação D)
func perto_da_escalada(pos: Vector2) -> bool:
	return destino_escalada(pos, Vector2.UP) != null or destino_escalada(pos, Vector2.DOWN) != null


## Chamado pelo jogador ao dar o dash padrão: se ele estiver num trecho D e
## o dash for na direção da parede, devolve o ponto do outro lado. Senão, null.
func destino_escalada(pos: Vector2, direcao: Vector2) -> Variant:
	var margem := V.GATO_RAIO_HITBOX + 12.0
	for trecho in _trechos_escalaveis():
		var centro_x: float = (trecho[0] + 0.5) * celula
		if absf(pos.x - centro_x) > celula / 2.0:
			continue
		var base_y: float = (trecho[2] + 1) * celula
		var topo_y: float = trecho[1] * celula
		if direcao.y < -0.1 and pos.y >= base_y and pos.y - base_y <= margem:
			return Vector2(centro_x, topo_y - V.GATO_RAIO_HITBOX - 4.0)
		if direcao.y > 0.1 and pos.y <= topo_y and topo_y - pos.y <= margem:
			return Vector2(centro_x, base_y + V.GATO_RAIO_HITBOX + 4.0)
	return null


## Descida (v): desce na mesma coluna até o primeiro chão livre depois da fachada.
func destino_descida(celula_v: Vector2i) -> Variant:
	var x := celula_v.x
	var passou_parede := false
	for y in range(celula_v.y + 1, _linhas.size()):
		var c := _linhas[y][x]
		if _bloqueia(c) or c == "=":
			passou_parede = true
		elif passou_parede:
			return _centro(x, y)
	return null


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
			if not _bloqueia(c):
				x += 1
				continue
			var inicio := x
			while x < linha.length() and _bloqueia(linha[x]):
				x += 1
			var largura := Vector2(x - inicio, 1) * celula
			_adicionar_caixa(paredes, Vector2(inicio, y) * celula + largura / 2.0, largura)


## Paredes: vegetação, ruína, obstáculos e o trecho escalável (que só se passa escalando).
func _bloqueia(c: String) -> bool:
	return SOLIDOS.has(c) or c == "D"


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
				# Trecho escalável: parede da ruína com faixas laranja. Só se passa escalando.
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
			var c := _linhas[y][x]
			# No jogo, os sapos são inimigos de verdade; o contorno só aparece no editor.
			if MARCADORES.has(c) and not (ENTIDADES.has(c) and not Engine.is_editor_hint()):
				_desenhar_marcador(c, _centro(x, y))
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
