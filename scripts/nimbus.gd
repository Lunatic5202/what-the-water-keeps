extends CharacterBody2D
# Napping Nimbus (Sloth): a puffy cloud that drifts and releases sleep spores.

signal defeated

const SPORE := preload("res://scripts/sleep_spore.gd")

var health := 25
var home := Vector2.ZERO
var t := 0.0
var spore_timer := 2.5
var attack_cooldown := 0.0
var hurt_flash := 0.0
var stun_time := 0.0
var dissolving := false
var dissolve_timer := 0.0
var puff := 0.0

func _ready() -> void:
	home = global_position
	collision_mask = 0

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
	t += delta
	global_position = home + Vector2(sin(t * 0.7) * 110.0, sin(t * 1.3) * 16.0)
	spore_timer -= delta
	puff = maxf(0.0, puff - delta)
	if spore_timer <= 0.8 and puff <= 0.0 and spore_timer > 0.0:
		puff = 0.8
	if spore_timer <= 0.0:
		spore_timer = 3.0
		var spore := Node2D.new()
		spore.set_script(SPORE)
		spore.set("velocity", Vector2(randf_range(-20.0, 20.0), 85.0))
		spore.set("drowse", 15.0)
		get_parent().add_child(spore)
		spore.global_position = global_position + Vector2(0, 22)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	var player := get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and attack_cooldown <= 0.0 \
			and global_position.distance_to(player.global_position) < 36.0:
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
	var body := Color(0.93, 0.9, 1.0, fade)
	var ink := Color(0.16, 0.13, 0.32, fade)
	if hurt_flash > 0.0:
		body = Color(1.0, 0.9, 0.9, fade)
	var s := 1.0 + puff * 0.25
	for offset in [Vector2(-18, 4), Vector2(0, -6), Vector2(18, 4), Vector2(0, 8)]:
		draw_circle(offset * s, 16.0 * s, body)
	draw_arc(Vector2(0, -6) * s, 16.0 * s, PI, TAU, 14, ink, 2.0)
	draw_line(Vector2(-9, 0), Vector2(-3, 0), ink, 2.0)
	draw_line(Vector2(3, 0), Vector2(9, 0), ink, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(14, -22), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.82, 0.8, 1.0, fade))
	if puff > 0.0:
		draw_circle(Vector2(0, 26), 5.0 + puff * 4.0, Color(0.72, 0.65, 0.92, 0.7))
