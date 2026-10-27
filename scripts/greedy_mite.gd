extends CharacterBody2D

signal defeated
signal dropped_coin(amount: int)

const GRAVITY := 1100.0
var health := 16
var max_health := 16
var start_x := 0.0
var patrol_direction := -1
var patrol_timer := 0.0
var attack_cooldown := 0.0
var dead := false
var knockback_timer := 0.0
var dissolve_timer := 0.0
var dissolving := false
var dissolve_alpha := 1.0
var chase := false
var chase_timer := 0.0

var stun_time := 0.0

func _ready() -> void:
	start_x = global_position.x
	add_to_group("enemy")

func stun(seconds: float) -> void:
	stun_time = maxf(stun_time, seconds)

func _physics_process(delta: float) -> void:
	if stun_time > 0.0 and not dissolving:
		stun_time -= delta
		return
	if dissolving:
		dissolve_timer += delta
		dissolve_alpha = maxf(0.0, 1.0 - (dissolve_timer / 0.5))
		if dissolve_timer >= 0.5:
			queue_free()
		queue_redraw()
		return

	if dead:
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

	var player := get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		var dist := global_position.distance_to(player.global_position)
		if dist < 160.0:
			chase = true
			chase_timer = 2.2
			patrol_direction = 1 if player.global_position.x >= global_position.x else -1
		if chase:
			chase_timer -= delta
			if chase_timer <= 0.0:
				chase = false

	patrol_timer += delta
	if not chase and patrol_timer > 1.0:
		patrol_timer = 0.0
		patrol_direction *= -1

	knockback_timer = maxf(0.0, knockback_timer - delta)
	if knockback_timer <= 0.0:
		var speed := 58.0 if chase else 38.0
		velocity.x = patrol_direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)

	if absf(global_position.x - start_x) > 140.0 and not chase:
		patrol_direction = -1 if global_position.x > start_x else 1

	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	move_and_slide()

	if is_instance_valid(player) and global_position.distance_to(player.global_position) < 38.0 and attack_cooldown <= 0.0:
		if player.has_method("take_damage"):
			player.take_damage(1)
			attack_cooldown = 0.9

	queue_redraw()

func take_damage(amount: int) -> void:
	if dead or dissolving:
		return
	health -= amount
	if health <= 0:
		dead = true
		dissolving = true
		dropped_coin.emit(5)
		defeated.emit()
	else:
		var player := get_tree().get_first_node_in_group("player")
		if player:
			velocity.x = sign(global_position.x - player.global_position.x) * 170.0
			velocity.y = -120.0
			knockback_timer = 0.22

func _draw() -> void:
	if dissolving:
		var particle_count := int(16 * dissolve_alpha)
		for i in range(particle_count):
			var angle := (i / float(particle_count)) * TAU
			var dist := (1.0 - dissolve_alpha) * 22.0
			var pos := Vector2(cos(angle), sin(angle)) * dist
			var size := lerpf(2.6, 0.4, 1.0 - dissolve_alpha)
			draw_circle(pos, size, Color(0.98, 0.86, 0.4, dissolve_alpha * 0.7))
		return

	draw_circle(Vector2(0, 4), 16, Color(0.96, 0.78, 0.28, 0.25))
	var body := PackedVector2Array([
		Vector2(-14, 6), Vector2(-15, -2), Vector2(-10, -10), Vector2(0, -14),
		Vector2(10, -10), Vector2(15, -2), Vector2(14, 6), Vector2(8, 9), Vector2(-8, 9)
	])
	draw_colored_polygon(body, Color(0.96, 0.78, 0.28, 1.0))
	body.append(body[0])
	draw_polyline(body, Color(0.4, 0.32, 0.16), 2.2)
	draw_circle(Vector2(-4, -2), 2.0, Color(0.2, 0.16, 0.08, 1.0))
	draw_circle(Vector2(4, -2), 2.0, Color(0.2, 0.16, 0.08, 1.0))
	draw_rect(Rect2(-3, 2, 6, 2), Color(0.9, 0.72, 0.26, 1.0))
	for i in range(health):
		draw_circle(Vector2(-7.0 + i * 1.8, -20), 1.0, Color(1.0, 0.9, 0.5, 0.9))
