extends Node2D
# Lantern Swing's extra moves (bible 4.3): heavy, Lantern Flash, guard and
# Warm Light. The J swing itself still lives in player.gd. Acts only while
# player.style is "lantern". Numbers are guesses.

const HEAVY_DAMAGE := 22
const HEAVY_WINDUP := 0.28
const HEAVY_RECOVER := 0.2
const FLASH_COST := 30.0
const FLASH_DAMAGE := 6
const FLASH_RADIUS := 150.0
const FLASH_STUN := 1.5
const OVERTURE_COST := 100.0
const OVERTURE_DAMAGE := 40
const OVERTURE_RADIUS := 260.0
const GUARD_TIME := 0.25
const PERFECT_WINDOW := 0.12
const GUARD_COOLDOWN := 0.5
const WARM := Color(1.0, 0.9, 0.6)

var player: Node
var windup := 0.0
var recover := 0.0
var guard_timer := 0.0
var guard_age := 0.0
var guard_cooldown := 0.0
var perfect_used := false
var effects: Array = []

func _ready() -> void:
	player = get_parent()

func _active() -> bool:
	return is_instance_valid(player) and player.get("style") == "lantern"

func _busy() -> bool:
	return windup > 0.0 or recover > 0.0 or guard_timer > 0.0

func _physics_process(delta: float) -> void:
	_tick_effects(delta)
	if not _active():
		windup = 0.0
		recover = 0.0
		guard_timer = 0.0
		queue_redraw()
		return
	guard_cooldown = maxf(0.0, guard_cooldown - delta)
	recover = maxf(0.0, recover - delta)
	if windup > 0.0:
		windup -= delta
		if windup <= 0.0:
			_heavy_hit()
	if guard_timer > 0.0:
		guard_age += delta
		guard_timer -= delta
		if guard_timer <= 0.0:
			guard_cooldown = GUARD_COOLDOWN
	if not _busy():
		if Input.is_action_just_pressed("heavy") and player.is_on_floor():
			windup = HEAVY_WINDUP
			player.emit_signal("status_changed", "HEAVY SWING...")
		elif Input.is_action_just_pressed("skill"):
			_flash()
		elif Input.is_action_just_pressed("guard") and guard_cooldown <= 0.0:
			guard_timer = GUARD_TIME
			guard_age = 0.0
			perfect_used = false
		elif Input.is_action_just_pressed("overture"):
			_overture()
	queue_redraw()

func _bodies_near(at: Vector2, radius: float) -> Array[Node2D]:
	var found: Array[Node2D] = []
	var params := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	params.shape = circle
	params.transform = Transform2D(0.0, at)
	params.collision_mask = 3
	for hit in get_world_2d().direct_space_state.intersect_shape(params, 32):
		var body: Node2D = hit["collider"]
		if body != player and body.has_method("take_damage"):
			found.append(body)
	return found

func _push(body: Node2D, dir: float, amount: float) -> void:
	if is_instance_valid(body) and not body.is_in_group("boss"):
		body.global_position.x += dir * amount

func _heavy_hit() -> void:
	var f := float(player.get("facing"))
	var at: Vector2 = player.global_position + Vector2(52.0 * f, -8.0)
	for body in _bodies_near(at, 62.0):
		body.take_damage(HEAVY_DAMAGE)
		player.call("add_glow", 8.0)
		_push(body, f, 70.0)
		var feedback := get_tree().get_first_node_in_group("combat_feedback")
		if is_instance_valid(feedback):
			feedback.call("apply_hit_freeze", 8)
			feedback.call("screenshake", 0.9, 0.12)
	effects.append({"pos": to_local(at), "t": 0.0, "dur": 0.25, "max": 62.0})
	recover = HEAVY_RECOVER

func _flash() -> void:
	if not player.call("spend_glow", FLASH_COST):
		player.emit_signal("status_changed", "NOT ENOUGH GLOW.")
		return
	for body in _bodies_near(player.global_position, FLASH_RADIUS):
		body.take_damage(FLASH_DAMAGE)
		if body.has_method("stun") and not body.is_in_group("boss"):
			body.call("stun", FLASH_STUN)
	effects.append({"pos": Vector2(0, -10), "t": 0.0, "dur": 0.4, "max": FLASH_RADIUS})
	recover = 0.25
	player.emit_signal("status_changed", "LANTERN FLASH!")

func _overture() -> void:
	if not player.call("spend_glow", OVERTURE_COST):
		player.emit_signal("status_changed", "NOT ENOUGH GLOW.")
		return
	for body in _bodies_near(player.global_position, OVERTURE_RADIUS):
		body.take_damage(OVERTURE_DAMAGE)
		var dir := signf(body.global_position.x - player.global_position.x)
		_push(body, dir if dir != 0.0 else 1.0, 120.0)
	effects.append({"pos": Vector2(0, -10), "t": 0.0, "dur": 0.8, "max": OVERTURE_RADIUS})
	recover = 0.5
	player.emit_signal("status_changed", "WARM LIGHT.")

# Called by player.take_damage. Returns true if the hit was absorbed.
func block_hit() -> bool:
	if guard_timer <= 0.0:
		return false
	if guard_age <= PERFECT_WINDOW and not perfect_used:
		perfect_used = true
		player.call("add_glow", 10.0)
		effects.append({"pos": Vector2(20.0 * float(player.get("facing")), -10.0), "t": 0.0, "dur": 0.3, "max": 40.0})
		player.emit_signal("status_changed", "PERFECT GUARD.")
	return true

func _tick_effects(delta: float) -> void:
	var alive := []
	for e in effects:
		e["t"] = float(e["t"]) + delta
		if float(e["t"]) < float(e["dur"]):
			alive.append(e)
	effects = alive
	if not effects.is_empty():
		queue_redraw()

func _draw() -> void:
	if not is_instance_valid(player):
		return
	if windup > 0.0:
		var c := 1.0 - windup / HEAVY_WINDUP
		draw_arc(Vector2(0, -10), 12.0 + c * 22.0, 0.0, TAU, 24, Color(WARM, 0.4 + 0.5 * c), 3.0)
	if guard_timer > 0.0:
		var bright := 1.0 if guard_age <= PERFECT_WINDOW else 0.55
		var f := int(player.get("facing"))
		var a := Vector2(-0.9, 0.9) if f > 0 else Vector2(PI - 0.9, PI + 0.9)
		draw_arc(Vector2(18.0 * f, -10.0), 24.0, a.x, a.y, 14, Color(WARM, bright), 6.0)
	for e in effects:
		var t := float(e["t"]) / float(e["dur"])
		var r := float(e["max"]) * ease(t, 0.35)
		draw_circle(e["pos"], r, Color(WARM, (1.0 - t) * 0.18))
		draw_arc(e["pos"], r, 0.0, TAU, 40, Color(WARM, 1.0 - t), 6.0)
