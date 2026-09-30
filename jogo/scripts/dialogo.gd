extends Node
## Caixa de diálogo provisória (M7). Uso: Dialogo.mostrar(falas, ao_terminar)
## Cada fala é [quem fala, texto]. O jogo pausa enquanto o diálogo está aberto,
## e cada frase avança com E (ou Enter).

signal terminou

var ativo := false

var _falas: Array = []
var _indice := 0
var _ao_terminar := Callable()
var _camada: CanvasLayer
var _nome: Label
var _texto: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_camada = CanvasLayer.new()
	_camada.layer = 10
	_camada.visible = false
	add_child(_camada)
	var caixa := Panel.new()
	caixa.position = Vector2(20, 268)
	caixa.size = Vector2(600, 80)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.06, 0.05, 0.1, 0.92)
	estilo.border_color = Color(0.95, 0.85, 0.6)
	estilo.set_border_width_all(1)
	caixa.add_theme_stylebox_override("panel", estilo)
	_camada.add_child(caixa)
	_nome = _rotulo(Vector2(10, 5), Vector2(580, 14), 11, Color(1, 0.8, 0.4))
	_texto = _rotulo(Vector2(10, 21), Vector2(580, 44), 11, Color.WHITE)
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caixa.add_child(_nome)
	caixa.add_child(_texto)
	var dica := _rotulo(Vector2(540, 64), Vector2(52, 12), 9, Color(1, 1, 1, 0.6))
	dica.text = "E ▸"
	dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	caixa.add_child(dica)


func _rotulo(pos: Vector2, medida: Vector2, fonte: int, cor: Color) -> Label:
	var r := Label.new()
	r.position = pos
	r.size = medida
	r.add_theme_font_size_override("font_size", fonte)
	r.add_theme_color_override("font_color", cor)
	return r


func mostrar(falas: Array, ao_terminar := Callable()) -> void:
	if ativo or falas.is_empty():
		return
	_falas = falas
	_indice = 0
	_ao_terminar = ao_terminar
	ativo = true
	get_tree().paused = true
	_camada.visible = true
	_exibir()


func avancar() -> void:
	if not ativo:
		return
	_indice += 1
	if _indice >= _falas.size():
		fechar()
	else:
		Som.tocar("troca")
		_exibir()


func fechar() -> void:
	if not ativo:
		return
	ativo = false
	_camada.visible = false
	get_tree().paused = false
	var callback := _ao_terminar
	_ao_terminar = Callable()
	if callback.is_valid():
		callback.call()
	terminou.emit()


func _exibir() -> void:
	var fala: Array = _falas[_indice]
	_nome.text = fala[0]
	_nome.visible = fala[0] != ""
	_texto.text = fala[1]


func _unhandled_input(evento: InputEvent) -> void:
	if not ativo:
		return
	if evento.is_action_pressed("interagir") or evento.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		avancar()
