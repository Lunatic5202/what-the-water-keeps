extends CharacterBody2D

# Souls-like: 5 hearts, precise combat
const SPEED := 260.0
const JUMP_VELOCITY := -430.0
const GRAVITY := 1200.0
const DASH_SPEED := 620.0
const DASH_TIME := 0.16

# COMBAT VALUES (per combat doc)
const ATTACK_DAMAGE := 8  # Light attack base
const HEAL_AMOUNT := 2  # Per charge
const ATTACK_IMPACT_FRAMES := 6  # Freeze on hit

var health := 5
var max_health := 5
var heals := 3
var facing := 1
var dash_timer := 0.0
var attack_timer := 0.0
var hurt_cooldown := 0.0
var dash_cooldown := 0.0
var attack_has_hit := false
var attack_area: Area2D
var attack_shape: CollisionShape2D

# Movement modifiers
var move_speed_mod := 1.0
var jump_power_mod := 1.0

# Gadgets (unlocked via pickups)
var has_dash := false  # Wind Ribbon
var can_double_jump := false  # Featherweight Charm
var can_wall_climb := false  # Snail Grips
var can_super_dash := false  # Hungry Wind Scarf
var can_glass_step := false  # Mirror Hairpin
var can_grapple := false  # Thread Needle
var can_ground_pound := false  # Ember Boots
var can_glide := false  # Halo Cloak

var has_double_jumped := false

# Animation state
var is_attacking := false
var attack_progress := 0.0  # 0.0 to 1.0 during swing
var swing_arc_start := 0.0
var swing_arc_end := 0.0

signal health_changed(value: int)
signal heals_changed(value: int)
signal status_changed(message: String)

func _ready() -> void:
	add_to_group("player")
	attack_area = Area2D.new()
	attack_area.name = "AttackArea"
	attack_area.position = Vector2(28, 0)
	attack_area.monitoring = false
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
	dash_cooldown = maxf(0.0, dash_cooldown - delta)

	if dash_timer > 0.0:
		dash_timer -= delta
		velocity.x = facing * DASH_SPEED
	else:
		var direction := Input.get_axis("move_left", "move_right")
		if direction != 0.0:
			facing = int(sign(direction))
			velocity.x = direction * SPEED * move_speed_mod
		else:
			velocity.x = move_toward(velocity.x, 0.0, SPEED * move_speed_mod * 7.0 * delta)

		if Input.is_action_just_pressed("jump"):
			if is_on_floor():
				velocity.y = JUMP_VELOCITY * jump_power_mod
				has_double_jumped = false
			elif can_double_jump and not has_double_jumped:
				velocity.y = JUMP_VELOCITY * jump_power_mod * 0.85
				has_double_jumped = true

		if Input.is_action_just_pressed("dash") and dash_cooldown <= 0.0 and has_dash:
			dash_timer = DASH_TIME
			dash_cooldown = 0.55
			velocity.y = 0.0

		if Input.is_action_just_pressed("attack"):
			_start_attack()

		if Input.is_action_just_pressed("heal"):
			_heal()

	if attack_timer > 0.0:
		attack_timer -= delta
		attack_progress = 1.0 - (attack_timer / 0.18)
		if attack_timer <= 0.0:
			attack_shape.set_deferred("disabled", true)
			attack_area.set_deferred("monitoring", false)
			is_attacking = false

	move_and_slide()
	queue_redraw()

func _start_attack() -> void:
	if attack_timer > 0.0:
		return
	attack_timer = 0.18
	attack_progress = 0.0
	attack_has_hit = false
	is_attacking = true
	attack_area.position.x = 28.0 * facing

	# Set arc based on facing direction
	if facing > 0:
		swing_arc_start = -1.15
		swing_arc_end = 1.15
	else:
		swing_arc_start = PI + 0.2
		swing_arc_end = PI + 2.1

	attack_shape.set_deferred("disabled", false)
	attack_area.set_deferred("monitoring", true)
	status_changed.emit("LANTERN SWING!")

func _on_attack_body_entered(body: Node2D) -> void:
	if body == self:
		return
	if attack_timer <= 0.0 or attack_has_hit:
		return
	if body.has_method("take_damage"):
		# Impact feedback
		var scene_root = get_tree().root.get_child(0)
		if scene_root and scene_root.has_method("apply_hit_freeze"):
			scene_root.apply_hit_freeze(ATTACK_IMPACT_FRAMES)
			scene_root.screenshake(0.5, 0.08)

		body.take_damage(ATTACK_DAMAGE)
		attack_has_hit = true

func take_damage(amount: int) -> void:
	if hurt_cooldown > 0.0:
		return
	health = maxi(0, health - amount)
	hurt_cooldown = 0.8
	health_changed.emit(health)
	status_changed.emit("LUMI IS HURT. FIND A QUIET MOMENT.")
	if health <= 0:
		health = max_health
		heals = maxi(0, heals - 1)
		global_position = Vector2(240, 570)
		velocity = Vector2.ZERO
		health_changed.emit(health)
		heals_changed.emit(heals)
		status_changed.emit("LUMI RETURNS TO THE SHORE. ONE HEAL CHARGE LOST.")

func _heal() -> void:
	if heals <= 0 or health >= max_health:
		status_changed.emit("NO HEAL NEEDED RIGHT NOW.")
		return
	heals -= 1
	health = mini(max_health, health + HEAL_AMOUNT)
	heals_changed.emit(heals)
	health_changed.emit(health)
	status_changed.emit("A MOMENT OF REST. +%d HEARTS." % HEAL_AMOUNT)

func _draw() -> void:
	var cloak := Color(0.23, 0.30, 0.48, 1.0)
	if hurt_cooldown > 0.0 and int(Time.get_ticks_msec() / 90) % 2 == 0:
		cloak = Color(0.95, 0.75, 0.83, 1.0)

	# Body
	draw_colored_polygon(PackedVector2Array([
		Vector2(-15, -4), Vector2(-11, -24), Vector2(0, -31),
		Vector2(11, -24), Vector2(15, -4), Vector2(20, 15), Vector2(-20, 15)
	]), cloak)

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
		draw_arc(Vector2(25 * facing, -8), 32, current_arc_start, current_arc_end, 20,
			Color(0.88, 0.95, 1.0, glow_alpha), 4.0)

		# Impact flash at peak
		if ease_progress > 0.6:
			var impact_flash := (ease_progress - 0.6) / 0.4
			draw_arc(Vector2(25 * facing, -8), 28, current_arc_start, current_arc_end, 16,
				Color(1.0, 1.0, 1.0, impact_flash * 0.5), 2.0)
