extends CharacterBody2D
# The Dreamer's lantern-heart (phase 3). It only listens while it glows.

var dreamer: Node = null

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 36.0
	shape.shape = circle
	add_child(shape)

func take_damage(amount: int) -> void:
	if is_instance_valid(dreamer):
		dreamer.call("hit_heart", amount)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var open := is_instance_valid(dreamer) and bool(dreamer.get("heart_open"))
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.01)
	var glow := Color(1.0, 0.82, 0.45)
	if open:
		draw_circle(Vector2.ZERO, 34.0 + pulse * 8.0, Color(glow, 0.25))
		draw_circle(Vector2.ZERO, 20.0, glow)
		draw_circle(Vector2.ZERO, 11.0, Color(1.0, 0.97, 0.8))
	else:
		draw_circle(Vector2.ZERO, 20.0, Color(0.38, 0.34, 0.6))
		draw_circle(Vector2.ZERO, 10.0, Color(0.55, 0.5, 0.8))
	draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 20, Color(0.12, 0.1, 0.24), 3.0)
