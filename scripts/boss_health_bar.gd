extends Control

# Screen-space boss HUD. It lives under each region's CanvasLayer so it follows
# the viewport and can be shown by any active boss without tracking world space.
var active_boss: Node
var boss_title := ""
var health := 0
var max_health := 1
var fight_active := false

func _ready() -> void:
	add_to_group("boss_health_bar")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	visible = false

func show_boss(boss: Node, title: String, current: int, maximum: int) -> void:
	active_boss = boss
	boss_title = title
	health = current
	max_health = maxi(1, maximum)
	fight_active = true
	_update_visibility()
	queue_redraw()

func update_boss_health(boss: Node, current: int, maximum: int) -> void:
	if not fight_active or boss != active_boss:
		return
	health = current
	max_health = maxi(1, maximum)
	queue_redraw()

func hide_boss(boss: Node) -> void:
	if boss != active_boss:
		return
	fight_active = false
	active_boss = null
	boss_title = ""
	visible = false

func _process(_delta: float) -> void:
	if fight_active:
		_update_visibility()

func _update_visibility() -> void:
	var dialogue_open := false
	for panel in get_tree().get_nodes_in_group("boss_dialogue_panel"):
		if is_instance_valid(panel) and panel.is_visible_in_tree():
			dialogue_open = true
			break
	visible = fight_active and not dialogue_open

func _draw() -> void:
	if not fight_active:
		return
	var viewport_width := get_viewport_rect().size.x
	var center_x := viewport_width * 0.5
	var bar_width := minf(520.0, viewport_width - 48.0)
	var bar_height := 13.0
	var bar_x := center_x - bar_width * 0.5
	var bar_y := get_viewport_rect().size.y - 68.0
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(center_x, bar_y - 14.0), boss_title, HORIZONTAL_ALIGNMENT_CENTER, -1.0, 18, Color(0.96, 0.91, 0.78, 1.0))
	draw_rect(Rect2(bar_x - 3.0, bar_y - 3.0, bar_width + 6.0, bar_height + 6.0), Color(0.08, 0.07, 0.10, 0.88))
	draw_rect(Rect2(bar_x, bar_y, bar_width, bar_height), Color(0.22, 0.12, 0.12, 1.0))
	var ratio := clampf(float(health) / float(max_health), 0.0, 1.0)
	draw_rect(Rect2(bar_x, bar_y, bar_width * ratio, bar_height), Color(0.77, 0.18, 0.15, 1.0))
	draw_rect(Rect2(bar_x - 1.0, bar_y - 1.0, bar_width + 2.0, bar_height + 2.0), Color(0.82, 0.72, 0.53, 0.95), false, 1.5)
