extends "res://testes/base_teste.gd"
## Teste automático do M4 (parry). Rodar na pasta jogo/:
##   godot --headless --path . -s res://testes/teste_m4.gd

const ATACANTE := "res://cenas/alvo_atacante.tscn"


func _rodar() -> void:
	_nome_teste = "M4"
	await carregar("res://cenas/sala_teste.tscn")
	var inicio := jogador.position
	var v := root.get_node("Valores")
	var alvo := await criar(ATACANTE, inicio + Vector2(26, 0))

	# Parry no tempo certo: Q um pouco antes do golpe.
	await ate(func(): return alvo.estado == 1 and alvo._tempo_estado >= 0.4)
	jogador.pedir_parry()
	var x_antes: float = alvo.position.x
	await ate(func(): return alvo.estado != 1)
	conferir("parry defende o golpe (vida %d)" % jogador.vida, jogador.vida == 10)
	await ate(func(): return alvo._empurrao_restante <= 0.0)
	conferir("inimigo é lançado 80 px (andou %.1f)" % (alvo.position.x - x_antes), absf(alvo.position.x - x_antes - 80.0) < 1.5)
	conferir("inimigo fica atordoado por 1 s", absf(alvo.atordoado - v.GATO_PARRY_ATORDOAMENTO) < 0.05)
	conferir("parry certo não tem recuperação", jogador.parry_recuperacao == 0.0)
	await esperar(30)
	conferir("atordoado, não age", alvo.estado == 0 and alvo.atordoado > 0.0)
	await ate(func(): return alvo.atordoado == 0.0)

	# Parry cedo demais: a janela fecha antes do golpe e o gato toma o dano.
	alvo.position = inicio + Vector2(26, 0)
	alvo._mudar(0)
	await ate(func(): return alvo.estado == 1)
	jogador.pedir_parry()
	await esperar(13)
	conferir("janela fecha em 0,2 s e começa a recuperação", jogador.parry_janela == 0.0 and jogador.parry_recuperacao > 0.0)
	conferir("na recuperação, Q não funciona", not jogador.pedir_parry())
	await ate(func(): return alvo.estado != 1)
	conferir("parry cedo demais: toma o golpe (vida %d)" % jogador.vida, jogador.vida == 9)
	await ate(func(): return jogador.parry_recuperacao == 0.0)
	conferir("depois de 0,4 s, Q volta a funcionar", jogador.pedir_parry())
	await esperar(15)

	# Sem parry: toma o golpe, pisca e a tela treme.
	alvo._mudar(0)
	await ate(func(): return alvo.estado == 2)
	conferir("sem parry: toma o golpe (vida %d)" % jogador.vida, jogador.vida == 8)
	conferir("dano: piscar e tremor", jogador.piscar_de_dano() > 0.0 and jogador._tremor > 0.0)
	alvo.queue_free()

	# Parry cancela o combo e não sai durante o dash.
	await esperar(30)
	jogador.pedir_ataque()
	await esperar(2)
	jogador.pedir_parry()
	conferir("Q cancela o golpe", jogador.golpe_atual == 0 and jogador.parry_janela > 0.0)
	Input.action_press("mover_direita")
	await esperar(3)
	conferir("com a janela aberta, o gato fica parado", jogador.velocity == Vector2.ZERO)
	Input.action_release("mover_direita")
	await ate(func(): return jogador.parry_recuperacao == 0.0 and jogador.parry_janela == 0.0)
	jogador.pedir_dash()
	conferir("durante o dash, Q não funciona", not jogador.pedir_parry())
	terminar()
