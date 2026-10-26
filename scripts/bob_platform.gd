extends AnimatableBody2D
# A floating pillow that bobs up and down. Lumi rides it.

var size := Vector2(130, 28)
var amplitude := 18.0
var speed := 1.1
var phase := 0.0
var origin := Vector2.ZERO
var t := 0.0

func _ready() -> void:
	sync_to_physics = true
	origin = position
	t = phase
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	add_child(shape)

func _physics_process(delta: float) -> void:
	t += delta * speed
	position = origin + Vector2(0, sin(t) * amplitude)
	queue_redraw()

func _draw() -> void:
	var half := size * 0.5
	draw_rect(Rect2(-half, size), Color(0.40, 0.38, 0.68))
	draw_rect(Rect2(-half, Vector2(size.x, 5)), Color(0.93, 0.9, 1.0))
	draw_rect(Rect2(-half.x, half.y - 3, size.x, 3), Color(0.12, 0.10, 0.24))
