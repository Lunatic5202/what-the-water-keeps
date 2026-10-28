extends CharacterBody2D

signal dropped_coin(amount: int)

const GRAVITY := 1100.0
var health := 10
var dead := false
var windup := 0.0
var hop_cooldown := 0.0
var contact_cooldown := 0.0
var dissolve_time := 0.0
var dissolving := false
var facing := -1.0

func _ready() -> void:
	add_to_group("enemy")

func _physics_process(delta: float) -> void:
	if dissolving:
		dissolve_time += delta
		queue_redraw()
		if dissolve_time >= 0.45:
			queue_free()
		return
	if dead:
		return

	var player := get_tree().get_first_node_in_group("player") as Node2D
	hop_cooldown = maxf(0.0, hop_cooldown - delta)
	contact_cooldown = maxf(0.0, contact_cooldown - delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

	if windup > 0.0:
		windup -= delta
		velocity.x = 0.0
		if windup <= 0.0 and is_instance_valid(player):
			facing = signf(player.global_position.x - global_position.x)
			if is_zero_approx(facing):
				facing = 1.0
			velocity = Vector2(facing * 205.0, -390.0)
			hop_cooldown = 1.15
	elif hop_cooldown <= 0.0 and is_on_floor() and is_instance_valid(player):
		if absf(player.global_position.x - global_position.x) < 185.0 and absf(player.global_position.y - global_position.y) < 90.0:
			windup = 0.38
			facing = signf(player.global_position.x - global_position.x)

	move_and_slide()
	if is_instance_valid(player) and contact_cooldown <= 0.0 and global_position.distance_to(player.global_position) < 34.0:
		if player.has_method("take_damage"):
			player.take_damage(1)
		var greed := get_tree().get_first_node_in_group("gold_holder")
		if is_instance_valid(greed) and greed.has_method("apply_pip_coin"):
			greed.call("apply_pip_coin")
		contact_cooldown = 1.0
	queue_redraw()

func take_damage(amount: int) -> void:
	if dead:
		return
	health -= amount
	if health <= 0:
		dead = true
		dissolving = true
		var hitbox := get_node_or_null("CollisionShape2D") as CollisionShape2D
		if is_instance_valid(hitbox):
			hitbox.set_deferred("disabled", true)
		dropped_coin.emit(6)
	else:
		var player := get_tree().get_first_node_in_group("player")
		if is_instance_valid(player):
			velocity.x = signf(global_position.x - player.global_position.x) * 140.0
			velocity.y = -110.0

func _draw() -> void:
	if dissolving:
		var alpha := maxf(0.0, 1.0 - dissolve_time / 0.45)
		for i in range(10):
			var angle := float(i) * TAU / 10.0
			draw_circle(Vector2(cos(angle), sin(angle)) * dissolve_time * 30.0, 2.2 * alpha, Color(1.0, 0.83, 0.35, alpha))
		return
	var body := PackedVector2Array([
		Vector2(-14, 8), Vector2(-16, -3), Vector2(-10, -12), Vector2(-8, -25),
		Vector2(-2, -15), Vector2(0, -18), Vector2(8, -25), Vector2(9, -12),
		Vector2(16, -3), Vector2(14, 8), Vector2(7, 12), Vector2(-7, 12)
	])
	draw_colored_polygon(body, Color(0.89, 0.73, 0.36, 1.0))
	body.append(body[0])
	draw_polyline(body, Color(0.38, 0.28, 0.16, 1.0), 2.0)
	draw_circle(Vector2(-5, -3), 2.0, Color(0.18, 0.14, 0.08, 1.0))
	draw_circle(Vector2(5, -3), 2.0, Color(0.18, 0.14, 0.08, 1.0))
	draw_circle(Vector2(0, 5), 5.0, Color(0.96, 0.78, 0.24, 1.0))
	draw_circle(Vector2(0, 5), 2.2, Color(1.0, 0.91, 0.54, 1.0))
	if windup > 0.0:
		draw_arc(Vector2.ZERO, 24.0, PI, TAU, 18, Color(1.0, 0.83, 0.38, 0.9), 2.5)
		draw_line(Vector2(0, 15), Vector2(facing * 48.0, 15), Color(0.89, 0.39, 0.18, 0.85), 3.0)
