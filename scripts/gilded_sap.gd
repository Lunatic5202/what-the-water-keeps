extends Node2D

var launch_velocity := Vector2.ZERO
var gravity := 320.0
var life := 3.0
var spent := false

func _physics_process(delta: float) -> void:
	if spent:
		return
	life -= delta
	launch_velocity.y += gravity * delta
	global_position += launch_velocity * delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if is_instance_valid(player) and global_position.distance_to(player.global_position) < 25.0:
		spent = true
		if player.has_method("take_damage"):
			player.take_damage(1)
		var greed := get_tree().get_first_node_in_group("gold_holder")
		if is_instance_valid(greed) and greed.has_method("apply_sticky_sap"):
			greed.call("apply_sticky_sap")
		queue_free()
		return
	if life <= 0.0:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 8.0, Color(0.44, 0.29, 0.12, 0.95))
	draw_circle(Vector2(-2, -2), 3.5, Color(1.0, 0.86, 0.41, 0.95))
