extends Node
## Sons provisórios, gerados por código. Serão trocados pelos sons do compositor.
## Uso: Som.tocar("dash")

const TAXA := 22050
const VOZES := 6

var _sons := {}
var _players: Array[AudioStreamPlayer] = []
var _proximo := 0


func _ready() -> void:
	for i in VOZES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	_sons["dash"] = _misturar(_sopro(0.18, 0.5, 0.9), _rosnado(0.16, 0.35))
	_sons["rolamento"] = _wav(_sopro(0.16, 0.35, 0.4))
	_sons["troca"] = _wav(_tom(1400.0, 0.04, 0.3, false))
	_sons["falha"] = _juntar(_tom(220.0, 0.08, 0.3, true), _tom(150.0, 0.12, 0.3, true))


func tocar(nome: String) -> void:
	if not _sons.has(nome):
		push_warning("Som desconhecido: %s" % nome)
		return
	var player := _players[_proximo]
	_proximo = (_proximo + 1) % VOZES
	player.stream = _sons[nome]
	player.play()


# --- Síntese ------------------------------------------------------------

## Ruído com envelope que sobe e cai; "brilho" controla o quanto o ruído é agudo.
func _sopro(duracao: float, volume: float, brilho: float) -> PackedFloat32Array:
	var n := int(duracao * TAXA)
	var amostras := PackedFloat32Array()
	amostras.resize(n)
	var filtrado := 0.0
	for i in n:
		var t := float(i) / n
		var envelope := sin(PI * t) * (1.0 - t * 0.5)
		var corte := lerpf(0.05, brilho, sin(PI * t))
		filtrado += (randf_range(-1.0, 1.0) - filtrado) * corte
		amostras[i] = filtrado * envelope * volume
	return amostras


## Rosnado grave: dente de serra em ~90 Hz com tremor.
func _rosnado(duracao: float, volume: float) -> PackedFloat32Array:
	var n := int(duracao * TAXA)
	var amostras := PackedFloat32Array()
	amostras.resize(n)
	var fase := 0.0
	for i in n:
		var t := float(i) / n
		var freq := 90.0 + 25.0 * sin(t * 60.0)
		fase = fmod(fase + freq / TAXA, 1.0)
		var envelope := minf(t * 8.0, 1.0) * (1.0 - t)
		amostras[i] = (fase * 2.0 - 1.0) * envelope * volume
	return amostras


func _tom(freq: float, duracao: float, volume: float, quadrada: bool) -> PackedFloat32Array:
	var n := int(duracao * TAXA)
	var amostras := PackedFloat32Array()
	amostras.resize(n)
	for i in n:
		var t := float(i) / n
		var onda := sin(TAU * freq * i / TAXA)
		if quadrada:
			onda = signf(onda)
		amostras[i] = onda * (1.0 - t) * volume
	return amostras


func _misturar(a: PackedFloat32Array, b: PackedFloat32Array) -> AudioStreamWAV:
	var n := maxi(a.size(), b.size())
	var soma := PackedFloat32Array()
	soma.resize(n)
	for i in n:
		soma[i] = (a[i] if i < a.size() else 0.0) + (b[i] if i < b.size() else 0.0)
	return _wav(soma)


func _juntar(a: PackedFloat32Array, b: PackedFloat32Array) -> AudioStreamWAV:
	var tudo := a.duplicate()
	tudo.append_array(b)
	return _wav(tudo)


func _wav(amostras: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(amostras.size() * 2)
	for i in amostras.size():
		bytes.encode_s16(i * 2, int(clampf(amostras[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = TAXA
	wav.data = bytes
	return wav
