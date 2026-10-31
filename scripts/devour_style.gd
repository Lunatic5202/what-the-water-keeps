extends Node2D
# Devour Style (The Hollow Spoon). First playable pass from game-bible section
# 4.4, "3. DEVOUR STYLE". Close range and hungry.
# Taste: absorb enemy projectiles into up to 3 Pips. A fourth makes Lumi Stuffed
# for 1.5 seconds (can't act). Pips are ammo for Spit.
# Built here: Scoop (J x3: 9/9/13), Gulp (hold K 0.4s: 26 and swallows enemies
# under 20 HP as a Pip), Spit (L: 15 Glow, fires Pips, 3 Pips = one beam of 45),
# Open Wide (I: absorbs one projectile, no melee) and absorbing projectiles with
# the Scoop. NOT built yet: Slurp Drop, Chomp Dash, the Overture.

const COMBO_DAMAGE := [9, 9, 13]
const GULP_DAMAGE := 26
const GULP_HOLD := 0.4
const SPIT_COST := 15.0
const SPIT_DAMAGE := 12
const BEAM_DAMAGE := 45
const MAX_PIPS := 3
const STUFFED_TIME := 1.5
const GUARD_TIME := 0.5
const GUARD_COOLDOWN := 0.8
const TASTE := Color(0.62, 0.9, 0.78)

var player: Node
var area: Area2D
var area_shape: CircleShape2D
var pips := 0
var combo_step := 0
var combo_timer := 0.0
var swing_timer := 0.0
var swing_damage := 0
var recover_timer := 0.0
var hit_ids := {}
var holding := false
var hold_time := 0.0
var guard_timer := 0.0
var guard_cooldown := 0.0
var stuffed_timer := 0.0
var shots: Array[Dictionary] = []   # visual only: {from, to, t, dur, width}

func _ready() -> void:
	player = get_parent()
	area = Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 3
	area.monitoring = false
	var shape := CollisionShape2D.new()
	area_shape = CircleShape2D.new()
	area_shape.radius = 30.0
	shape.shape = area_shape
	area.add_child(shape)
	add_child(area)

func _active() -> bool:
	return is_instance_valid(player) and float(player.get("asleep_timer")) <= 0.0 and player.get("style") == "devour"

func _physics_process(delta: float) -> void:
	combo_timer = maxf(0.0, combo_timer - delta)
	recover_timer = maxf(0.0, recover_timer - delta)
	guard_cooldown = maxf(0.0, guard_cooldown - delta)
	for i in range(shots.size() - 1, -1, -1):
		shots[i]["t"] += delta
		if shots[i]["t"] >= shots[i]["dur"]:
			shots.remove_at(i)
	if not _active():
		area.set_deferred("monitoring", false)
		holding = false
		guard_timer = 0.0
		queue_redraw()
		return
	if stuffed_timer > 0.0:
		stuffed_timer -= delta
		queue_redraw()
		return
	if swing_timer > 0.0:
		swing_timer -= delta
		for body in area.get_overlapping_bodies():
			_hit(body)
		_absorb_in_reach(area.global_position, 40.0)
		if swing_timer <= 0.0:
			area.set_deferred("monitoring", false)
			recover_timer = 0.14
			combo_timer = 0.55
	if guard_timer > 0.0:
		guard_timer -= delta
		_absorb_in_reach(player.global_position, 46.0, 1)
	if swing_timer <= 0.0 and recover_timer <= 0.0:
		_read_input(delta)
	queue_redraw()

func _read_input(delta: float) -> void:
	if holding:
		hold_time += delta
		if not Input.is_action_pressed("heavy"):
			holding = false
			if hold_time >= GULP_HOLD:
				_gulp()
			hold_time = 0.0
		return
	if Input.is_action_just_pressed("attack"):
		combo_step = (combo_step % 3) + 1 if combo_timer > 0.0 else 1
		_scoop()
	elif Input.is_action_just_pressed("heavy"):
		holding = true
		hold_time = 0.0
	elif Input.is_action_just_pressed("skill"):
		_spit()
	elif Input.is_action_just_pressed("guard") and guard_cooldown <= 0.0:
		guard_timer = GUARD_TIME
		guard_cooldown = GUARD_COOLDOWN
		player.emit_signal("status_changed", "OPEN WIDE.")

func _scoop() -> void:
	var facing := int(player.call("attack_facing"))
	hit_ids.clear()
	swing_damage = COMBO_DAMAGE[combo_step - 1]
	swing_timer = 0.16
	area_shape.radius = 30.0
	area.position = Vector2(30.0 * facing, -6.0)
	area.set_deferred("monitoring", true)
	player.emit_signal("status_changed", "SCOOP %d/3 (%d)" % [combo_step, swing_damage])

func _hit(body: Node2D) -> void:
	if body == player or not body.has_method("take_damage"):
		return
	var id := body.get_instance_id()
	if hit_ids.has(id):
		return
	hit_ids[id] = true
	body.call("take_damage", swing_damage)
	player.call("add_glow", 2.0)
	# The third scoop pulls ordinary enemies in a little.
	if combo_step == 3 and not body.is_in_group("boss"):
		var toward := signf(player.global_position.x - body.global_position.x)
		body.global_position.x += toward * 40.0

func _gulp() -> void:
	var facing := int(player.call("attack_facing"))
	var spot: Vector2 = player.global_position + Vector2(40.0 * facing, -6.0)
	var swallowed := false
	for body in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(body) or body.is_in_group("boss") or body.global_position.distance_to(spot) > 58.0:
			continue
		if body.has_method("take_damage"):
			var hp: int = int(body.get("health")) if body.get("health") != null else 99
			body.call("take_damage", GULP_DAMAGE)
			if hp < 20 and not swallowed:
				swallowed = true
				_add_pip()
	for body in get_tree().get_nodes_in_group("boss"):
		if is_instance_valid(body) and body.global_position.distance_to(spot) < 120.0 and body.has_method("take_damage"):
			body.call("take_damage", GULP_DAMAGE)
	recover_timer = 0.3
	shots.append({"from": spot, "to": spot, "t": 0.0, "dur": 0.25, "width": 40.0})
	player.emit_signal("status_changed", "GULP! (%d)%s" % [GULP_DAMAGE, "  A PIP." if swallowed else ""])

func _absorb_in_reach(center: Vector2, radius: float, limit := 3) -> void:
	var taken := 0
	for proj in get_tree().get_nodes_in_group("enemy_projectile"):
		if not is_instance_valid(proj) or proj.is_queued_for_deletion():
			continue
		if proj.global_position.distance_to(center) <= radius:
			proj.queue_free()
			_add_pip()
			taken += 1
			if taken >= limit:
				return

func _add_pip() -> void:
	if pips >= MAX_PIPS:
		pips = 0
		stuffed_timer = STUFFED_TIME
		player.emit_signal("status_changed", "TOO MUCH. STUFFED FOR A MOMENT.")
		return
	pips += 1
	player.emit_signal("status_changed", "TASTE: %d/%d PIPS." % [pips, MAX_PIPS])

func _spit() -> void:
	if pips <= 0:
		player.emit_signal("status_changed", "NO PIPS TO SPIT. TAKING ONLY WHAT YOU NEED.")
		return
	if not player.call("spend_glow", SPIT_COST):
		player.emit_signal("status_changed", "SPIT NEEDS 15 GLOW.")
		return
	var facing := int(player.call("attack_facing"))
	var origin: Vector2 = player.global_position + Vector2(20.0 * facing, -8.0)
	var damage := BEAM_DAMAGE if pips >= 3 else SPIT_DAMAGE * pips
	var reach := 520.0 if pips >= 3 else 380.0
	var width := 44.0 if pips >= 3 else 18.0
	var box := Rect2(origin.x if facing > 0 else origin.x - reach, origin.y - width / 2.0, reach, width)
	hit_ids.clear()
	for body in get_tree().get_nodes_in_group("enemy") + get_tree().get_nodes_in_group("boss"):
		if not is_instance_valid(body) or not body.has_method("take_damage"):
			continue
		var id := body.get_instance_id()
		if hit_ids.has(id) or not box.has_point(body.global_position):
			continue
		hit_ids[id] = true
		body.call("take_damage", damage)
	shots.append({"from": origin, "to": origin + Vector2(reach * facing, 0.0), "t": 0.0, "dur": 0.3, "width": width})
	player.emit_signal("status_changed", "SPIT: %d DAMAGE." % damage)
	pips = 0

func block_hit() -> bool:
	return false   # Open Wide takes projectiles, not melee, so it never blocks a hit

func _draw() -> void:
	if not _active():
		return
	for i in range(MAX_PIPS):
		var c := Vector2(-14.0 + i * 14.0, -58.0)
		draw_circle(c, 5.0, Color(TASTE, 1.0) if i < pips else Color(0.2, 0.3, 0.28, 0.45))
		draw_arc(c, 5.0, 0.0, TAU, 12, Color(0.12, 0.22, 0.2), 1.5)
	if guard_timer > 0.0:
		var facing := float(player.get("facing"))
		draw_arc(Vector2(16.0 * facing, -8.0), 26.0, -1.0, 1.0, 12, TASTE, 3.0) if facing > 0.0 else draw_arc(Vector2(16.0 * facing, -8.0), 26.0, PI - 1.0, PI + 1.0, 12, TASTE, 3.0)
	if holding and hold_time > 0.1:
		draw_circle(Vector2(30.0 * float(player.get("facing")), -6.0), 10.0 + minf(hold_time / GULP_HOLD, 1.0) * 14.0, Color(TASTE, 0.4))
	if stuffed_timer > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(-14, -70), "...", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, TASTE)
	for s in shots:
		var k := 1.0 - float(s["t"]) / float(s["dur"])
		var a: Vector2 = to_local(s["from"])
		var b: Vector2 = to_local(s["to"])
		if a.distance_to(b) < 1.0:
			draw_circle(a, float(s["width"]) * 0.5 * k, Color(TASTE, 0.5 * k))
		else:
			draw_line(a, b, Color(TASTE, 0.8 * k), float(s["width"]) * k)
