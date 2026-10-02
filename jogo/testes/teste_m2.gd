extends SceneTree
## Teste automático do M2 (dashes e stamina). Rodar na pasta jogo/:
##   godot --headless --path . -s res://testes/teste_m2.gd

const ACOES := ["mover_esquerda", "mover_direita", "mover_cima", "mover_baixo"]

var _falhas := 0
var _jogador: CharacterBody2D
var _v: Node


func _initialize() -> void:
	_rodar()


func _rodar() -> void:
	_v = root.get_node("Valores")
	var sala: Node2D = load("res://cenas/sala_teste.tscn").instantiate()
	root.add_child(sala)
	await _esperar(2)
	_jogador = sala.get_node("Jogador")
	var inicio := _jogador.position
	var avisos_sem_stamina := [0]
	_jogador.sem_stamina.connect(func() -> void: avisos_sem_stamina[0] += 1)

	# Dash ofensivo para a direita: 104 px em ~0,13 s, gasta 2 unidades.
	Input.action_press("mover_direita")
	_jogador.pedir_dash()
	var quadros := 0
	while _jogador.em_dash:
		await _esperar(1)
		quadros += 1
	_soltar()
	var andou := _jogador.position.x - inicio.x
	_conferir("dash padrão anda 104 px (andou %.1f)" % andou, absf(andou - 104.0) < 1.0)
	_conferir("dash padrão dura 0,13 s (%d quadros = %.2f s)" % [quadros, quadros / 60.0], quadros >= 7 and quadros <= 9)
	_conferir("dash ofensivo gasta 2 unidades", _jogador.stamina == 2)

	# Sem direção apertada, o dash vai para onde o gato olha (direita).
	var x_antes := _jogador.position.x
	_jogador.pedir_dash()
	await _fim_do_dash()
	_conferir("sem seta, dash vai para onde o gato olha", _jogador.position.x > x_antes + 100.0)

	# Parede interrompe o dash no contato: borda em x = 32, raio 10.
	_jogador.stamina = 4
	_jogador.position = Vector2(80, inicio.y)
	Input.action_press("mover_esquerda")
	_jogador.pedir_dash()
	_soltar()
	await _fim_do_dash()
	_conferir("parede interrompe o dash (x = %.1f)" % _jogador.position.x, absf(_jogador.position.x - 42.0) < 1.0)

	# Stamina acabando: 2 dashes zeram, o 3º falha e não move.
	_jogador.stamina = 4
	for i in 2:
		_jogador.position = inicio
		_jogador.pedir_dash()
		await _fim_do_dash()
	_conferir("2 dashes zeram a stamina", _jogador.stamina == 0)
	var pos := _jogador.position
	_conferir("sem stamina o dash falha", not _jogador.pedir_dash() and _jogador.position == pos)
	_conferir("falha avisa a HUD", avisos_sem_stamina[0] == 1)

	# Recuperação: 1 unidade a cada 2 s (120 quadros).
	while _jogador.stamina == 0:
		await _esperar(1)
	var espera := 0
	while _jogador.stamina == 1:
		await _esperar(1)
		espera += 1
	_conferir("recupera 1 unidade a cada 2 s (%d quadros)" % espera, absi(espera - 120) <= 1)

	# Troca para o rolamento.
	_jogador.stamina = 4
	_jogador.trocar_dash()
	_conferir("S troca para o rolamento", _jogador.dash_equipado == 1)
	_jogador.position = inicio
	_jogador.pedir_dash()
	await _fim_do_dash()
	andou = absf(_jogador.position.x - inicio.x)
	_conferir("rolamento anda 64 px (andou %.1f)" % andou, absf(andou - 64.0) < 1.0)
	_conferir("1º rolamento é grátis", _jogador.stamina == 4)
	_jogador.position = inicio
	_jogador.pedir_dash()
	await _fim_do_dash()
	_conferir("2º rolamento é grátis", _jogador.stamina == 4)
	_jogador.position = inicio
	_jogador.pedir_dash()
	await _fim_do_dash()
	_conferir("3º rolamento em 5 s gasta 1", _jogador.stamina == 3)
	_jogador.position = inicio
	_jogador.pedir_dash()
	await _fim_do_dash()
	_conferir("depois de gastar, a contagem recomeça (4º é grátis)", _jogador.stamina == 3)

	# Depois que a janela de 5 s passa, volta a ser grátis.
	await _esperar(310)
	var antes: int = _jogador.stamina
	_jogador.position = inicio
	_jogador.pedir_dash()
	await _fim_do_dash()
	_conferir("depois de 5 s o rolamento volta a ser grátis", _jogador.stamina == antes)

	_jogador.trocar_dash()
	_conferir("S volta para o dash ofensivo", _jogador.dash_equipado == 0)

	print("\n%s" % ("M2 OK: todos os testes passaram." if _falhas == 0 else "M2 FALHOU: %d teste(s)." % _falhas))
	quit(1 if _falhas > 0 else 0)


func _fim_do_dash() -> void:
	while _jogador.em_dash:
		await _esperar(1)


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
