extends Inimigo
## Alvo de treino que ataca: serve para treinar o parry antes dos sapos (M5).
## Ciclo: espera → se o jogador estiver perto, telegraph (treme e fica vermelho)
## → golpe curto na frente dele → espera de novo.

enum Estado { ESPERA, TELEGRAPH, GOLPE }

const COR_ALERTA := Color(0.9, 0.25, 0.2)
const GOLPE_VISUAL := 0.12

var estado := Estado.ESPERA
var _tempo_estado := 0.0
var _mira := Vector2.RIGHT


func _agir(delta: float) -> void:
	_tempo_estado += delta
	var jogador: Node2D = get_tree().get_first_node_in_group("jogador")
	match estado:
		Estado.ESPERA:
			if _tempo_estado >= Valores.TREINO_INTERVALO and jogador != null \
					and global_position.distance_to(jogador.global_position) <= Valores.TREINO_PERCEPCAO:
				_mudar(Estado.TELEGRAPH)
		Estado.TELEGRAPH:
			if jogador != null:
				_mira = (jogador.global_position - global_position).normalized()
			if _tempo_estado >= Valores.TREINO_TELEGRAPH:
				_golpear(jogador)
				_mudar(Estado.GOLPE)
		Estado.GOLPE:
			if _tempo_estado >= GOLPE_VISUAL:
				_mudar(Estado.ESPERA)


func _golpear(jogador: Node2D) -> void:
	Som.tocar("garra")
	if jogador != null and global_position.distance_to(jogador.global_position) <= Valores.TREINO_ALCANCE:
		jogador.receber_ataque(self, Valores.TREINO_DANO)


func _mudar(novo: Estado) -> void:
	estado = novo
	_tempo_estado = 0.0


func _interromper() -> void:
	_mudar(Estado.ESPERA)


func _cor_do_corpo() -> Color:
	if estado == Estado.TELEGRAPH:
		return cor.lerp(COR_ALERTA, _tempo_estado / Valores.TREINO_TELEGRAPH)
	return cor


func _tremor() -> Vector2:
	if estado == Estado.TELEGRAPH:
		return Vector2(1.0 if int(_tempo_estado * 30.0) % 2 == 0 else -1.0, 0)
	return Vector2.ZERO


func _draw() -> void:
	super()
	if estado == Estado.GOLPE and not morto:
		var a := _mira.angle()
		draw_arc(_mira * 8.0, Valores.TREINO_ALCANCE - 8.0, a - 0.8, a + 0.8, 10, Color(1, 0.5, 0.4), 2.0)
