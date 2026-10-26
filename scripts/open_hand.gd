extends Node2D
# The Open Hand (Offering Style), bible part 4.4 move 1.
# Lives under Lumi as "OpenHand" and acts only while player.style is
# "open_hand". Coin amounts spent per move are guesses (marked TUNE).

const PalmShot := preload("res://scripts/palm_shot.gd")

const COIN := 10                  # gold per coin, same as collector_coin.gd
const MAX_OFFER := 10             # most bonus damage Offer can add
const SWING_TIME := 0.26          # slow palm waves
const RECOVER_TIME := 0.12
const COMBO_WINDOW := 0.5
const EMPTY_PURSE_SPEED := 0.85   # empty purse: 15 percent faster
const LIGHT_DAMAGE := [7, 7, 10]
const SHOCKWAVE_DAMAGE := 6
const SHOCKWAVE_SPEED := 600.0
const SHOCKWAVE_RANGE := 192.0    # 3 tiles of 64px
const HEAVY_CHARGE := 0.6
const HEAVY_DAMAGE := 24
const AIR_DAMAGE := 14
const DASH_DAMAGE := 8
const SKILL_COST := 20.0
const OVERTURE_COST := 100.0
const OVERTURE_DAMAGE := 12
const GUARD_TIME := 0.25
const PERFECT_WINDOW := 0.12
const GUARD_COOLDOWN := 0.5
const REFLECT_DAMAGE := 2         # 1 x 150 percent, rounded up
const LIGHT_COINS := 2            # TUNE
const HEAVY_COINS := 10           # TUNE
const TOSS_COINS := 5
const PEACH := Color(1.0, 0.85, 0.75)
const GOLD := Color(1.0, 0.82, 0.35)

var player: Node
var area: Area2D
var area_shape: CircleShape2D
var step := 0
var combo_timer := 0.0
var swing_timer := 0.0
var swing_total := SWING_TIME
var recover_timer := 0.0
var swing_kind := ""
var swing_damage := 0
var swing_push := 0.0
var swing_glow := 3.0
var hit_ids := {}
var charging := false
var charge_time := 0.0
var guard_timer := 0.0
var guard_age := 0.0
var guard_cooldown := 0.0
var perfect_used := false
var petals_pending := false
var effects: Array = []

func _ready() -> void:
	player = get_parent()
	area = Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 3
	area.monitoring = false
	var shape := CollisionShape2D.new()
	area_shape = CircleShape2D.new()
	area_shape.radius = 44.0
	shape.shape = area_shape
	area.add_child(shape)
	add_child(area)

func _active() -> bool:
	return is_instance_valid(player) and float(player.get("asleep_timer")) <= 0.0 and player.get("style") == "open_hand"

func _facing() -> int:
	return int(player.get("facing"))

func _busy() -> bool:
	return swing_timer > 0.0 or recover_timer > 0.0 or guard_timer > 0.0

# --- Gold: the Offer ----------------------------------------------------------

func _gold_holder() -> Node:
	for node in get_tree().get_nodes_in_group("gold_holder"):
		if node.is_inside_tree() and node.get("visible") == true:
			return node
	return null

func _coins_held() -> int:
	var holder := _gold_holder()
	if holder == null:
		return 0
	return int(floor(float(holder.get("carried_gold")) / COIN))

# Spends up to max_coins from the purse. Returns how many were spent.
func _spend_coins(max_coins: int) -> int:
	var spent := mini(_coins_held(), max_coins)
	if spent > 0:
		_gold_holder().call("spend_gold", spent * COIN)
	return spent

# --- Frame loop ---------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_tick_effects(delta)
	if not _active():
		_reset()
		queue_redraw()
		return
	guard_cooldown = maxf(0.0, guard_cooldown - delta)
	combo_timer = maxf(0.0, combo_timer - delta)
	recover_timer = maxf(0.0, recover_timer - delta)
	_update_swing(delta)
	_update_guard(delta)
	_update_petals()
	_read_input(delta)
	queue_redraw()

func _reset() -> void:
	step = 0
	swing_timer = 0.0
	recover_timer = 0.0
	guard_timer = 0.0
	charging = false
	petals_pending = false
	area.set_deferred("monitoring", false)

func _read_input(delta: float) -> void:
	var on_floor: bool = player.is_on_floor()
	if charging:
		charge_time += delta
		if not Input.is_action_pressed("heavy"):
			charging = false
			if charge_time >= HEAVY_CHARGE:
				_start_swing("heavy")
			charge_time = 0.0
		return
	if _busy():
		return
	if Input.is_action_just_pressed("attack"):
		if not on_floor:
			_start_swing("air")
		elif float(player.get("dash_cooldown")) > 0.15:
			_start_swing("dash")
		else:
			_start_swing("light")
	elif Input.is_action_just_pressed("heavy") and on_floor:
		charging = true
		charge_time = 0.0
	elif Input.is_action_just_pressed("skill"):
		_coin_toss()
	elif Input.is_action_just_pressed("guard") and guard_cooldown <= 0.0:
		guard_timer = GUARD_TIME
		guard_age = 0.0
		perfect_used = false
	elif Input.is_action_just_pressed("overture"):
		_overture()

# --- Swings -------------------------------------------------------------------

func _start_swing(kind: String) -> void:
	var f := _facing()
	var purse := _coins_held()
	var speed := EMPTY_PURSE_SPEED if purse == 0 else 1.0
	swing_kind = kind
	swing_total = SWING_TIME * speed
	swing_timer = swing_total
	recover_timer = 0.0
	hit_ids.clear()
	swing_push = 0.0
	swing_glow = 3.0
	var coins := 0
	match kind:
		"light":
			step = (step % 3) + 1 if combo_timer > 0.0 else 1
			swing_damage = LIGHT_DAMAGE[step - 1]
			_place_area(Vector2(44.0 * f, -8.0), 44.0)
			coins = _spend_coins(LIGHT_COINS)
			if step == 3:
				_shockwave()
		"heavy":
			swing_damage = HEAVY_DAMAGE
			swing_push = 70.0
			swing_glow = 8.0
			swing_total = SWING_TIME * 1.4 * speed
			swing_timer = swing_total
			_place_area(Vector2(60.0 * f, -8.0), 80.0)
			coins = _spend_coins(HEAVY_COINS)
		"air":
			swing_damage = AIR_DAMAGE
			petals_pending = true
			_place_area(Vector2(0.0, 24.0), 42.0)
			coins = _spend_coins(LIGHT_COINS)
		"dash":
			swing_damage = DASH_DAMAGE
			swing_push = 60.0
			_place_area(Vector2(44.0 * f, -8.0), 46.0)
			coins = _spend_coins(LIGHT_COINS)
	swing_damage += mini(coins, MAX_OFFER)
	area.set_deferred("monitoring", true)
	player.emit_signal("status_changed", _swing_text(kind, coins))

func _swing_text(kind: String, coins: int) -> String:
	var names := {"light": "PALM PUSH", "heavy": "WIDE OFFERING", "air": "FALLING PETALS", "dash": "GENTLE RUSH"}
	var text: String = names[kind]
	if coins > 0:
		text += "  (+%d GIVEN)" % coins
	return text

func _place_area(at: Vector2, radius: float) -> void:
	area.position = at
	area_shape.radius = radius

func _update_swing(delta: float) -> void:
	if swing_timer <= 0.0:
		return
	swing_timer -= delta
	for body in area.get_overlapping_bodies():
		_hit(body)
	if swing_timer <= 0.0:
		area.set_deferred("monitoring", false)
		recover_timer = RECOVER_TIME
		combo_timer = COMBO_WINDOW if swing_kind == "light" else 0.0

func _hit(body: Node2D) -> void:
	var id := body.get_instance_id()
	if hit_ids.has(id) or body == player or not body.has_method("take_damage"):
		return
	hit_ids[id] = true
	var feedback := get_tree().get_first_node_in_group("combat_feedback")
	if is_instance_valid(feedback):
		feedback.call("apply_hit_freeze", 5)
		feedback.call("screenshake", 0.5, 0.08)
	body.take_damage(swing_damage)
	player.call("add_glow", swing_glow)
	if swing_push > 0.0:
		_push(body, float(_facing()), swing_push)

func _push(body: Node2D, dir: float, amount: float) -> void:
	if is_instance_valid(body) and not body.is_in_group("boss"):
		body.global_position.x += dir * amount

func _shockwave() -> void:
	var f := _facing()
	_spawn_shot(Vector2(30.0 * f, -8.0), Vector2(f * SHOCKWAVE_SPEED, 0.0),
		SHOCKWAVE_DAMAGE, SHOCKWAVE_RANGE / SHOCKWAVE_SPEED, 18.0, true, PEACH, 0.0)

func _spawn_shot(at: Vector2, vel: Vector2, dmg: int, life: float, radius: float,
		pierce: bool, color: Color, gravity: float) -> void:
	var shot := Area2D.new()
	shot.set_script(PalmShot)
	shot.set("velocity", vel)
	shot.set("damage", dmg)
	shot.set("life", life)
	shot.set("radius", radius)
	shot.set("pierce", pierce)
	shot.set("color", color)
	shot.set("fall_gravity", gravity)
	player.get_parent().add_child(shot)
	shot.global_position = player.global_position + at

# --- Falling Petals landing ring ---------------------------------------------

func _update_petals() -> void:
	if petals_pending and player.is_on_floor():
		petals_pending = false
		effects.append({"kind": "ring", "pos": Vector2(0, 14), "t": 0.0, "dur": 0.45, "max": 130.0})
		for body in _bodies_near(130.0):
			var dir := signf(body.global_position.x - player.global_position.x)
			_push(body, dir if dir != 0.0 else 1.0, 50.0)

func _bodies_near(radius: float) -> Array[Node2D]:
	var found: Array[Node2D] = []
	var params := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	params.shape = circle
	params.transform = Transform2D(0.0, player.global_position)
	params.collision_mask = 3
	for hit in get_world_2d().direct_space_state.intersect_shape(params, 32):
		var body: Node2D = hit["collider"]
		if body != player and body.has_method("take_damage"):
			found.append(body)
	return found

# --- Skill: Coin Toss ---------------------------------------------------------

func _coin_toss() -> void:
	if not player.call("spend_glow", SKILL_COST):
		player.emit_signal("status_changed", "NOT ENOUGH GLOW.")
		return
	var f := _facing()
	var coins := _spend_coins(TOSS_COINS)
	var count := maxi(1, coins)
	for i in range(count):
		var t := 0.0 if count == 1 else float(i) / float(count - 1) - 0.5
		var vel := Vector2(f * 520.0, t * 260.0 - 40.0)
		var color := GOLD if coins > 0 else Color(1.0, 0.95, 0.9)
		_spawn_shot(Vector2(24.0 * f, -10.0), vel, 3, 0.7, 9.0, false, color, 260.0)
	recover_timer = 0.3
	var what := "COIN TOSS (%d COINS)" % coins if coins > 0 else "SOFT ORB"
	player.emit_signal("status_changed", what)

# --- Guard: Open Palm ---------------------------------------------------------

func _update_guard(delta: float) -> void:
	if guard_timer <= 0.0:
		return
	guard_age += delta
	guard_timer -= delta
	if guard_age <= PERFECT_WINDOW:
		_reflect_spores()
	if guard_timer <= 0.0:
		guard_cooldown = GUARD_COOLDOWN

func _reflect_spores() -> void:
	var f := _facing()
	for node in get_tree().get_nodes_in_group("enemy_projectile"):
		var spore: Node2D = node
		var offset: Vector2 = spore.global_position - player.global_position
		if offset.length() > 48.0 or signf(offset.x) == -f:
			continue
		var at: Vector2 = spore.global_position - player.global_position
		spore.queue_free()
		_spawn_shot(at, Vector2(f * 360.0, 0.0), REFLECT_DAMAGE, 1.2, 10.0, false, PEACH, 0.0)
		_perfect()

func _perfect() -> void:
	if perfect_used:
		return
	perfect_used = true
	player.call("add_glow", 10.0)
	effects.append({"kind": "ring", "pos": Vector2(26.0 * _facing(), -10.0), "t": 0.0, "dur": 0.3, "max": 46.0})
	player.emit_signal("status_changed", "PERFECT. THE PALM GIVES IT BACK.")

# Called by player.take_damage. Returns true if the hit was absorbed.
func block_hit() -> bool:
	if guard_timer <= 0.0:
		return false
	if guard_age <= PERFECT_WINDOW:
		_perfect()
	return true

# --- Overture: Everything Given ----------------------------------------------

func _overture() -> void:
	if not player.call("spend_glow", OVERTURE_COST):
		player.emit_signal("status_changed", "NOT ENOUGH GLOW.")
		return
	var coins := _spend_coins(1000)
	var damage := OVERTURE_DAMAGE + coins
	var camera := get_tree().get_first_node_in_group("game_camera") as Camera2D
	var center: Vector2 = camera.get_screen_center_position() if camera else player.global_position
	var params := PhysicsShapeQueryParameters2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(1280, 720)
	params.shape = rect
	params.transform = Transform2D(0.0, center)
	params.collision_mask = 3
	var seen := {}
	for hit in get_world_2d().direct_space_state.intersect_shape(params, 64):
		var body: Node2D = hit["collider"]
		var id := body.get_instance_id()
		if seen.has(id) or body == player or not body.has_method("take_damage"):
			continue
		seen[id] = true
		body.take_damage(damage)
	effects.append({"kind": "bloom", "pos": to_local(center), "t": 0.0, "dur": 1.1, "max": 700.0})
	recover_timer = 0.5
	player.emit_signal("status_changed", "EVERYTHING GIVEN. (%d DAMAGE, %d COINS)" % [damage, coins])

# --- Drawing ------------------------------------------------------------------

func _tick_effects(delta: float) -> void:
	for e in effects:
		e["t"] = float(e["t"]) + delta
	var alive := []
	for e in effects:
		if float(e["t"]) < float(e["dur"]):
			alive.append(e)
	effects = alive
	if not effects.is_empty():
		queue_redraw()

func _arc_angles(f: int) -> Vector2:
	return Vector2(-1.0, 1.0) if f > 0 else Vector2(PI - 1.0, PI + 1.0)

func _draw() -> void:
	if not is_instance_valid(player):
		return
	var f := _facing()
	if swing_timer > 0.0:
		var p := 1.0 - swing_timer / swing_total
		var size_mult := 1.6 if swing_kind == "heavy" else 1.0
		var a := _arc_angles(f)
		var r := lerpf(24.0, 58.0, ease(p, 0.4)) * size_mult
		var center := Vector2(30.0 * f, -8.0)
		if swing_kind == "air":
			center = Vector2(0, 16)
			a = Vector2(0.3, PI - 0.3)
		draw_arc(center, r, a.x, a.y, 24, Color(PEACH, (1.0 - p) * 0.8), 8.0)
		draw_arc(center, r * 0.72, a.x, a.y, 24, Color(1, 1, 1, (1.0 - p) * 0.4), 3.0)
	if charging:
		var c := clampf(charge_time / HEAVY_CHARGE, 0.0, 1.0)
		draw_arc(Vector2(0, -10), 14.0 + c * 26.0, 0.0, TAU, 28, Color(PEACH, 0.35 + 0.5 * c), 3.0)
		if c >= 1.0:
			draw_circle(Vector2(0, -10), 8.0, Color(1, 1, 1, 0.55))
	if guard_timer > 0.0:
		var bright := 1.0 if guard_age <= PERFECT_WINDOW else 0.55
		var a := _arc_angles(f)
		draw_arc(Vector2(24.0 * f, -10.0), 24.0, a.x * 0.8, a.y * 0.8, 16, Color(1.0, 0.95, 0.85, bright), 6.0)
	for e in effects:
		var t := float(e["t"]) / float(e["dur"])
		var pos: Vector2 = e["pos"]
		var radius := float(e["max"]) * ease(t, 0.35)
		if e["kind"] == "ring":
			draw_arc(pos, radius, 0.0, TAU, 32, Color(PEACH, 1.0 - t), 5.0)
		else:
			draw_arc(pos, radius, 0.0, TAU, 48, Color(PEACH, (1.0 - t) * 0.8), 10.0)
			for i in range(28):
				var spot := pos + Vector2(fposmod(i * 131.0, 1200.0) - 600.0, fposmod(i * 71.0, 640.0) - 320.0)
				var bloom := clampf(t * 3.0 - float(i % 7) * 0.12, 0.0, 1.0)
				draw_circle(spot, 14.0 * bloom, Color(1.0, 0.8, 0.85, (1.0 - t) * 0.85))
				draw_circle(spot, 5.0 * bloom, Color(1.0, 0.95, 0.5, 1.0 - t))
