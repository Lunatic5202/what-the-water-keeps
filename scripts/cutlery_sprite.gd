extends CharacterBody2D
# Cutlery Sprite (Gluttony): a fork that flits about, winds up, then pokes.
# Prototype stats.

signal defeated

var health := 18
var home := Vector2.ZERO
var state := "flit"       # flit, windup, dart, recover
var state_time := 0.0
var dart_dir := Vector2.RIGHT
var attack_cooldown := 0.0
var hurt_flash := 0.0
var stun_time := 0.0
var dissolving := false
var dissolve_timer := 0.0
var t := 0.0

func _ready() -> void:
	home = global_position
	add_to_group("enemy")

func stun(seconds: float) -> void:
	stun_time = maxf(stun_time, seconds)

func _physics_process(delta: float) -> void:
	t += delta
	hurt_flash = maxf(0.0, hurt_flash - delta)
	if dissolving:
		dissolve_timer += delta
		if dissolve_timer >= 0.5:
			queue_free()
		queue_redraw()
		return
	if stun_time > 0.0:
		stun_time -= delta
		queue_redraw()
		return
	state_time += delta
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	var player := get_tree().get_first_node_in_group("player")
	match state:
		"flit":
			var want := home + Vector2(sin(t * 1.1) * 70.0, sin(t * 2.1) * 25.0)
			global_position = global_position.move_toward(want, 60.0 * delta)
			if is_instance_valid(player) and global_position.distance_to(player.global_position) < 280.0 and state_time > 1.2:
				state = "windup"
				state_time = 0.0
		"windup":
			if is_instance_valid(player):
				dart_dir = (player.global_position - global_position).normalized()
			if state_time >= 0.55:
				state = "dart"
				state_time = 0.0
		"dart":
			global_position += dart_dir * 420.0 * delta
			if is_instance_valid(player) and attack_cooldown <= 0.0 \
					and global_position.distance_to(player.global_position) < 30.0:
				player.take_damage(1)
				attack_cooldown = 1.0
			if state_time >= 0.35 or absf(global_position.x - home.x) > 420.0:
				state = "recover"
				state_time = 0.0
		"recover":
			global_position = global_position.move_toward(home, 140.0 * delta)
			if state_time >= 1.0:
				state = "flit"
				state_time = 0.0
	queue_redraw()

func take_damage(amount: int) -> void:
	if dissolving:
		return
	health -= amount
	hurt_flash = 0.15
	if state == "windup":
		state = "recover"
		state_time = 0.0
	if health <= 0:
		dissolving = true
		defeated.emit()

func _draw() -> void:
	var fade := 1.0 - dissolve_timer / 0.5 if dissolving else 1.0
	var metal := Color(0.82, 0.86, 0.92, fade)
	if hurt_flash > 0.0:
		metal = Color(1, 1, 1, fade)
	var ang := dart_dir.angle() if state != "flit" else sin(t * 2.0) * 0.4 + PI / 2.0
	draw_set_transform(Vector2.ZERO, ang - PI / 2.0, Vector2.ONE)
	draw_rect(Rect2(-2, -4, 4, 26), metal)
	for i in range(3):
		draw_rect(Rect2(-8 + i * 6, -22, 3, 20), metal)
	draw_rect(Rect2(-8, -6, 16, 4), metal)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(Vector2(-4, -2), 2.0, Color(0.15, 0.17, 0.25, fade))
	draw_circle(Vector2(4, -2), 2.0, Color(0.15, 0.17, 0.25, fade))
	if state == "windup":
		draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 20, Color(1.0, 0.5, 0.4, 0.8), 2.0)
