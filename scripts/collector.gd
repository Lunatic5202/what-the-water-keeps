extends CharacterBody2D
# The Collector: boss of the Gilded Garden (see docs/game-bible.md, Region 1).
# A giant golden plush bear in a tiny crown, sitting on a mountain of coins.
# He is moved by code (no physics) on collision layer 2, so he never shoves Lumi.
#
# Phase 1 Coin Rain: coins fall, belly slam. Missed coins land as pickups.
# Phase 2 Feast:     swallows the mountain and grows, faster if Lumi carries gold.
# Phase 3 Hunger:    lunges for Lumi's purse. No gold means the grab whiffs.
# Offering bowls let Lumi give gold away to shrink and hurt him.

signal defeated
signal health_changed(current: int, maximum: int)
signal phase_changed(new_phase: int)
signal gold_stolen(amount: int)
signal grab_whiffed
signal mountain_swallowed

const COIN_SCRIPT := preload("res://scripts/collector_coin.gd")
# The bible lists 700 HP, but Lumi's swing does 8 damage, so this is scaled down.
const MAX_HEALTH := 360
const BODY_RADIUS := 70.0
const GROUND_Y := 570.0
const MAX_SIZE := 1.7
const SEQUENCES := {
	1: ["coin_rain", "slam", "coin_rain", "slam"],
	2: ["coin_rain", "slam", "spit", "slam"],
	3: ["grab", "coin_rain", "grab", "slam", "spit"]
}
const TELLS := {"coin_rain": 0.8, "slam": 0.9, "spit": 0.6, "grab": 0.9}
const RECOVERS := {"coin_rain": 1.0, "slam": 1.1, "spit": 0.9, "grab": 1.1}

var health := MAX_HEALTH
var phase := 0 # 0 dormant, 1 coin rain, 2 feast, 3 hunger, 4 defeated
var state := "dormant"
var state_time := 0.0
var attack := ""
var attack_index := 0
var pending_phase := 0
var facing := -1
var body_size := 1.0
var air_offset := 0.0
var hurt_cooldown := 0.0
var contact_cooldown := 0.0
var open_for_hits := false # true while staggered from a whiffed grab
var arena_left := 2100.0
var arena_right := 2730.0
var mountain_x := 2580.0
var home := Vector2.ZERO
var rain_left := 0
var rain_timer := 0.0
var spit_fired := false
var slam_start_x := 0.0
var slam_target_x := 0.0
var shock_time := 0.0
var grab_resolved := false
var swallowed := false
var dead_time := 0.0
var player: Node = null
var greed: Node = null

func _ready() -> void:
	add_to_group("boss")
	home = global_position

func start_fight() -> void:
	if phase != 0:
		return
	greed = get_parent()
	phase = 1
	attack_index = 0
	_set_state("idle")
	health_changed.emit(health, MAX_HEALTH)

func reset() -> void:
	health = MAX_HEALTH
	phase = 0
	pending_phase = 0
	attack_index = 0
	body_size = 1.0
	air_offset = 0.0
	swallowed = false
	open_for_hits = false
	dead_time = 0.0
	modulate = Color.WHITE
	scale = Vector2.ONE
	global_position = home
	_set_state("dormant")
	for child in get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", false)
	queue_redraw()

func _set_state(next: String) -> void:
	state = next
	state_time = 0.0

func _pace() -> float:
	return 1.0 if phase <= 1 else (0.85 if phase == 2 else 0.72)

func _physics_process(delta: float) -> void:
	hurt_cooldown = maxf(0.0, hurt_cooldown - delta)
	contact_cooldown = maxf(0.0, contact_cooldown - delta)
	shock_time = maxf(0.0, shock_time - delta)
	if phase == 0:
		queue_redraw()
		return
	state_time += delta
	if phase == 4:
		_update_dead(delta)
		return
	player = get_tree().get_first_node_in_group("player")
	_update_growth(delta)
	match state:
		"idle":
			_face_player()
			if state_time >= 0.9 * _pace():
				_next_step()
		"tell":
			_update_tell()
		"act":
			_update_act(delta)
		"recover":
			if state_time >= RECOVERS[attack] * _pace():
				_set_state("idle")
		"stagger":
			if state_time >= 2.4:
				open_for_hits = false
				_set_state("idle")
		"feast":
			_update_feast(delta)
		"roar":
			if state_time >= 1.0:
				_set_state("idle")
	_apply_position()
	_check_contact()
	queue_redraw()

func _face_player() -> void:
	if is_instance_valid(player):
		facing = 1 if player.global_position.x >= global_position.x else -1

func _next_step() -> void:
	if pending_phase > phase:
		if pending_phase == 2:
			_begin_feast()
		else:
			_begin_roar()
		return
	var sequence: Array = SEQUENCES[phase]
	attack = sequence[attack_index % sequence.size()]
	attack_index += 1
	_face_player()
	if attack == "slam" and is_instance_valid(player):
		slam_target_x = player.global_position.x
	_set_state("tell")

func _update_tell() -> void:
	_face_player()
	# The slam marker follows Lumi at first, then locks so it can be dodged.
	if attack == "slam" and is_instance_valid(player) and state_time < TELLS[attack] * 0.55:
		slam_target_x = player.global_position.x
	if state_time >= TELLS[attack] * _pace():
		_begin_act()

func _begin_act() -> void:
	_set_state("act")
	match attack:
		"coin_rain":
			rain_left = 5 if phase == 1 else (7 if phase == 2 else 8)
			rain_timer = 0.0
		"slam":
			slam_start_x = global_position.x
			slam_target_x = clampf(slam_target_x, arena_left + 90.0, arena_right - 90.0)
		"spit":
			spit_fired = false
		"grab":
			grab_resolved = false
			_face_player()

func _update_act(delta: float) -> void:
	match attack:
		"coin_rain":
			rain_timer -= delta
			if rain_left > 0:
				if rain_timer <= 0.0:
					_drop_coin(rain_left % 2 == 0)
					rain_left -= 1
					rain_timer = 0.2 * _pace()
			elif rain_timer <= 0.0:
				_finish_attack()
		"slam":
			_update_slam()
		"spit":
			if not spit_fired and state_time >= 0.2:
				spit_fired = true
				_spit_coins()
			if state_time >= 0.5:
				_finish_attack()
		"grab":
			_update_grab(delta)

func _update_slam() -> void:
	var t := state_time
	if t < 0.45:
		var k := clampf(t / 0.45, 0.0, 1.0)
		air_offset = -150.0 * sin(k * PI * 0.5)
		global_position.x = lerpf(slam_start_x, slam_target_x, k)
	elif t < 0.6:
		air_offset = -150.0
		global_position.x = slam_target_x
	else:
		air_offset = 0.0
		_do_slam()
		_finish_attack()

func _do_slam() -> void:
	shock_time = 0.35
	_shake(1.4, 0.22)
	if not is_instance_valid(player) or not player.has_method("take_damage"):
		return
	var reach := 120.0 * body_size
	var dx := absf(player.global_position.x - global_position.x)
	# Only grounded Lumi is hit: jump (or double jump) to clear the shockwave.
	if dx < reach and player.global_position.y > GROUND_Y - 80.0:
		player.take_damage(1)

func _update_grab(delta: float) -> void:
	var r := BODY_RADIUS * body_size
	global_position.x = clampf(global_position.x + facing * 560.0 * delta,
		arena_left + r, arena_right - r)
	if not grab_resolved and is_instance_valid(player):
		var dx := absf(player.global_position.x - global_position.x)
		var dy := absf(player.global_position.y - global_position.y)
		if dx < 90.0 * body_size and dy < 90.0 * body_size:
			var gold := 0
			if is_instance_valid(greed):
				gold = int(greed.get("carried_gold"))
			# He grabs low: a well-timed jump avoids the steal. With empty
			# hands there is nothing to avoid, so the grab whiffs wherever Lumi is.
			if gold <= 0 or player.global_position.y > GROUND_Y - 60.0:
				_resolve_grab(gold)
				return
	if state_time >= 0.5:
		_finish_attack()

func _resolve_grab(gold: int) -> void:
	grab_resolved = true
	if gold > 0:
		var stolen := int(greed.call("steal_all_gold"))
		health = mini(MAX_HEALTH, health + int(stolen * 1.5))
		health_changed.emit(health, MAX_HEALTH)
		gold_stolen.emit(stolen)
		if player.has_method("take_damage"):
			player.take_damage(1)
		_finish_attack()
	else:
		# Empty hands are the safest hands: he grabs nothing and is left open.
		grab_whiffed.emit()
		open_for_hits = true
		_set_state("stagger")

func _finish_attack() -> void:
	air_offset = 0.0
	_set_state("recover")

func _drop_coin(near_player: bool) -> void:
	var x := randf_range(arena_left + 40.0, arena_right - 40.0)
	if near_player and is_instance_valid(player):
		x = clampf(player.global_position.x + randf_range(-130.0, 130.0),
			arena_left + 30.0, arena_right - 30.0)
	_spawn_coin(Vector2(x, 300.0), Vector2(0, 40))

func _spit_coins() -> void:
	var origin := global_position + Vector2(facing * 50.0 * body_size, -40.0 * body_size)
	var target_x := origin.x + facing * 260.0
	if is_instance_valid(player):
		target_x = player.global_position.x
	for offset in [-110.0, 0.0, 110.0]:
		var sx := clampf((target_x + offset - origin.x) / 0.95, -420.0, 420.0)
		_spawn_coin(origin, Vector2(sx, -300.0))

func _spawn_coin(at: Vector2, start_velocity: Vector2) -> void:
	var coin := Node2D.new()
	coin.set_script(COIN_SCRIPT)
	coin.set("velocity", start_velocity)
	get_parent().add_child(coin)
	coin.global_position = at

func _update_growth(delta: float) -> void:
	if phase < 2 or state == "feast":
		return
	var gold := 0
	if is_instance_valid(greed):
		gold = int(greed.get("carried_gold"))
	# Carrying more gold feeds him faster.
	var rate := 0.006 + clampf(gold / 80.0, 0.0, 1.0) * 0.035
	body_size = minf(MAX_SIZE, body_size + rate * delta)

func _begin_feast() -> void:
	pending_phase = 0
	phase = 2
	attack_index = 0
	_set_state("feast")
	phase_changed.emit(2)

func _update_feast(delta: float) -> void:
	var dx := mountain_x - global_position.x
	if state_time < 1.4 and absf(dx) > 6.0:
		global_position.x += signf(dx) * minf(absf(dx), 230.0 * delta)
	if state_time >= 1.2 and not swallowed:
		swallowed = true
		mountain_swallowed.emit()
	if state_time >= 1.2 and state_time < 2.4:
		body_size = minf(MAX_SIZE, body_size + 0.22 * delta / 1.2)
	if state_time >= 2.6:
		_set_state("idle")

func _begin_roar() -> void:
	pending_phase = 0
	phase = 3
	attack_index = 0
	_set_state("roar")
	_shake(1.0, 0.3)
	phase_changed.emit(3)

func _apply_position() -> void:
	var r := BODY_RADIUS * body_size
	scale = Vector2.ONE * body_size
	var x := clampf(global_position.x, arena_left + r, arena_right - r)
	global_position = Vector2(x, GROUND_Y - r + air_offset)

func _check_contact() -> void:
	if contact_cooldown > 0.0 or state == "feast" or state == "roar":
		return
	if not is_instance_valid(player) or air_offset < -40.0:
		return
	if global_position.distance_to(player.global_position) < BODY_RADIUS * body_size * 0.85:
		if player.has_method("take_damage"):
			player.take_damage(1)
			contact_cooldown = 1.2

func take_damage(amount: int) -> void:
	var untouchable := state == "feast" or state == "roar" or air_offset < -20.0
	if phase == 0 or phase == 4 or hurt_cooldown > 0.0 or untouchable:
		return
	var dealt := int(round(amount * (1.5 if open_for_hits else 1.0)))
	_lose_health(dealt)
	hurt_cooldown = 0.2

func take_offering(gold: int) -> void:
	# Gold dropped in an offering bowl hurts him and makes him smaller.
	if phase == 0 or phase == 4:
		return
	_lose_health(int(gold * 1.2))
	if phase >= 2:
		body_size = maxf(1.0, body_size - gold / 10.0 * 0.04)

func _lose_health(amount: int) -> void:
	health = maxi(0, health - amount)
	health_changed.emit(health, MAX_HEALTH)
	if health <= 0:
		_defeat()
	elif phase == 1 and health <= MAX_HEALTH * 0.66:
		pending_phase = 2
	elif phase == 2 and health <= MAX_HEALTH * 0.33:
		pending_phase = 3

func _defeat() -> void:
	phase = 4
	air_offset = 0.0
	dead_time = 0.0
	_set_state("dead")
	for child in get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)
	defeated.emit()

func _update_dead(delta: float) -> void:
	# He shrinks into a tiny crying bear holding one coin, then fades quietly.
	dead_time += delta
	body_size = lerpf(body_size, 0.32, 1.0 - exp(-2.2 * delta))
	if dead_time > 7.0:
		modulate.a = maxf(0.0, 1.0 - (dead_time - 7.0) / 1.5)
	if dead_time > 8.6:
		queue_free()
		return
	_apply_position()
	queue_redraw()

func _shake(intensity: float, duration: float) -> void:
	var feedback := get_tree().get_first_node_in_group("combat_feedback")
	if is_instance_valid(feedback):
		feedback.call("screenshake", intensity, duration)

func _draw() -> void:
	var honey := Color(0.94, 0.78, 0.31)
	var light := Color(1.0, 0.9, 0.58)
	var dark := Color(0.72, 0.55, 0.2)
	if hurt_cooldown > 0.0 and int(Time.get_ticks_msec() / 70) % 2 == 0:
		honey = Color(1.0, 0.96, 0.85)
	var ground_local := (GROUND_Y - global_position.y) / body_size
	# Soft shadow on the ground.
	var shadow := PackedVector2Array()
	for i in range(20):
		var a := TAU * i / 20.0
		shadow.append(Vector2(cos(a) * 62.0, ground_local + sin(a) * 8.0))
	draw_colored_polygon(shadow, Color(0.3, 0.2, 0.05, 0.22))
	var raised := (attack == "coin_rain" and (state == "tell" or state == "act"))
	var reaching := (attack == "grab" and (state == "tell" or state == "act"))
	# Arms.
	if reaching:
		var reach := 82.0 + (24.0 if state == "act" else 0.0)
		draw_line(Vector2(facing * 40, 4), Vector2(facing * reach, -2), dark, 14.0)
		draw_circle(Vector2(facing * reach, -2), 17, honey)
		draw_circle(Vector2(-facing * 62, 18), 16, honey)
	elif raised:
		draw_circle(Vector2(-62, -46), 16, honey)
		draw_circle(Vector2(62, -46), 16, honey)
	else:
		draw_circle(Vector2(-64, 18), 16, honey)
		draw_circle(Vector2(64, 18), 16, honey)
	# Body, belly, head, ears.
	draw_circle(Vector2.ZERO, BODY_RADIUS, honey)
	draw_circle(Vector2(0, 14), 44, light)
	draw_circle(Vector2(-34, -92), 15, honey)
	draw_circle(Vector2(34, -92), 15, honey)
	draw_circle(Vector2(-34, -92), 8, dark)
	draw_circle(Vector2(34, -92), 8, dark)
	draw_circle(Vector2(0, -62), 40, honey)
	draw_circle(Vector2(0, -52), 17, light)
	# Tiny crown.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-17, -98), Vector2(-20, -118), Vector2(-9, -108), Vector2(0, -122),
		Vector2(9, -108), Vector2(20, -118), Vector2(17, -98)
	]), Color(0.98, 0.82, 0.25))
	draw_arc(Vector2(0, -98), 17.0, PI, TAU, 10, dark, 2.0)
	# Face.
	var eyes_open := phase != 0
	for side in [-1, 1]:
		var eye := Vector2(side * 15, -68)
		if eyes_open:
			draw_circle(eye, 4.5, Color(0.2, 0.14, 0.1))
		else:
			draw_line(eye - Vector2(5, 0), eye + Vector2(5, 0), Color(0.2, 0.14, 0.1), 2.0)
	draw_circle(Vector2(0, -56), 5.0, Color(0.3, 0.18, 0.1))
	var sad := phase == 4 or (phase >= 1 and health < MAX_HEALTH * 0.33)
	if sad:
		draw_arc(Vector2(0, -38), 11.0, PI + 0.4, TAU - 0.4, 10, Color(0.3, 0.18, 0.1), 2.0)
		for side in [-1, 1]:
			var drip := fmod(Time.get_ticks_msec() * 0.05 + side * 7.0, 26.0)
			draw_circle(Vector2(side * 15, -62 + drip), 2.8, Color(0.6, 0.82, 1.0, 0.85))
	else:
		draw_arc(Vector2(0, -44), 11.0, 0.3, PI - 0.3, 10, Color(0.3, 0.18, 0.1), 2.0)
	if phase == 4:
		# The one coin he keeps.
		draw_circle(Vector2(26, 22), 11, Color(0.98, 0.82, 0.25))
		draw_circle(Vector2(26, 22), 6, Color(1.0, 0.93, 0.55))
	# Slam shockwave.
	if shock_time > 0.0:
		var ring := (1.0 - shock_time / 0.35) * 150.0
		draw_arc(Vector2(0, ground_local - 4), 40.0 + ring, PI, TAU, 24,
			Color(1.0, 0.88, 0.4, shock_time / 0.35), 5.0)
	_draw_telegraph(ground_local)
	if phase >= 1 and phase <= 3:
		_draw_health_bar()

func _draw_telegraph(ground_local: float) -> void:
	if state != "tell":
		return
	var warn := Color(1.0, 0.82, 0.45, 0.75 + sin(Time.get_ticks_msec() * 0.02) * 0.2)
	match attack:
		"coin_rain":
			for i in range(5):
				draw_circle(Vector2(-60 + i * 30, -150 - (i % 2) * 14), 5, warn)
		"slam":
			var marker_x := (slam_target_x - global_position.x) / body_size
			var ring := PackedVector2Array()
			for i in range(25):
				var a := TAU * i / 24.0
				ring.append(Vector2(marker_x + cos(a) * 120.0, ground_local - 3 + sin(a) * 12.0))
			draw_polyline(ring, warn, 4.0)
		"spit":
			draw_circle(Vector2(facing * 52, -44), 12, warn)
		"grab":
			draw_line(Vector2(facing * 90, -4), Vector2(facing * 230, -4), warn, 5.0)
			draw_line(Vector2(facing * 230, -4), Vector2(facing * 205, -22), warn, 5.0)
			draw_line(Vector2(facing * 230, -4), Vector2(facing * 205, 14), warn, 5.0)

func _draw_health_bar() -> void:
	# Keep the bar a fixed size on screen no matter how big he grows.
	draw_set_transform(Vector2(0, -150), 0.0, Vector2.ONE / body_size)
	draw_rect(Rect2(-60, 0, 120, 8), Color(0.2, 0.18, 0.25, 0.85))
	var fill := float(health) / float(MAX_HEALTH) * 120.0
	var bar_color := Color(0.95, 0.8, 0.35) if phase < 3 else Color(0.9, 0.55, 0.3)
	draw_rect(Rect2(-60, 0, fill, 8), bar_color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
