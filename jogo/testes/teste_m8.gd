extends "res://testes/base_teste.gd"
## Teste automático do M8 (escalada e descida). Rodar na pasta jogo/:
##   godot --headless --path . -s res://testes/teste_m8.gd
## Fachada da ruína nas linhas 11 e 12; trecho escalável (D) na coluna 4.

const BASE_FACHADA := 13 * 32.0  # borda de baixo da fachada
const TOPO_FACHADA := 11 * 32.0  # borda de cima


func _rodar() -> void:
	_nome_teste = "M8"
	await carregar("res://cenas/floresta.tscn")  # sem sapos, para testar só a escalada

	# Embaixo do trecho D: aparece a indicação D.
	jogador.position = Vector2(4.5 * 32, BASE_FACHADA + 14)
	await esperar(2)
	conferir("perto do trecho escalável, indicação D", jogador.indicador == "D")

	# Andando, a parede segura.
	Input.action_press("mover_cima")
	await esperar(30)
	Input.action_release("mover_cima")
	conferir("andando, não passa da parede (y = %.1f)" % jogador.position.y, jogador.position.y >= BASE_FACHADA + 9.0)

	# Rolamento para cima: não escala.
	jogador.trocar_dash()
	Input.action_press("mover_cima")
	jogador.pedir_dash()
	Input.action_release("mover_cima")
	await ate(func(): return not jogador.em_dash)
	conferir("rolamento não escala", jogador.position.y >= BASE_FACHADA + 9.0 and not jogador.em_escalada)
	jogador.trocar_dash()

	# Dash ofensivo para cima: escala, com a duração do dash, e gasta stamina.
	jogador.stamina = 4
	Input.action_press("mover_cima")
	jogador.pedir_dash()
	Input.action_release("mover_cima")
	conferir("dash padrão para cima começa a escalada", jogador.em_escalada)
	var quadros := 0
	while jogador.em_escalada:
		await esperar(1)
		quadros += 1
	conferir("escalada dura o mesmo que o dash (%d quadros)" % quadros, quadros >= 7 and quadros <= 9)
	conferir("chega em cima da ruína (y = %.1f)" % jogador.position.y, jogador.position.y < TOPO_FACHADA)
	conferir("área superior", sala.area_em(jogador.position) == "Área superior")
	conferir("escalada gasta 2 de stamina (dash ofensivo)", jogador.stamina == 2)

	# Longe do trecho D, o dash para cima é um dash normal (bate na parede).
	jogador.position = Vector2(8.5 * 32, BASE_FACHADA + 14)
	await esperar(1)
	Input.action_press("mover_cima")
	jogador.pedir_dash()
	Input.action_release("mover_cima")
	await ate(func(): return not jogador.em_dash)
	conferir("fora do trecho D, a parede segura o dash", jogador.position.y >= BASE_FACHADA + 9.0)

	# Descida (v): E perto dela desce para a frente da ruína.
	jogador.position = Vector2(18.5 * 32, 10.5 * 32)
	await esperar(2)
	conferir("perto da descida, indicador E", jogador.indicador == "E")
	sala._interagir()
	await ate(func(): return not jogador.em_escalada)
	conferir("desce para o exterior (y = %.1f)" % jogador.position.y, jogador.position.y > BASE_FACHADA and sala.area_em(jogador.position) == "Exterior da ruína")

	# De cima do trecho D, dash para baixo também desce.
	jogador.position = Vector2(4.5 * 32, TOPO_FACHADA - 14)
	jogador.stamina = 4
	await esperar(1)
	Input.action_press("mover_baixo")
	jogador.pedir_dash()
	Input.action_release("mover_baixo")
	await ate(func(): return not jogador.em_escalada)
	conferir("dash para baixo no trecho D desce", jogador.position.y > BASE_FACHADA)
	terminar()
