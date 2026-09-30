extends SceneTree
## Confere o blockout da floresta: tamanho, áreas e se dá para chegar a tudo
## a partir do início (@). Rodar na pasta jogo/:
##   godot --headless --path . -s res://testes/teste_blockout.gd

const PRECISA_ALCANCAR := "sl!LKv"  # pisa em cima
const PRECISA_ENCOSTAR := "XFGt="  # sólidos: precisa chegar do lado

var _falhas := 0


func _initialize() -> void:
	_rodar()


func _rodar() -> void:
	var floresta: Node2D = load("res://cenas/floresta.tscn").instantiate()
	root.add_child(floresta)
	await physics_frame
	var linhas: Array[String] = floresta._linhas
	var solidos: Dictionary = floresta.SOLIDOS
	var marcadores: Dictionary = floresta.MARCADORES

	_conferir("mapa de 960 × 2432 px (%s)" % floresta.tamanho, floresta.tamanho == Vector2(960, 2432))
	var larguras_ok := true
	for l in linhas:
		larguras_ok = larguras_ok and l.length() == 30
	_conferir("todas as linhas com 30 colunas", larguras_ok)
	_conferir("começa na área segura", floresta.area_em(floresta.jogador.position) == "Área segura")

	# Busca em largura pelas células livres, a partir do @.
	var livre := func(x: int, y: int) -> bool:
		if y < 0 or y >= linhas.size() or x < 0 or x >= linhas[y].length():
			return false
		var c := linhas[y][x]
		return not solidos.has(c) and not (marcadores.has(c) and marcadores[c].solido)
	var inicio := Vector2i(-1, -1)
	for y in linhas.size():
		if linhas[y].find("@") >= 0:
			inicio = Vector2i(linhas[y].find("@"), y)
	var visto := {inicio: true}
	var fila: Array[Vector2i] = [inicio]
	while not fila.is_empty():
		var p: Vector2i = fila.pop_front()
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var q: Vector2i = p + d
			if not visto.has(q) and livre.call(q.x, q.y):
				visto[q] = true
				fila.append(q)

	var contagem := {}
	var sem_acesso: Array[String] = []
	for y in linhas.size():
		for x in linhas[y].length():
			var c := linhas[y][x]
			contagem[c] = contagem.get(c, 0) + 1
			if c in PRECISA_ALCANCAR and not visto.has(Vector2i(x, y)):
				sem_acesso.append("%s em (%d, %d)" % [c, x, y])
			elif c in PRECISA_ENCOSTAR:
				var encosta := false
				for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					encosta = encosta or visto.has(Vector2i(x, y) + d)
				if not encosta:
					sem_acesso.append("%s em (%d, %d)" % [c, x, y])
	_conferir("tudo alcançável a partir do início %s" % [sem_acesso], sem_acesso.is_empty())
	_conferir("11 sapos comuns (tem %d)" % contagem.get("s", 0), contagem.get("s", 0) == 11)
	_conferir("5 sapos com língua (tem %d)" % contagem.get("l", 0), contagem.get("l", 0) == 5)
	for c in "XFGtLK":
		_conferir("1 marcador %s" % c, contagem.get(c, 0) == 1)

	print("\n%s" % ("BLOCKOUT OK: todos os testes passaram." if _falhas == 0 else "BLOCKOUT FALHOU: %d teste(s)." % _falhas))
	quit(1 if _falhas > 0 else 0)


func _conferir(nome: String, ok: bool) -> void:
	print("[%s] %s" % ["ok" if ok else "FALHOU", nome])
	if not ok:
		_falhas += 1
