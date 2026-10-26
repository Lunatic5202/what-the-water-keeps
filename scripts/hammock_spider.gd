extends CharacterBody2D
# Hammock Spider (Sloth): hangs on a thread and waits until Lumi stops moving,
# then drops on her. Keep moving and it stays up.

signal defeated

enum {HANG, TELL, DROP, REST, CLIMB}
const IDLE_NEEDED := 1.0
const TELL_TIME := 0.6
const DROP_SPEED := 620.0

var health := 22
var anchor_y := 0.0
var floor_y := 0.0
var state := HANG
var state_time := 0.0
var idle_time := 0.0
var attack_cooldown := 0.0
var hurt_flash := 0.0
var stun_time := 0.0
var dissolving := false
var dissolve_timer := 0.0

func _ready() -> void:
	collision_mask = 0
	if anchor_y == 0.0:
		anchor_y = global_position.y - 60.0

func stun(seconds: float) -> void:
	stun_time = maxf(stun_time, seconds)

func _hang_y() -> float:
	return anchor_y + 70.0

func _physics_process(delta: float) -> void:
	hurt_flash = maxf(0.0, hurt_flash - delta)
	if dissolving:
		dissolve_timer += delta
		if dissolve_timer >= 0.6:
			queue_free()
		queue_redraw()
		return
	if stun_time > 0.0:
		stun_time -= delta
		queue_redraw()
		return
	state_time += delta
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	var player := get_tree().get_first_node_in_group("player")
	match state:
		HANG:
			global_position.y = _hang_y() + sin(state_time * 2.0) * 3.0
			if is_instance_valid(player) and _player_idle(player, delta):
				_set_state(TELL)
		TELL:
			global_position.x += sin(state_time * 60.0) * 0.8
			if state_time >= TELL_TIME:
				_set_state(DROP)
		DROP:
			global_position.y += DROP_SPEED * delta
			if global_position.y >= floor_y:
				global_position.y = floor_y
				_set_state(REST)
		REST:
			if state_time >= 1.0:
				_set_state(CLIMB)
		CLIMB:
			global_position.y -= 120.0 * delta
			if global_position.y <= _hang_y():
				idle_time = 0.0
				_set_state(HANG)
	if is_instance_valid(player) and attack_cooldown <= 0.0 and state != HANG \
			and global_position.distance_to(player.global_position) < 34.0:
		player.take_damage(1)
		attack_cooldown = 1.0
	queue_redraw()

func _set_state(next: int) -> void:
	state = next
	state_time = 0.0

func _player_idle(player: Node, delta: float) -> bool:
	var close: bool = absf(player.global_position.x - global_position.x) < 170.0 \
		and player.global_position.y > global_position.y
	if close and player.is_on_floor() and player.velocity.length() < 12.0:
		idle_time += delta
	else:
		idle_time = maxf(0.0, idle_time - delta * 2.0)
	return idle_time >= IDLE_NEEDED

func take_damage(amount: int) -> void:
	if dissolving:
		return
	health -= amount
	hurt_flash = 0.15
	if health <= 0:
		dissolving = true
		defeated.emit()

func _draw() -> void:
	var fade := 1.0 - dissolve_timer / 0.6 if dissolving else 1.0
	var ink := Color(0.16, 0.13, 0.32, fade)
	var body := Color(0.45, 0.4, 0.72, fade)
	if hurt_flash > 0.0:
		body = Color(1, 1, 1, fade)
	var local_anchor := Vector2(0, anchor_y - global_position.y)
	draw_line(local_anchor, Vector2(0, -8), Color(0.9, 0.88, 1.0, 0.7 * fade), 2.0)
	for side in [-1, 1]:
		for i in range(3):
			var y := -4.0 + i * 5.0
			draw_line(Vector2(side * 8, y), Vector2(side * (18 + i * 2), y + 9.0), ink, 2.0)
	draw_circle(Vector2.ZERO, 11.0, body)
	draw_arc(Vector2.ZERO, 11.0, 0.0, TAU, 16, ink, 2.0)
	var eye := Color(1.0, 0.85, 0.75, fade) if state == TELL else Color(0.97, 0.97, 1.0, fade)
	draw_circle(Vector2(-4, -2), 2.5, eye)
	draw_circle(Vector2(4, -2), 2.5, eye)
	if state == TELL:
		draw_string(ThemeDB.fallback_font, Vector2(-4, -18), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1.0, 0.85, 0.5, fade))
