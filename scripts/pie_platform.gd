extends AnimatableBody2D
# A pie or cake platform that sags when Lumi stands on it, then springs back.
# Moved by code; the collision rect is added by the region.

var rest_y := 0.0
var size := Vector2(140, 18)
var sag := 0.0
var tint := Color(0.96, 0.78, 0.5)

func _ready() -> void:
	rest_y = position.y
	sync_to_physics = true

func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	var on_top := false
	if is_instance_valid(player):
		var d: Vector2 = player.global_position - global_position
		on_top = absf(d.x) < size.x / 2.0 + 6.0 and d.y < -size.y / 2.0 + 4.0 and d.y > -size.y / 2.0 - 40.0
	sag = move_toward(sag, 34.0 if on_top else 0.0, (46.0 if on_top else 70.0) * delta)
	position.y = rest_y + sag
	queue_redraw()

func _draw() -> void:
	var r := Rect2(-size / 2.0, size)
	draw_rect(r, tint)
	draw_rect(Rect2(r.position, Vector2(size.x, 5)), Color(1.0, 0.96, 0.88))
	draw_rect(r, Color(0.42, 0.25, 0.2), false, 2.0)
	for i in range(int(size.x / 28.0)):
		draw_circle(Vector2(r.position.x + 14.0 + i * 28.0, r.position.y - 3.0), 5.0, Color(0.92, 0.3, 0.38))
