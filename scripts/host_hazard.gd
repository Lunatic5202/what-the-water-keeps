extends Node2D
# Short-lived hazards thrown by The Host. Collision is a plain rect test against
# Lumi so these need no physics bodies.
#   "snack": an arcing ball. Hits for 1 damage and force-feeds Lumi (+Fullness).
#   "wave":  a low shock wave along the table. Jump it.
#   "gulp":  a jaw wall with a gap, sweeping left. Pass through the gap.

var kind := "snack"
var velocity := Vector2.ZERO
var gravity := 0.0
var size := Vector2(30, 30)      # for snack and wave
var gap_top := 0.0               # gulp: gap spans gap_top .. gap_bottom (world y)
var gap_bottom := 0.0
var floor_y := 600.0
var end_x := 0.0                 # despawn when it passes this x
var fullness := 0.0
var damage := 1
var cooldown := 0.0
var age := 0.0

func _physics_process(delta: float) -> void:
	age += delta
	velocity.y += gravity * delta
	position += velocity * delta
	cooldown = maxf(0.0, cooldown - delta)
	if position.x < end_x or position.y > floor_y + 80.0 or age > 9.0:
		queue_free()
		return
	var player := get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and cooldown <= 0.0:
		var box := Rect2(player.global_position - Vector2(13, 21), Vector2(26, 42))
		for r in _rects():
			if r.intersects(box):
				player.take_damage(damage)
				if fullness > 0.0:
					get_tree().call_group("fullness_holder", "add_fullness", fullness)
				cooldown = 0.9
				if kind == "snack":
					queue_free()
				break
	queue_redraw()

func _rects() -> Array:
	var out: Array = []
	match kind:
		"snack":
			out.append(Rect2(global_position - size / 2.0, size))
		"wave":
			out.append(Rect2(global_position - Vector2(size.x / 2.0, size.y), size))
		"gulp":
			out.append(Rect2(global_position.x - 20.0, -400.0, 40.0, gap_top + 400.0))
			out.append(Rect2(global_position.x - 20.0, gap_bottom, 40.0, 700.0 - gap_bottom))
	return out

func _draw() -> void:
	match kind:
		"snack":
			draw_circle(Vector2.ZERO, size.x / 2.0, Color(0.98, 0.7, 0.8))
			draw_arc(Vector2.ZERO, size.x / 2.0, 0.0, TAU, 14, Color(0.45, 0.22, 0.28), 2.5)
			draw_circle(Vector2(-4, -4), 3.5, Color(1, 1, 1, 0.8))
		"wave":
			draw_rect(Rect2(-size.x / 2.0, -size.y, size.x, size.y), Color(0.96, 0.72, 0.5, 0.9))
			draw_rect(Rect2(-size.x / 2.0, -size.y, size.x, size.y), Color(0.42, 0.25, 0.2), false, 3.0)
		"gulp":
			var top := Rect2(-20.0, -400.0 - global_position.y, 40.0, gap_top + 400.0)
			var bot := Rect2(-20.0, gap_bottom - global_position.y, 40.0, 700.0 - gap_bottom)
			for r in [top, bot]:
				draw_rect(r, Color(0.96, 0.62, 0.72, 0.92))
				draw_rect(r, Color(0.42, 0.18, 0.28), false, 3.0)
			for i in range(5):
				var y := gap_top - 14.0 - float(i) * 34.0 - global_position.y
				draw_colored_polygon(PackedVector2Array([Vector2(-20, y), Vector2(20, y), Vector2(0, y + 18)]), Color(1, 0.96, 0.9))
				var y2 := gap_bottom + 14.0 + float(i) * 34.0 - global_position.y
				draw_colored_polygon(PackedVector2Array([Vector2(-20, y2), Vector2(20, y2), Vector2(0, y2 - 18)]), Color(1, 0.96, 0.9))
