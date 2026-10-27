extends CharacterBody2D

signal defeated
signal dropped_coins(amount: int)

const GRAVITY := 1100.0
var health := 48
var max_health := 48
var phase := 0
var attack_timer := 0.0
var state := "idle"
var state_time := 0.0
var stun_time := 0.0
var dead := false
var dissolve_timer := 0.0
var dissolving := false
var dissolve_alpha := 1.0
var shield := 8
var player_ref: Node2D
var slam_cooldown := 0.0

func _ready() -> void:
	add_to_group("boss")
	add_to_group("enemy")

func stun(seconds: float) -> void:
	stun_time = maxf(stun_time, seconds)

func take_damage(amount: int) -> void:
	if dead or dissolving:
		return
	if shield > 0 and state != "stagger":
		shield -= 1
		_show_shield_hit()
		return
	health -= amount
	if health <= 0:
		_die()
	else:
		state = "hurt"
		state_time = 0.0
		var player := get_tree().get_first_node_in_group("player")
		if player:
			velocity.x = sign(global_position.x - player.global_position.x) * 140.0
			velocity.y = -90.0

func _show_shield_hit() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("add_screen_shake"):
		player.add_screen_shake(4.0, 0.12)

func _die() -> void:
	dead = true
	dissolving = true
	dropped_coins.emit(25)
	defeated.emit()

func _physics_process(delta: float) -> void:
	if stun_time > 0.0 and not dissolving:
		stun_time -= delta
		return
	if dissolving:
		dissolve_timer += delta
		dissolve_alpha = maxf(0.0, 1.0 - (dissolve_timer / 0.7))
		if dissolve_timer >= 0.7:
			queue_free()
		queue_redraw()
		return
	if dead:
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

	player_ref = get_tree().get_first_node_in_group("player") as Node2D
	state_time += delta
	slam_cooldown = maxf(0.0, slam_cooldown - delta)

	if state == "idle":
		velocity.x = 0.0
		if state_time > 1.0 and is_instance_valid(player_ref) and slam_cooldown <= 0.0:
			_start_slam()
	elif state == "slam_windup":
		velocity.x = 0.0
		if state_time > 0.8:
			_do_slam()
	elif state == "slam":
		var dir := 1 if is_instance_valid(player_ref) and player_ref.global_position.x >= global_position.x else -1
		velocity.x = dir * 220.0
		if state_time > 0.6:
			_end_slam()
	elif state == "recover":
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
		if state_time > 1.0:
			state = "idle"
			state_time = 0.0
			slam_cooldown = 1.6
	elif state == "hurt":
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		if state_time > 0.25:
			state = "idle"
			state_time = 0.0

	move_and_slide()
	_check_contact()
	queue_redraw()

func _start_slam() -> void:
	state = "slam_windup"
	state_time = 0.0

func _do_slam() -> void:
	state = "slam"
	state_time = 0.0

func _end_slam() -> void:
	state = "recover"
	state_time = 0.0
	if is_instance_valid(player_ref) and global_position.distance_to(player_ref.global_position) < 70.0:
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(2)

func _check_contact() -> void:
	if not is_instance_valid(player_ref):
		return
	if global_position.distance_to(player_ref.global_position) < 52.0 and slam_cooldown <= 0.5:
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(1)

func _draw() -> void:
	if dissolving:
		var particle_count := int(24 * dissolve_alpha)
		for i in range(particle_count):
			var angle := (i / float(particle_count)) * TAU
			var dist := (1.0 - dissolve_alpha) * 40.0
			var pos := Vector2(cos(angle), sin(angle)) * dist
			var size := lerpf(3.2, 0.5, 1.0 - dissolve_alpha)
			draw_circle(pos, size, Color(0.98, 0.86, 0.4, dissolve_alpha * 0.7))
		return

	draw_circle(Vector2(0, 2), 28, Color(0.96, 0.78, 0.28, 0.22))
	var body := PackedVector2Array([
		Vector2(-26, 10), Vector2(-28, -6), Vector2(-18, -20), Vector2(0, -28),
		Vector2(18, -20), Vector2(28, -6), Vector2(26, 10), Vector2(16, 16), Vector2(-16, 16)
	])
	draw_colored_polygon(body, Color(0.95, 0.76, 0.26, 1.0))
	body.append(body[0])
	draw_polyline(body, Color(0.32, 0.26, 0.12), 3.0)
	draw_circle(Vector2(-10, -4), 3.0, Color(0.16, 0.12, 0.06, 1.0))
	draw_circle(Vector2(10, -4), 3.0, Color(0.16, 0.12, 0.06, 1.0))
	draw_rect(Rect2(-6, 6, 12, 3), Color(0.86, 0.68, 0.24, 1.0))
	if shield > 0:
		draw_arc(Vector2(0, -6), 30, 0, TAU, 32, Color(1.0, 0.92, 0.6, 0.7), 3.0)
		for i in range(min(shield, 8)):
			draw_circle(Vector2(-20.0 + i * 5.0, -36), 2.2, Color(1.0, 0.94, 0.7, 0.95))
	for i in range(health):
		if i % 6 == 0:
			draw_circle(Vector2(-14.0 + (i / 6.0) * 4.0, -44), 1.4, Color(1.0, 0.9, 0.5, 0.9))
