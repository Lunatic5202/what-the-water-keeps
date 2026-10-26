extends CharacterBody2D
# Snoozle Snail (Sloth): slow and harmless-looking. Leaves a drowsy trail.

signal defeated

const TRAIL := preload("res://scripts/drowsy_trail.gd")
const GRAVITY := 1100.0
const SPEED := 30.0

var health := 30
var home_x := 0.0
var patrol := 120.0
var direction := 1
var trail_timer := 0.0
var attack_cooldown := 0.0
var hurt_flash := 0.0
var stun_time := 0.0
var dissolving := false
var dissolve_timer := 0.0

func _ready() -> void:
	home_x = global_position.x

func stun(seconds: float) -> void:
	stun_time = maxf(stun_time, seconds)

func _physics_process(delta: float) -> void:
	hurt_flash = maxf(0.0, hurt_flash - delta)
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
	velocity.x = direction * SPEED
	move_and_slide()
	trail_timer -= delta
	if trail_timer <= 0.0 and is_on_floor():
		trail_timer = 1.4
		var trail := Node2D.new()
		trail.set_script(TRAIL)
		get_parent().add_child(trail)
		trail.global_position = global_position + Vector2(0, 18)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	var player := get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and attack_cooldown <= 0.0 \
			and global_position.distance_to(player.global_position) < 40.0:
		player.take_damage(1)
		attack_cooldown = 1.2
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
	var shell := Color(0.62, 0.55, 0.88, fade)
	var ink := Color(0.16, 0.13, 0.32, fade)
	if hurt_flash > 0.0:
		shell = Color(1, 1, 1, fade)
	var f := float(direction)
	draw_rect(Rect2(-24, 8, 48, 12), Color(0.82, 0.78, 0.9, fade))
	draw_circle(Vector2(f * 22, 6), 9.0, Color(0.82, 0.78, 0.9, fade))
	draw_circle(Vector2(-f * 4, -4), 18.0, shell)
	draw_arc(Vector2(-f * 4, -4), 18.0, 0.0, TAU, 24, ink, 2.5)
	draw_arc(Vector2(-f * 4, -4), 9.0, 0.5, 4.5, 14, ink, 2.0)
	draw_line(Vector2(f * 26, 0), Vector2(f * 30, -12), ink, 2.0)
	draw_circle(Vector2(f * 30, -13), 2.5, ink)
	draw_arc(Vector2(f * 24, 4), 3.0, 0.2, PI - 0.2, 6, ink, 1.5)
	var pips := ceili(health / 8.0)
	for i in range(pips):
		draw_circle(Vector2(-12 + i * 8, -32), 2.5, Color(1.0, 0.85, 0.75, fade))
