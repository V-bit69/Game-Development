extends SceneTree
## Teste automático do M1. Rodar na pasta jogo/:
##   godot --headless --path . -s res://testes/teste_m1.gd

const ACOES := ["mover_esquerda", "mover_direita", "mover_cima", "mover_baixo"]

var _falhas := 0


func _initialize() -> void:
	_rodar()


func _rodar() -> void:
	var valores := root.get_node("Valores")
	var sala: Node2D = load("res://cenas/sala_teste.tscn").instantiate()
	root.add_child(sala)
	await _esperar(2)
	var jogador: CharacterBody2D = sala.get_node("Jogador")
	var camera: Camera2D = jogador.get_node("Camera")
	var inicio := jogador.position

	_conferir("resolução base 1920 × 1080", root.content_scale_size == Vector2i(1920, 1080))
	_conferir("mapa de 2880 × 1632 px", sala.tamanho == Vector2(2880, 1632))
	_conferir("jogador começa no @", inicio == Vector2(624, 1008))
	_conferir("câmera limitada ao mapa", camera.limit_right == 2880 and camera.limit_bottom == 1632)

	# Reta: 30 quadros de física = 0,5 s -> 195 px a 390 px/s.
	await _andar(["mover_direita"], 30)
	var andou := jogador.position - inicio
	_conferir("anda 195 px em 0,5 s para a direita (andou %.1f)" % andou.x,
		absf(andou.x - valores.GATO_CAMINHADA * 0.5) < 1.0 and absf(andou.y) < 0.01)

	# Diagonal: mesma velocidade, não soma os dois eixos.
	var antes := jogador.position
	Input.action_press("mover_direita")
	Input.action_press("mover_cima")
	await _esperar(10)
	var vel := jogador.velocity
	_soltar()
	_conferir("diagonal a 390 px/s (foi %.1f)" % vel.length(), absf(vel.length() - valores.GATO_CAMINHADA) < 0.5)
	_conferir("diagonal sobe e vai para a direita", jogador.position.x > antes.x and jogador.position.y < antes.y)

	# Parado quando solta.
	await _esperar(2)
	_conferir("para ao soltar as setas", jogador.velocity == Vector2.ZERO)

	# Parede da esquerda: borda em x = 96, raio 30 -> para em x ≈ 126.
	jogador.position = inicio
	await _andar(["mover_esquerda"], 180)
	_conferir("parede segura o jogador (x = %.1f)" % jogador.position.x, absf(jogador.position.x - 126.0) < 1.5)

	# Desliza na parede quando anda na diagonal contra ela.
	var y_antes := jogador.position.y
	await _andar(["mover_esquerda", "mover_baixo"], 20)
	_conferir("desliza na parede em diagonal", jogador.position.y > y_antes + 20.0 and absf(jogador.position.x - 126.0) < 1.5)

	# Obstáculo 'o' na célula (7, 12): bloqueia quem vem de cima.
	jogador.position = Vector2(7.5 * 96, 10.5 * 96)
	await _andar(["mover_baixo"], 120)
	_conferir("obstáculo bloqueia (y = %.1f)" % jogador.position.y, absf(jogador.position.y - (12 * 96 - 30)) < 1.5)

	print("\n%s" % ("M1 OK: todos os testes passaram." if _falhas == 0 else "M1 FALHOU: %d teste(s)." % _falhas))
	quit(1 if _falhas > 0 else 0)


func _andar(acoes: Array, quadros: int) -> void:
	for acao in acoes:
		Input.action_press(acao)
	await _esperar(quadros)
	_soltar()


func _soltar() -> void:
	for acao in ACOES:
		Input.action_release(acao)


func _esperar(quadros: int) -> void:
	for i in quadros:
		await physics_frame


func _conferir(nome: String, ok: bool) -> void:
	print("[%s] %s" % ["ok" if ok else "FALHOU", nome])
	if not ok:
		_falhas += 1
