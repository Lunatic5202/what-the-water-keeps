extends CharacterBody2D
# THE HOST (Gluttony boss). See docs/game-bible.md, Region 3.
# Phase 1, Appetizers: lobs snacks that force-feed Lumi (damage + Fullness).
# Phase 2, Main Course: the table fills the arena, pies sag underfoot, and he
#   slams the table (a low shock wave to jump).
# Phase 3, Dessert: he swallows the room and grows. Jaw walls sweep the arena
#   (pass through the gap; dashing helps, but not while Stuffed). After each
#   run of walls he gapes, and that is the only time he can be hurt.
# Numbers are prototype guesses (bible says 900 HP, trimmed for a short fight).

signal defeated
signal phase_changed(phase: int)
signal line(text: String)

const HAZARD := preload("res://scripts/host_hazard.gd")
const MAX_HEALTH := 420

var health := MAX_HEALTH
var phase := 0                 # 0 asleep, 1..3
var fight_on := false
var arena_left := 3750.0
var arena_right := 4850.0
var floor_y := 600.0
var home := Vector2(4640, 495)
var t := 0.0
var attack_time := 0.0
var wave_windup := 0.0
var gulp_walls_left := 0
var open_time := 0.0           # phase 3: > 0 means he is gaping (vulnerable)
var hurt_flash := 0.0
var dying := false
var die_time := 0.0
var scale_draw := 1.0
var cycle := 0

func _ready() -> void:
	add_to_group("boss")
	global_position = home

func start_fight() -> void:
	fight_on = true
	phase = 1
	health = MAX_HEALTH
	attack_time = 1.6
	get_tree().call_group("boss_health_bar", "show_boss", self, "THE HOST", health, MAX_HEALTH)
	phase_changed.emit(1)

func reset() -> void:
	fight_on = false
	phase = 0
	health = MAX_HEALTH
	dying = false
	scale_draw = 1.0
	open_time = 0.0
	gulp_walls_left = 0
	wave_windup = 0.0
	global_position = home
	get_tree().call_group("boss_health_bar", "hide_boss", self)
	for h in get_tree().get_nodes_in_group("host_hazard"):
		h.queue_free()

func _physics_process(delta: float) -> void:
	t += delta
	hurt_flash = maxf(0.0, hurt_flash - delta)
	if dying:
		die_time += delta
		scale_draw = lerpf(scale_draw, 0.55, delta * 1.5)
		if die_time > 2.0:
			queue_free()
		queue_redraw()
		return
	if not fight_on:
		queue_redraw()
		return
	global_position = home + Vector2(sin(t * 0.9) * 60.0, cos(t * 1.3) * 14.0)
	scale_draw = lerpf(scale_draw, 1.3 if phase >= 3 else 1.0, delta * 1.2)
	var player := get_tree().get_first_node_in_group("player")
	attack_time -= delta
	if open_time > 0.0:
		open_time -= delta
		if open_time <= 0.0:
			gulp_walls_left = 3
			attack_time = 1.2
	elif attack_time <= 0.0 and is_instance_valid(player):
		match phase:
			1:
				_throw_snack(player)
				attack_time = 2.3
			2:
				cycle += 1
				if cycle % 3 == 0:
					wave_windup = 0.8
					attack_time = 99.0
				else:
					_throw_snack(player)
					attack_time = 1.9
			3:
				if gulp_walls_left > 0:
					_spawn_gulp()
					gulp_walls_left -= 1
					attack_time = 2.3
					if gulp_walls_left == 0:
						open_time = 4.2
						attack_time = 99.0
						line.emit("THE HOST: One more bite! Just one more!")
	if wave_windup > 0.0:
		wave_windup -= delta
		if wave_windup <= 0.0:
			_spawn_wave()
			attack_time = 2.2
	queue_redraw()

func _hazard() -> Node2D:
	var h := Node2D.new()
	h.set_script(HAZARD)
	h.add_to_group("host_hazard")
	h.set("floor_y", floor_y)
	h.set("end_x", arena_left - 120.0)
	get_parent().add_child(h)
	return h

func _throw_snack(player: Node2D) -> void:
	var h := _hazard()
	h.set("kind", "snack")
	h.add_to_group("enemy_projectile")   # Devour Style can swallow snacks
	h.global_position = global_position + Vector2(-70, -30)
	var to: Vector2 = player.global_position - h.global_position
	var flight := clampf(to.length() / 420.0, 0.5, 1.4)
	h.set("gravity", 620.0)
	h.set("velocity", Vector2(to.x / flight, to.y / flight - 0.5 * 620.0 * flight))
	h.set("fullness", 22.0)

func _spawn_wave() -> void:
	var h := _hazard()
	h.set("kind", "wave")
	h.set("size", Vector2(46, 54))
	h.global_position = Vector2(global_position.x - 90.0, floor_y)
	h.set("velocity", Vector2(-330.0, 0.0))

func _spawn_gulp() -> void:
	var h := _hazard()
	h.set("kind", "gulp")
	var high := randi() % 2 == 0
	h.set("gap_top", 330.0 if high else 450.0)
	h.set("gap_bottom", 470.0 if high else 600.0)
	h.global_position = Vector2(arena_right - 40.0, 0.0)
	h.set("velocity", Vector2(-260.0, 0.0))

func take_damage(amount: int) -> void:
	if dying or not fight_on:
		return
	if phase == 3 and open_time <= 0.0:
		hurt_flash = 0.05
		return   # jaws shut: nothing gets through
	health -= amount
	hurt_flash = 0.12
	get_tree().call_group("boss_health_bar", "update_boss_health", self, health, MAX_HEALTH)
	var pct := float(health) / float(MAX_HEALTH)
	if phase == 1 and pct <= 0.66:
		phase = 2
		attack_time = 2.0
		phase_changed.emit(2)
	elif phase == 2 and pct <= 0.33:
		phase = 3
		gulp_walls_left = 3
		attack_time = 2.5
		for h in get_tree().get_nodes_in_group("host_hazard"):
			h.queue_free()
		phase_changed.emit(3)
	if health <= 0:
		dying = true
		fight_on = false
		get_tree().call_group("boss_health_bar", "hide_boss", self)
		for h in get_tree().get_nodes_in_group("host_hazard"):
			h.queue_free()
		defeated.emit()

func _draw() -> void:
	var s := scale_draw
	var fade := 1.0 - clampf((die_time - 1.2) / 0.8, 0.0, 1.0) if dying else 1.0
	var cake := Color(0.98, 0.78, 0.82, fade)
	var cream := Color(1.0, 0.96, 0.9, fade)
	var ink := Color(0.38, 0.2, 0.22, fade)
	if hurt_flash > 0.0:
		cake = Color(1, 1, 1, fade)
	# Tiered cake body.
	draw_circle(Vector2(0, 20) * s, 95.0 * s, cake)
	draw_arc(Vector2(0, 20) * s, 95.0 * s, 0.0, TAU, 36, ink, 3.0)
	draw_rect(Rect2(-80 * s, 0, 160 * s, 14 * s), cream)
	# Cat head, ears, chef's hat.
	draw_circle(Vector2(0, -62) * s, 50.0 * s, cake)
	draw_arc(Vector2(0, -62) * s, 50.0 * s, 0.0, TAU, 28, ink, 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-44, -92) * s, Vector2(-30, -130) * s, Vector2(-12, -100) * s]), cake)
	draw_colored_polygon(PackedVector2Array([Vector2(44, -92) * s, Vector2(30, -130) * s, Vector2(12, -100) * s]), cake)
	draw_rect(Rect2(-24 * s, -150 * s, 48 * s, 34 * s), cream)
	draw_rect(Rect2(-24 * s, -150 * s, 48 * s, 34 * s), ink, false, 2.0)
	draw_circle(Vector2(0, -156) * s, 18.0 * s, cream)
	# Face: sad when the jaws are shut, gaping when open.
	draw_circle(Vector2(-18, -66) * s, 5.0 * s, ink)
	draw_circle(Vector2(18, -66) * s, 5.0 * s, ink)
	if phase == 3 and open_time > 0.0:
		draw_circle(Vector2(0, -42) * s, 24.0 * s, Color(0.45, 0.12, 0.2, fade))
		draw_circle(Vector2(0, -42) * s, 24.0 * s, Color(1.0, 0.9, 0.4, 0.35 + 0.2 * sin(t * 12.0)))
	else:
		draw_arc(Vector2(0, -40) * s, 14.0 * s, 0.3, PI - 0.3, 10, ink, 3.0)
	if wave_windup > 0.0:
		draw_circle(Vector2(0, 30) * s, 110.0 * s, Color(1.0, 0.4, 0.3, 0.18))
