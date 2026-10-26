extends Area2D
# A moving palm wave: the Open Hand's shockwave, coins, soft orbs and
# reflected spores. It hurts anything with take_damage except Lumi.

var velocity := Vector2(500, 0)
var damage := 3
var life := 0.5
var radius := 14.0
var pierce := false
var fall_gravity := 0.0
var color := Color(1.0, 0.85, 0.75)
var hit_ids := {}
var total_life := 0.5

func _ready() -> void:
	collision_layer = 0
	collision_mask = 3
	monitoring = true
	total_life = life
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)

func _physics_process(delta: float) -> void:
	velocity.y += fall_gravity * delta
	position += velocity * delta
	life -= delta
	queue_redraw()
	for body in get_overlapping_bodies():
		var id := body.get_instance_id()
		if hit_ids.has(id) or body.is_in_group("player"):
			continue
		if not body.has_method("take_damage"):
			continue
		hit_ids[id] = true
		body.take_damage(damage)
		var player := get_tree().get_first_node_in_group("player")
		if is_instance_valid(player):
			player.call("add_glow", 2.0)
		if not pierce:
			queue_free()
			return
	if life <= 0.0:
		queue_free()

func _draw() -> void:
	var fade := clampf(life / maxf(0.01, total_life), 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius * 1.5, Color(color, 0.18 * fade + 0.05))
	draw_circle(Vector2.ZERO, radius, Color(color, 0.85 * fade + 0.1))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 16, Color(1, 1, 1, 0.6 * fade), 1.5)
