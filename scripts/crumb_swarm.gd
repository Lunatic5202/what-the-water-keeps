extends CharacterBody2D
# Crumb Swarm (Gluttony): a cloud of crumbs that drifts toward Lumi. Hit it and
# it scatters, then re-forms. Prototype stats.

signal defeated

var health := 14
var home := Vector2.ZERO
var scatter := 0.0
var hurt_flash := 0.0
var attack_cooldown := 0.0
var dissolving := false
var dissolve_timer := 0.0
var stun_time := 0.0
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
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	var player := get_tree().get_first_node_in_group("player")
	var want := home + Vector2(sin(t * 1.3) * 40.0, cos(t * 1.7) * 18.0)
	if scatter > 0.0:
		scatter -= delta
		want = global_position
	elif is_instance_valid(player) and global_position.distance_to(player.global_position) < 330.0 \
			and absf(global_position.x - home.x) < 260.0:
		want = player.global_position + Vector2(0, -30)
	global_position = global_position.move_toward(want, 70.0 * delta)
	if is_instance_valid(player) and scatter <= 0.0 and attack_cooldown <= 0.0 \
			and global_position.distance_to(player.global_position) < 34.0:
		player.take_damage(1)
		attack_cooldown = 1.1
	queue_redraw()

func take_damage(amount: int) -> void:
	if dissolving:
		return
	health -= amount
	hurt_flash = 0.15
	scatter = 0.7
	if health <= 0:
		dissolving = true
		defeated.emit()

func _draw() -> void:
	var fade := 1.0 - dissolve_timer / 0.5 if dissolving else 1.0
	var spread := 1.0 + (scatter / 0.7) * 1.8 + dissolve_timer * 3.0
	for i in range(12):
		var a := float(i) * 2.399 + t * 0.8
		var r := (6.0 + float(i % 4) * 5.0) * spread
		var pos := Vector2(cos(a), sin(a)) * r
		var col := Color(0.82, 0.55, 0.36, fade) if i % 3 else Color(0.96, 0.78, 0.5, fade)
		if hurt_flash > 0.0:
			col = Color(1, 1, 1, fade)
		draw_circle(pos, 4.0, col)
		draw_arc(pos, 4.0, 0.0, TAU, 8, Color(0.36, 0.22, 0.16, fade), 1.2)
	# Crumbs arrange themselves into eyes (bible art note).
	draw_circle(Vector2(-6, -2), 2.0, Color(0.2, 0.12, 0.1, fade * 0.8))
	draw_circle(Vector2(6, -2), 2.0, Color(0.2, 0.12, 0.1, fade * 0.8))
