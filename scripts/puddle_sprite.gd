extends CharacterBody2D

const GRAVITY := 1200.0
const SPEED := 85.0
const HOP_VELOCITY := -220.0
const HOP_INTERVAL := 1.8

var health := 15
var max_health := 15
var direction := -1
var hop_timer := 0.0
var dissolving := false
var dissolve_timer := 0.0
var hurt_flash := 0.0

signal defeated()

func _ready() -> void:
	hop_timer = randf_range(0.2, HOP_INTERVAL)

var stun_time := 0.0

func stun(seconds: float) -> void:
	stun_time = maxf(stun_time, seconds)

func _physics_process(delta: float) -> void:
	if stun_time > 0.0 and not dissolving:
		stun_time -= delta
		return
	if dissolving:
		dissolve_timer += delta
		if dissolve_timer >= 0.6:
			queue_free()
		queue_redraw()
		return

	hurt_flash = maxf(0.0, hurt_flash - delta * 3.0)

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0
		hop_timer -= delta
		if hop_timer <= 0.0:
			velocity.y = HOP_VELOCITY
			hop_timer = HOP_INTERVAL

	velocity.x = direction * SPEED
	move_and_slide()

	var player := get_tree().get_first_node_in_group("player")
	if player and global_position.distance_to(player.global_position) < 24.0:
		if player.has_method("take_damage"):
			player.take_damage(1)

	queue_redraw()

func take_damage(amount: int) -> void:
	if dissolving:
		return
	health -= amount
	hurt_flash = 1.0
	if health <= 0:
		_start_dissolve()

func _start_dissolve() -> void:
	dissolving = true
	dissolve_timer = 0.0
	defeated.emit()

func _draw() -> void:
	if dissolving:
		var alpha := 1.0 - (dissolve_timer / 0.6)
		# Dissolve particles
		for i in range(12):
			var angle := (i / 12.0) * TAU
			var dist := dissolve_timer * 35.0
			var particle_pos := Vector2(cos(angle), sin(angle)) * dist
			draw_circle(particle_pos, 2.5, Color(0.5, 0.7, 0.9, alpha * 0.7))

		draw_circle(Vector2.ZERO, 14, Color(0.45, 0.65, 0.85, alpha * 0.4))
		draw_circle(Vector2.ZERO, 10, Color(0.55, 0.75, 0.92, alpha))
		return

	var base_color := Color(0.55, 0.75, 0.92, 1.0)
	if hurt_flash > 0.0:
		base_color = base_color.lerp(Color(1.0, 0.9, 0.9, 1.0), hurt_flash)

	# Puddle sprite body
	draw_circle(Vector2(0, 2), 14, Color(0.45, 0.65, 0.85, 0.4))
	draw_circle(Vector2(0, 0), 12, base_color)
	draw_circle(Vector2(4 * direction, -2), 3, Color(0.2, 0.3, 0.4, 0.7))

	# Health dots above
	var dots := ceili(float(health) / float(max_health) * 5.0)
	for i in range(dots):
		var x := -8 + i * 4
		draw_circle(Vector2(x, -20), 1.5, Color(0.6, 0.8, 0.95, 0.9))
