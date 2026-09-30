class_name Sapo
extends Inimigo
## Sapo comum (M5). Usa o próprio salto como ataque.
## Ciclo: decisão → telegraph (0,5 s) → salto (40 px) → possível contato →
## aterrissagem → espera (1 s) → nova decisão.
## Fica aguardando até o jogador entrar na zona de percepção. Depois, persegue.
## Se levar um golpe no meio do salto, o salto é cancelado e ele não causa dano.

enum Estado { AGUARDANDO, TELEGRAPH, SALTO, LINGUA, ESPERA }

const COR_TELEGRAPH := Color(0.95, 0.85, 0.3)

var estado := Estado.AGUARDANDO
var alerta := false  # já viu o jogador
var _t := 0.0
var _salto_direcao := Vector2.ZERO
var _salto_restante := 0.0
var _salto_acertou := false


func _jogador() -> Node2D:
	return get_tree().get_first_node_in_group("jogador")


func _agir(delta: float) -> void:
	_t += delta
	var j := _jogador()
	if j == null or j.morto:
		return
	match estado:
		Estado.AGUARDANDO:
			if not alerta and global_position.distance_to(j.global_position) <= Valores.SAPO_PERCEPCAO:
				alertar()
			if alerta:
				_decidir(j)
		Estado.TELEGRAPH:
			if _t >= Valores.SAPO_TELEGRAPH:
				_executar(j)
		Estado.SALTO:
			_mover_salto(delta, j)
		Estado.ESPERA:
			if _t >= Valores.SAPO_INTERVALO:
				_mudar(Estado.AGUARDANDO)


func alertar() -> void:
	if alerta:
		return
	alerta = true
	Som.tocar("alerta")


## Início do ciclo: o sapo comum sempre salta na direção do jogador.
## A direção é decidida aqui, no começo do telegraph, e não muda depois.
func _decidir(j: Node2D) -> void:
	_salto_direcao = _direcao_livre(j.global_position - global_position)
	_mudar(Estado.TELEGRAPH)


func _executar(_j: Node2D) -> void:
	_comecar_salto(_salto_direcao)


func _comecar_salto(direcao: Vector2) -> void:
	_salto_direcao = direcao
	_salto_restante = Valores.SAPO_SALTO_COMPRIMENTO
	_salto_acertou = false
	_mudar(Estado.SALTO)
	Som.tocar("salto")


func _mover_salto(delta: float, j: Node2D) -> void:
	var passo := minf(Valores.SAPO_SALTO_VELOCIDADE * delta, _salto_restante)
	var batida := move_and_collide(_salto_direcao * passo)
	_salto_restante -= passo
	if not _salto_acertou and _encosta_no_jogador(j):
		_salto_acertou = true
		j.receber_ataque(self, Valores.SAPO_DANO)
		if estado != Estado.SALTO:
			return  # o parry interrompeu o salto
	if batida != null or _salto_restante <= 0.001:
		_mudar(Estado.ESPERA)


## A hitbox retangular do sapo encosta no círculo do jogador?
func _encosta_no_jogador(j: Node2D) -> bool:
	var metade: Vector2 = (colisao.shape as RectangleShape2D).size / 2.0
	var local := j.global_position - global_position
	var mais_perto := local.clamp(-metade, metade)
	return local.distance_to(mais_perto) <= Valores.GATO_RAIO_HITBOX


## Obstáculos bloqueiam o caminho: tenta a direção do jogador e, se estiver
## bloqueada, desvios de 45° e 90° para contornar.
func _direcao_livre(desejada: Vector2) -> Vector2:
	var base := desejada.normalized()
	var espaco := get_world_2d().direct_space_state
	for graus in [0.0, 45.0, -45.0, 90.0, -90.0]:
		var d := base.rotated(deg_to_rad(graus))
		var consulta := PhysicsRayQueryParameters2D.create(global_position, global_position + d * (Valores.SAPO_SALTO_COMPRIMENTO + 10.0), 1)
		if espaco.intersect_ray(consulta).is_empty():
			return d
	return base


## Linha reta até o jogador sem obstáculo no meio?
func _linha_livre(j: Node2D) -> bool:
	var consulta := PhysicsRayQueryParameters2D.create(global_position, j.global_position, 1)
	return get_world_2d().direct_space_state.intersect_ray(consulta).is_empty()


## Golpe no meio do salto: cancela o salto (sem dano no jogador) e o knockback vale.
## Golpe no corpo com a língua para fora também recolhe a língua.
func receber_dano(dano: int, direcao := Vector2.ZERO, empurrao := 0.0) -> void:
	if estado == Estado.SALTO or estado == Estado.LINGUA:
		_interromper()
	alertar()
	super(dano, direcao, empurrao)


func _interromper() -> void:
	_mudar(Estado.ESPERA)


func _mudar(novo: Estado) -> void:
	estado = novo
	_t = 0.0


func _cor_do_corpo() -> Color:
	if estado == Estado.TELEGRAPH:
		return cor.lerp(COR_TELEGRAPH, 0.6 * _t / Valores.SAPO_TELEGRAPH)
	return cor


func _tremor() -> Vector2:
	if estado == Estado.TELEGRAPH:
		return Vector2(1.0 if int(_t * 30.0) % 2 == 0 else -1.0, 0)
	if estado == Estado.SALTO:
		var p := 1.0 - _salto_restante / Valores.SAPO_SALTO_COMPRIMENTO
		return Vector2(0, -sin(p * PI) * 8.0)
	return Vector2.ZERO


func _escala() -> Vector2:
	if estado == Estado.TELEGRAPH:
		var p := _t / Valores.SAPO_TELEGRAPH
		return Vector2(1.0 + 0.25 * p, 1.0 - 0.3 * p)
	return Vector2.ONE
