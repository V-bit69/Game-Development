extends Node
## Telas por cima do jogo (M9): pausa, morte, e atalhos de janela.
##   Esc  pausa / continua
##   F11  alterna tela cheia e janela
##   R    recomeça a fase (atalho de desenvolvimento)
## Na morte: filtro cinza avermelhado, aviso, e E recomeça a fase desde o início.

const OPCOES := ["Continuar", "Recomeçar a fase", "Sair do jogo"]

var pausado := false
var na_morte := false

var _opcao := 0
var _camada_pausa: CanvasLayer
var _rotulos: Array[Label] = []
var _camada_morte: CanvasLayer
var _filtro: ColorRect
var _aviso_morte: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_montar_pausa()
	_montar_morte()


func _unhandled_input(evento: InputEvent) -> void:
	if not (evento is InputEventKey and evento.pressed and not evento.echo):
		return
	if evento.physical_keycode == KEY_F11:
		var cheia := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if cheia else DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	if na_morte:
		if evento.is_action_pressed("interagir"):
			get_viewport().set_input_as_handled()
			recomecar()
		return
	if pausado:
		get_viewport().set_input_as_handled()
		if evento.physical_keycode == KEY_ESCAPE:
			continuar()
		elif evento.is_action_pressed("mover_cima"):
			_escolher(_opcao - 1)
		elif evento.is_action_pressed("mover_baixo"):
			_escolher(_opcao + 1)
		elif evento.is_action_pressed("interagir") or evento.is_action_pressed("ui_accept"):
			_confirmar()
		return
	if Dialogo.ativo:
		return
	if evento.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		pausar()
	elif evento.physical_keycode == KEY_R:
		recomecar()


# --- Pausa --------------------------------------------------------------

func pausar() -> void:
	if pausado or na_morte:
		return
	pausado = true
	get_tree().paused = true
	_escolher(0)
	_camada_pausa.visible = true
	Som.tocar("troca")


func continuar() -> void:
	if not pausado:
		return
	pausado = false
	_camada_pausa.visible = false
	get_tree().paused = Dialogo.ativo


func _escolher(indice: int) -> void:
	_opcao = wrapi(indice, 0, OPCOES.size())
	for i in _rotulos.size():
		_rotulos[i].text = ("▸ " if i == _opcao else "   ") + OPCOES[i]
		_rotulos[i].modulate = Color(1, 0.85, 0.5) if i == _opcao else Color(1, 1, 1, 0.75)


func _confirmar() -> void:
	match _opcao:
		0: continuar()
		1: recomecar()
		2: get_tree().quit()


func _montar_pausa() -> void:
	_camada_pausa = CanvasLayer.new()
	_camada_pausa.layer = 20
	_camada_pausa.visible = false
	add_child(_camada_pausa)
	var fundo := ColorRect.new()
	fundo.color = Color(0.03, 0.02, 0.06, 0.7)
	fundo.size = Vector2(640, 360)
	_camada_pausa.add_child(fundo)
	var titulo := _rotulo("Pausado", 22, Vector2(0, 110))
	_camada_pausa.add_child(titulo)
	for i in OPCOES.size():
		var r := _rotulo(OPCOES[i], 13, Vector2(0, 160 + i * 22))
		_camada_pausa.add_child(r)
		_rotulos.append(r)
	var dica := _rotulo("Setas: escolher · E: confirmar · Esc: voltar ao jogo", 9, Vector2(0, 320))
	dica.modulate = Color(1, 1, 1, 0.6)
	_camada_pausa.add_child(dica)


# --- Morte --------------------------------------------------------------

func mostrar_morte() -> void:
	if na_morte:
		return
	na_morte = true
	pausado = false
	_camada_pausa.visible = false
	_camada_morte.visible = true
	_aviso_morte.modulate.a = 0.0
	_filtro.material.set_shader_parameter("forca", 0.0)
	var entrada := create_tween()
	entrada.tween_method(func(v: float) -> void: _filtro.material.set_shader_parameter("forca", v), 0.0, 1.0, 0.8)
	entrada.parallel().tween_property(_aviso_morte, "modulate:a", 1.0, 0.8).set_delay(0.4)
	# Os inimigos param quando o filtro termina de entrar.
	entrada.tween_callback(func() -> void: get_tree().paused = true)


func _montar_morte() -> void:
	_camada_morte = CanvasLayer.new()
	_camada_morte.layer = 15
	_camada_morte.visible = false
	add_child(_camada_morte)
	_filtro = ColorRect.new()
	_filtro.size = Vector2(640, 360)
	_filtro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sombra := ShaderMaterial.new()
	sombra.shader = Shader.new()
	sombra.shader.code = """shader_type canvas_item;
uniform sampler2D tela : hint_screen_texture, filter_nearest;
uniform float forca = 1.0;
void fragment() {
	vec3 c = texture(tela, SCREEN_UV).rgb;
	float cinza = dot(c, vec3(0.3, 0.59, 0.11));
	vec3 morto = vec3(cinza) * vec3(0.9, 0.55, 0.55) * 0.75;
	COLOR = vec4(mix(c, morto, forca), 1.0);
}"""
	_filtro.material = sombra
	_camada_morte.add_child(_filtro)
	_aviso_morte = Control.new()
	_aviso_morte.size = Vector2(640, 360)
	_camada_morte.add_child(_aviso_morte)
	_aviso_morte.add_child(_rotulo("O Homem-gato caiu", 22, Vector2(0, 140)))
	var dica := _rotulo("Pressione E para recomeçar", 12, Vector2(0, 180))
	dica.modulate = Color(1, 0.85, 0.7)
	_aviso_morte.add_child(dica)


# --- Recomeçar ----------------------------------------------------------

## Recomeça a fase desde o início. Não há checkpoint: tudo volta ao estado inicial.
func recomecar() -> void:
	pausado = false
	na_morte = false
	_camada_pausa.visible = false
	_camada_morte.visible = false
	if Dialogo.ativo:
		Dialogo.fechar()
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene()


func _rotulo(texto: String, fonte: int, pos: Vector2) -> Label:
	var r := Label.new()
	r.text = texto
	r.position = pos
	r.size = Vector2(640, fonte + 8)
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	r.add_theme_font_size_override("font_size", fonte)
	r.add_theme_color_override("font_outline_color", Color.BLACK)
	r.add_theme_constant_override("outline_size", 3)
	return r
