extends Node2D

var direction := Vector2.RIGHT
var speed := 140.0
var lifetime := 2.5
var hit_player := false

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	if hit_player:
		return

	var player := get_tree().get_first_node_in_group("player")
	if player and global_position.distance_to(player.global_position) < 22.0:
		if player.has_method("take_damage"):
			player.take_damage(1)  # Tutorial boss damage
			hit_player = true
			queue_free()

	queue_redraw()

func _draw() -> void:
	var alpha := minf(1.0, lifetime / 0.5)
	draw_circle(Vector2.ZERO, 8, Color(0.65, 0.78, 0.58, alpha * 0.4))
	draw_circle(Vector2.ZERO, 5, Color(0.75, 0.88, 0.68, alpha))
