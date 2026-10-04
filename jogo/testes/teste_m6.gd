extends "res://testes/base_teste.gd"
## Teste automático do M6 (sapo com língua). Rodar na pasta jogo/:
##   godot --headless --path . -s res://testes/teste_m6.gd

const SAPO := "res://cenas/sapo_lingua.tscn"
enum E { AGUARDANDO, TELEGRAPH, SALTO, LINGUA, ESPERA }
enum A { LINGUA, SALTO_LINGUA, PERSEGUIR }


func _rodar() -> void:
	_nome_teste = "M6"
	await carregar("res://cenas/sala_teste.tscn")
	var inicio := jogador.position

	# Zona próxima (até 40 px): parado, telegraph, língua.
	var sapo := await criar(SAPO, inicio + Vector2(30, 0))
	await ate(func(): return sapo.estado == E.TELEGRAPH)
	conferir("zona próxima: escolhe a língua", sapo._acao == A.LINGUA)
	var pos: Vector2 = sapo.position
	await ate(func(): return sapo.lingua_ativa)
	var maior := 0.0
	while sapo.lingua_ativa:
		maior = maxf(maior, sapo._lingua_comprimento)
		await esperar(1)
	conferir("língua alcança o gato: 1 de dano (vida %d)" % jogador.vida, jogador.vida == 9)
	conferir("língua para no gato ou em 40 px e volta (máx %.1f)" % maior, maior <= 40.0 and maior > 20.0)
	conferir("usou a língua parado", sapo.position == pos)
	await ate(func(): return sapo.estado == E.ESPERA)
	conferir("depois da língua, espera", sapo.estado == E.ESPERA)

	# Longe do gato, a língua vai até 40 px e volta pelo mesmo caminho.
	sapo._lancar_lingua(jogador)
	sapo._lingua_direcao = Vector2.UP
	sapo._lingua_acertou = true
	maior = 0.0
	var quadros := 0
	while sapo.lingua_ativa:
		maior = maxf(maior, sapo._lingua_comprimento)
		quadros += 1
		sapo._atualizar_lingua(1.0 / 60.0, jogador)
	conferir("língua solta: 40 px, ida e volta em ~0,2 s (%.1f px, %d quadros)" % [maior, quadros], absf(maior - 40.0) < 0.1 and absi(quadros - 12) <= 1)

	# Zona intermediária (40 a 80 px): pula e usa a língua.
	jogador.vida = 10
	sapo.position = inicio + Vector2(65, 0)
	sapo._mudar(E.AGUARDANDO)
	await ate(func(): return sapo.estado == E.TELEGRAPH)
	conferir("zona intermediária: pula e usa a língua", sapo._acao == A.SALTO_LINGUA)
	await ate(func(): return sapo.estado == E.SALTO)
	conferir("no salto, a língua sai junto", sapo.lingua_ativa)
	await ate(func(): return sapo.estado == E.ESPERA and not sapo.lingua_ativa)

	# Zona externa: salto de perseguição, sem língua.
	sapo.position = inicio + Vector2(150, 0)
	sapo._mudar(E.AGUARDANDO)
	await ate(func(): return sapo.estado == E.TELEGRAPH)
	conferir("zona externa: salto de perseguição", sapo._acao == A.PERSEGUIR)
	var usou := false
	while sapo.estado != E.ESPERA:
		usou = usou or sapo.lingua_ativa
		await esperar(1)
	conferir("perseguição sem língua", not usou)

	# Parry na língua: rebatida, sapo atingido e atordoado onde está.
	jogador.vida = 10
	sapo.vida = 3
	sapo.position = inicio + Vector2(30, 0)
	sapo._mudar(E.AGUARDANDO)
	await ate(func(): return sapo.estado == E.TELEGRAPH)
	await ate(func(): return sapo._t >= 0.45)
	jogador.pedir_parry()
	pos = sapo.position
	await ate(func(): return sapo.atordoado > 0.0, 60)
	conferir("parry na língua: gato sem dano", jogador.vida == 10)
	conferir("sapo atingido (vida %d) e atordoado" % sapo.vida, sapo.vida == 2 and sapo.atordoado > 0.0)
	conferir("fica onde está, sem ser lançado", sapo.position == pos)
	conferir("língua interrompida", not sapo.lingua_ativa)
	conferir("atordoado por 2 s (%.2f)" % sapo.atordoado, absf(sapo.atordoado - 2.0) < 0.05)
	conferir("chute imediato, sem espera", jogador._chute > 0.0 and jogador._chute_espera == 0.0)

	# Golpe que pega só a língua não faz nada; golpe no corpo recolhe a língua.
	await ate(func(): return sapo.atordoado == 0.0)
	sapo._mudar(E.ESPERA)
	sapo._lancar_lingua(jogador)
	sapo._mudar(E.LINGUA)
	sapo.receber_dano(1, Vector2.RIGHT, 24.0)
	conferir("golpe no corpo recolhe a língua", not sapo.lingua_ativa)

	# Rolamento esquiva da língua (projétil): sem dano, e ela não fere mais depois.
	jogador.vida = 10
	jogador.invulneravel = 0.0
	sapo.position = inicio + Vector2(30, 0)
	sapo.atordoado = 0.0
	sapo._mudar(E.LINGUA)
	jogador.trocar_dash()
	jogador.direcao_olhar = Vector2.UP
	jogador.pedir_dash()
	sapo._lancar_lingua(jogador)
	await ate(func(): return not sapo.lingua_ativa, 60)
	conferir("rolamento esquiva da língua (vida %d)" % jogador.vida, jogador.vida == 10)
	jogador.trocar_dash()
	jogador.position = inicio

	# O salto do sapo com língua não causa dano (seção 30): todo o dano vem da língua.
	conferir("sapo com língua tem 4 de vida", sapo.vida_maxima == 4)
	conferir("salto_fere() é false no sapo com língua e true no comum", not sapo.salto_fere() and load("res://cenas/sapo.tscn").instantiate().salto_fere())
	jogador.vida = 10
	jogador.invulneravel = 0.0
	sapo.atordoado = 0.0
	sapo.vida = 4
	sapo.position = jogador.position + Vector2(25, 0)
	sapo._comecar_salto(Vector2.LEFT)  # salto puro (sem língua) por cima do gato
	var encostou := false
	while sapo.estado == E.SALTO:
		encostou = encostou or sapo._encosta_no_jogador(jogador)
		await esperar(1)
	conferir("o salto passou encostando no gato", encostou)
	conferir("mas o salto não causa dano (vida %d)" % jogador.vida, jogador.vida == 10)
	# Golpe simultâneo com o salto encostando: também sem dano.
	sapo.position = jogador.position + Vector2(18, 0)
	sapo._comecar_salto(Vector2.LEFT)
	sapo.receber_dano(1, Vector2.RIGHT, 24.0)
	conferir("golpe no salto encostando: sem dano para o gato (vida %d)" % jogador.vida, jogador.vida == 10)

	# Obstáculo entre o sapo e o gato: não usa a língua, contorna.
	sapo.queue_free()
	var outro := await criar(SAPO, Vector2(7.5 * 32, 13 * 32 + 14))
	jogador.position = Vector2(7.5 * 32, 11 * 32)
	await ate(func(): return outro.estado == E.TELEGRAPH)
	conferir("obstáculo bloqueia a língua: persegue", outro._acao == A.PERSEGUIR)
	terminar()
