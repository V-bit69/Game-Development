extends Sapo
## Sapo com língua (M6). Mesma movimentação do sapo comum, mais a língua.
## A ação é decidida no início do ciclo, pela distância até o jogador:
##   zona próxima (até 40 px)       → parado, telegraph, língua
##   zona intermediária (até 80 px) → telegraph, pula e usa a língua
##   zona externa                   → telegraph, salto de perseguição
## A língua vai em linha reta e volta pelo mesmo caminho. Obstáculos a seguram.
## Com parry, a língua é rebatida: o sapo é atingido e fica atordoado onde está.

const COR_LINGUA := Color(0.95, 0.45, 0.6)

enum Acao { LINGUA, SALTO_LINGUA, PERSEGUIR }

var lingua_ativa := false
var _acao := Acao.PERSEGUIR
var _lingua_direcao := Vector2.ZERO
var _lingua_comprimento := 0.0
var _lingua_maximo := 0.0
var _lingua_voltando := false
var _lingua_acertou := false


func _agir(delta: float) -> void:
	var j := _jogador()
	if lingua_ativa and j != null:
		_atualizar_lingua(delta, j)
	super(delta)
	if estado == Estado.LINGUA and not lingua_ativa:
		_mudar(Estado.ESPERA)


func _decidir(j: Node2D) -> void:
	var distancia := global_position.distance_to(j.global_position)
	var livre := _linha_livre(j)
	if distancia <= Valores.SAPO_ZONA_PROXIMA and livre:
		_acao = Acao.LINGUA
	elif distancia <= Valores.SAPO_ZONA_INTERMEDIARIA and livre:
		_acao = Acao.SALTO_LINGUA
	else:
		_acao = Acao.PERSEGUIR  # também quando um obstáculo bloqueia a língua
	_salto_direcao = _direcao_livre(j.global_position - global_position)
	_mudar(Estado.TELEGRAPH)


func _executar(j: Node2D) -> void:
	match _acao:
		Acao.LINGUA:
			_lancar_lingua(j)
			_mudar(Estado.LINGUA)
		Acao.SALTO_LINGUA:
			_comecar_salto(_salto_direcao)
			_lancar_lingua(j)
		Acao.PERSEGUIR:
			_comecar_salto(_salto_direcao)


func _origem_lingua() -> Vector2:
	return global_position + Vector2(0, -3)


func _lancar_lingua(j: Node2D) -> void:
	_lingua_direcao = (j.global_position - global_position).normalized()
	_lingua_maximo = Valores.SAPO_LINGUA_ALCANCE
	# Obstáculo no caminho segura a língua.
	var consulta := PhysicsRayQueryParameters2D.create(_origem_lingua(), _origem_lingua() + _lingua_direcao * _lingua_maximo, 1)
	var batida := get_world_2d().direct_space_state.intersect_ray(consulta)
	if not batida.is_empty():
		_lingua_maximo = _origem_lingua().distance_to(batida.position)
	_lingua_comprimento = 0.0
	_lingua_voltando = false
	_lingua_acertou = false
	lingua_ativa = true
	Som.tocar("lingua")


func _atualizar_lingua(delta: float, j: Node2D) -> void:
	var passo := Valores.SAPO_LINGUA_VELOCIDADE * delta
	if not _lingua_voltando:
		_lingua_comprimento = minf(_lingua_comprimento + passo, _lingua_maximo)
		if _lingua_comprimento >= _lingua_maximo:
			_lingua_voltando = true
	else:
		_lingua_comprimento -= passo
		if _lingua_comprimento <= 0.0:
			lingua_ativa = false
			return
	if not _lingua_acertou and _lingua_toca(j):
		_lingua_acertou = true
		j.receber_ataque(self, Valores.SAPO_LINGUA_DANO)


func ponta_da_lingua() -> Vector2:
	return _origem_lingua() + _lingua_direcao * _lingua_comprimento


func _lingua_toca(j: Node2D) -> bool:
	var perto := Geometry2D.get_closest_point_to_segment(j.global_position, _origem_lingua(), ponta_da_lingua())
	return perto.distance_to(j.global_position) <= Valores.GATO_RAIO_HITBOX


## Parry: se a língua estiver para fora, ela é rebatida. O sapo é atingido e
## fica atordoado onde está, sem ser lançado. Sem língua, vale o parry normal.
func receber_parry(direcao: Vector2) -> void:
	if not lingua_ativa:
		super(direcao)
		return
	lingua_ativa = false
	_interromper()
	receber_dano(Valores.SAPO_LINGUA_PARRY_DANO)
	if not morto:
		atordoado = Valores.GATO_PARRY_ATORDOAMENTO


func _interromper() -> void:
	lingua_ativa = false
	super()


func _cor_do_corpo() -> Color:
	var c := super()
	return c.lerp(COR_LINGUA, 0.25)


func _draw() -> void:
	super()
	if lingua_ativa and not morto:
		var inicio := _origem_lingua() - global_position + _tremor()
		var fim := ponta_da_lingua() - global_position
		draw_line(inicio, fim, COR_LINGUA, 2.0)
		draw_circle(fim, 2.5, COR_LINGUA.lightened(0.2))
