extends CharacterBody2D
# Cutlery Knight (Gluttony mini-boss, prototype name): patrols the Syrup Cellar.
# It pauses to wind up (red flash), then charges in a straight line. The charge
# is the only thing that hurts; the recovery afterwards is the opening.

signal defeated

const GRAVITY := 1100.0
const MAX_HEALTH := 64
var health := MAX_HEALTH
var left_x := 0.0
var right_x := 0.0
var state := "patrol"      # patrol, windup, charge, recover
var state_time := 0.0
var direction := 1
var attack_cooldown := 0.0
var hurt_flash := 0.0
var dissolving := false
var dissolve_timer := 0.0
var engaged := false

func _ready() -> void:
	add_to_group("boss")
	add_to_group("enemy")

func _physics_process(delta: float) -> void:
	hurt_flash = maxf(0.0, hurt_flash - delta)
	if dissolving:
		dissolve_timer += delta
		if dissolve_timer >= 0.8:
			queue_free()
		queue_redraw()
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0
	state_time += delta
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	var player := get_tree().get_first_node_in_group("player")
	match state:
		"patrol":
			velocity.x = direction * 55.0
			if global_position.x < left_x:
				direction = 1
			elif global_position.x > right_x:
				direction = -1
			if is_instance_valid(player):
				var d: float = player.global_position.x - global_position.x
				if absf(d) < 300.0 and absf(player.global_position.y - global_position.y) < 120.0 and state_time > 1.6:
					direction = 1 if d > 0.0 else -1
					state = "windup"
					state_time = 0.0
		"windup":
			velocity.x = 0.0
			if state_time >= 0.8:
				state = "charge"
				state_time = 0.0
		"charge":
			velocity.x = direction * 420.0
			if is_instance_valid(player) and attack_cooldown <= 0.0 \
					and global_position.distance_to(player.global_position) < 44.0:
				player.take_damage(2)
				attack_cooldown = 1.0
			if state_time >= 0.55 or global_position.x < left_x - 60.0 or global_position.x > right_x + 60.0:
				state = "recover"
				state_time = 0.0
		"recover":
			velocity.x = 0.0
			if state_time >= 1.3:
				state = "patrol"
				state_time = 0.0
	move_and_slide()
	global_position.x = clampf(global_position.x, left_x - 80.0, right_x + 80.0)
	if engaged:
		get_tree().call_group("boss_health_bar", "update_boss_health", self, health, MAX_HEALTH)
	queue_redraw()

func take_damage(amount: int) -> void:
	if dissolving:
		return
	if not engaged:
		engaged = true
		get_tree().call_group("boss_health_bar", "show_boss", self, "CUTLERY KNIGHT", health, MAX_HEALTH)
	health -= amount
	hurt_flash = 0.15
	if health <= 0:
		dissolving = true
		get_tree().call_group("boss_health_bar", "hide_boss", self)
		defeated.emit()

func _draw() -> void:
	var fade := 1.0 - dissolve_timer / 0.8 if dissolving else 1.0
	var metal := Color(0.76, 0.8, 0.9, fade)
	var dark := Color(0.2, 0.22, 0.34, fade)
	if hurt_flash > 0.0:
		metal = Color(1, 1, 1, fade)
	elif state == "windup" and int(state_time * 12.0) % 2 == 0:
		metal = Color(1.0, 0.55, 0.5, fade)
	var f := float(direction)
	draw_rect(Rect2(-20, -38, 40, 58), metal)
	draw_rect(Rect2(-20, -38, 40, 58), dark, false, 3.0)
	draw_circle(Vector2(0, -52), 16.0, metal)
	draw_arc(Vector2(0, -52), 16.0, 0.0, TAU, 18, dark, 2.5)
	draw_rect(Rect2(-12, -56, 24, 5), dark)
	# Fork lance.
	draw_rect(Rect2(f * 18, -20, f * 38, 4), metal)
	for i in range(3):
		draw_rect(Rect2(f * 54, -28 + i * 7, f * 14, 3), metal)
	if not dissolving and engaged:
		for i in range(ceili(health / 8.0)):
			draw_circle(Vector2(-24 + i * 8, -78), 2.5, Color(1.0, 0.85, 0.75, fade))
