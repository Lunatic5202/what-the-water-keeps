extends Node2D
# A coin thrown by The Collector. It falls and can hurt Lumi. A coin that
# lands becomes a pickup: grabbing it adds gold (and weight), which is the
# temptation the fight is about.

const GRAVITY := 650.0
const GROUND_Y := 570.0
const VALUE := 10

var velocity := Vector2(0, 40)
var landed := false
var life := 14.0

func _ready() -> void:
	add_to_group("collector_coin")

func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	var player := get_tree().get_first_node_in_group("player")
	if not landed:
		velocity.y += GRAVITY * delta
		position += velocity * delta
		if player and global_position.distance_to(player.global_position) < 22.0:
			if player.has_method("take_damage"):
				player.take_damage(1)
			queue_free()
			return
		if position.y >= GROUND_Y - 8.0:
			position.y = GROUND_Y - 8.0
			landed = true
	elif player and global_position.distance_to(player.global_position) < 28.0:
		var region := get_parent()
		if region and region.has_method("add_gold"):
			region.call("add_gold", VALUE)
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var fade := minf(1.0, life / 2.0)
	var glow := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.008)
	if landed:
		draw_circle(Vector2.ZERO, 14.0 + glow * 3.0, Color(1.0, 0.9, 0.4, 0.18 * fade))
	draw_circle(Vector2.ZERO, 9.0, Color(0.94, 0.74, 0.22, fade))
	draw_circle(Vector2.ZERO, 5.5, Color(1.0, 0.9, 0.45, fade))
	draw_arc(Vector2.ZERO, 9.0, 0.0, TAU, 16, Color(0.7, 0.5, 0.15, fade), 1.5)
