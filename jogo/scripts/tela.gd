extends Node
## Atalhos de janela durante o desenvolvimento.
## F11 alterna tela cheia e janela. Esc fecha o jogo.
## Em tela cheia num monitor 1920 × 1080, a arte fica exatamente 3× maior.


func _unhandled_input(evento: InputEvent) -> void:
	if not (evento is InputEventKey and evento.pressed and not evento.echo):
		return
	match evento.physical_keycode:
		KEY_F11:
			var cheia := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if cheia else DisplayServer.WINDOW_MODE_FULLSCREEN)
		KEY_ESCAPE:
			get_tree().quit()
