extends CharacterBody2D

signal defeated

const GRAVITY := 1100.0
const HEAD_BUMP_DAMAGE := 1  # Per balance doc: Wake boss 8-10
const ROLL_DAMAGE := 1
const SPORE_DAMAGE := 1

var health := 120
var max_health := 120
var phase := 0  # 0=intro, 1=fighting, 2=defeated
var attack_timer := 0.0
var attack_index := 0
var direction := 1
var hurt_cooldown := 0.0
var is_rolling := false
var roll_timer := 0.0
var spore_cooldown := 0.0
var defeat_timer := 0.0
var defeat_alpha := 1.0
var defeat_scale := 1.0

func _ready() -> void:
	add_to_group("boss")

func _physics_process(delta: float) -> void:
	if phase == 2:
		# Defeat animation
		defeat_timer += delta
		defeat_alpha = maxf(0.0, 1.0 - (defeat_timer / 2.0))
		defeat_scale = 1.0 + (defeat_timer * 0.3)
		if defeat_timer >= 2.0:
			queue_free()
		queue_redraw()
		return

	if phase != 1:
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

	hurt_cooldown = maxf(0.0, hurt_cooldown - delta)
	attack_timer -= delta
	spore_cooldown = maxf(0.0, spore_cooldown - delta)

	if is_rolling:
		roll_timer -= delta
		velocity.x = direction * 180.0
		if roll_timer <= 0.0:
			is_rolling = false
			velocity.x = 0.0
			attack_timer = 1.8
	elif attack_timer <= 0.0:
		_do_attack()
	else:
		velocity.x = 0.0

	move_and_slide()
	_check_player_collision()
	queue_redraw()

func _do_attack() -> void:
	attack_index = (attack_index + 1) % 3
	match attack_index:
		0:  # Head bump
			attack_timer = 2.2
		1:  # Roll
			is_rolling = true
			roll_timer = 1.6
			var player := get_tree().get_first_node_in_group("player")
			if player:
				direction = 1 if player.global_position.x > global_position.x else -1
		2:  # Spore puff
			_spawn_spores()
			attack_timer = 2.0

func _spawn_spores() -> void:
	for i in range(5):
		var angle := (i - 2) * 0.5
		var spore := Node2D.new()
		spore.position = global_position + Vector2(0, -20)
		spore.set_script(load("res://scripts/moss_spore.gd"))
		spore.set("direction", Vector2(cos(angle), sin(angle) - 0.3).normalized())
		get_parent().add_child(spore)

func _check_player_collision() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not player or spore_cooldown > 0.0:
		return
	var distance := global_position.distance_to(player.global_position)
	if distance < 55.0:
		if player.has_method("take_damage"):
			var dmg := ROLL_DAMAGE if is_rolling else HEAD_BUMP_DAMAGE
			player.take_damage(dmg)
			spore_cooldown = 1.0

func take_damage(amount: int) -> void:
	if phase != 1 or hurt_cooldown > 0.0:
		return
	health = maxi(0, health - amount)
	hurt_cooldown = 0.3
	if health <= 0:
		_defeat()

func start_fight() -> void:
	phase = 1
	attack_timer = 1.5

func _defeat() -> void:
	phase = 2
	velocity = Vector2.ZERO
	defeat_timer = 0.0
	defeated.emit()

func _draw() -> void:
	if phase == 2:
		# Boss defeat - gentle fade with glow
		var glow_alpha := sin(defeat_timer * 4.0) * 0.3 * defeat_alpha
		draw_circle(Vector2.ZERO, 50 * defeat_scale, Color(0.75, 0.88, 0.68, glow_alpha))

		var shell_color := Color(0.35, 0.48, 0.38, defeat_alpha)
		draw_circle(Vector2(0, 8), 28, Color(0.42, 0.52, 0.44, defeat_alpha * 0.5))
		draw_arc(Vector2(0, 0), 32, 0, PI, 16, shell_color, 8.0)
		return

	# Shell (mossy turtle)
	var shell_color := Color(0.35, 0.48, 0.38, 1.0)
	if hurt_cooldown > 0.0 and int(Time.get_ticks_msec() / 80) % 2 == 0:
		shell_color = Color(0.95, 0.92, 0.88, 1.0)

	# Body
	draw_circle(Vector2(0, 8), 28, Color(0.42, 0.52, 0.44, 1.0))

	# Shell pattern
	draw_arc(Vector2(0, 0), 32, 0, PI, 16, shell_color, 8.0)
	draw_circle(Vector2(-14, -4), 6, shell_color.darkened(0.2))
	draw_circle(Vector2(0, -8), 6, shell_color.darkened(0.2))
	draw_circle(Vector2(14, -4), 6, shell_color.darkened(0.2))

	if phase == 0:
		return

	# Head (hidden during roll)
	if not is_rolling:
		var head_x := 28 * direction
		draw_circle(Vector2(head_x, 12), 10, Color(0.52, 0.58, 0.48, 1.0))
		draw_circle(Vector2(head_x + 3 * direction, 10), 2, Color(0.12, 0.15, 0.23, 1.0))

	# Health bar
	if phase == 1:
		var bar_width := 80.0
		var bar_height := 6.0
		var bar_y := -50.0
		draw_rect(Rect2(-bar_width / 2, bar_y, bar_width, bar_height),
			Color(0.2, 0.2, 0.25, 0.8))
		var health_width := (float(health) / float(max_health)) * bar_width
		draw_rect(Rect2(-bar_width / 2, bar_y, health_width, bar_height),
			Color(0.55, 0.75, 0.58, 1.0))
