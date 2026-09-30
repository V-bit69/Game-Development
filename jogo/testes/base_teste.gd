extends SceneTree
## Base dos testes automáticos do M4 em diante: carregar sala, esperar, conferir.

var _falhas := 0
var _nome_teste := "TESTE"
var sala: Node2D
var jogador: CharacterBody2D


func _initialize() -> void:
	_rodar()


## Cada teste escreve o próprio _rodar() e termina com terminar().
func _rodar() -> void:
	pass


## Carrega uma sala. Com "limpar", tira os inimigos que já vêm no mapa.
func carregar(caminho: String, limpar := true) -> void:
	sala = load(caminho).instantiate()
	root.add_child(sala)
	current_scene = sala
	await esperar(2)
	jogador = sala.get_node("Jogador")
	if limpar:
		for e in get_nodes_in_group("inimigos"):
			e.queue_free()
		await esperar(1)


func criar(caminho: String, pos: Vector2) -> Node2D:
	var e: Node2D = load(caminho).instantiate()
	e.position = pos
	sala.add_child(e)
	await esperar(1)
	return e


func ate(condicao: Callable, limite := 900) -> bool:
	for i in limite:
		if condicao.call():
			return true
		await physics_frame
	print("  (tempo esgotado esperando condição)")
	return false


func esperar(quadros: int) -> void:
	for i in quadros:
		await physics_frame


func conferir(nome: String, ok: bool) -> void:
	print("[%s] %s" % ["ok" if ok else "FALHOU", nome])
	if not ok:
		_falhas += 1


func terminar() -> void:
	Engine.time_scale = 1.0
	paused = false
	print("\n%s" % ("%s OK: todos os testes passaram." % _nome_teste if _falhas == 0 else "%s FALHOU: %d teste(s)." % [_nome_teste, _falhas]))
	quit(1 if _falhas > 0 else 0)
