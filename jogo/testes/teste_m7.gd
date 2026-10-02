extends "res://testes/base_teste.gd"
## Teste automático do M7 (interação com E, diálogos e coletas). Rodar na pasta jogo/:
##   godot --headless --path . -s res://testes/teste_m7.gd

const T := preload("res://scripts/textos.gd")


func _celula(x: int, y: int) -> Vector2:
	return (Vector2(x, y) + Vector2(0.5, 0.5)) * 32.0


func _rodar() -> void:
	_nome_teste = "M7"
	await carregar("res://cenas/floresta.tscn", false)
	var dialogo := root.get_node("Dialogo")

	conferir("no início, sem objetivo e sem diálogo", sala.objetivo == "" and not dialogo.ativo)

	# Chegar perto de Xennar: o diálogo começa sozinho e o jogo pausa.
	jogador.position = _celula(13, 68) + Vector2(0, 40)
	await esperar(2)
	conferir("perto de Xennar, o diálogo começa sozinho", dialogo.ativo and paused)
	conferir("primeira fala é a do VELHO", dialogo._nome.text == "VELHO" and dialogo._texto.text == T.XENNAR_PRIMEIRA[0][1])
	for i in T.XENNAR_PRIMEIRA.size() - 1:
		dialogo.avancar()
	conferir("cada frase avança com um comando (10 falas)", dialogo.ativo and dialogo._indice == 9)
	dialogo.avancar()
	await esperar(1)
	conferir("fim do diálogo: jogo volta", not dialogo.ativo and not paused)
	conferir("objetivo: recuperar o cajado", sala.objetivo == T.OBJETIVO)

	# Segunda conversa, com E: as duas falas de depois.
	jogador.position = _celula(13, 68) + Vector2(0, 24)
	await esperar(2)
	conferir("perto de Xennar, indicador E", jogador.indicador == "E")
	sala._interagir()
	conferir("segunda conversa: falas de depois", dialogo.ativo and dialogo._texto.text == T.XENNAR_DEPOIS[0][1])
	dialogo.fechar()

	# Estátua: indicador E, inscrição sem nome e fala do gato.
	jogador.position = _celula(14, 32) + Vector2(0, 26)
	await esperar(2)
	conferir("perto da estátua, indicador E", jogador.indicador == "E")
	sala._interagir()
	conferir("estátua: inscrição sem nome", dialogo.ativo and dialogo._nome.text == "" and dialogo._texto.text == T.ESTATUA[0][1])
	dialogo.fechar()

	# Flor: interação oculta (sem indicador), coleta e some.
	jogador.position = _celula(10, 50) + Vector2(16, 0)
	await esperar(2)
	conferir("perto da flor, sem indicador (oculta)", jogador.indicador == "")
	sala._interagir()
	conferir("E na flor: coleta e fala do gato", dialogo.ativo and dialogo._texto.text == T.FLOR[0][1])
	dialogo.fechar()
	conferir("flor some do mapa", sala._linhas[50][10] == "." and sala._interativo_por_id("flor").is_empty())

	# Elemento tecnológico.
	jogador.position = _celula(17, 58)  # fragmento longe da ruína, no corredor
	await esperar(2)
	sala._interagir()
	conferir("elemento tecnológico: falas do gato", dialogo.ativo and dialogo._texto.text == T.ELEMENTO[0][1])
	dialogo.fechar()

	# Peça da KLM-99 na área superior.
	jogador.position = _celula(3, 2) + Vector2(16, 0)
	await esperar(2)
	conferir("perto da peça, indicador E", jogador.indicador == "E")
	sala._interagir()
	conferir("peça: coleta e fala", dialogo.ativo and dialogo._texto.text == T.PECA[0][1])
	dialogo.fechar()
	conferir("peça some do mapa", sala._interativo_por_id("peca").is_empty())

	# Longe de tudo, E não faz nada.
	jogador.position = _celula(15, 20)
	await esperar(2)
	sala._interagir()
	conferir("longe de tudo, E não faz nada", not dialogo.ativo and jogador.indicador == "")
	terminar()
