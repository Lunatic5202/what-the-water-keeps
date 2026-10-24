extends CharacterBody2D

const GRAVITY := 1200.0
const SPEED := 110.0
const PUFF_DISTANCE := 160.0

var health := 12
var max_health := 12
var direction := 1
var dissolving := false
var dissolve_timer := 0.0
var hurt_flash := 0.0
var puff_timer := 0.0

signal defeated()

func _ready() -> void:
	direction = 1 if randf() > 0.5 else -1

func _physics_process(delta: float) -> void:
	if dissolving:
		dissolve_timer += delta
		if dissolve_timer >= 0.6:
			queue_free()
		queue_redraw()
		return

	hurt_flash = maxf(0.0, hurt_flash - delta * 3.0)
	puff_timer += delta

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

	var player := get_tree().get_first_node_in_group("player")
	if player:
		var distance := global_position.distance_to(player.global_position)
		if distance < PUFF_DISTANCE:
			# Flee from player
			direction = sign(global_position.x - player.global_position.x)
			velocity.x = direction * SPEED * 1.4
		else:
			velocity.x = direction * SPEED * 0.5

		if distance < 24.0 and player.has_method("take_damage"):
			player.take_damage(1)

	move_and_slide()
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
		# Dust particles scatter
		for i in range(15):
			var angle := (i / 15.0) * TAU
			var dist := dissolve_timer * 40.0
			var particle_pos := Vector2(cos(angle), sin(angle)) * dist
			draw_circle(particle_pos, 2.0, Color(0.8, 0.75, 0.7, alpha * 0.6))

		draw_circle(Vector2.ZERO, 13, Color(0.75, 0.7, 0.65, alpha * 0.3))
		return

	var base_color := Color(0.82, 0.78, 0.72, 1.0)
	if hurt_flash > 0.0:
		base_color = base_color.lerp(Color(1.0, 0.9, 0.9, 1.0), hurt_flash)

	# Dust bunny body - fluffy circles
	var puff_offset := sin(puff_timer * 3.0) * 2.0
	draw_circle(Vector2(0, puff_offset), 13, Color(0.7, 0.65, 0.6, 0.5))
	draw_circle(Vector2(0, puff_offset), 10, base_color)
	draw_circle(Vector2(-5 * direction, -3 + puff_offset), 6, base_color)
	draw_circle(Vector2(4 * direction, -2 + puff_offset), 5, base_color)

	# Eyes
	draw_circle(Vector2(3 * direction, -4 + puff_offset), 1.5, Color(0.2, 0.2, 0.25, 0.8))

	# Health dots
	var dots := ceili(float(health) / float(max_health) * 5.0)
	for i in range(dots):
		var x := -8 + i * 4
		draw_circle(Vector2(x, -20), 1.5, Color(0.85, 0.8, 0.75, 0.9))
