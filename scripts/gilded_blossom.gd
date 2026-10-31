extends StaticBody2D

signal dropped_coin(amount: int)

const SAP_SCRIPT := preload("res://scripts/gilded_sap.gd")
var health := 12
var dead := false
var windup := 0.0
var shot_cooldown := 0.0
var dissolve_time := 0.0
var dissolving := false
var aim_direction := Vector2.RIGHT
var stun_time := 0.0

func _ready() -> void:
	add_to_group("enemy")

func stun(seconds: float) -> void:
	stun_time = maxf(stun_time, seconds)

func _physics_process(delta: float) -> void:
	if dissolving:
		dissolve_time += delta
		queue_redraw()
		if dissolve_time >= 0.5:
			queue_free()
		return
	if dead:
		return
	if stun_time > 0.0:
		stun_time = maxf(0.0, stun_time - delta)
		queue_redraw()
		return

	var player := get_tree().get_first_node_in_group("player") as Node2D
	shot_cooldown = maxf(0.0, shot_cooldown - delta)
	if windup > 0.0:
		windup -= delta
		if windup <= 0.0:
			_fire_sap()
	elif shot_cooldown <= 0.0 and is_instance_valid(player):
		var offset := player.global_position - global_position
		if offset.length() < 320.0 and absf(offset.y) < 210.0:
			aim_direction = offset.normalized()
			windup = 0.62
	queue_redraw()

func _fire_sap() -> void:
	var sap := Node2D.new()
	sap.set_script(SAP_SCRIPT)
	get_parent().add_child(sap)
	sap.global_position = global_position + aim_direction * 22.0 + Vector2(0.0, -4.0)
	sap.set("launch_velocity", aim_direction * 205.0 + Vector2(0.0, -230.0))
	shot_cooldown = 2.5

func take_damage(amount: int) -> void:
	if dead:
		return
	health -= amount
	if health <= 0:
		dead = true
		dissolving = true
		var hitbox := get_node_or_null("CollisionShape2D") as CollisionShape2D
		if is_instance_valid(hitbox):
			hitbox.set_deferred("disabled", true)
		dropped_coin.emit(8)
	queue_redraw()

func _draw() -> void:
	if dissolving:
		var alpha := maxf(0.0, 1.0 - dissolve_time / 0.5)
		for i in range(12):
			var angle := float(i) * TAU / 12.0
			draw_circle(Vector2(cos(angle), sin(angle)) * dissolve_time * 26.0, 2.4 * alpha, Color(0.98, 0.78, 0.25, alpha))
		return
	if windup > 0.0:
		draw_line(Vector2.ZERO, aim_direction * 180.0, Color(0.89, 0.46, 0.14, 0.32 + 0.35 * absf(sin(windup * 12.0))), 3.0)
		draw_circle(aim_direction * 180.0, 10.0, Color(1.0, 0.74, 0.24, 0.24))
	for i in range(8):
		var angle := -PI * 0.5 + float(i) * TAU / 8.0
		var petal := Vector2(cos(angle), sin(angle))
		draw_line(petal * 8.0 + Vector2(0, -12), petal * 22.0 + Vector2(0, -12), Color(0.84, 0.65, 0.23, 1.0), 10.0)
		draw_circle(petal * 22.0 + Vector2(0, -12), 5.0, Color(0.98, 0.81, 0.36, 1.0))
	draw_circle(Vector2(0, -12), 13.0, Color(0.55, 0.37, 0.17, 1.0))
	draw_circle(Vector2(0, -12), 8.0, Color(0.93, 0.69, 0.23, 1.0))
	draw_circle(Vector2(-3, -14), 1.8, Color(0.16, 0.12, 0.08, 1.0))
	draw_circle(Vector2(3, -14), 1.8, Color(0.16, 0.12, 0.08, 1.0))
	draw_rect(Rect2(-4, 4, 8, 16), Color(0.35, 0.48, 0.25, 1.0))
	for i in range(health):
		if i % 3 == 0:
			draw_circle(Vector2(-8.0 + float(i % 6) * 3.0, 18.0 + float(i / 6) * 4.0), 1.2, Color(1.0, 0.93, 0.62, 0.95))
