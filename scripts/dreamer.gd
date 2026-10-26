extends CharacterBody2D
# The Dreamer: boss of Slumber Hollow (bible Region 2). A gigantic fluffy sloth
# in a hammock between two glowing moons. Moved by code on collision layer 2.
#
# Phase 1 Lullaby:     slow waves of notes (touching them builds Drowse).
#                      After a few waves she yawns and sinks into reach.
# Phase 2 Pillow Fall: huge pillows drop and become soft platforms. Lantern
#                      posts appear (the region adds them).
# Phase 3 Covers Over: the blanket comes down, the arena goes dim, climbable
#                      walls appear and Lumi must strike the lantern-heart.

signal defeated
signal health_changed(current: int, maximum: int)
signal phase_changed(new_phase: int)

const NOTE := preload("res://scripts/sleep_spore.gd")
const PILLOW := preload("res://scripts/pillow.gd")
const HEART := preload("res://scripts/dreamer_heart.gd")
# Bible lists 800 HP; scaled to Lumi's 8 damage swing like The Collector.
const MAX_HEALTH := 420
const SEQUENCES := {
	1: ["wave", "wave", "wave", "yawn"],
	2: ["pillows", "wave", "pillows", "yawn"],
	3: ["wave", "pillows", "wave", "pillows"]
}
const HIGH_Y := 300.0
const LOW_Y := 470.0
const YAWN_TIME := 4.0
const MOON_COLOR := Color(0.97, 0.91, 0.63)

var health := MAX_HEALTH
var phase := 0     # 0 dormant, 1 lullaby, 2 pillows, 3 covers, 4 defeated
var state := "dormant"
var state_time := 0.0
var attack := ""
var attack_index := 0
var home := Vector2.ZERO
var arena_left := 4350.0
var arena_right := 5150.0
var floor_y := 600.0
var heart_pos := Vector2(5015, 230)  # y is used; x moves between the two walls
const HEART_LEFT_X := 4515.0   # within reach of someone clinging to the left wall
const HEART_RIGHT_X := 5015.0  # within reach of someone clinging to the right wall
var heart: CharacterBody2D
var heart_open := false
var heart_timer := 0.0
var hurt_flash := 0.0
var notes_left := 0
var note_timer := 0.0
var note_side := 1
var target_y := HIGH_Y
var dead_time := 0.0
var player: Node = null

func _ready() -> void:
	add_to_group("boss")
	home = global_position

func start_fight() -> void:
	if phase != 0:
		return
	phase = 1
	attack_index = 0
	_set_state("idle")
	health_changed.emit(health, MAX_HEALTH)

func reset() -> void:
	health = MAX_HEALTH
	phase = 0
	attack_index = 0
	heart_open = false
	dead_time = 0.0
	modulate = Color.WHITE
	scale = Vector2.ONE
	global_position = home
	target_y = HIGH_Y
	_clear_arena()
	_set_state("dormant")
	for child in get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", false)
	queue_redraw()

func _clear_arena() -> void:
	for n in get_tree().get_nodes_in_group("pillow"):
		n.queue_free()
	for n in get_tree().get_nodes_in_group("enemy_projectile"):
		n.queue_free()
	if is_instance_valid(heart):
		heart.queue_free()
	heart = null

func _set_state(next: String) -> void:
	state = next
	state_time = 0.0

func _pace() -> float:
	return 1.0 if phase <= 1 else (0.88 if phase == 2 else 0.8)

func _physics_process(delta: float) -> void:
	hurt_flash = maxf(0.0, hurt_flash - delta)
	if phase == 0:
		queue_redraw()
		return
	state_time += delta
	if phase == 4:
		_update_dead(delta)
		return
	player = get_tree().get_first_node_in_group("player")
	match state:
		"idle":
			if state_time >= 1.0 * _pace():
				_next_step()
		"tell":
			if state_time >= (0.9 if attack == "wave" else 0.5) * _pace():
				_begin_act()
		"act":
			_update_act(delta)
		"recover":
			if state_time >= 1.2 * _pace():
				_set_state("idle")
		"yawn":
			target_y = LOW_Y
			if state_time >= YAWN_TIME:
				target_y = HIGH_Y
				_set_state("idle")
		"transition":
			if state_time >= 2.0:
				_set_state("idle")
	if phase == 3:
		_update_heart(delta)
	global_position.y = move_toward(global_position.y, target_y, 140.0 * delta)
	global_position.x = home.x + sin(Time.get_ticks_msec() * 0.0008) * 30.0
	queue_redraw()

func _next_step() -> void:
	var seq: Array = SEQUENCES[phase]
	attack = seq[attack_index % seq.size()]
	attack_index += 1
	if attack == "yawn":
		_set_state("yawn")
		return
	_set_state("tell")

func _begin_act() -> void:
	_set_state("act")
	if attack == "wave":
		notes_left = 5 if phase == 1 else 6
		note_timer = 0.0
	elif attack == "pillows":
		_drop_pillows()

func _update_act(delta: float) -> void:
	if attack == "wave":
		note_timer -= delta
		if note_timer <= 0.0 and notes_left > 0:
			_fire_note()
			notes_left -= 1
			note_timer = 0.55 * _pace()
		if notes_left <= 0 and state_time > 3.2:
			_set_state("recover")
	else:
		if state_time >= 1.8:
			_set_state("recover")

func _fire_note() -> void:
	var heights := [575.0, 520.0, 470.0]
	var y: float = heights[randi() % heights.size()]
	var note := Node2D.new()
	note.set_script(NOTE)
	note.set("note", true)
	note.set("velocity", Vector2(note_side * (125.0 / _pace()), 0.0))
	note.set("drowse", 25.0)
	note.set("damage", 0 if phase == 1 else 1)
	note.set("wobble", 10.0)
	note.set("life", 9.0)
	get_parent().add_child(note)
	note.global_position = Vector2(home.x, y)
	note_side *= -1

func _drop_pillows() -> void:
	var count := 2 if phase == 2 else 2
	var px := 4750.0
	if is_instance_valid(player):
		px = player.global_position.x
	for i in range(count):
		var pillow := Node2D.new()
		pillow.set_script(PILLOW)
		pillow.set("floor_y", floor_y)
		get_parent().add_child(pillow)
		var x := clampf(px + (i - 0.5) * 230.0 + randf_range(-60.0, 60.0), arena_left + 90.0, arena_right - 90.0)
		pillow.global_position = Vector2(x, 0.0)
		pillow.position.y = floor_y - 520.0

func _update_heart(delta: float) -> void:
	heart_timer += delta
	var cycle := 7.0
	heart_open = fmod(heart_timer, cycle) > cycle - 4.0
	# Each round the heart hangs by the other wall. It drifts across while shut.
	var goal_x := HEART_RIGHT_X if int(heart_timer / cycle) % 2 == 0 else HEART_LEFT_X
	heart_pos.x = move_toward(heart_pos.x, goal_x, 300.0 * delta)
	if is_instance_valid(heart):
		heart.global_position = heart_pos

func hit_heart(amount: int) -> void:
	if phase != 3 or not heart_open:
		return
	hurt_flash = 0.15
	_apply_damage(amount * 2)

func take_damage(amount: int) -> void:
	if phase == 0 or phase >= 3:
		return
	hurt_flash = 0.15
	_apply_damage(amount)

func _apply_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	health_changed.emit(health, MAX_HEALTH)
	if health <= 0:
		_die()
		return
	var frac := float(health) / float(MAX_HEALTH)
	if phase == 1 and frac <= 0.66:
		_enter_phase(2)
	elif phase == 2 and frac <= 0.33:
		_enter_phase(3)

func _enter_phase(next: int) -> void:
	phase = next
	attack_index = 0
	target_y = HIGH_Y
	_set_state("transition")
	for n in get_tree().get_nodes_in_group("enemy_projectile"):
		n.queue_free()
	if next == 3:
		heart_timer = 0.0
		heart_pos.x = HEART_RIGHT_X
		heart = CharacterBody2D.new()
		heart.set_script(HEART)
		heart.set("dreamer", self)
		get_parent().add_child(heart)
		heart.global_position = heart_pos
	phase_changed.emit(next)

func _die() -> void:
	phase = 4
	dead_time = 0.0
	heart_open = false
	_clear_arena()
	for child in get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)
	defeated.emit()

func _update_dead(delta: float) -> void:
	dead_time += delta
	scale = Vector2.ONE * lerpf(1.0, 0.45, clampf(dead_time / 2.5, 0.0, 1.0))
	global_position.y = move_toward(global_position.y, floor_y - 40.0, 90.0 * delta)
	queue_redraw()

func _draw() -> void:
	var fur := Color(0.76, 0.72, 0.9)
	var face := Color(0.93, 0.9, 0.98)
	var ink := Color(0.16, 0.13, 0.32)
	if hurt_flash > 0.0:
		fur = Color(1, 1, 1)
	# Moons and hammock ropes (world positions, drawn in local space).
	var moon_a := to_local(Vector2(home.x - 330.0, 170.0))
	var moon_b := to_local(Vector2(home.x + 330.0, 170.0))
	for m in [moon_a, moon_b]:
		draw_circle(m, 58.0, Color(MOON_COLOR, 0.2))
		draw_circle(m, 40.0, MOON_COLOR)
		draw_arc(m, 40.0, 0.0, TAU, 28, Color(0.55, 0.5, 0.3), 2.5)
		draw_line(m + Vector2(0, 30), Vector2(sign(-m.x) * 60.0, 24.0), Color(0.9, 0.88, 1.0), 3.0)
	# Hammock.
	draw_arc(Vector2(0, -40), 120.0, 0.35, PI - 0.35, 24, Color(0.45, 0.42, 0.75), 10.0)
	# Body.
	draw_circle(Vector2.ZERO, 74.0, fur)
	draw_circle(Vector2(0, 14), 46.0, face)
	draw_circle(Vector2(0, -52), 40.0, fur)
	draw_circle(Vector2(0, -46), 28.0, face)
	draw_arc(Vector2.ZERO, 74.0, 0.0, TAU, 40, ink, 3.0)
	draw_arc(Vector2(0, -52), 40.0, 0.0, TAU, 28, ink, 3.0)
	# Sleepy face: dark patches, closed eyes, tiny smile.
	for side in [-1, 1]:
		draw_circle(Vector2(side * 14, -50), 9.0, Color(0.5, 0.45, 0.7))
		draw_arc(Vector2(side * 14, -50), 6.0, 0.2, PI - 0.2, 8, ink, 2.5)
	draw_circle(Vector2(0, -40), 4.0, ink)
	draw_arc(Vector2(0, -34), 8.0, 0.3, PI - 0.3, 8, ink, 2.0)
	# Dangling arms with claws.
	for side in [-1, 1]:
		draw_line(Vector2(side * 56, 10), Vector2(side * 78, 52), fur, 18.0)
		for c in range(3):
			draw_line(Vector2(side * 78 + (c - 1) * 6, 54), Vector2(side * 78 + (c - 1) * 6, 66), ink, 2.5)
	if state == "tell" and attack == "wave":
		draw_arc(Vector2(0, -34), 18.0 + state_time * 30.0, 0.0, TAU, 20, Color(MOON_COLOR, 0.8), 3.0)
	if state == "yawn":
		draw_circle(Vector2(0, -34), 9.0, Color(0.2, 0.1, 0.2))
	if phase == 3:
		var cover := PackedVector2Array([
			Vector2(-110, -110), Vector2(110, -110), Vector2(130, 90), Vector2(-130, 90)])
		draw_colored_polygon(cover, Color(0.24, 0.2, 0.5, 0.86))
		for i in range(5):
			draw_line(Vector2(-110 + i * 55, -110), Vector2(-120 + i * 60, 90), Color(0.5, 0.45, 0.8, 0.5), 5.0)
		draw_polyline(PackedVector2Array([Vector2(-110, -110), Vector2(110, -110), Vector2(130, 90), Vector2(-130, 90), Vector2(-110, -110)]), ink, 3.0)
	if phase > 0 and phase < 4:
		draw_rect(Rect2(-60, -128, 120, 8), Color(0.2, 0.18, 0.25, 0.85))
		draw_rect(Rect2(-60, -128, float(health) / float(MAX_HEALTH) * 120.0, 8), Color(0.78, 0.72, 1.0))
