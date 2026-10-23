extends CharacterBody2D

signal defeated

const GRAVITY := 1100.0
var health := 2
var start_x := 0.0
var patrol_direction := -1
var patrol_timer := 0.0
var attack_cooldown := 0.0
var dead := false

func _ready() -> void:
    start_x = global_position.x

func _physics_process(delta: float) -> void:
    if dead:
        return
    if not is_on_floor():
        velocity.y += GRAVITY * delta
    else:
        velocity.y = 0.0
    patrol_timer += delta
    if patrol_timer > 1.4:
        patrol_timer = 0.0
        patrol_direction *= -1
    velocity.x = patrol_direction * 38.0
    if absf(global_position.x - start_x) > 85.0:
        patrol_direction = -1 if global_position.x > start_x else 1
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    move_and_slide()

    var player := get_tree().get_first_node_in_group("player")
    if player and global_position.distance_to(player.global_position) < 42.0 and attack_cooldown <= 0.0:
        if player.has_method("take_damage"):
            player.take_damage(1)
            attack_cooldown = 1.1
    queue_redraw()

func take_damage(amount: int) -> void:
    if dead:
        return
    health -= amount
    if health <= 0:
        dead = true
        defeated.emit()
        queue_free()
    else:
        var player := get_tree().get_first_node_in_group("player")
        if player:
            velocity.x = sign(global_position.x - player.global_position.x) * 160.0
            velocity.y = -110.0

func _draw() -> void:
    draw_circle(Vector2(0, 1), 19, Color(0.55, 0.79, 0.82, 0.24))
    draw_colored_polygon(PackedVector2Array([
        Vector2(-17, 8), Vector2(-18, -2), Vector2(-12, -12), Vector2(0, -17),
        Vector2(12, -12), Vector2(18, -2), Vector2(17, 8), Vector2(10, 12),
        Vector2(3, 9), Vector2(-4, 12), Vector2(-11, 9)
    ]), Color(0.55, 0.79, 0.82, 1.0))
    draw_circle(Vector2(-6, -2), 2.2, Color(0.12, 0.20, 0.31, 1.0))
    draw_circle(Vector2(6, -2), 2.2, Color(0.12, 0.20, 0.31, 1.0))
    draw_arc(Vector2(0, 2), 4, 0.15, PI - 0.15, 12, Color(0.12, 0.20, 0.31, 1.0), 1.5)
    for i in range(health):
        draw_circle(Vector2(-5.0 + i * 10.0, -25), 2.5, Color(0.88, 0.95, 1.0, 0.9))
