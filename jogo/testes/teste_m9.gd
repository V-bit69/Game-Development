extends "res://testes/base_teste.gd"
## Teste automático do M9 (vida, morte, recomeço e pausa). Rodar na pasta jogo/:
##   godot --headless --path . -s res://testes/teste_m9.gd


func _rodar() -> void:
	_nome_teste = "M9"
	await carregar("res://cenas/sala_teste.tscn")
	var tela := root.get_node("Tela")
	var hud := sala.get_node("HUD/Barras")

	# Pausa: congela o jogo e volta.
	tela.pausar()
	await esperar(1)
	conferir("Esc pausa o jogo", tela.pausado and paused)
	var pos := jogador.position
	Input.action_press("mover_direita")
	await esperar(10)
	Input.action_release("mover_direita")
	conferir("pausado, o gato não anda", jogador.position == pos)
	tela._escolher(1)
	conferir("menu: setas escolhem a opção", tela._opcao == 1)
	tela._escolher(0)
	tela._confirmar()
	await esperar(1)
	conferir("Continuar volta ao jogo", not tela.pausado and not paused)

	# Dano: vida cai, borda vermelha na HUD.
	var atacante := Node2D.new()
	atacante.position = jogador.position + Vector2(20, 0)
	sala.add_child(atacante)
	jogador.receber_ataque(atacante, 3)
	conferir("vida cai em unidades (10 → 7)", jogador.vida == 7)
	conferir("borda vermelha de dano", jogador.piscar_de_dano() > 0.0)

	# Morte: vida em 0, filtro, aviso, e o jogo para.
	jogador.receber_ataque(atacante, 7)
	conferir("vida 0: morte", jogador.vida == 0 and jogador.morto)
	conferir("tela de morte aparece", tela.na_morte and tela._camada_morte.visible)
	await ate(func(): return paused, 120)
	conferir("depois do filtro, o jogo para", paused)
	tela.pausar()
	conferir("na morte, o menu de pausa não abre", not tela.pausado)

	# E recomeça a fase desde o início, com tudo zerado.
	tela._unhandled_input(_tecla_e())
	await esperar(3)
	var nova: Node2D = current_scene
	var novo_jogador: CharacterBody2D = nova.get_node("Jogador")
	conferir("E recomeça a fase", nova != sala and not tela.na_morte and not paused)
	conferir("vida cheia de novo", novo_jogador.vida == 10 and not novo_jogador.morto)
	conferir("de volta ao início (@)", novo_jogador.position == Vector2(6.5 * 32, 10.5 * 32))
	terminar()


func _tecla_e() -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = KEY_E
	e.keycode = KEY_E
	e.pressed = true
	return e
