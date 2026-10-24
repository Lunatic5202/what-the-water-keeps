extends CharacterBody2D

signal health_changed(value: int)
signal heals_changed(value: int)
signal status_changed(message: String)

const SPEED := 260.0
const JUMP_VELOCITY := -430.0
const GRAVITY := 1200.0
const DASH_SPEED := 620.0
const DASH_TIME := 0.16
const HEAL_AMOUNT := 2

var health := 5
var max_health := 5
var heals := 2
var facing := 1
var dash_timer := 0.0
var attack_timer := 0.0
var hurt_cooldown := 0.0
var dash_cooldown := 0.0
var attack_has_hit := false
var attack_area: Area2D
var attack_shape: CollisionShape2D

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
            velocity.x = direction * SPEED
        else:
            velocity.x = move_toward(velocity.x, 0.0, SPEED * 7.0 * delta)

        if Input.is_action_just_pressed("jump") and is_on_floor():
            velocity.y = JUMP_VELOCITY
        if Input.is_action_just_pressed("dash") and dash_cooldown <= 0.0:
            dash_timer = DASH_TIME
            dash_cooldown = 0.55
            velocity.y = 0.0
        if Input.is_action_just_pressed("attack"):
            _start_attack()
        if Input.is_action_just_pressed("heal"):
            _heal()

    if attack_timer > 0.0:
        attack_timer -= delta
        if attack_timer <= 0.0:
            attack_shape.set_deferred("disabled", true)
            attack_area.set_deferred("monitoring", false)

    move_and_slide()
    queue_redraw()

func _start_attack() -> void:
    if attack_timer > 0.0:
        return
    attack_timer = 0.18
    attack_has_hit = false
    attack_area.position.x = 28.0 * facing
    attack_shape.set_deferred("disabled", false)
    attack_area.set_deferred("monitoring", true)
    status_changed.emit("LANTERN SWING!")

func _on_attack_body_entered(body: Node2D) -> void:
    # The attack Area2D is a child of Lumi, so never let the swing hit its owner.
    if body == self:
        return
    if attack_timer <= 0.0 or attack_has_hit:
        return
    if body.has_method("take_damage"):
        body.take_damage(1)
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
    draw_colored_polygon(PackedVector2Array([
        Vector2(-15, -4), Vector2(-11, -24), Vector2(0, -31),
        Vector2(11, -24), Vector2(15, -4), Vector2(20, 15), Vector2(-20, 15)
    ]), cloak)
    draw_circle(Vector2(0, -25), 10, Color(0.88, 0.82, 0.78, 1.0))
    draw_circle(Vector2(3, -26), 1.8, Color(0.13, 0.15, 0.23, 1.0))
    var lamp := Vector2(19 * facing, -7)
    draw_circle(lamp, 10, Color(0.56, 0.87, 1.0, 0.16))
    draw_circle(lamp, 6, Color(0.64, 0.91, 1.0, 0.9))
    draw_arc(lamp + Vector2(0, -6), 5, PI, TAU, 16, Color(0.91, 0.94, 1.0, 1.0), 2.0)
    if attack_timer > 0.0:
        var start_angle := -1.15 if facing > 0 else PI + 0.2
        var end_angle := 1.15 if facing > 0 else PI + 2.1
        draw_arc(Vector2(25 * facing, -8), 29, start_angle, end_angle, 16, Color(0.66, 0.91, 1.0, 0.9), 3.0)
