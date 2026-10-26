extends Node2D
# A sticky lilac smear left by a Snoozle Snail. Standing in it builds Drowse.

var life := 10.0
var width := 70.0

func _ready() -> void:
	add_to_group("drowsy_trail")

func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	var player := get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and player.is_on_floor():
		var offset: Vector2 = player.global_position - global_position
		if absf(offset.x) < width * 0.5 and offset.y > -12.0 and offset.y < 50.0:
			var holder := get_tree().get_first_node_in_group("drowse_holder")
			if is_instance_valid(holder):
				holder.call("add_drowse", 4.0 * delta)
	queue_redraw()

func _draw() -> void:
	var fade := clampf(life / 2.0, 0.0, 1.0)
	draw_rect(Rect2(-width * 0.5, -5, width, 7), Color(0.55, 0.45, 0.8, 0.75 * fade))
	draw_rect(Rect2(-width * 0.5, -5, width, 2), Color(0.88, 0.82, 1.0, 0.8 * fade))
