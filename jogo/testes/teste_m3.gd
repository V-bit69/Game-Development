extends SceneTree
## Teste automático do M3 (combo, dano do dash, knockback) já com o game design v1.4.1:
## fases do golpe, cancelamento, leque, passo de 24 px e magnetismo de mira.
## Rodar na pasta jogo/:
##   godot --headless --path . -s res://testes/teste_m3.gd

var ALVO: PackedScene
const QUADRO := 1.0 / 60.0

var _falhas := 0
var _sala: Node2D
var _jogador: CharacterBody2D
var _inicio: Vector2
var _v: Node


func _initialize() -> void:
	_rodar()


func _rodar() -> void:
	ALVO = load("res://cenas/alvo.tscn")
	_sala = load("res://cenas/sala_teste.tscn").instantiate()
	root.add_child(_sala)
	await _esperar(2)
	_jogador = _sala.get_node("Jogador")
	_inicio = _jogador.position
	_v = root.get_node("Valores")
	for e in get_nodes_in_group("inimigos"):
		e.queue_free()
	await _esperar(1)

	# --- Valores da seção 49 ---
	_conferir("duração 0,308 = antecipação 0,077 + execução 0,231", absf(_v.GATO_GOLPE_DURACAO - 0.3077) < 0.001 and absf(_v.GATO_GOLPE_ANTECIPACAO - 0.0769) < 0.001 and absf(_v.GATO_GOLPE_EXECUCAO - 0.2308) < 0.001)
	_conferir("recuperações 0,154 / 0,308 / 0,4", absf(_v.GATO_RECUPERACAO_GOLPE_1 - 0.1538) < 0.001 and absf(_v.GATO_RECUPERACAO_GOLPE_2 - 0.3077) < 0.001 and _v.GATO_RECUPERACAO_GOLPE_3 == 0.4)
	_conferir("alcances 30 / 40 e aberturas 120° / 90°", _v.GATO_ALCANCE_ATAQUE == 30.0 and _v.GATO_ALCANCE_GOLPE_3 == 40.0 and _v.GATO_ANGULO_ATAQUE == 120.0 and _v.GATO_ANGULO_GOLPE_3 == 90.0)
	_conferir("alcance efetivo 54 / 64, knockback e passo 24", _v.GATO_ALCANCE_EFETIVO_1_2 == 54.0 and _v.GATO_ALCANCE_EFETIVO_3 == 64.0 and _v.KNOCKBACK_PADRAO == 24.0 and _v.GATO_GOLPE_AVANCO == 24.0)

	# --- Ritmo do combo, sem alvo: golpes em 0 / 0,462 / 1,077 / 1,785 s (ciclo ≈ 1,78 s) ---
	var inicios: Array = []
	_jogador.golpe_iniciado.connect(func(n: int) -> void: inicios.append([n, _jogador._tempo]))
	var t0: float = _jogador._tempo
	_jogador.direcao_olhar = Vector2.RIGHT
	while inicios.size() < 4:
		_jogador.pedir_ataque()  # A apertado sem parar
		await _esperar(1)
	var sequencia := inicios.map(func(i): return i[0])
	_conferir("sequência 1 → 2 → 3 → 1 (%s)" % [sequencia], sequencia == [1, 2, 3, 1])
	var tempos := inicios.map(func(i): return i[1] - t0)
	var esperado := [0.0, 0.4615, 1.0769, 1.7846]
	var ok := true
	for i in 4:
		ok = ok and absf(tempos[i] - esperado[i]) <= QUADRO * 1.5
	_conferir("tempos do combo 0 / 0,46 / 1,08 / 1,78 s (%s)" % [tempos.map(func(t): return snappedf(t, 0.01))], ok)
	await _fim_do_combo()
	_jogador.position = _inicio

	# --- Passo à frente de 24 px, mesmo sem inimigo ---
	_jogador._proximo_golpe = 1
	_jogador.direcao_olhar = Vector2.RIGHT
	_jogador.pedir_ataque()
	await _fim_do_combo()
	_conferir("passo de 24 px sem inimigo (andou %.1f)" % (_jogador.position.x - _inicio.x), absf(_jogador.position.x - _inicio.x - 24.0) < 1.0)
	_jogador.position = _inicio

	# --- O passo para ao encostar no corpo do inimigo (sem knockback, ele não sai do lugar) ---
	_jogador._proximo_golpe = 1
	_jogador.direcao_olhar = Vector2.RIGHT
	var firme := await _novo_alvo(_inicio + Vector2(26, 0))
	firme.em_avanco = true  # não leva knockback
	_jogador.pedir_ataque()
	await _fim_do_combo()
	_conferir("o passo para ao encostar (gato a %.1f px do centro do inimigo)" % (firme.position.x - _jogador.position.x), firme.position.x - _jogador.position.x >= 18.5 and _jogador.position.x - _inicio.x < 10.0)
	firme.queue_free()
	await _esperar(1)
	_jogador.position = _inicio

	# --- Fases: sem dano na antecipação, dano no impacto, 1 vez por golpe ---
	_jogador._proximo_golpe = 1
	_jogador.direcao_olhar = Vector2.RIGHT
	var alvo := await _novo_alvo(_inicio + Vector2(26, 0))
	var x_alvo: float = alvo.position.x
	_jogador.pedir_ataque()
	await _esperar(4)  # 0,067 s: ainda antecipação
	_conferir("antecipação: sem dano e sem passo (vida %d)" % alvo.vida, alvo.vida == 3 and _jogador.position == _inicio)
	await _ate(func(): return alvo.vida < 3)
	_conferir("golpe 1 tira 1 de vida", alvo.vida == 2)
	await _fim_do_combo()
	_conferir("o inimigo leva no máximo 1 vez por golpe (vida %d)" % alvo.vida, alvo.vida == 2)
	_conferir("knockback de 24 px (andou %.1f)" % (alvo.position.x - x_alvo), absf(alvo.position.x - x_alvo - 24.0) < 1.0)

	# Dano 1 + 1 + 2 mata o alvo de 3 de vida; o passo de 24 px mantém o alcance.
	_jogador.pedir_ataque()
	await _ate(func(): return alvo.vida < 2)
	_conferir("golpe 2 alcança e tira 1 (vida %d, dist %.1f)" % [alvo.vida, alvo.position.x - _jogador.position.x], alvo.vida == 1)
	_jogador.pedir_ataque()
	await _ate(func(): return alvo.morto or _jogador.golpe_atual == 0 and _jogador._intervalo == 0.0 and _jogador._proximo_golpe == 1)
	_conferir("golpe 3 (espada) tira 2 e mata", alvo.morto and alvo.vida == 0)
	await _esperar(2)
	_conferir("corpo fica no chão sem colisão", is_instance_valid(alvo) and alvo.colisao.disabled)
	await _fim_do_combo()
	alvo.queue_free()
	await _esperar(1)

	# --- Janela do impacto: ~0,1 s no início da execução ---
	_jogador.position = _inicio
	_jogador._proximo_golpe = 1
	_jogador.direcao_olhar = Vector2.RIGHT
	alvo = await _novo_alvo(_inicio + Vector2(300, 0))  # longe: fora da magnetismo
	_jogador.pedir_ataque()
	await _esperar(7)  # dentro do impacto (0,117 s)
	alvo.position = _jogador.position + Vector2(20, 0)  # entra no leque no meio da janela
	await _ate(func(): return alvo.vida < 3, 12)
	_conferir("quem entra no leque durante o impacto é atingido", alvo.vida == 2)
	await _fim_do_combo()
	alvo.vida = 3
	alvo.position = _inicio + Vector2(300, 0)
	_jogador.position = _inicio
	_jogador.pedir_ataque()
	await _esperar(13)  # 0,217 s: o impacto já acabou
	alvo.position = _jogador.position + Vector2(20, 0)
	await _esperar(8)
	_conferir("depois da janela de impacto, a hitbox está desligada", alvo.vida == 3)
	await _fim_do_combo()
	alvo.queue_free()
	await _esperar(1)

	# --- Andar contra um alvo vivo: ele bloqueia ---
	alvo = await _novo_alvo(_inicio + Vector2(60, 0))
	_jogador.position = _inicio
	await _andar("mover_direita", 60)
	_conferir("alvo vivo bloqueia a passagem (x = %.1f)" % _jogador.position.x, _jogador.position.x < alvo.position.x - 15.0)

	# --- Dash ofensivo atravessa, tira 1 e não empurra ---
	_jogador.position = _inicio
	await _esperar(1)
	x_alvo = alvo.position.x
	_jogador.direcao_olhar = Vector2.RIGHT
	_jogador.pedir_dash()
	await _fim_do_dash()
	_conferir("dash ofensivo tira 1 de vida", alvo.vida == 2)
	_conferir("dash atravessa o alvo (x = %.1f)" % _jogador.position.x, absf(_jogador.position.x - (_inicio.x + 104.0)) < 1.0)
	_conferir("dash não empurra", alvo.position.x == x_alvo)

	# --- Rolamento não atravessa: para no inimigo e não causa dano ---
	_jogador.trocar_dash()
	_jogador.position = _inicio
	await _esperar(1)
	_jogador.direcao_olhar = Vector2.RIGHT
	_jogador.pedir_dash()
	await _fim_do_dash()
	_conferir("rolamento não causa dano", alvo.vida == 2)
	_conferir("rolamento para no inimigo (x = %.1f)" % _jogador.position.x, _jogador.position.x < alvo.position.x - 15.0)
	_jogador.trocar_dash()
	alvo.queue_free()
	await _esperar(130)  # stamina volta

	# --- Cancelamento: o dash na antecipação cancela e o golpe não conta ---
	_jogador.position = _inicio
	_jogador.direcao_olhar = Vector2.LEFT
	_jogador._proximo_golpe = 2
	alvo = await _novo_alvo(_inicio + Vector2(-26, 0))
	inicios.clear()
	_jogador.pedir_ataque()
	await _esperar(3)  # 0,05 s: antecipação
	_jogador.direcao_olhar = Vector2.UP  # foge sem passar pelo inimigo
	_jogador.pedir_dash()
	_conferir("dash na antecipação cancela o golpe", _jogador.em_dash and _jogador.golpe_atual == 0)
	await _fim_do_dash()
	_conferir("golpe cancelado: sem dano e o ciclo não avançou", alvo.vida == 3 and _jogador._proximo_golpe == 2)
	_jogador.position = _inicio
	_jogador.direcao_olhar = Vector2.LEFT
	await _esperar(40)  # a stamina e o gato se acalmam
	_jogador.pedir_ataque()
	await _esperar(1)
	_conferir("depois do cancelamento, o próximo A é o mesmo golpe (%d)" % inicios.back()[0], inicios.back()[0] == 2)
	await _fim_do_combo()
	alvo.queue_free()
	await _esperar(130)

	# --- Execução: o dash é ignorado e não fica guardado ---
	_jogador.position = _inicio
	_jogador.direcao_olhar = Vector2.LEFT
	_jogador.pedir_ataque()
	await _esperar(8)  # 0,133 s: execução
	var stamina_antes: int = _jogador.stamina
	_conferir("dash na execução é ignorado", not _jogador.pedir_dash() and not _jogador.em_dash and _jogador.golpe_atual != 0)
	await _fim_do_combo()
	await _esperar(5)
	_conferir("e não fica guardado (sem dash, stamina %d)" % _jogador.stamina, not _jogador.em_dash and _jogador.stamina == stamina_antes)

	# --- Recuperação: o dash funciona, mas não encurta a recuperação ---
	_jogador.position = _inicio
	_jogador.direcao_olhar = Vector2.LEFT
	inicios.clear()
	_jogador._proximo_golpe = 2
	_jogador.pedir_ataque()
	await _ate(func(): return _jogador.golpe_atual == 0 and _jogador._intervalo > 0.0)
	var fim_golpe_2: float = _jogador._tempo
	await _esperar(2)
	_conferir("dash na recuperação funciona", _jogador.pedir_dash() and _jogador.em_dash)
	await _fim_do_dash()
	_jogador.pedir_ataque()
	await _ate(func(): return inicios.back()[0] == 3, 120)
	var espera: float = inicios.back()[1] - fim_golpe_2
	_conferir("e a recuperação do golpe 2 continua 0,308 s (%.3f)" % espera, absf(espera - 0.3077) <= QUADRO * 1.5)
	await _fim_do_combo()
	_jogador.position = _inicio

	# --- Parado por bastante tempo, o combo não volta ao golpe 1 ---
	var antes: int = inicios.back()[0]
	await _esperar(120)
	_jogador.pedir_ataque()
	await _esperar(1)
	_conferir("parado por 2 s, continua a sequência", inicios.back()[0] == antes % 3 + 1)
	await _fim_do_combo()
	_jogador.position = _inicio

	# --- Área de ataque: leque que sai do gato, vale o retângulo do inimigo ---
	var lado := await _novo_alvo(Vector2(400, 400))
	_jogador.direcao_olhar = Vector2.RIGHT
	_jogador.position = Vector2(400, 400) - Vector2(28, 0)
	await _esperar(1)
	_conferir("à frente, a 28 px: dentro (golpe 1, 30 px)", _jogador._no_leque(lado, Vector2.RIGHT, 120.0, 30.0))
	_jogador.position = Vector2(400, 400) - Vector2(45, 0)  # borda do retângulo a 36 px
	await _esperar(1)
	_conferir("a 36 px da borda: fora do golpe 1 (30 px)", not _jogador._no_leque(lado, Vector2.RIGHT, 120.0, 30.0))
	_conferir("a 36 px da borda: dentro do golpe 3 (40 px)", _jogador._no_leque(lado, Vector2.RIGHT, 90.0, 40.0))
	_jogador.position = Vector2(400, 400) - Vector2(6.8, 18.8)  # centro a 70° da frente, canto do retângulo a 37°
	await _esperar(1)
	_conferir("centro fora dos 120°, mas o retângulo entra: acerta", _jogador._no_leque(lado, Vector2.RIGHT, 120.0, 30.0))
	_jogador.position = Vector2(400, 400) - Vector2(0, 30)
	await _esperar(1)
	_conferir("alvo do lado (90° da frente): fora da área", not _jogador._no_leque(lado, Vector2.RIGHT, 120.0, 30.0))
	lado.queue_free()
	await _esperar(1)

	# --- Obstáculo entre o gato e o inimigo bloqueia o golpe (obstáculo 'o' na célula 7, 12) ---
	var atras := await _novo_alvo(Vector2(7.5 * 32, 13.5 * 32))
	_jogador.position = Vector2(7.5 * 32, 11.5 * 32)
	await _esperar(1)
	_conferir("obstáculo bloqueia o ataque", _jogador._obstaculo_entre(atras))
	_jogador.position = Vector2(4.5 * 32, 13.5 * 32)
	await _esperar(1)
	_conferir("sem obstáculo, não bloqueia", not _jogador._obstaculo_entre(atras))
	atras.queue_free()
	await _esperar(1)

	# --- Magnetismo de mira (seção 18) ---
	var centro := Vector2(400, 400)
	_jogador.position = centro
	_jogador.direcao_olhar = Vector2.RIGHT
	_jogador._alvo_golpe = null
	var perto := await _novo_alvo(centro + Vector2.from_angle(deg_to_rad(30.0)) * 40.0)
	_conferir("inimigo a 30° dentro do cone: é o alvo", _achar(1) == perto)
	perto.position = centro + Vector2.from_angle(deg_to_rad(60.0)) * 40.0
	_conferir("inimigo a 60°, fora do cone de ±45°: sem alvo", _achar(1) == null)
	perto.position = centro + Vector2(69.0, 0)  # borda a 60 px: dentro de 54 + 10
	_conferir("golpe 1: borda a 60 px entra no alcance de 64", _achar(1) == perto)
	perto.position = centro + Vector2(79.0, 0)  # borda a 70 px
	_conferir("golpe 1: borda a 70 px passa de 64: sem alvo", _achar(1) == null)
	_conferir("golpe 3: borda a 70 px entra no alcance de 74", _achar(3) == perto)
	# O mais próximo ganha; o alvo anterior tem preferência enquanto estiver no cone.
	perto.position = centro + Vector2(30, 0)
	var longe := await _novo_alvo(centro + Vector2.from_angle(deg_to_rad(-20.0)) * 50.0)
	_conferir("dois no cone: o mais próximo é o alvo", _achar(1) == perto)
	_jogador._alvo_golpe = longe
	_conferir("o alvo anterior tem preferência enquanto está no cone", _achar(1) == longe)
	longe.position = centro + Vector2.from_angle(deg_to_rad(-80.0)) * 50.0
	_conferir("saiu do cone: volta ao mais próximo", _achar(1) == perto)
	longe.queue_free()
	perto.queue_free()
	await _esperar(1)

	# Golpe com magnetismo: ângulo contínuo, sprite em 8 direções, passo e knockback na mira.
	_jogador.position = centro
	_jogador._proximo_golpe = 1
	_jogador.direcao_olhar = Vector2.RIGHT
	var torto := await _novo_alvo(centro + Vector2.from_angle(deg_to_rad(30.0)) * 30.0)
	_jogador.pedir_ataque()
	_conferir("mira com ângulo contínuo (%.1f°)" % rad_to_deg(_jogador._mira.angle()), absf(rad_to_deg(_jogador._mira.angle()) - 30.0) < 1.0)
	_conferir("sprite usa a direção de 8 mais próxima (45°)", absf(rad_to_deg(_jogador.direcao_olhar.angle()) - 45.0) < 0.1)
	var antes_pos: Vector2 = torto.position
	await _ate(func(): return torto.vida < 3)
	_conferir("o golpe aponta para o inimigo torto e acerta", torto.vida == 2)
	await _esperar(8)
	var empurrado: Vector2 = torto.position - antes_pos
	_conferir("knockback na direção da mira (%.1f°)" % rad_to_deg(empurrado.angle()), absf(rad_to_deg(empurrado.angle()) - 30.0) < 2.0)
	await _fim_do_combo()
	torto.queue_free()
	await _esperar(1)

	# O dash não tem magnetismo: vai para onde o gato olha.
	_jogador.position = centro
	_jogador.direcao_olhar = Vector2.RIGHT
	var ao_lado := await _novo_alvo(centro + Vector2.from_angle(deg_to_rad(30.0)) * 40.0)
	await _esperar(130)
	_jogador.pedir_dash()
	_conferir("dash não usa magnetismo", _jogador._dash_direcao == Vector2.RIGHT)
	await _fim_do_dash()
	ao_lado.queue_free()

	print("\n%s" % ("M3 OK: todos os testes passaram." if _falhas == 0 else "M3 FALHOU: %d teste(s)." % _falhas))
	quit(1 if _falhas > 0 else 0)


## Procura o alvo do magnetismo como se o golpe `numero` estivesse começando.
func _achar(numero: int) -> Node2D:
	_jogador.golpe_atual = numero
	var alvo: Node2D = _jogador._achar_alvo_magnetismo()
	_jogador.golpe_atual = 0
	return alvo


func _novo_alvo(pos: Vector2) -> Node:
	var alvo := ALVO.instantiate()
	alvo.position = pos
	_sala.add_child(alvo)
	await _esperar(1)
	return alvo


func _fim_do_combo() -> void:
	await _ate(func(): return _jogador.golpe_atual == 0 and _jogador._intervalo == 0.0)


func _fim_do_dash() -> void:
	await _ate(func(): return not _jogador.em_dash)


func _andar(acao: String, quadros: int) -> void:
	Input.action_press(acao)
	await _esperar(quadros)
	Input.action_release(acao)


func _ate(condicao: Callable, limite := 600) -> void:
	for i in limite:
		if condicao.call():
			return
		await physics_frame
	print("  (tempo esgotado esperando condição)")


func _esperar(quadros: int) -> void:
	for i in quadros:
		await physics_frame


func _conferir(nome: String, ok: bool) -> void:
	print("[%s] %s" % ["ok" if ok else "FALHOU", nome])
	if not ok:
		_falhas += 1
