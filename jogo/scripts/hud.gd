extends Control
## HUD provisória do canto superior esquerdo: vida, stamina e dash equipado.
## Desenhada com formas simples até chegar a arte da UI.

const COR_VIDA := Color(0.86, 0.23, 0.23)
const COR_STAMINA := Color(1.0, 0.58, 0.15)
const COR_VAZIO := Color(0, 0, 0, 0.45)
const COR_BORDA := Color(0, 0, 0, 0.8)
const COR_FALHA := Color(1, 1, 1)
const PISCAR_DURACAO := 0.45

const ORIGEM := Vector2(8, 8)
const VIDA_TAMANHO := Vector2(7, 7)
const STAMINA_TAMANHO := Vector2(14, 6)
const ESPACO := 2.0

const Jogador := preload("res://scripts/jogador.gd")

var _jogador: Jogador
var _piscar := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_jogador = get_tree().get_first_node_in_group("jogador")
	_jogador.sem_stamina.connect(func() -> void: _piscar = PISCAR_DURACAO)


func _process(delta: float) -> void:
	_piscar = maxf(_piscar - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	# Vida: 10 quadrados. O dano chega no M9, então por enquanto fica cheia.
	for i in Valores.GATO_VIDA:
		var pos := ORIGEM + Vector2(i * (VIDA_TAMANHO.x + ESPACO), 0)
		_bloco(Rect2(pos, VIDA_TAMANHO), COR_VIDA, 1.0)

	# Stamina: 4 unidades laranja. A próxima a voltar vai enchendo.
	var y := ORIGEM.y + VIDA_TAMANHO.y + 4.0
	var piscando := _piscar > 0.0 and fmod(_piscar, 0.15) > 0.075
	for i in Valores.STAMINA_MAXIMA:
		var pos := Vector2(ORIGEM.x + i * (STAMINA_TAMANHO.x + ESPACO), y)
		var cor := COR_FALHA if piscando else COR_STAMINA
		var cheio := 1.0 if i < _jogador.stamina else 0.0
		if i == _jogador.stamina:
			cheio = _jogador.progresso_recarga()
		_bloco(Rect2(pos, STAMINA_TAMANHO), cor, cheio, i >= _jogador.stamina)

	# Dash equipado: seta dupla (padrão) ou bola (rolamento).
	var largura_linhas := maxf(Valores.GATO_VIDA * (VIDA_TAMANHO.x + ESPACO), Valores.STAMINA_MAXIMA * (STAMINA_TAMANHO.x + ESPACO))
	var caixa := Rect2(ORIGEM.x + largura_linhas + 3.0, ORIGEM.y - 1.0, 17, 19)
	draw_rect(caixa, COR_VAZIO)
	draw_rect(caixa, COR_STAMINA, false, 1.0)
	var c := caixa.get_center()
	if _jogador.dash_equipado == Jogador.Dash.PADRAO:
		for dx in [-3.0, 2.0]:
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(dx - 2, -4), c + Vector2(dx + 3, 0), c + Vector2(dx - 2, 4)]), Color.WHITE)
	else:
		draw_circle(c, 4.5, Color.WHITE)
		draw_line(c + Vector2(-3, -3), c + Vector2(3, 3), COR_VAZIO, 1.0)


## Um bloco com borda escura; "cheio" de 0 a 1 preenche da esquerda para a direita.
func _bloco(area: Rect2, cor: Color, cheio: float, apagado := false) -> void:
	draw_rect(area.grow(1.0), COR_BORDA)
	draw_rect(area, COR_VAZIO)
	if cheio > 0.0:
		var parte := Rect2(area.position, Vector2(area.size.x * cheio, area.size.y))
		draw_rect(parte, cor.darkened(0.45) if apagado else cor)
