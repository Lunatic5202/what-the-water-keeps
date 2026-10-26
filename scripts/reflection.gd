extends Node2D
# The Reflection in the pond (bible Part 2): a mirrored Lumi that moves a
# moment late. The more regions are cleared, the longer it looks at her.

var player: Node = null
var clears := 0

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var f := 1.0
	var look := Vector2.ZERO
	if is_instance_valid(player):
		f = float(player.get("facing"))
		look = (player.global_position - global_position).normalized()
	var body := PackedVector2Array([
		Vector2(-15, 4), Vector2(-11, 24), Vector2(0, 31),
		Vector2(11, 24), Vector2(15, 4), Vector2(20, -15), Vector2(-20, -15)])
	var alpha := 0.45 + 0.06 * clears
	draw_colored_polygon(body, Color(0.18, 0.2, 0.42, alpha))
	draw_circle(Vector2(0, 25), 10.0, Color(0.5, 0.55, 0.78, alpha))
	# Eyes follow Lumi, and glow more with every region cleared.
	var eye := 2.0 + 0.7 * clears
	var glow := Color(0.95, 0.97, 1.0, 0.5 + 0.12 * clears)
	for side in [-4.0, 4.0]:
		draw_circle(Vector2(side + look.x * 2.5, 24 + look.y * 2.5), eye, glow)
	# The lantern is on the other side from Lumi's, like a mirror.
	draw_circle(Vector2(-19 * f, 7), 5.0, Color(0.64, 0.91, 1.0, alpha))
	if clears >= 3:
		draw_arc(Vector2(0, 14), 6.0, 0.3, PI - 0.3, 8, Color(0.95, 0.97, 1.0, 0.6), 1.5)
