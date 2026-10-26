extends Node2D
# A huge pillow dropped by The Dreamer. A shadow warns first. It crushes
# whatever is under it while falling, then rests as a soft platform.

const SIZE := Vector2(140, 44)
const FALL_SPEED := 760.0
const TELL_TIME := 0.9
const REST_TIME := 9.0

var floor_y := 600.0
var state := "tell"   # tell, fall, rest
var t := 0.0
var body: StaticBody2D

func _ready() -> void:
	add_to_group("pillow")
	position.y = floor_y - 520.0

func _physics_process(delta: float) -> void:
	t += delta
	match state:
		"tell":
			if t >= TELL_TIME:
				state = "fall"
				t = 0.0
		"fall":
			position.y += FALL_SPEED * delta
			var player := get_tree().get_first_node_in_group("player")
			if is_instance_valid(player):
				var d: Vector2 = player.global_position - global_position
				if absf(d.x) < SIZE.x * 0.5 + 12.0 and absf(d.y) < SIZE.y * 0.5 + 22.0:
					player.take_damage(1)
			if position.y >= floor_y - SIZE.y * 0.5:
				position.y = floor_y - SIZE.y * 0.5
				state = "rest"
				t = 0.0
				_make_platform()
		"rest":
			if t >= REST_TIME:
				queue_free()
	queue_redraw()

func _make_platform() -> void:
	body = StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	shape.shape = rect
	body.add_child(shape)
	add_child(body)

func _draw() -> void:
	var half := SIZE * 0.5
	if state == "tell":
		var pulse := 0.25 + 0.2 * sin(t * 18.0)
		var shadow_y := floor_y - global_position.y
		draw_rect(Rect2(-half.x, shadow_y - 6, SIZE.x, 8), Color(0.12, 0.1, 0.24, pulse + 0.2))
		draw_rect(Rect2(-half.x, shadow_y - 460.0, SIZE.x, 3), Color(1.0, 0.85, 0.5, pulse))
		return
	var fade := 1.0 if state != "rest" else clampf((REST_TIME - t) / 1.5, 0.0, 1.0)
	draw_rect(Rect2(-half, SIZE), Color(0.93, 0.9, 1.0, fade))
	draw_rect(Rect2(-half.x, -half.y, SIZE.x, 6), Color(1.0, 1.0, 1.0, fade))
	draw_rect(Rect2(-half.x, half.y - 5, SIZE.x, 5), Color(0.66, 0.6, 0.88, fade))
	draw_rect(Rect2(-half, SIZE), Color(0.16, 0.13, 0.32, fade), false, 2.5)
	draw_line(Vector2(-half.x, -half.y), Vector2(half.x, half.y), Color(0.66, 0.6, 0.88, fade * 0.6), 2.0)
	draw_line(Vector2(half.x, -half.y), Vector2(-half.x, half.y), Color(0.66, 0.6, 0.88, fade * 0.6), 2.0)
