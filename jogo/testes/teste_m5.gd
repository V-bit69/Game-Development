extends "res://testes/base_teste.gd"
## Teste automático do M5 (sapo comum e encontros). Rodar na pasta jogo/:
##   godot --headless --path . -s res://testes/teste_m5.gd

const SAPO := "res://cenas/sapo.tscn"
enum E { AGUARDANDO, TELEGRAPH, SALTO, LINGUA, ESPERA }


func _rodar() -> void:
	_nome_teste = "M5"
	await carregar("res://cenas/sala_teste.tscn")
	var inicio := jogador.position

	# Fora da percepção, fica aguardando.
	var sapo := await criar(SAPO, inicio + Vector2(260, 0))
	await esperar(30)
	conferir("longe (260 px), fica aguardando", sapo.estado == E.AGUARDANDO and not sapo.alerta)
	sapo.position = inicio + Vector2(150, 0)
	await esperar(2)
	conferir("dentro de 200 px, percebe o jogador", sapo.alerta)

	# Ciclo: telegraph 0,5 s, salto de 40 px na direção do jogador, espera 1 s.
	await ate(func(): return sapo.estado == E.TELEGRAPH)
	var t0: float = sapo._relogio
	await ate(func(): return sapo.estado == E.SALTO)
	conferir("telegraph de 0,5 s (%.2f)" % (sapo._relogio - t0), absf(sapo._relogio - t0 - 0.5) <= 0.02)
	var antes: Vector2 = sapo.position
	await ate(func(): return sapo.estado == E.ESPERA)
	var salto: Vector2 = sapo.position - antes
	conferir("salto de 40 px (%.1f)" % salto.length(), absf(salto.length() - 40.0) < 1.0)
	conferir("salto na direção do jogador", salto.x < -35.0)
	t0 = sapo._relogio
	await ate(func(): return sapo.estado == E.TELEGRAPH)
	conferir("espera de 1 s entre ciclos (%.2f)" % (sapo._relogio - t0), absf(sapo._relogio - t0 - 1.0) <= 0.03)

	# Contato no salto: 1 de dano.
	sapo._mudar(E.ESPERA)
	sapo.position = jogador.position + Vector2(45, 0)
	await ate(func(): return sapo.estado == E.ESPERA and sapo._t > 0.1)
	await ate(func(): return sapo.estado == E.SALTO)
	await ate(func(): return sapo.estado != E.SALTO)
	conferir("salto encosta no gato: 1 de dano (vida %d)" % jogador.vida, jogador.vida == 9)

	# Golpe no meio do salto, longe do gato: knockback, o salto acaba e não há dano.
	jogador.vida = 10
	jogador.invulneravel = 0.0
	sapo.position = jogador.position + Vector2(50, 0)
	sapo._mudar(E.ESPERA)
	await ate(func(): return sapo.estado == E.SALTO)
	await esperar(1)
	var x_sapo: float = sapo.position.x
	sapo.receber_dano(1, Vector2.RIGHT, 16.0)
	conferir("golpe no salto: o salto acaba", sapo.estado == E.ESPERA)
	await esperar(10)
	conferir("e aplica o knockback (%.1f)" % (sapo.position.x - x_sapo), sapo.position.x - x_sapo > 14.0)
	conferir("sem encostar, não causa dano", jogador.vida == 10)

	# Golpe no salto ao mesmo tempo que encosta no gato: o dano do salto vale.
	sapo.position = jogador.position + Vector2(18, 0)
	sapo._comecar_salto(Vector2.LEFT)
	sapo.receber_dano(1, Vector2.RIGHT, 16.0)
	conferir("encostou junto com o golpe: 1 de dano (vida %d)" % jogador.vida, jogador.vida == 9)
	jogador.vida = 10
	jogador.invulneravel = 0.0
	await esperar(10)

	# Parry no salto: sem dano, o sapo é lançado e atordoado.
	sapo.vida = 3
	sapo.atordoado = 0.0
	sapo.position = jogador.position + Vector2(45, 0)
	sapo._mudar(E.ESPERA)
	await ate(func(): return sapo.estado == E.SALTO)
	jogador.pedir_parry()
	await ate(func(): return sapo.atordoado > 0.0, 120)
	conferir("parry no salto: sem dano e sapo atordoado", jogador.vida == 10 and sapo.atordoado > 0.0)

	# Morte: corpo fica no chão (o sapo comum tem 4 de vida).
	sapo.receber_dano(3)
	await esperar(2)
	conferir("3 de dano mata e o corpo fica", sapo.morto and is_instance_valid(sapo) and sapo.visible)

	# Morto em cima de um ponto de interesse, o corpo some.
	var ponto := Node2D.new()
	ponto.position = inicio + Vector2(0, 60)
	ponto.add_to_group("interesse")
	sala.add_child(ponto)
	var outro := await criar(SAPO, inicio + Vector2(0, 60))
	conferir("sapo comum tem 4 de vida", outro.vida == 4)
	outro.receber_dano(4)
	await esperar(40)
	conferir("morto em ponto de interesse, o corpo some", not is_instance_valid(outro))

	# Sapos não colidem entre si.
	var a := await criar(SAPO, Vector2(600, 60))
	var b := await criar(SAPO, Vector2(600, 60))
	a._comecar_salto(Vector2.LEFT)
	await esperar(10)
	conferir("sapos se atravessam", absf(a.position.x - (600 - 40)) < 1.0 and b.position == Vector2(600, 60))

	# Obstáculo no caminho: escolhe um desvio (obstáculo 'o' na célula 7, 12).
	var c := await criar(SAPO, Vector2(7.5 * 32, 13 * 32 + 12))
	var d: Vector2 = c._direcao_livre(Vector2.UP)
	conferir("obstáculo no caminho: desvia (%s)" % d, d != Vector2.UP and d.y <= 0.01)

	# Encontros na floresta: sapos dormem até o gatilho.
	a.queue_free()
	b.queue_free()
	c.queue_free()
	sala.queue_free()
	await esperar(2)
	await carregar("res://cenas/floresta.tscn", false)
	var clareira := get_nodes_in_group("inimigos").filter(func(s): return sala.area_em(s.position) == "Clareira")
	var superior := get_nodes_in_group("inimigos").filter(func(s): return sala.area_em(s.position) == "Área superior")
	conferir("21 sapos na floresta (%d)" % get_nodes_in_group("inimigos").size(), get_nodes_in_group("inimigos").size() == 21)
	conferir("sapos da clareira dormem antes do gatilho", clareira.size() == 4 and clareira.all(func(s): return s.dormindo and not s.visible))
	conferir("área superior sem gatilho: sapos acordados", superior.size() == 4 and superior.all(func(s): return not s.dormindo))
	jogador.position = Vector2(15.5 * 32, 36.8 * 32)  # clareira, logo depois de cruzar o gatilho (linha 37)
	await esperar(3)
	await ate(func(): return clareira.all(func(s): return not s.dormindo), 60)
	conferir("cruzou o gatilho: os 4 sapos entram quase juntos", clareira.all(func(s): return s.visible and s.alerta))
	var exterior := get_nodes_in_group("inimigos").filter(func(s): return sala.area_em(s.position) == "Exterior da ruína")
	conferir("exterior continua dormindo", exterior.size() == 13 and exterior.all(func(s): return s.dormindo))
	terminar()
