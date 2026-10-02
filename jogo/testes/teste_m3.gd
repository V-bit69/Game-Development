extends SceneTree
## Teste automático do M3 (combo, dano do dash, knockback). Rodar na pasta jogo/:
##   godot --headless --path . -s res://testes/teste_m3.gd

var ALVO: PackedScene
const QUADRO := 1.0 / 60.0

var _falhas := 0
var _sala: Node2D
var _jogador: CharacterBody2D
var _inicio: Vector2


func _initialize() -> void:
	_rodar()


func _rodar() -> void:
	ALVO = load("res://cenas/alvo.tscn")
	_sala = load("res://cenas/sala_teste.tscn").instantiate()
	root.add_child(_sala)
	await _esperar(2)
	_jogador = _sala.get_node("Jogador")
	_inicio = _jogador.position

	# Ritmo do combo, sem alvo: golpes começam em 0 s, 0,46 s e 1,08 s; o 4º volta a ser o golpe 1.
	var inicios: Array = []
	_jogador.golpe_iniciado.connect(func(n: int) -> void: inicios.append([n, _jogador._tempo]))
	var t0: float = _jogador._tempo
	_jogador.direcao_olhar = Vector2.RIGHT
	while inicios.size() < 4:
		_jogador.pedir_ataque()  # A apertado sem parar
		await _esperar(1)
	var sequencia := inicios.map(func(i): return i[0])
	_conferir("sequência 1 → 2 → 3 → 1 (%s)" % [sequencia], sequencia == [1, 2, 3, 1])
	var tempos := inicios.map(func(i): return i[1] - t0)
	var esperado := [0.0, 0.46, 1.08, 1.38]
	var ok := true
	for i in 4:
		ok = ok and absf(tempos[i] - esperado[i]) <= QUADRO * 1.5
	_conferir("tempos do combo 0 / 0,46 / 1,08 / 1,38 s (%s)" % [tempos.map(func(t): return snappedf(t, 0.01))], ok)
	await _fim_do_combo()
	_jogador._proximo_golpe = 1  # o combo é cíclico; o teste de dano começa do golpe 1

	# Dano 1 + 1 + 2 mata o alvo de 3 de vida; o passo à frente mantém o alcance.
	var alvo := await _novo_alvo(_inicio + Vector2(24, 0))
	_jogador.position = _inicio
	_jogador.direcao_olhar = Vector2.RIGHT
	var x_alvo: float = alvo.position.x
	_jogador.pedir_ataque()
	await _ate(func(): return alvo.vida < 3)
	_conferir("golpe 1 tira 1 de vida", alvo.vida == 2)
	await _esperar(12)
	_conferir("knockback de 16 px (andou %.1f)" % (alvo.position.x - x_alvo), absf(alvo.position.x - x_alvo - 16.0) < 1.0)
	_jogador.pedir_ataque()
	await _ate(func(): return alvo.vida < 2)
	_conferir("golpe 2 alcança e tira 1 (vida %d, dist %.1f)" % [alvo.vida, alvo.position.x - _jogador.position.x], alvo.vida == 1)
	_jogador.pedir_ataque()
	await _ate(func(): return alvo.morto or _jogador.golpe_atual == 0 and _jogador._intervalo == 0.0 and _jogador._proximo_golpe == 1)
	_conferir("golpe 3 (espada) tira 2 e mata", alvo.morto and alvo.vida == 0)
	await _esperar(2)
	_conferir("corpo fica no chão sem colisão", is_instance_valid(alvo) and alvo.colisao.disabled)
	await _fim_do_combo()
	alvo.queue_free()

	# Andar contra um alvo vivo: ele bloqueia.
	alvo = await _novo_alvo(_inicio + Vector2(60, 0))
	_jogador.position = _inicio
	await _andar("mover_direita", 60)
	_conferir("alvo vivo bloqueia a passagem (x = %.1f)" % _jogador.position.x, _jogador.position.x < alvo.position.x - 15.0)

	# Dash ofensivo atravessa, tira 1 e não empurra.
	_jogador.position = _inicio
	await _esperar(1)
	x_alvo = alvo.position.x
	_jogador.direcao_olhar = Vector2.RIGHT
	_jogador.pedir_dash()
	await _fim_do_dash()
	_conferir("dash ofensivo tira 1 de vida", alvo.vida == 2)
	_conferir("dash atravessa o alvo (x = %.1f)" % _jogador.position.x, absf(_jogador.position.x - (_inicio.x + 104.0)) < 1.0)
	_conferir("dash não empurra", alvo.position.x == x_alvo)

	# Rolamento atravessa sem dano.
	_jogador.trocar_dash()
	_jogador.position = _inicio
	await _esperar(1)
	_jogador.direcao_olhar = Vector2.RIGHT
	_jogador.pedir_dash()
	await _fim_do_dash()
	_conferir("rolamento não causa dano", alvo.vida == 2)
	_jogador.trocar_dash()

	# Dash interrompe o golpe, mas a sequência continua (combo cíclico).
	await _esperar(130)  # stamina volta
	_jogador.position = _inicio
	_jogador.direcao_olhar = Vector2.LEFT
	inicios.clear()
	_jogador.pedir_ataque()
	await _esperar(3)
	var interrompido: int = inicios.back()[0]
	_jogador.pedir_dash()
	_conferir("dash interrompe o golpe", _jogador.em_dash and _jogador.golpe_atual == 0)
	await _fim_do_dash()
	_jogador.pedir_ataque()
	await _esperar(1)
	_conferir("depois do dash, vem o golpe seguinte", inicios.back()[0] == interrompido % 3 + 1)
	await _fim_do_combo()

	# Parado por bastante tempo, o combo não volta ao golpe 1.
	var antes: int = inicios.back()[0]
	await _esperar(120)
	_jogador.pedir_ataque()
	await _esperar(1)
	_conferir("parado por 2 s, continua a sequência", inicios.back()[0] == antes % 3 + 1)
	await _fim_do_combo()

	# Área de ataque: arco de 120° (golpes 1 e 2) e de 60° com 25 px (golpe 3).
	var lado := await _novo_alvo(Vector2(400, 400))
	_jogador.position = Vector2(400, 400) - Vector2(10, 20)
	_jogador.direcao_olhar = Vector2.RIGHT
	await _esperar(1)
	_conferir("alvo a 34° da frente: dentro de 120°", _jogador._dentro_do_angulo(lado, 120.0))
	_conferir("alvo a 34° da frente: fora de 60° (golpe 3)", not _jogador._dentro_do_angulo(lado, 60.0))
	_jogador.position = Vector2(400, 400) - Vector2(0, 30)
	await _esperar(1)
	_conferir("alvo do lado (90°): fora da área", not _jogador._dentro_do_angulo(lado, 120.0))
	lado.queue_free()

	# Obstáculo entre o gato e o inimigo bloqueia o golpe (obstáculo 'o' na célula 7, 12).
	var atras := await _novo_alvo(Vector2(7.5 * 32, 13.5 * 32))
	_jogador.position = Vector2(7.5 * 32, 11.5 * 32)
	await _esperar(1)
	_conferir("obstáculo bloqueia o ataque", _jogador._obstaculo_entre(atras))
	_jogador.position = Vector2(4.5 * 32, 13.5 * 32)
	await _esperar(1)
	_conferir("sem obstáculo, não bloqueia", not _jogador._obstaculo_entre(atras))

	print("\n%s" % ("M3 OK: todos os testes passaram." if _falhas == 0 else "M3 FALHOU: %d teste(s)." % _falhas))
	quit(1 if _falhas > 0 else 0)


func _novo_alvo(pos: Vector2) -> Node:
	var alvo := ALVO.instantiate()
	alvo.position = pos
	_sala.add_child(alvo)
	await _esperar(1)
	return alvo


func _fim_do_combo() -> void:
	await _ate(func(): return _jogador.golpe_atual == 0 and _jogador._intervalo == 0.0)


func _fim_do_dash() -> void:
	await _ate(func(): return not _jogador.em_dash)


func _andar(acao: String, quadros: int) -> void:
	Input.action_press(acao)
	await _esperar(quadros)
	Input.action_release(acao)


func _ate(condicao: Callable, limite := 600) -> void:
	for i in limite:
		if condicao.call():
			return
		await physics_frame
	print("  (tempo esgotado esperando condição)")


func _esperar(quadros: int) -> void:
	for i in quadros:
		await physics_frame


func _conferir(nome: String, ok: bool) -> void:
	print("[%s] %s" % ["ok" if ok else "FALHOU", nome])
	if not ok:
		_falhas += 1
