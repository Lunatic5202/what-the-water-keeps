extends Node2D
# Tempo Style (Hourglass Shard). First playable pass from game-bible section 4.4.
# The pulse timing and damage values are intentionally easy to tune.
const BEAT_PERIOD := 0.75
const BEAT_WINDOW := 0.12
const COMBO_DAMAGE := [6, 6, 8, 14]
const HEAVY_DAMAGE := 28
const AIR_DAMAGE := 12
const GUARD_TIME := 0.25
const PERFECT_WINDOW := 0.12
const GUARD_COOLDOWN := 0.7
const STOPWATCH_COST := 30.0
const PEARL := Color(0.76, 0.88, 1.0)

var player: Node
var area: Area2D
var area_shape: CircleShape2D
var beat_time := 0.0
var combo_step := 0
var combo_timer := 0.0
var swing_timer := 0.0
var swing_damage := 0
var hit_ids := {}
var recover_timer := 0.0
var guard_timer := 0.0
var guard_age := 0.0
var guard_cooldown := 0.0
var charging := false
var charge_time := 0.0
var strike_delay := -1.0
var effects: Array[Dictionary] = []
var slow_generation := 0

func _ready() -> void:
	player = get_parent()
	area = Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 3
	area.monitoring = false
	var shape := CollisionShape2D.new()
	area_shape = CircleShape2D.new()
	area_shape.radius = 42.0
	shape.shape = area_shape
	area.add_child(shape)
	add_child(area)

func _active() -> bool:
	return is_instance_valid(player) and float(player.get("asleep_timer")) <= 0.0 and player.get("style") == "tempo"

func _physics_process(delta: float) -> void:
	beat_time = fmod(beat_time + delta, BEAT_PERIOD)
	combo_timer = maxf(0.0, combo_timer - delta)
	recover_timer = maxf(0.0, recover_timer - delta)
	guard_cooldown = maxf(0.0, guard_cooldown - delta)
	_tick_effects(delta)
	if not _active():
		area.set_deferred("monitoring", false)
		charging = false
		strike_delay = -1.0
		guard_timer = 0.0
		queue_redraw()
		return
	if strike_delay >= 0.0:
		strike_delay -= delta
		if strike_delay <= 0.0:
			_start_swing("heavy")
	if swing_timer > 0.0:
		swing_timer -= delta
		for body in area.get_overlapping_bodies():
			_hit(body)
		if swing_timer <= 0.0:
			area.set_deferred("monitoring", false)
			recover_timer = 0.16
			if combo_step > 0:
				combo_timer = 0.55
	if guard_timer > 0.0:
		guard_age += delta
		guard_timer -= delta
		if guard_timer <= 0.0:
			guard_cooldown = GUARD_COOLDOWN
	if strike_delay < 0.0 and swing_timer <= 0.0 and recover_timer <= 0.0:
		_read_input(delta)
	queue_redraw()

func _read_input(delta: float) -> void:
	if charging:
		charge_time = minf(2.0, charge_time + delta)
		if not Input.is_action_pressed("heavy"):
			charging = false
			strike_delay = 1.0
			player.emit_signal("status_changed", "HOUR STRIKE: THE NEXT SECOND IS YOURS.")
		return
	if Input.is_action_just_pressed("attack"):
		if not player.is_on_floor():
			_start_swing("air")
		else:
			combo_step = (combo_step % 4) + 1 if combo_timer > 0.0 else 1
			_start_swing("combo")
	elif Input.is_action_just_pressed("heavy") and player.is_on_floor():
		charging = true
		charge_time = 0.0
	elif Input.is_action_just_pressed("skill"):
		_stopwatch()
	elif Input.is_action_just_pressed("guard") and guard_cooldown <= 0.0:
		guard_timer = GUARD_TIME
		guard_age = 0.0

func _on_beat() -> bool:
	return beat_time <= BEAT_WINDOW or beat_time >= BEAT_PERIOD - BEAT_WINDOW

func _start_swing(kind: String) -> void:
	var facing := int(player.call("attack_facing"))
	hit_ids.clear()
	var damage: int = AIR_DAMAGE if kind == "air" else (HEAVY_DAMAGE if kind == "heavy" else COMBO_DAMAGE[combo_step - 1])
	var on_beat := _on_beat()
	if on_beat:
		damage = int(ceil(float(damage) * 1.3))
	swing_damage = damage
	var attack_speed := maxf(0.01, float(player.get("attack_speed_mod")))
	swing_timer = (0.18 if kind != "heavy" else 0.28) / attack_speed
	area_shape.radius = 46.0 if kind == "heavy" else 38.0
	if kind == "air":
		area.position = Vector2(0, 26)
	elif kind == "heavy":
		area.position = Vector2(0, -43)
	else:
		area.position = Vector2(38.0 * facing, -8.0)
	area.set_deferred("monitoring", true)
	player.call("add_glow", 3.0 + (3.0 if on_beat else 0.0))
	player.emit_signal("status_changed", "ON THE BEAT! +30% DAMAGE, +3 GLOW." if on_beat else "TICK-TOCK %d/4" % maxi(combo_step, 1))

func _hit(body: Node2D) -> void:
	if body == player or not body.has_method("take_damage"):
		return
	var id := body.get_instance_id()
	if hit_ids.has(id):
		return
	hit_ids[id] = true
	body.call("take_damage", swing_damage)
	if is_instance_valid(player):
		player.call("add_glow", 2.0)
	if swing_damage >= 14 and not body.is_in_group("boss"):
		body.global_position.y -= 12.0

func _stopwatch() -> void:
	if not player.call("spend_glow", STOPWATCH_COST):
		player.emit_signal("status_changed", "STOPWATCH NEEDS 30 GLOW.")
		return
	var frozen := 0
	for body in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(body) or body.is_in_group("boss"):
			continue
		if body.has_method("stun"):
			body.call("stun", 1.5)
			frozen += 1
	player.emit_signal("status_changed", "STOPWATCH: %d ENEMIES CAUGHT IN THE PAUSE." % frozen)

func block_hit() -> bool:
	if guard_timer <= 0.0:
		return false
	if guard_age <= PERFECT_WINDOW:
		_perfect_guard()
	return true

func _perfect_guard() -> void:
	guard_timer = 0.0
	guard_cooldown = GUARD_COOLDOWN
	player.call("add_glow", 10.0)
	var facing := int(player.call("attack_facing"))
	var countered := 0
	for body in _nearby_targets(90.0):
		if body.has_method("take_damage"):
			body.call("take_damage", 20)
			countered += 1
	player.emit_signal("status_changed", "PERFECT BEAT. COUNTER SLASH: 20 DAMAGE.")
	_slow_world()

func _nearby_targets(radius: float) -> Array[Node2D]:
	var found: Array[Node2D] = []
	var params := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	params.shape = circle
	params.transform = Transform2D(0.0, player.global_position)
	params.collision_mask = 3
	for hit in player.get_world_2d().direct_space_state.intersect_shape(params, 32):
		var body := hit["collider"] as Node2D
		if body != player and body.has_method("take_damage"):
			found.append(body)
	return found

func _slow_world() -> void:
	slow_generation += 1
	var generation := slow_generation
	Engine.time_scale = 0.35
	await get_tree().create_timer(1.0, true, false, true).timeout
	if generation == slow_generation:
		Engine.time_scale = 1.0

func _tick_effects(delta: float) -> void:
	for i in range(effects.size() - 1, -1, -1):
		effects[i]["t"] += delta
		if effects[i]["t"] >= effects[i]["dur"]:
			effects.remove_at(i)

func _draw() -> void:
	if not _active():
		return
	var lantern := Vector2(19.0 * int(player.get("facing")), -7.0)
	var beat_strength := 1.0 - clampf(minf(beat_time, BEAT_PERIOD - beat_time) / BEAT_WINDOW, 0.0, 1.0)
	draw_arc(lantern, 12.0 + beat_strength * 8.0, 0.0, TAU, 32, Color(PEARL, 0.35 + beat_strength * 0.65), 2.0)
	draw_arc(lantern, 20.0 + beat_strength * 10.0, 0.0, TAU, 32, Color(PEARL, 0.18 + beat_strength * 0.35), 1.0)
	if guard_timer > 0.0:
		draw_arc(lantern, 30.0, 0.0, TAU, 32, Color(0.78, 0.9, 1.0, 0.8), 3.0)
