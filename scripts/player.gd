extends CharacterBody2D

const RunState := preload("res://scripts/run_state.gd")

# Souls-like: 5 hearts, precise combat
const SPEED := 260.0
const JUMP_VELOCITY := -430.0
const GRAVITY := 1200.0
const DASH_SPEED := 620.0
const DASH_TIME := 0.16

# COMBAT VALUES (per combat doc)
const ATTACK_DAMAGE := 8  # Light attack base
const COMBO_DAMAGE := [8, 8, 12]  # Lantern combo (bible 4.3)
const AIR_DAMAGE := 9
const DASH_ATTACK_DAMAGE := 10
const UP_DAMAGE := 9  # W + J, hits above Lumi
const POGO_BOUNCE := -380.0  # S + J in the air: hit something and bounce
const COMBO_WINDOW := 0.45
const HEAL_AMOUNT := 2  # Per charge
const ATTACK_IMPACT_FRAMES := 6  # Freeze on hit

var health := 5
var max_health := 5
var heals := 3
var vulnerable := 0       # extra damage per hit while a debuff is heavy (Drowse, Weight)
var heal_blocked := false # too sleepy to heal
var weighed_down := false # Weight: no dash or double jump
var facing := 1
var dash_timer := 0.0
var attack_timer := 0.0
var hurt_cooldown := 0.0
var dash_cooldown := 0.0
var attack_has_hit := false
var attack_dir := "side"  # "side", "up" or "down" (W / S held when swinging)
var swing_center := Vector2(25, -8)
var attack_damage := ATTACK_DAMAGE
var attack_step := 0
var combo_timer := 0.0
var lunge_timer := 0.0
var attack_area: Area2D
var attack_shape: CollisionShape2D

# Fighting styles (bible 4.3 and 4.4). Lantern Swing is the default.
const MAX_GLOW := 100.0
var style := "lantern"
var unlocked_styles: Array[String] = ["lantern"]
var glow := 0.0

# Movement modifiers
var move_speed_mod := 1.0
var jump_power_mod := 1.0

# Gadgets (unlocked via pickups)
var has_dash := false  # Wind Ribbon
var can_double_jump := false  # Featherweight Charm
var can_wall_climb := false  # Snail Grips
var can_super_dash := false  # Hungry Wind Scarf: a longer, faster dash
var dash_blocked := false     # Stuffed: no dash (jumps still work)
var attack_speed_mod := 1.0   # Stuffed slows swings (0.75)
var heal_amount_mod := 1.0    # Stuffed halves healing (0.5)
var can_glass_step := false  # Mirror Hairpin
var can_grapple := false  # Thread Needle
var can_ground_pound := false  # Ember Boots
var can_glide := false  # Halo Cloak

var has_double_jumped := false
var asleep_timer := 0.0   # Drowse: Lumi nods off and cannot act
var clinging := false
var cling_dir := 1  # side of the wall Lumi is clinging to (1 = wall on the right)
const CLIMB_SPEED := 170.0
var respawn_point := Vector2(240, 570)

# Animation state
var is_attacking := false
var attack_progress := 0.0  # 0.0 to 1.0 during swing
var swing_arc_start := 0.0
var swing_arc_end := 0.0

signal health_changed(value: int)
signal heals_changed(value: int)
signal status_changed(message: String)
signal died
signal no_hit_failed  # the secret no-hit challenge: any damage ends the run

func _ready() -> void:
	add_to_group("player")
	var hand := Node2D.new()
	hand.name = "OpenHand"
	hand.set_script(load("res://scripts/open_hand.gd"))
	add_child(hand)
	var kit := Node2D.new()
	kit.name = "LanternKit"
	kit.set_script(load("res://scripts/lantern_kit.gd"))
	add_child(kit)
	attack_area = Area2D.new()
	attack_area.name = "AttackArea"
	attack_area.position = Vector2(28, 0)
	attack_area.monitoring = false
	attack_area.collision_mask = 3  # layer 1 (enemies) and layer 2 (The Collector)
	attack_shape = CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 28.0
	attack_shape.shape = shape
	attack_shape.disabled = true
	attack_area.add_child(attack_shape)
	add_child(attack_area)
	attack_area.body_entered.connect(_on_attack_body_entered)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	elif velocity.y > 0.0:
		velocity.y = 0.0
	hurt_cooldown = maxf(0.0, hurt_cooldown - delta)
	combo_timer = maxf(0.0, combo_timer - delta)
	lunge_timer = maxf(0.0, lunge_timer - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)

	if asleep_timer > 0.0:
		asleep_timer -= delta
		velocity.x = 0.0
		move_and_slide()
		queue_redraw()
		return

	clinging = _touching_climbable_wall(Input.get_axis("move_left", "move_right"))

	if dash_timer > 0.0:
		dash_timer -= delta
		velocity.x = facing * DASH_SPEED * (1.35 if can_super_dash else 1.0)
	else:
		var direction := Input.get_axis("move_left", "move_right")
		if lunge_timer > 0.0:
			velocity.x = facing * SPEED * 1.5
		elif direction != 0.0:
			facing = int(sign(direction))
			velocity.x = direction * SPEED * move_speed_mod
		else:
			velocity.x = move_toward(velocity.x, 0.0, SPEED * move_speed_mod * 7.0 * delta)

		if Input.is_action_just_pressed("jump"):
			if is_on_floor():
				velocity.y = JUMP_VELOCITY * jump_power_mod
				has_double_jumped = false
			elif can_double_jump and not has_double_jumped and not clinging and not weighed_down:
				velocity.y = JUMP_VELOCITY * jump_power_mod * 0.85
				has_double_jumped = true

		if Input.is_action_just_pressed("dash") and has_dash and not weighed_down and not dash_blocked and dash_cooldown <= 0.0:
			dash_timer = DASH_TIME * (1.6 if can_super_dash else 1.0)
			dash_cooldown = 0.55
			velocity.y = 0.0

		if Input.is_action_just_pressed("attack") and style == "lantern":
			_start_attack()

		if Input.is_action_just_pressed("style_cycle"):
			_cycle_style()


		if Input.is_action_just_pressed("heal"):
			_heal()

	if attack_timer > 0.0:
		attack_timer -= delta
		attack_progress = 1.0 - (attack_timer / 0.18)
		if attack_timer <= 0.0:
			attack_shape.set_deferred("disabled", true)
			attack_area.set_deferred("monitoring", false)
			is_attacking = false
			if attack_step > 0:
				combo_timer = COMBO_WINDOW

	# Snail Grips: hold toward a climbable wall to cling; hold jump to climb.
	if clinging and dash_timer <= 0.0:
		velocity.y = -CLIMB_SPEED if Input.is_action_pressed("jump") else 0.0
		has_double_jumped = false

	move_and_slide()
	queue_redraw()

# Where the player is aiming: W / A / S / D combined, snapped to 8 directions.
# With nothing held it is the way Lumi faces.
func aim_held() -> bool:
	return Input.get_axis("move_left", "move_right") != 0.0 or Input.get_axis("move_up", "move_down") != 0.0

# While clinging to a wall, attacks and throws point away from it (holding
# toward the wall is what keeps Lumi on it).
func attack_facing() -> int:
	return -cling_dir if clinging else facing

func aim_vector() -> Vector2:
	var raw := Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
	if clinging:
		raw.x = -float(cling_dir)
	if raw.length() < 0.3:
		return Vector2(attack_facing(), 0)
	var step := PI / 4.0
	return Vector2.from_angle(roundf(raw.angle() / step) * step)

func _start_attack() -> void:
	if attack_timer > 0.0:
		return
	attack_timer = 0.18 / attack_speed_mod
	attack_progress = 0.0
	attack_has_hit = false
	attack_dir = "side"
	var vertical := Input.get_axis("move_up", "move_down")
	# Bible 4.3: J,J,J = 8/8/12 (third hit lunges), air 9, dash attack 10.
	var kind := "NORMAL"
	if vertical < -0.5:
		attack_damage = UP_DAMAGE
		attack_step = 0
		attack_dir = "up"
		kind = "UP"
	elif not is_on_floor():
		attack_damage = AIR_DAMAGE
		attack_step = 0
		kind = "AIR"
		if vertical > 0.5:
			attack_dir = "down"
			kind = "POGO"
	elif dash_cooldown > 0.15:
		attack_damage = DASH_ATTACK_DAMAGE
		attack_step = 0
		kind = "DASH"
	else:
		attack_step = (attack_step % 3) + 1 if combo_timer > 0.0 else 1
		attack_damage = COMBO_DAMAGE[attack_step - 1]
		if attack_step == 3:
			lunge_timer = 0.12
			kind = "LUNGE"
	is_attacking = true
	attack_area.position = Vector2(28.0 * attack_facing(), 0.0)
	swing_center = Vector2(25 * attack_facing(), -8)

	# Set arc based on attack_facing() direction
	if attack_facing() > 0:
		swing_arc_start = -1.15
		swing_arc_end = 1.15
	else:
		swing_arc_start = PI + 0.2
		swing_arc_end = PI + 2.1
	if attack_dir == "up":
		attack_area.position = Vector2(0, -44)
		swing_center = Vector2(0, -14)
		swing_arc_start = -PI / 2.0 - 1.15
		swing_arc_end = -PI / 2.0 + 1.15
	elif attack_dir == "down":
		attack_area.position = Vector2(0, 38)
		swing_center = Vector2(0, 14)
		swing_arc_start = PI / 2.0 - 1.15
		swing_arc_end = PI / 2.0 + 1.15

	attack_shape.set_deferred("disabled", false)
	attack_area.set_deferred("monitoring", true)
	status_changed.emit("LANTERN SWING! (%d)" % attack_damage if kind == "NORMAL" else "LANTERN SWING: %s (%d)" % [kind, attack_damage])

func _on_attack_body_entered(body: Node2D) -> void:
	if body == self:
		return
	if attack_timer <= 0.0 or attack_has_hit:
		return
	if body.has_method("take_damage"):
		var feedback := get_tree().get_first_node_in_group("combat_feedback")
		if is_instance_valid(feedback):
			feedback.call("apply_hit_freeze", ATTACK_IMPACT_FRAMES)
			feedback.call("screenshake", 0.5, 0.08)

		body.take_damage(attack_damage)
		add_glow(3.0)
		attack_has_hit = true
		if attack_dir == "down":
			velocity.y = POGO_BOUNCE
			has_double_jumped = false

func take_damage(amount: int) -> void:
	if hurt_cooldown > 0.0:
		return
	for node_name in ["OpenHand", "LanternKit"]:
		var kit := get_node_or_null(node_name)
		if kit != null and kit.call("block_hit"):
			hurt_cooldown = 0.2
			return
	# Challenge mode: any hit that gets past a guard ends the run.
	if RunState.no_hit:
		health = 0
		hurt_cooldown = 5.0
		health_changed.emit(health)
		no_hit_failed.emit()
		return
	if amount > 0:
		amount += vulnerable + (1 if asleep_timer > 0.0 else 0)
	amount = RunState.damage(amount)
	if amount <= 0:
		hurt_cooldown = 0.8
		status_changed.emit("A SOFTER LANDING.")
		return
	health = maxi(0, health - amount)
	hurt_cooldown = 0.8
	health_changed.emit(health)
	status_changed.emit("LUMI IS HURT. FIND A QUIET MOMENT.")
	if health <= 0:
		health = max_health
		heals = maxi(0, heals - 1)
		global_position = respawn_point
		velocity = Vector2.ZERO
		asleep_timer = 0.0
		health_changed.emit(health)
		died.emit()
		heals_changed.emit(heals)
		status_changed.emit("LUMI RETURNS TO THE SHORE. ONE HEAL CHARGE LOST.")

func fall_asleep(seconds: float) -> void:
	asleep_timer = seconds
	attack_timer = 0.0
	is_attacking = false
	attack_shape.set_deferred("disabled", true)
	attack_area.set_deferred("monitoring", false)
	status_changed.emit("LUMI NODS OFF...")

func _touching_climbable_wall(direction: float) -> bool:
	if not can_wall_climb or is_on_floor() or direction == 0.0:
		return false
	for i in range(get_slide_collision_count()):
		var hit := get_slide_collision(i)
		var collider := hit.get_collider() as Node
		if absf(hit.get_normal().x) > 0.9 and collider != null and collider.is_in_group("climbable"):
			if signf(-hit.get_normal().x) == signf(direction):
				cling_dir = int(signf(direction))
				return true
			return false
	return false

func add_glow(amount: float) -> void:
	glow = clampf(glow + amount, 0.0, MAX_GLOW)

func spend_glow(cost: float) -> bool:
	if glow < cost:
		return false
	glow -= cost
	return true

func unlock_style(style_name: String) -> void:
	if not unlocked_styles.has(style_name):
		unlocked_styles.append(style_name)
	style = style_name
	status_changed.emit("OPEN HAND EQUIPPED. TAB SWAPS STYLES.")

func _cycle_style() -> void:
	if unlocked_styles.size() < 2:
		return
	var next := (unlocked_styles.find(style) + 1) % unlocked_styles.size()
	style = unlocked_styles[next]
	status_changed.emit("STYLE: " + ("OPEN HAND" if style == "open_hand" else "LANTERN SWING"))

func _heal() -> void:
	if heal_blocked:
		status_changed.emit("TOO SLEEPY TO REST.")
		return
	if heals <= 0 or health >= max_health:
		status_changed.emit("NO HEAL NEEDED RIGHT NOW.")
		return
	heals -= 1
	var gained := maxi(1, roundi(HEAL_AMOUNT * heal_amount_mod))
	health = mini(max_health, health + gained)
	heals_changed.emit(heals)
	health_changed.emit(health)
	status_changed.emit("A MOMENT OF REST. +%d HEARTS." % gained)

func _draw() -> void:
	var cloak := Color(0.23, 0.30, 0.48, 1.0)
	if asleep_timer > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(8, -40), "Z z z", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.9, 0.88, 1.0))
	if hurt_cooldown > 0.0 and int(Time.get_ticks_msec() / 90) % 2 == 0:
		cloak = Color(0.95, 0.75, 0.83, 1.0)

	# Body
	draw_colored_polygon(PackedVector2Array([
		Vector2(-15, -4), Vector2(-11, -24), Vector2(0, -31),
		Vector2(11, -24), Vector2(15, -4), Vector2(20, 15), Vector2(-20, 15)
	]), cloak)
	draw_polyline(PackedVector2Array([
		Vector2(-20, 15), Vector2(-15, -4), Vector2(-11, -24), Vector2(0, -31),
		Vector2(11, -24), Vector2(15, -4), Vector2(20, 15), Vector2(-20, 15)
	]), Color(0.95, 0.92, 1.0, 0.85), 1.8)

	# Head
	draw_circle(Vector2(0, -25), 10, Color(0.88, 0.82, 0.78, 1.0))
	draw_circle(Vector2(3, -26), 1.8, Color(0.13, 0.15, 0.23, 1.0))

	# Lantern
	var lamp := Vector2(19 * facing, -7)
	draw_circle(lamp, 10, Color(0.56, 0.87, 1.0, 0.16))
	draw_circle(lamp, 6, Color(0.64, 0.91, 1.0, 0.9))
	draw_arc(lamp + Vector2(0, -6), 5, PI, TAU, 16, Color(0.91, 0.94, 1.0, 1.0), 2.0)

	# Better sword swing animation
	if is_attacking and attack_timer > 0.0:
		var ease_progress := ease(attack_progress, -2.0)  # Ease out
		var current_arc_start := lerpf(swing_arc_start, swing_arc_start + 2.3, ease_progress)
		var current_arc_end := lerpf(swing_arc_end, swing_arc_end - 2.3, ease_progress)

		var glow_alpha := (1.0 - ease_progress) * 0.7
		draw_arc(swing_center, 32, current_arc_start, current_arc_end, 20,
			Color(0.88, 0.95, 1.0, glow_alpha), 4.0)

		# Impact flash at peak
		if ease_progress > 0.6:
			var impact_flash := (ease_progress - 0.6) / 0.4
			draw_arc(swing_center, 28, current_arc_start, current_arc_end, 16,
				Color(1.0, 1.0, 1.0, impact_flash * 0.5), 2.0)
