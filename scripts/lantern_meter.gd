extends Control
# HUD health meter: a paper lantern whose flame shrinks as health drops,
# a thin health bar, and small oil drops for heal charges.
# It reads Lumi directly (group "player"), so every region can reuse it.

const MAX_DROPS := 3
const INDIGO := Color(0.29, 0.23, 0.48)
const LAVENDER := Color(0.79, 0.72, 0.94)

func _ready() -> void:
	size = Vector2(290, 68)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var health := float(player.get("health"))
	var max_health := maxf(1.0, float(player.get("max_health")))
	var heals := int(player.get("heals"))
	var frac := clampf(health / max_health, 0.0, 1.0)
	_draw_lantern(Vector2(32, 33), frac)
	_draw_bar(frac, int(health), int(max_health))
	_draw_drops(heals)

func _draw_lantern(c: Vector2, frac: float) -> void:
	draw_circle(c, 28.0, Color(1.0, 0.85, 0.55, 0.06 + 0.14 * frac))
	# Paper body.
	var body := PackedVector2Array()
	for i in range(24):
		var a := TAU * i / 24.0
		body.append(c + Vector2(cos(a) * 17.0, sin(a) * 22.0))
	draw_colored_polygon(body, Color(0.97, 0.91, 0.82, 0.96))
	for x in [-9.0, 0.0, 9.0]:
		draw_line(c + Vector2(x, -19.0 + absf(x) * 0.5), c + Vector2(x, 19.0 - absf(x) * 0.5),
			Color(0.8, 0.68, 0.52, 0.45), 1.5)
	# Caps and handle.
	draw_rect(Rect2(c.x - 10, c.y - 27, 20, 5), INDIGO)
	draw_rect(Rect2(c.x - 10, c.y + 22, 20, 5), INDIGO)
	draw_arc(Vector2(c.x, c.y - 27), 8.0, PI, TAU, 10, LAVENDER, 2.0)
	# Flame: smaller as health drops, gone at zero.
	if frac <= 0.0:
		return
	var flicker := 1.0 + 0.07 * sin(Time.get_ticks_msec() * 0.013)
	var r := lerpf(2.5, 11.0, frac) * flicker
	var core := c + Vector2(0, 5)
	draw_circle(core, r * 1.9, Color(1.0, 0.8, 0.4, 0.22))
	draw_colored_polygon(PackedVector2Array([
		core + Vector2(-r * 0.75, 0), core + Vector2(0, -r * 1.9), core + Vector2(r * 0.75, 0)
	]), Color(1.0, 0.7, 0.3))
	draw_circle(core, r, Color(1.0, 0.72, 0.3))
	draw_circle(core + Vector2(0, 1), r * 0.55, Color(1.0, 0.94, 0.7))

func _draw_bar(frac: float, health: int, max_health: int) -> void:
	var bar := Rect2(68, 20, 170, 8)
	draw_rect(bar.grow(2.0), Color(0.12, 0.1, 0.22, 0.85))
	var low := Color(0.95, 0.55, 0.55)
	var color := LAVENDER.lerp(low, clampf((0.5 - frac) / 0.4, 0.0, 1.0))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)), color)
	draw_string(ThemeDB.fallback_font, Vector2(246, 29), "%d / %d" % [health, max_health],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.82, 0.83, 0.92))

func _draw_drops(heals: int) -> void:
	for i in range(MAX_DROPS):
		var at := Vector2(76 + i * 24, 48)
		var tip := PackedVector2Array([at + Vector2(-4.5, 2), at + Vector2(0, -9), at + Vector2(4.5, 2)])
		if i < heals:
			var oil := Color(0.55, 0.82, 1.0)
			draw_colored_polygon(tip, oil)
			draw_circle(at + Vector2(0, 3), 5.0, oil)
		else:
			var faint := Color(0.55, 0.82, 1.0, 0.35)
			draw_polyline(PackedVector2Array([tip[0], tip[1], tip[2]]), faint, 1.5)
			draw_arc(at + Vector2(0, 3), 5.0, 0.0, TAU, 12, faint, 1.5)
