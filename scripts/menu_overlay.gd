extends CanvasLayer
# Title, pause, controls and settings menus.
# Lives on the root node so it survives the Wake -> Hub -> Greed scene switches
# (main.gd disables itself once Lumi leaves the Wake), and keeps running while
# the tree is paused. Created by main.gd. Esc opens or closes the pause menu.

const Settings := preload("res://scripts/game_settings.gd")

const INDIGO := Color(0.29, 0.23, 0.48)
const LAVENDER := Color(0.79, 0.72, 0.94)
const PEACH := Color(1.0, 0.85, 0.75)
const MUTED := Color(0.82, 0.82, 0.93)
const NIGHT := Color(0.08, 0.09, 0.16)

const CONTROLS := [
	["Move", "A / D"],
	["Jump", "Space"],
	["Dash", "Left Shift (needs Wind Ribbon)"],
	["Lantern swing", "J"],
	["Heal", "Q"],
	["Interact", "E"],
	["Swap style", "Tab (after Greed)"],
	["Heavy attack", "K (Open Hand: hold)"],
	["Skill", "L (Open Hand 20 / Lantern 30 Glow)"],
	["Guard", "I (both styles)"],
	["Overture", "O (both styles, full Glow)"],
	["Enter the hub", "T (at the first door)"],
	["Menu", "Esc"]
]

const OPTIONS := [
	["reduce_shake", "Reduce screen shake", "Softens or removes the camera shake on hits and slams."],
	["gentle_mode", "Gentle mode", "A softer way to walk: 25% less damage and lighter debuffs."],
	["fullscreen", "Fullscreen", "Fill the whole screen."]
]

var title_panel: Control
var pause_panel: Control
var settings_panel: Control
var controls_panel: Control
var current: Control = null
var return_to: Control = null
var game_running := false
var quit_armed := false
var quit_button: Button
var option_buttons: Dictionary = {}

class Motes extends Control:
	# Soft drifting lights behind the title.
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var t := Time.get_ticks_msec() / 1000.0
		draw_circle(Vector2(1040, 140), 48, Color(0.77, 0.85, 1.0, 0.10))
		draw_circle(Vector2(1040, 140), 30, Color(0.82, 0.88, 1.0, 0.80))
		for i in range(40):
			var x := fposmod(i * 211.0 + t * (5.0 + i % 5), 1320.0) - 20.0
			var y := fposmod(i * 97.0 - t * (9.0 + i % 7), 760.0) - 20.0
			var a := 0.14 + 0.12 * sin(t * 0.8 + i)
			draw_circle(Vector2(x, y), 2.0 + i % 3, Color(0.79, 0.72, 0.94, a))

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	Settings.load_settings()
	Settings.apply()
	var root_ui := Control.new()
	root_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ui.theme = _build_theme()
	add_child(root_ui)
	title_panel = _build_title()
	pause_panel = _build_pause()
	settings_panel = _build_settings()
	controls_panel = _build_controls()
	for panel in [title_panel, pause_panel, settings_panel, controls_panel]:
		panel.visible = false
		root_ui.add_child(panel)
	get_tree().paused = true
	_show_panel(title_panel)

# --- Theme and small builders -------------------------------------------------

func _box(bg: Color, border: Color, border_width := 2, radius := 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

func _build_theme() -> Theme:
	var t := Theme.new()
	var normal := _box(Color(0.17, 0.14, 0.30, 0.95), LAVENDER.darkened(0.45))
	var lit := _box(Color(0.30, 0.24, 0.50, 1.0), LAVENDER)
	var focus := _box(Color(0.30, 0.24, 0.50, 1.0), PEACH, 3)
	for kind in ["Button", "CheckButton"]:
		t.set_stylebox("normal", kind, normal)
		t.set_stylebox("hover", kind, lit)
		t.set_stylebox("pressed", kind, lit)
		t.set_stylebox("focus", kind, focus)
		t.set_color("font_color", kind, Color(0.93, 0.90, 1.0))
		t.set_color("font_hover_color", kind, Color.WHITE)
		t.set_color("font_focus_color", kind, Color.WHITE)
		t.set_color("font_pressed_color", kind, Color.WHITE)
		t.set_font_size("font_size", kind, 22)
	t.set_stylebox("panel", "PanelContainer", _box(Color(0.10, 0.09, 0.20, 0.97), LAVENDER, 2, 16))
	return t

func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _spacer(height: float) -> Control:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, height)
	return gap

func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(380, 48)
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(callback)
	return button

func _backdrop(opaque: bool) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = NIGHT if opaque else Color(0.03, 0.03, 0.08, 0.78)
	root.add_child(shade)
	if opaque:
		root.add_child(Motes.new())
	return root

func _column(root: Control, framed: bool) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.custom_minimum_size = Vector2(420, 0)
	if framed:
		var frame := PanelContainer.new()
		var margin := MarginContainer.new()
		for side in ["left", "right", "top", "bottom"]:
			margin.add_theme_constant_override("margin_" + side, 32)
		center.add_child(frame)
		frame.add_child(margin)
		margin.add_child(box)
	else:
		center.add_child(box)
	return box

# --- Panels -------------------------------------------------------------------

func _build_title() -> Control:
	var root := _backdrop(true)
	var box := _column(root, false)
	box.add_child(_label("WHAT THE WATER KEEPS", 54, LAVENDER))
	box.add_child(_label("Some things are only safe when you let go.", 20, PEACH))
	box.add_child(_spacer(30))
	var begin := _button("Begin", _on_begin)
	box.add_child(begin)
	box.add_child(_button("Controls", _open_controls.bind(title_panel_ref)))
	box.add_child(_button("Settings", _open_settings.bind(title_panel_ref)))
	box.add_child(_button("Quit", _on_quit_pressed))
	box.add_child(_spacer(16))
	box.add_child(_label("W / S or arrows to move   Enter or Space to choose   Esc to go back", 17, MUTED))
	box.add_child(_label("Prototype 02", 16, MUTED))
	root.set_meta("first", begin)
	return root

func _build_pause() -> Control:
	var root := _backdrop(false)
	var box := _column(root, true)
	box.add_child(_label("PAUSED", 36, LAVENDER))
	box.add_child(_spacer(6))
	var resume := _button("Resume", _resume)
	box.add_child(resume)
	box.add_child(_button("Controls", _open_controls.bind(pause_panel_ref)))
	box.add_child(_button("Settings", _open_settings.bind(pause_panel_ref)))
	quit_button = _button("Quit game", _on_quit_pressed)
	box.add_child(quit_button)
	box.add_child(_label("Progress is not saved yet.", 17, MUTED))
	root.set_meta("first", resume)
	return root

func _build_settings() -> Control:
	var root := _backdrop(false)
	var box := _column(root, true)
	box.add_child(_label("SETTINGS", 36, LAVENDER))
	box.add_child(_spacer(4))
	for option in OPTIONS:
		var key: String = option[0]
		var toggle := CheckButton.new()
		toggle.text = option[1]
		toggle.focus_mode = Control.FOCUS_ALL
		toggle.custom_minimum_size = Vector2(380, 46)
		toggle.toggled.connect(_on_option_toggled.bind(key))
		box.add_child(toggle)
		box.add_child(_label(option[2], 16, MUTED))
		option_buttons[key] = toggle
	box.add_child(_spacer(6))
	var back := _button("Back", _go_back)
	box.add_child(back)
	root.set_meta("first", option_buttons["reduce_shake"])
	return root

func _build_controls() -> Control:
	var root := _backdrop(false)
	var box := _column(root, true)
	box.add_child(_label("CONTROLS", 36, LAVENDER))
	box.add_child(_spacer(4))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 28)
	grid.add_theme_constant_override("v_separation", 8)
	box.add_child(grid)
	for row in CONTROLS:
		# No autowrap here: wrapped labels in a grid collapse to a sliver.
		var action := _label(row[0], 19, MUTED)
		action.autowrap_mode = TextServer.AUTOWRAP_OFF
		action.custom_minimum_size = Vector2(170, 0)
		action.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		var key := _label(row[1], 19, Color(0.93, 0.90, 1.0))
		key.autowrap_mode = TextServer.AUTOWRAP_OFF
		key.custom_minimum_size = Vector2(300, 0)
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		grid.add_child(action)
		grid.add_child(key)
	box.add_child(_spacer(8))
	var back := _button("Back", _go_back)
	box.add_child(back)
	root.set_meta("first", back)
	return root

# Panels are built before they are assigned, so the Controls / Settings buttons
# look the panel up when pressed instead of capturing it at build time.
var title_panel_ref: String = "title"
var pause_panel_ref: String = "pause"

func _panel_for(ref: Variant) -> Control:
	return title_panel if str(ref) == "title" else pause_panel

# --- Navigation ---------------------------------------------------------------

func _show_panel(panel: Control) -> void:
	for p in [title_panel, pause_panel, settings_panel, controls_panel]:
		p.visible = false
	panel.visible = true
	current = panel
	if panel == settings_panel:
		for key in option_buttons:
			(option_buttons[key] as CheckButton).set_pressed_no_signal(Settings.get_option(key))
	if panel == pause_panel:
		quit_armed = false
		quit_button.text = "Quit game"
	_focus_first.call_deferred(panel)

func _focus_first(panel: Control) -> void:
	var first: Control = panel.get_meta("first", null)
	if first:
		first.grab_focus()

func _open_controls(from_ref: Variant) -> void:
	return_to = _panel_for(from_ref)
	_show_panel(controls_panel)

func _open_settings(from_ref: Variant) -> void:
	return_to = _panel_for(from_ref)
	_show_panel(settings_panel)

func _go_back() -> void:
	_show_panel(return_to if return_to else pause_panel)

func _on_begin() -> void:
	game_running = true
	_resume()

func _open_pause() -> void:
	get_tree().paused = true
	_show_panel(pause_panel)

func _resume() -> void:
	for p in [title_panel, pause_panel, settings_panel, controls_panel]:
		p.visible = false
	current = null
	get_tree().paused = false

func _on_quit_pressed() -> void:
	# Two presses on the pause menu, since nothing is saved yet.
	if current == pause_panel and not quit_armed:
		quit_armed = true
		quit_button.text = "Really quit? Press again"
		return
	get_tree().quit()

func _on_option_toggled(pressed: bool, key: String) -> void:
	Settings.set_option(key, pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _handle_cancel():
			get_viewport().set_input_as_handled()
		return
	if current != null and event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_W:
			_step_focus(-1)
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_S:
			_step_focus(1)
			get_viewport().set_input_as_handled()

func _handle_cancel() -> bool:
	if current == settings_panel or current == controls_panel:
		_go_back()
		return true
	if current == pause_panel:
		_resume()
		return true
	if current == title_panel:
		return true
	# No menu open: only pause during normal play, never during a hit freeze.
	if game_running and not get_tree().paused:
		_open_pause()
		return true
	return false

func _step_focus(direction: int) -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused == null:
		return
	var next := focused.find_next_valid_focus() if direction > 0 else focused.find_prev_valid_focus()
	if next:
		next.grab_focus()
