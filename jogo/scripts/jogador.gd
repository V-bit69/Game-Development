extends CharacterBody2D
## Homem-gato. M1: movimento em 8 direções e colisão.
## A origem do nó fica nos pés, no centro do círculo de colisão.

const COR_CORPO := Color(0.93, 0.6, 0.25)
const COR_HITBOX := Color(1, 1, 1, 0.35)
const LARGURA := 56.0

var direcao_olhar := Vector2.DOWN

@onready var colisao: CollisionShape2D = $Colisao
@onready var camera: Camera2D = $Camera


func _ready() -> void:
	(colisao.shape as CircleShape2D).radius = Valores.GATO_RAIO_HITBOX


func _physics_process(_delta: float) -> void:
	var direcao := _ler_direcao()
	if direcao != Vector2.ZERO:
		direcao_olhar = direcao
		queue_redraw()
	velocity = direcao * Valores.GATO_CAMINHADA
	move_and_slide()


## Devolve a direção do movimento travada em 8 direções, já normalizada.
func _ler_direcao() -> Vector2:
	var entrada := Input.get_vector("mover_esquerda", "mover_direita", "mover_cima", "mover_baixo")
	if entrada == Vector2.ZERO:
		return Vector2.ZERO
	return Vector2.from_angle(snappedf(entrada.angle(), PI / 4.0))


# Placeholder: retângulo com a altura do gato, círculo da hitbox e seta do olhar.
func _draw() -> void:
	var raio := Valores.GATO_RAIO_HITBOX
	var topo := raio - Valores.GATO_ALTURA
	draw_rect(Rect2(-LARGURA / 2.0, topo, LARGURA, Valores.GATO_ALTURA), COR_CORPO)
	draw_arc(Vector2.ZERO, raio, 0.0, TAU, 32, COR_HITBOX, 2.0)
	var ponta := direcao_olhar * (raio + 22.0)
	var lado := direcao_olhar.orthogonal() * 10.0
	var base := direcao_olhar * (raio + 6.0)
	draw_colored_polygon(PackedVector2Array([ponta, base + lado, base - lado]), Color.WHITE)
