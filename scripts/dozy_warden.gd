extends CharacterBody2D
# Dozy Warden: Sloth's sub-boss, guarding the sky route. Name comes from the
# prototype, not the bible. Patrols a ledge, yawns out lullaby notes (they add
# Drowse and hurt) and slams the ledge when Lumi gets close.
# Never run in Godot as a real fight: all numbers are guesses.

signal defeated

const NOTE := preload("res://scripts/sleep_spore.gd")
const Palette := preload("res://scripts/palette.gd")

const GRAVITY := 1100.0
const MAX_HEALTH := 70
const PATROL_SPEED := 55.0
const YAWN_TIME := 0.9
const SLAM_TIME := 0.8
const RECOVER_TIME := 1.3
const SLAM_RANGE := 190.0
const SEE_RANGE := 700.0
const BODY := Color(0.30, 0.26, 0.55)
const RIM := Color(0.97, 0.93, 1.0)
const GLOW := Color(0.97, 0.91, 0.63)

var health := MAX_HEALTH
var left_x := 0.0           # patrol bounds, set by sloth.gd
var right_x := 0.0
var facing := -1
var state := "patrol"
var state_time := 0.0
var cooldown := 1.5
var contact_cooldown := 0.0
var stun_time := 0.0
var hurt_flash := 0.0
var dissolving := false
var dissolve_time := 0.0
var spawn := Vector2.ZERO
var player_ref: Node2D = null

func _ready() -> void:
	add_to_group("boss")
	spawn = global_position
	collision_layer = 1
	collision_mask = 1

func stun(seconds: float) -> void:
	stun_time = maxf(stun_time, seconds)

func take_damage(amount: int) -> void:
	if dissolving:
		return
	health -= amount
	hurt_flash = 0.15
	if health <= 0:
		dissolving = true
		dissolve_time = 0.0
		velocity = Vector2.ZERO
		defeated.emit()

func _physics_process(delta: float) -> void:
	hurt_flash = maxf(0.0, hurt_flash - delta)
	contact_cooldown = maxf(0.0, contact_cooldown - delta)
	if dissolving:
		dissolve_time += delta
		if dissolve_time >= 0.8:
			queue_free()
		queue_redraw()
		return
	if global_position.y > 1200.0:
		global_position = spawn
		velocity = Vector2.ZERO
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0
	if stun_time > 0.0:
		stun_time -= delta
		velocity.x = 0.0
		move_and_slide()
		queue_redraw()
		return
	player_ref = get_tree().get_first_node_in_group("player") as Node2D
	state_time += delta
	cooldown = maxf(0.0, cooldown - delta)
	match state:
		"patrol":
			velocity.x = facing * PATROL_SPEED
			if global_position.x <= left_x:
				facing = 1
			elif global_position.x >= right_x:
				facing = -1
			if cooldown <= 0.0 and _sees_player():
				_pick_attack()
		"yawn":
			velocity.x = 0.0
			_face_player()
			if state_time >= YAWN_TIME:
				_fire_notes()
				_set_state("recover")
		"slam_windup":
			velocity.x = 0.0
			if state_time >= SLAM_TIME:
				_do_slam()
				_set_state("recover")
		"recover":
			velocity.x = 0.0
			if state_time >= RECOVER_TIME:
				cooldown = 1.2
				_set_state("patrol")
	move_and_slide()
	_check_contact()
	queue_redraw()

func _set_state(next: String) -> void:
	state = next
	state_time = 0.0

func _sees_player() -> bool:
	return is_instance_valid(player_ref) and global_position.distance_to(player_ref.global_position) < SEE_RANGE

func _face_player() -> void:
	if is_instance_valid(player_ref):
		facing = 1 if player_ref.global_position.x >= global_position.x else -1

func _pick_attack() -> void:
	_face_player()
	var dx := absf(player_ref.global_position.x - global_position.x)
	var dy := absf(player_ref.global_position.y - global_position.y)
	if dx < SLAM_RANGE and dy < 90.0:
		_set_state("slam_windup")
	else:
		_set_state("yawn")

func _fire_notes() -> void:
	if not is_instance_valid(player_ref):
		return
	var aim := (player_ref.global_position - global_position).normalized()
	for offset in [-0.28, 0.0, 0.28]:
		var note := Node2D.new()
		note.set_script(NOTE)
		note.set("note", true)
		note.set("velocity", aim.rotated(offset) * 190.0)
		note.set("drowse", 25.0)
		note.set("damage", 1)
		note.set("life", 4.0)
		get_parent().add_child(note)
		note.global_position = global_position + Vector2(facing * 20.0, -10.0)

func _do_slam() -> void:
	if not is_instance_valid(player_ref):
		return
	var dx := absf(player_ref.global_position.x - global_position.x)
	if dx < SLAM_RANGE and player_ref.is_on_floor():
		player_ref.take_damage(1)
		var holder := get_tree().get_first_node_in_group("drowse_holder")
		if is_instance_valid(holder):
			holder.call("add_drowse", 20.0)

func _check_contact() -> void:
	if contact_cooldown > 0.0 or not is_instance_valid(player_ref):
		return
	if global_position.distance_to(player_ref.global_position) < 44.0:
		player_ref.take_damage(1)
		contact_cooldown = 1.1

func _draw() -> void:
	var fade := 1.0 - clampf(dissolve_time / 0.8, 0.0, 1.0)
	var body := BODY
	if hurt_flash > 0.0:
		body = Color(0.8, 0.75, 1.0)
	body.a = fade
	var rim := Color(RIM, fade)
	# Telegraphs: a warm glow while yawning, a raised ring before the slam.
	if state == "yawn" or state == "slam_windup":
		var p := clampf(state_time / (YAWN_TIME if state == "yawn" else SLAM_TIME), 0.0, 1.0)
		draw_circle(Vector2.ZERO, 46.0 + 22.0 * p, Color(GLOW, 0.18 + 0.2 * p))
		if state == "slam_windup":
			draw_arc(Vector2(0, 26), SLAM_RANGE * p, PI, TAU, 28, Color(GLOW, 0.8), 4.0)
	draw_circle(Vector2(0, -4), 34.0, body)
	draw_arc(Vector2(0, -4), 34.0, 0.0, TAU, 28, rim, 3.0)
	# Sleepy eyes and an open mouth when yawning.
	for side in [-1.0, 1.0]:
		draw_line(Vector2(side * 12.0 - 6.0, -10.0), Vector2(side * 12.0 + 6.0, -8.0), rim, 3.0)
	if state == "yawn":
		draw_circle(Vector2(0, 10), 8.0 + 4.0 * clampf(state_time / YAWN_TIME, 0.0, 1.0), Color(GLOW, fade))
	else:
		draw_line(Vector2(-7, 12), Vector2(7, 12), rim, 3.0)
	var pips := ceili(float(health) / float(MAX_HEALTH) * 7.0)
	for i in range(7):
		var on := i < pips
		draw_circle(Vector2(-27.0 + i * 9.0, -52.0), 3.2, Color(GLOW, fade) if on else Color(0.4, 0.35, 0.6, fade * 0.6))
