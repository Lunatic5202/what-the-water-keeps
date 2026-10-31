extends CharacterBody2D
# Jelly Gulper (Gluttony): a gelatin blob. Touch it and it swallows Lumi for a
# moment, then spits her back with weight (Fullness). Prototype stats.

signal defeated

const GRAVITY := 1100.0
var health := 34
var home_x := 0.0
var patrol := 110.0
var direction := 1
var attack_cooldown := 0.0
var hurt_flash := 0.0
var stun_time := 0.0
var dissolving := false
var dissolve_timer := 0.0
var gulp := 0.0

func _ready() -> void:
	home_x = global_position.x
	add_to_group("enemy")

func stun(seconds: float) -> void:
	stun_time = maxf(stun_time, seconds)

func _physics_process(delta: float) -> void:
	hurt_flash = maxf(0.0, hurt_flash - delta)
	gulp = maxf(0.0, gulp - delta)
	if dissolving:
		dissolve_timer += delta
		if dissolve_timer >= 0.6:
			queue_free()
		queue_redraw()
		return
	if stun_time > 0.0:
		stun_time -= delta
		queue_redraw()
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0
	if absf(global_position.x - home_x) > patrol:
		direction = -1 if global_position.x > home_x else 1
	velocity.x = direction * (14.0 if gulp > 0.0 else 40.0)
	move_and_slide()
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	var player := get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and attack_cooldown <= 0.0 \
			and global_position.distance_to(player.global_position) < 42.0:
		player.take_damage(1)
		attack_cooldown = 1.4
		gulp = 0.5
		get_tree().call_group("fullness_holder", "add_fullness", 18.0)
	queue_redraw()

func take_damage(amount: int) -> void:
	if dissolving:
		return
	health -= amount
	hurt_flash = 0.15
	if health <= 0:
		dissolving = true
		defeated.emit()

func _draw() -> void:
	var fade := 1.0 - dissolve_timer / 0.6 if dissolving else 1.0
	var body := Color(0.96, 0.52, 0.66, 0.82 * fade)
	if hurt_flash > 0.0:
		body = Color(1, 1, 1, fade)
	var squash := 1.0 + gulp * 0.5
	draw_colored_polygon(PackedVector2Array([
		Vector2(-24, 20), Vector2(-26, 2), Vector2(-14, -16), Vector2(0, -22),
		Vector2(14, -16), Vector2(26, 2), Vector2(24, 20)
	]), body)
	draw_arc(Vector2(0, 0), 24.0, PI, TAU, 14, Color(0.45, 0.16, 0.26, fade), 2.5)
	draw_circle(Vector2(-8, -4), 3.0, Color(0.25, 0.08, 0.14, fade))
	draw_circle(Vector2(8, -4), 3.0, Color(0.25, 0.08, 0.14, fade))
	draw_arc(Vector2(0, 6), 8.0 * squash, 0.2, PI - 0.2, 8, Color(0.25, 0.08, 0.14, fade), 2.0)
	draw_circle(Vector2(-10, -12), 4.0, Color(1, 1, 1, 0.35 * fade))
