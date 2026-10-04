extends "res://testes/base_teste.gd"
## Teste automático do M4 (parry em dois tempos, invulnerabilidade de 1 s e dash/golpe x parry, v1.4.1). Rodar na pasta jogo/:
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
	conferir("defesa: inimigo atordoado 0,5 s, ainda no lugar", absf(alvo.atordoado - v.GATO_PARRY_ESPERA_CHUTE) < 0.05 and alvo.position.x == x_antes)
	conferir("parry certo não tem recuperação", jogador.parry_recuperacao == 0.0)
	Input.action_press("mover_cima")
	await esperar(10)
	conferir("esperando o chute, o gato não anda", jogador.velocity == Vector2.ZERO)
	Input.action_release("mover_cima")
	await ate(func(): return alvo._empurrao_restante > 0.0, 40)
	conferir("chute sai depois de 0,5 s", jogador._chute > 0.0)
	await ate(func(): return alvo._empurrao_restante <= 0.0)
	await esperar(1)
	conferir("inimigo é lançado 80 px (andou %.1f)" % (alvo.position.x - x_antes), absf(alvo.position.x - x_antes - 80.0) < 1.5)
	conferir("depois do empurrão, mais 1,5 s atordoado", absf(alvo.atordoado - v.GATO_PARRY_ATORDOAMENTO) < 0.05)
	await esperar(30)
	conferir("atordoado, não age", alvo.estado == 0 and alvo.atordoado > 0.0)
	await ate(func(): return alvo.atordoado == 0.0)

	# Dash na espera cancela o chute: o inimigo fica só com os 0,5 s.
	alvo.position = inicio + Vector2(26, 0)
	alvo._mudar(0)
	await ate(func(): return alvo.estado == 1 and alvo._tempo_estado >= 0.4)
	jogador.pedir_parry()
	await ate(func(): return alvo.estado != 1)
	x_antes = alvo.position.x
	await esperar(5)
	jogador.direcao_olhar = Vector2.UP
	conferir("dash funciona na espera do chute", jogador.pedir_dash())
	await ate(func(): return alvo.atordoado == 0.0, 60)
	await esperar(5)
	conferir("sem chute: não foi lançado e o atordoamento acabou", alvo.position.x == x_antes and alvo.atordoado == 0.0)
	await ate(func(): return not jogador.em_dash)
	jogador.position = inicio + Vector2(-150, 0)  # longe do alvo enquanto a stamina volta
	await esperar(100)
	jogador.position = inicio

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

	# Depois do dano, 1 s invulnerável (pode atacar e dar dash).
	conferir("invulnerável logo depois do dano (%.2f s)" % jogador.invulneravel, jogador.invulneravel > 0.95 and jogador.invulneravel <= 1.0)
	jogador.receber_ataque(sala, 1)
	conferir("invulnerável: o segundo golpe não tira vida", jogador.vida == 8)
	jogador.direcao_olhar = Vector2.UP
	jogador.pedir_ataque()
	conferir("invulnerável, o gato pode atacar", jogador.golpe_atual != 0)
	await esperar(2)
	conferir("invulnerável, o gato pode dar dash", jogador.pedir_dash() and jogador.em_dash)
	await ate(func(): return not jogador.em_dash)
	await ate(func(): return jogador.invulneravel == 0.0)
	jogador.receber_ataque(sala, 1)
	conferir("depois de 1 s, toma dano de novo", jogador.vida == 7)
	await ate(func(): return jogador.invulneravel == 0.0)
	jogador.position = inicio

	# Parry x golpe: a mesma regra do dash (antecipação cancela, execução ignora, recuperação funciona).
	jogador.stamina = 4
	await esperar(30)
	jogador.position = inicio
	jogador._proximo_golpe = 1
	jogador.pedir_ataque()
	await esperar(2)
	jogador.pedir_parry()
	conferir("Q na antecipação cancela o golpe, que não conta", jogador.golpe_atual == 0 and jogador.parry_janela > 0.0 and jogador._proximo_golpe == 1)
	Input.action_press("mover_direita")
	await esperar(3)
	conferir("com a janela aberta, o gato fica parado", jogador.velocity == Vector2.ZERO)
	Input.action_release("mover_direita")
	await ate(func(): return jogador.parry_recuperacao == 0.0 and jogador.parry_janela == 0.0)
	jogador.pedir_ataque()
	await esperar(8)  # 0,133 s: execução
	conferir("Q na execução é ignorado", not jogador.pedir_parry() and jogador.golpe_atual != 0 and jogador.parry_janela == 0.0)
	await ate(func(): return jogador.golpe_atual == 0 and jogador._intervalo > 0.0)
	var recuperacao_antes: float = jogador._intervalo
	conferir("Q na recuperação funciona", jogador.pedir_parry() and jogador.parry_janela > 0.0)
	await esperar(3)
	conferir("e a recuperação do golpe continua correndo", jogador._intervalo < recuperacao_antes - 0.04)
	await ate(func(): return jogador.parry_recuperacao == 0.0 and jogador.parry_janela == 0.0 and jogador._intervalo == 0.0)

	# O dash cancela o parry, mas a recuperação de 0,4 s não encurta.
	jogador.position = inicio
	jogador.pedir_parry()
	await esperar(3)
	var resta: float = jogador.parry_janela
	jogador.direcao_olhar = Vector2.UP
	conferir("dash cancela a janela do parry", jogador.pedir_dash() and jogador.parry_janela == 0.0 and jogador.em_dash)
	conferir("os 0,4 s de recuperação continuam contando (%.2f s)" % jogador.parry_recuperacao, absf(jogador.parry_recuperacao - (resta + 0.4)) < 0.02)
	await ate(func(): return not jogador.em_dash)
	conferir("depois do dash, Q ainda não funciona", not jogador.pedir_parry())
	await ate(func(): return jogador.parry_recuperacao == 0.0)
	conferir("passada a recuperação, Q volta a funcionar", jogador.pedir_parry())
	await ate(func(): return jogador.parry_recuperacao == 0.0 and jogador.parry_janela == 0.0)

	# Durante o dash, Q não funciona.
	jogador.stamina = 4
	jogador.pedir_dash()
	conferir("durante o dash, Q não funciona", not jogador.pedir_parry())
	terminar()
