extends CharacterBody2D

signal defeated

const GRAVITY := 1100.0
const CONTACT_DAMAGE := 1 # Tutorial-friendly; telegraphs teach the pattern, not huge damage.
const ROLL_SPEED := 210.0
const HEAD_LUNGE_SPEED := 300.0
const SPORE_SCRIPT := preload("res://scripts/moss_spore.gd")

var health := 120
var max_health := 120
var phase := 0 # 0=intro, 1=fighting, 2=defeated
var attack_timer := 0.0
var attack_index := -1
var direction := 1
var hurt_cooldown := 0.0
var is_rolling := false
var roll_timer := 0.0
var spore_cooldown := 0.0
var defeat_timer := 0.0
var defeat_alpha := 1.0
var defeat_scale := 1.0

# Attack states make a readable wind-up, attack, and recovery.
var attack_state := "idle"
var tell_timer := 0.0
var attack_duration := 0.0
var lunge_timer := 0.0
var phase_two := false
var stagger_timer := 0.0
var player_ref: Node2D

func _ready() -> void:
	add_to_group("boss")

func _physics_process(delta: float) -> void:
	if phase == 2:
		defeat_timer += delta
		defeat_alpha = maxf(0.0, 1.0 - defeat_timer / 2.0)
		defeat_scale = 1.0 + defeat_timer * 0.3
		if defeat_timer >= 2.0:
			queue_free()
		queue_redraw()
		return
	if phase != 1:
		return

	player_ref = get_tree().get_first_node_in_group("player") as Node2D
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

	hurt_cooldown = maxf(0.0, hurt_cooldown - delta)
	spore_cooldown = maxf(0.0, spore_cooldown - delta)
	stagger_timer = maxf(0.0, stagger_timer - delta)

	if stagger_timer > 0.0:
		attack_state = "stagger"
		velocity.x = -direction * 95.0
	elif attack_state == "tell":
		tell_timer -= delta
		velocity.x = 0.0
		if tell_timer <= 0.0:
			_begin_attack()
	elif attack_state == "head_lunge":
		lunge_timer -= delta
		velocity.x = direction * HEAD_LUNGE_SPEED
		if lunge_timer <= 0.0:
			_finish_attack(1.0)
	elif attack_state == "roll":
		roll_timer -= delta
		velocity.x = direction * ROLL_SPEED
		if roll_timer <= 0.0:
			is_rolling = false
			_finish_attack(1.1)
	elif attack_state == "spores":
		velocity.x = 0.0
		attack_duration -= delta
		if attack_duration <= 0.0:
			_finish_attack(1.2)
	else:
		if attack_state == "stagger":
			attack_state = "idle"
			attack_timer = 0.55
		attack_timer -= delta
		velocity.x = 0.0
		if attack_timer <= 0.0:
			_choose_attack()

	move_and_slide()
	_check_player_collision()
	queue_redraw()

func _choose_attack() -> void:
	if not is_instance_valid(player_ref):
		attack_timer = 0.5
		return
	direction = 1 if player_ref.global_position.x >= global_position.x else -1

	# Phase two begins at half health: shorter waits and a wider spore fan.
	phase_two = health <= max_health / 2
	attack_index = (attack_index + 1) % (4 if phase_two else 3)
	attack_state = "tell"
	match attack_index:
		0:
			tell_timer = 0.75 if not phase_two else 0.55
		1:
			tell_timer = 0.9 if not phase_two else 0.65
		2:
			tell_timer = 0.8 if not phase_two else 0.55
		3:
			tell_timer = 0.7

func _begin_attack() -> void:
	match attack_index:
		0: # Head bump: quick, committed lunge in the player's last direction.
			attack_state = "head_lunge"
			lunge_timer = 0.32
		1: # Rolling shell: fast horizontal charge; jump over it.
			attack_state = "roll"
			is_rolling = true
			roll_timer = 1.15 if not phase_two else 1.4
		2: # Spore fan: several slow spores spread across the arena.
			attack_state = "spores"
			attack_duration = 0.25
			_spawn_spore_fan(5 if not phase_two else 7)
		3: # Phase two: a short aimed burst after the regular fan.
			attack_state = "spores"
			attack_duration = 0.3
			_spawn_aimed_burst()

func _finish_attack(recovery: float) -> void:
	attack_state = "idle"
	is_rolling = false
	velocity.x = 0.0
	attack_timer = recovery if not phase_two else recovery * 0.75

func _spawn_spore_fan(count: int) -> void:
	var origin := global_position + Vector2(0, -18)
	var spread := 0.85 if count <= 5 else 1.1
	for i in range(count):
		var t := 0.0 if count == 1 else float(i) / float(count - 1)
		var angle := lerpf(-spread, spread, t)
		_spawn_spore(origin, Vector2(direction * cos(angle), -absf(sin(angle)) - 0.12).normalized(), 135.0)

func _spawn_aimed_burst() -> void:
	var origin := global_position + Vector2(direction * 24, -18)
	var target_dir := Vector2(direction, -0.15)
	if is_instance_valid(player_ref):
		target_dir = (player_ref.global_position - origin).normalized()
	for offset in [-0.22, 0.0, 0.22]:
		_spawn_spore(origin, target_dir.rotated(offset), 175.0)

func _spawn_spore(origin: Vector2, travel_dir: Vector2, travel_speed: float) -> void:
	var spore := Node2D.new()
	spore.set_script(SPORE_SCRIPT)
	spore.global_position = origin
	spore.set("direction", travel_dir)
	spore.set("speed", travel_speed)
	get_parent().add_child(spore)

func _check_player_collision() -> void:
	if not is_instance_valid(player_ref) or spore_cooldown > 0.0:
		return
	if global_position.distance_to(player_ref.global_position) < (62.0 if is_rolling else 54.0):
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(CONTACT_DAMAGE)
			spore_cooldown = 0.85

func take_damage(amount: int) -> void:
	if phase != 1 or hurt_cooldown > 0.0:
		return
	health = maxi(0, health - amount)
	hurt_cooldown = 0.25
	stagger_timer = 0.12
	is_rolling = false
	attack_state = "stagger"
	velocity.x = -direction * 95.0
	if health <= 0:
		_defeat()

func start_fight() -> void:
	if phase != 0:
		return
	phase = 1
	attack_state = "idle"
	attack_timer = 1.2

func _defeat() -> void:
	phase = 2
	velocity = Vector2.ZERO
	attack_state = "idle"
	is_rolling = false
	defeat_timer = 0.0
	defeated.emit()

func _draw() -> void:
	if phase == 2:
		var glow_alpha := sin(defeat_timer * 4.0) * 0.3 * defeat_alpha
		draw_circle(Vector2.ZERO, 50 * defeat_scale, Color(0.75, 0.88, 0.68, glow_alpha))
		draw_circle(Vector2(0, 8), 28, Color(0.42, 0.52, 0.44, defeat_alpha * 0.5))
		draw_arc(Vector2.ZERO, 32, 0, PI, 16, Color(0.35, 0.48, 0.38, defeat_alpha), 8.0)
		return

	var shell_color := Color(0.35, 0.48, 0.38, 1.0)
	if hurt_cooldown > 0.0 and int(Time.get_ticks_msec() / 80) % 2 == 0:
		shell_color = Color(0.95, 0.92, 0.88, 1.0)
	draw_circle(Vector2(0, 8), 28, Color(0.42, 0.52, 0.44, 1.0))
	draw_arc(Vector2.ZERO, 32, 0, PI, 16, shell_color, 8.0)
	draw_circle(Vector2(-14, -4), 6, shell_color.darkened(0.2))
	draw_circle(Vector2(0, -8), 6, shell_color.darkened(0.2))
	draw_circle(Vector2(14, -4), 6, shell_color.darkened(0.2))

	if phase == 0:
		return

	if not is_rolling:
		var head_x := 28 * direction
		draw_circle(Vector2(head_x, 12), 10, Color(0.52, 0.58, 0.48, 1.0))
		draw_circle(Vector2(head_x + 3 * direction, 10), 2, Color(0.12, 0.15, 0.23, 1.0))

	# Tiny leaf flecks make hits feel tactile without adding external assets.
	if hurt_cooldown > 0.0:
		for i in range(4):
			var leaf_x := -direction * (18.0 + float(i) * 9.0) + sin(Time.get_ticks_msec() * 0.025 + i) * 3.0
			var leaf_y := -18.0 - float((Time.get_ticks_msec() / 35 + i * 7) % 22)
			draw_line(Vector2(leaf_x, leaf_y), Vector2(leaf_x + 5.0, leaf_y - 3.0), Color(0.79, 0.88, 0.58, 0.9), 2.0)

	# Dust puffs trail behind the shell while Old Moss rolls.
	if is_rolling:
		for i in range(4):
			var dust_x := -direction * (25.0 + float(i) * 12.0)
			var dust_y := 19.0 + sin(Time.get_ticks_msec() * 0.02 + i) * 3.0
			draw_circle(Vector2(dust_x, dust_y), 4.0 + float(i % 2), Color(0.79, 0.83, 0.69, 0.35 - float(i) * 0.06))

	# Clear attack telegraph: the shell glows before each move.
	if attack_state == "tell":
		var tell_color := Color(1.0, 0.82, 0.48, 0.75)
		if attack_index == 1:
			tell_color = Color(0.95, 0.68, 0.48, 0.8)
		elif attack_index >= 2:
			tell_color = Color(0.72, 0.9, 0.65, 0.8)
		draw_circle(Vector2.ZERO, 39 + sin(Time.get_ticks_msec() * 0.02) * 3.0, tell_color)
		if attack_index == 0:
			draw_line(Vector2(direction * 32, 18), Vector2(direction * 90, 18), tell_color, 4.0)
		elif attack_index == 1:
			draw_arc(Vector2(0, 0), 48, PI, TAU, 24, tell_color, 4.0)
		else:
			for i in range(5):
				draw_circle(Vector2(direction * (24 + i * 14), -34 - i * 3), 3, tell_color)

	# Health bar with a phase-two tint.
	var bar_width := 90.0
	var bar_y := -54.0
	draw_rect(Rect2(-bar_width / 2, bar_y, bar_width, 7), Color(0.2, 0.2, 0.25, 0.85))
	var health_width := float(health) / float(max_health) * bar_width
	draw_rect(Rect2(-bar_width / 2, bar_y, health_width, 7),
		Color(0.68, 0.83, 0.58, 1.0) if not phase_two else Color(0.84, 0.76, 0.5, 1.0))
