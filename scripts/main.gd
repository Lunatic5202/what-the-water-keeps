extends Node2D

var player: CharacterBody2D
var jelly: CharacterBody2D
var old_moss: CharacterBody2D
var stats_label: Label
var hud_layer: CanvasLayer
var prompt_label: Label
var dialogue_panel: ColorRect
var dialogue_label: Label
var dialogue_target: Node2D
var interactables: Array[Dictionary] = []
var dialogue_open := false
var has_wind_ribbon := false
var reached_greed := false
var moss_defeated := false
var current_region := "wake"  # wake, hub, greed, etc.
var respawn_point := Vector2(240, 570)
var status_id := 0

# Region references for scene management
var hub_scene: Node2D = null
var greed_scene: Node2D = null
var pending_transition := ""
var combat_feedback: Node2D = null

const SIGN_MESSAGES := [
	"Walk! (it's easy, I believe in you)",
	"Jump over the tiny puddle.",
	"Swing your lantern. Hit the little jelly. He is very forgiving.",
    "Healing takes a moment. Be brave, but not silly."
]

func _ready() -> void:
	_create_menus()
	_create_ground()
	_create_player()
	_create_jelly()
	_create_old_moss()
	_create_hud()
	_create_wake_tutorial()
	player.health_changed.connect(_update_hud)
	player.heals_changed.connect(_update_hud)
	player.status_changed.connect(_show_status)
	jelly.defeated.connect(_jelly_defeated)
	old_moss.defeated.connect(_moss_defeated)
	_update_hud()

func _create_menus() -> void:
	# Lives on the root so it survives main being disabled after the hub loads.
	if get_tree().root.has_node("MenuOverlay"):
		return
	var overlay := CanvasLayer.new()
	overlay.name = "MenuOverlay"
	overlay.set_script(load("res://scripts/menu_overlay.gd"))
	get_tree().root.add_child.call_deferred(overlay)

func _process(_delta: float) -> void:
	if pending_transition == "hub" and Input.is_action_just_pressed("enter_region"):
		_transition_to_hub()
		return

	# Falling below the level sends Lumi safely back to the shore.
	if is_instance_valid(player) and player.global_position.y > 900.0:
		player.global_position = respawn_point
		player.velocity = Vector2.ZERO
		_show_status("THE WATER CATCHES LUMI. BACK TO SAFE GROUND.")

	if dialogue_open:
		var walked_away := not is_instance_valid(dialogue_target)
		if is_instance_valid(dialogue_target):
			walked_away = player.global_position.distance_to(dialogue_target.global_position) > 95.0
		if walked_away or Input.is_action_just_pressed("interact"):
			dialogue_panel.visible = false
			dialogue_open = false
			dialogue_target = null
			pending_transition = ""
		else:
			prompt_label.text = ""
			return

	var nearest: Dictionary = {}
	var nearest_distance := 95.0
	for item in interactables:
		var target: Node2D = item["node"]
		if not is_instance_valid(target) or item.get("used", false):
			continue
		var distance := player.global_position.distance_to(target.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = item

	prompt_label.text = "E  •  interact" if not nearest.is_empty() else ""
	if not nearest.is_empty() and Input.is_action_just_pressed("interact"):
		_interact(nearest)

func _draw() -> void:
	# Wake palette: meadow green, cream, sky (#BFE3B4, #FFF6DC, #CFE8F7)
	draw_rect(Rect2(-3000, -1000, 8000, 1800), Color(0.81, 0.91, 0.97, 1))

	# Sun
	draw_circle(Vector2(1800, 180), 55, Color(1.0, 0.98, 0.92, 0.3))
	draw_circle(Vector2(1800, 180), 38, Color(1.0, 0.96, 0.86, 1.0))

	# Tutorial ground - meadow green
	draw_rect(Rect2(0, 610, 2200, 150), Color(0.75, 0.89, 0.71, 1))
	draw_rect(Rect2(0, 610, 2200, 4), Color(0.85, 0.94, 0.82, 1))

	# Boss arena - circular moss clearing framed by old trees
	draw_circle(Vector2(2800, 610), 380, Color(0.68, 0.82, 0.65, 1))
	draw_rect(Rect2(2200, 610, 1200, 150), Color(0.68, 0.82, 0.65, 1))
	draw_rect(Rect2(2200, 610, 1200, 4), Color(0.78, 0.88, 0.72, 1))
	for tree_x in [2300.0, 3300.0]:
		draw_rect(Rect2(tree_x - 24, 350, 48, 260), Color(0.43, 0.49, 0.36, 1))
		draw_circle(Vector2(tree_x, 330), 92, Color(0.56, 0.70, 0.51, 1))
		draw_circle(Vector2(tree_x - 55, 380), 62, Color(0.61, 0.75, 0.55, 1))
		draw_circle(Vector2(tree_x + 55, 380), 62, Color(0.61, 0.75, 0.55, 1))

	# Moss stones make the arena boundary readable without trapping Lumi
	for stone_x in [2240.0, 2340.0, 3260.0, 3360.0]:
		draw_circle(Vector2(stone_x, 596), 24, Color(0.51, 0.61, 0.48, 1))
		draw_circle(Vector2(stone_x, 590), 16, Color(0.68, 0.78, 0.62, 1))

	# The Wind Ribbon is before the dash gap.
	draw_rect(Rect2(3400, 610, 500, 150), Color(0.80, 0.92, 0.76, 1))
	draw_rect(Rect2(3400, 610, 500, 4), Color(0.88, 0.96, 0.85, 1))
	draw_rect(Rect2(4100, 610, 700, 150), Color(0.80, 0.92, 0.76, 1))
	draw_rect(Rect2(4100, 610, 700, 4), Color(0.88, 0.96, 0.85, 1))
	draw_rect(Rect2(3900, 610, 200, 150), Color(0.57, 0.77, 0.86, 0.75))

	# Boundary posts
	draw_rect(Rect2(35, 475, 40, 135), Color(0.56, 0.62, 0.54, 1))
	draw_rect(Rect2(35, 475, 40, 5), Color(0.75, 0.82, 0.71, 1))
	draw_rect(Rect2(4580, 475, 40, 135), Color(0.56, 0.62, 0.54, 1))
	draw_rect(Rect2(4580, 475, 40, 5), Color(0.75, 0.82, 0.71, 1))

func _create_ground() -> void:
	# Tutorial path: signs and jelly (0 to 2200)
	_create_ground_section(Vector2(1100, 650), Vector2(2200, 80), "TutorialGround")

	# Boss arena (2200 to 3400)
	_create_ground_section(Vector2(2800, 650), Vector2(1200, 80), "BossArena")

	# Post-boss path split by a gap that needs jump + Wind Ribbon dash.
	_create_ground_section(Vector2(3650, 650), Vector2(500, 80), "RibbonPath")
	_create_ground_section(Vector2(4450, 650), Vector2(700, 80), "GreedApproach")

	# Invisible walls
	_create_boundary(Vector2(55, 0), "StartBoundary")
	_create_boundary(Vector2(4600, 0), "EndBoundary")

func _create_boundary(at: Vector2, boundary_name: String) -> void:
	var wall := StaticBody2D.new()
	wall.name = boundary_name
	wall.position = at
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(40, 1600)
	collision.shape = shape
	wall.add_child(collision)
	add_child(wall)

func _create_ground_section(at: Vector2, size: Vector2, section_name: String) -> void:
	var ground := StaticBody2D.new()
	ground.name = section_name
	ground.position = at
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	ground.add_child(collision)
	add_child(ground)

func _create_player() -> void:
	player = CharacterBody2D.new()
	player.name = "Lumi"
	player.position = Vector2(240, 570)
	player.set_script(load("res://scripts/player.gd"))
	var collision := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 13.0
	shape.height = 42.0
	collision.shape = shape
	player.add_child(collision)
	add_child(player)

	var camera := Camera2D.new()
	camera.position = Vector2(0, -100)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	camera.limit_left = 0
	camera.limit_right = 4650
	camera.limit_bottom = 800
	player.add_child(camera)
	camera.add_to_group("game_camera")

	var feedback_script = load("res://scripts/combat_feedback.gd")
	combat_feedback = feedback_script.new(camera)
	combat_feedback.add_to_group("combat_feedback")
	combat_feedback.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(combat_feedback)
	player.set("respawn_point", respawn_point)

func _create_jelly() -> void:
	jelly = CharacterBody2D.new()
	jelly.name = "LittleJelly"
	jelly.position = Vector2(570, 590)
	jelly.set_script(load("res://scripts/little_jelly.gd"))
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 18.0
	collision.shape = shape
	jelly.add_child(collision)
	add_child(jelly)

func _create_old_moss() -> void:
	old_moss = CharacterBody2D.new()
	old_moss.name = "OldMoss"
	old_moss.position = Vector2(2800, 560)
	old_moss.set_script(load("res://scripts/old_moss.gd"))
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 32.0
	collision.shape = shape
	old_moss.add_child(collision)
	add_child(old_moss)

func _create_hud() -> void:
	hud_layer = CanvasLayer.new()
	add_child(hud_layer)
	var hud := hud_layer

	var title := Label.new()
	title.position = Vector2(24, 18)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.91, 0.91, 1.0))
	title.text = "WHAT THE WATER KEEPS  •  WAKE"
	hud.add_child(title)

	stats_label = Label.new()
	stats_label.position = Vector2(24, 128)
	stats_label.add_theme_font_size_override("font_size", 18)
	stats_label.add_theme_color_override("font_color", Color(0.77, 0.88, 1.0))
	hud.add_child(stats_label)

	var meter := Control.new()
	meter.set_script(load("res://scripts/lantern_meter.gd"))
	meter.position = Vector2(24, 52)
	hud.add_child(meter)

	var help := Label.new()
	help.position = Vector2(24, 670)
	help.add_theme_font_size_override("font_size", 16)
	help.add_theme_color_override("font_color", Color(0.82, 0.83, 0.9))
	help.text = "A/D move   SPACE jump   J lantern swing   LEFT SHIFT dash   Q heal   E interact   ESC menu"
	hud.add_child(help)

	prompt_label = Label.new()
	prompt_label.position = Vector2(0, 610)
	prompt_label.size = Vector2(1280, 32)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 21)
	prompt_label.add_theme_color_override("font_color", Color(0.80, 0.94, 1.0))
	hud.add_child(prompt_label)

	dialogue_panel = ColorRect.new()
	dialogue_panel.position = Vector2(180, 500)
	dialogue_panel.size = Vector2(920, 105)
	dialogue_panel.color = Color(0.07, 0.09, 0.17, 0.94)
	dialogue_panel.visible = false
	hud.add_child(dialogue_panel)

	dialogue_label = Label.new()
	dialogue_label.position = Vector2(22, 16)
	dialogue_label.size = Vector2(876, 74)
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_label.add_theme_font_size_override("font_size", 23)
	dialogue_label.add_theme_color_override("font_color", Color(0.91, 0.93, 1.0))
	dialogue_panel.add_child(dialogue_label)

func _create_wake_tutorial() -> void:
	var sign_positions := [Vector2(355, 570), Vector2(560, 570), Vector2(820, 570), Vector2(1100, 570)]
	for i in range(SIGN_MESSAGES.size()):
		var sign_marker := _make_marker("SIGN %d\n[E] READ" % (i + 1), sign_positions[i], Color(0.60, 0.75, 0.58))
		interactables.append({"node": sign_marker, "message": SIGN_MESSAGES[i], "kind": "sign", "used": false})

	# Arena entrance marker
	var arena_marker := _make_marker("MOSS CLEARING\n[E] ENTER", Vector2(1650, 565), Color(0.65, 0.78, 0.68))
	interactables.append({
		"node": arena_marker,
		"message": "A circular clearing ahead. Old Moss waits in the center, guarding something.",
		"kind": "arena_entrance",
		"used": false
	})

	var moss_marker := _make_marker("OLD MOSS\n[E] APPROACH", Vector2(2800, 520), Color(0.65, 0.78, 0.68))
	interactables.append({
		"node": moss_marker,
		"message": "Little light... that ribbon is all I have left of the wind.\n\n(Lumi steps closer. Old Moss readies himself.)",
		"kind": "moss",
		"used": false
	})

	var ribbon := _make_marker("✧\nWIND RIBBON", Vector2(3750, 565), Color(0.57, 0.91, 1.0))
	ribbon.visible = false
	interactables.append({
		"node": ribbon,
		"message": "Nim flutters warmly inside your lantern.\n\n'Pretend you're a leaf in a breeze.'\n\nWind Ribbon found.",
		"kind": "ribbon",
		"used": false
	})

	var door := _make_marker("THE FIRST DOOR", Vector2(4380, 565), Color(1.0, 0.81, 0.47))
	interactables.append({
		"node": door,
		"message": "The first golden door waits quietly. Beyond it, something has mistaken holding on for being safe.\n\n[T] Enter Hub?",
		"kind": "door",
		"used": false
	})

func _make_marker(marker_text: String, at: Vector2, tint: Color) -> Node2D:
	var marker := Node2D.new()
	marker.position = at
	var label := Label.new()
	label.text = marker_text
	label.position = Vector2(-55, -78)
	label.size = Vector2(110, 70)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", tint)
	marker.add_child(label)
	add_child(marker)
	return marker

func _interact(item: Dictionary) -> void:
	var kind: String = item["kind"]
	var target: Node2D = item["node"]
	if kind == "door" and not has_wind_ribbon:
		_show_dialogue("The golden door hums, but the gap before it is too wide. Look for something light enough to ride the breeze.", target)
		return
	if kind == "moss":
		item["used"] = true
		target.visible = false
		old_moss.start_fight()
		_show_dialogue(item["message"], target)
	elif kind == "arena_entrance":
		item["used"] = true
		_show_dialogue(item["message"], target)
	elif kind == "ribbon":
		has_wind_ribbon = true
		item["used"] = true
		target.visible = false
		respawn_point = Vector2(3750, 570)
		player.set("respawn_point", respawn_point)
		player.set("has_dash", true)
		_show_dialogue(item["message"], target)
	elif kind == "door":
		reached_greed = true
		pending_transition = "hub"
		_show_dialogue("Enter the Hub (The Still Pond)?\n\n[T] Press T to continue.", target)
		prompt_label.text = "T  •  ENTER HUB"
	else:
		_show_dialogue(item["message"], target)

func _transition_to_hub() -> void:
	pending_transition = ""
	dialogue_panel.visible = false
	dialogue_open = false
	current_region = "hub"

	hub_scene = Node2D.new()
	hub_scene.set_script(load("res://scripts/hub.gd"))
	hub_scene.set("player", player)
	hub_scene.connect("region_entered", Callable(self, "_on_hub_region_entered"))
	get_parent().add_child(hub_scene)

	remove_child(player)
	hub_scene.add_child(player)
	player.position = hub_scene.get("respawn_point")
	player.set("respawn_point", hub_scene.get("respawn_point"))
	_set_camera_limits(-200, 3000, 100, 850)
	visible = false
	hud_layer.visible = false
	process_mode = Node.PROCESS_MODE_DISABLED

func _on_hub_region_entered(region_name: String) -> void:
	if region_name == "greed":
		_transition_to_greed()

func _transition_to_greed() -> void:
	if not is_instance_valid(hub_scene) or not is_instance_valid(player):
		return
	hub_scene.call("set_region_active", false)

	if not is_instance_valid(greed_scene):
		greed_scene = Node2D.new()
		greed_scene.set_script(load("res://scripts/greed.gd"))
		greed_scene.set("player", player)
		greed_scene.connect("return_to_hub", Callable(self, "_return_to_hub"))
		greed_scene.connect("region_cleared", Callable(self, "_on_region_cleared"))
		get_parent().add_child(greed_scene)
	else:
		greed_scene.call("set_region_active", true)

	hub_scene.remove_child(player)
	greed_scene.add_child(player)
	player.position = greed_scene.get("respawn_point")
	player.set("respawn_point", greed_scene.get("respawn_point"))
	_set_camera_limits(0, 2850, 100, 750)
	current_region = "greed"

func _return_to_hub() -> void:
	if not is_instance_valid(hub_scene) or not is_instance_valid(greed_scene):
		return
	if player.get_parent() == greed_scene:
		greed_scene.remove_child(player)
	greed_scene.call("set_region_active", false)
	hub_scene.add_child(player)
	player.position = hub_scene.get("respawn_point")
	player.set("respawn_point", hub_scene.get("respawn_point"))
	hub_scene.call("set_region_active", true)
	_set_camera_limits(-200, 3000, 100, 850)
	current_region = "hub"

func _on_region_cleared(region_name: String) -> void:
	if is_instance_valid(hub_scene):
		hub_scene.call("unlock_region", region_name)
	_return_to_hub()

func _set_camera_limits(left: int, right: int, top: int, bottom: int) -> void:
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	camera.position = Vector2(0, -100)
	camera.limit_left = left
	camera.limit_right = right
	camera.limit_top = top
	camera.limit_bottom = bottom

func _show_dialogue(message: String, target: Node2D = null) -> void:
	dialogue_label.text = message
	dialogue_panel.visible = true
	dialogue_open = true
	dialogue_target = target

func _update_hud(_value: int = 0) -> void:
	if not is_instance_valid(player) or not is_instance_valid(stats_label):
		return
	stats_label.text = "WIND RIBBON: FOUND" if has_wind_ribbon else ""

func _show_status(message: String) -> void:
	status_id += 1
	var my_id := status_id
	stats_label.text = message
	await get_tree().create_timer(1.6).timeout
	# Only the newest message restores the HUD, so overlapping ones don't flicker.
	if my_id == status_id:
		_update_hud()

func _jelly_defeated() -> void:
	stats_label.text = "THE LITTLE JELLY IS RESTING. (IT WAS VERY FORGIVING.)"

func _moss_defeated() -> void:
	moss_defeated = true
	_show_status("OLD MOSS LOWERS HIS HEAD. THE RIBBON GLOWS SOFTLY NEARBY.")
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(player):
		_show_dialogue("Old Moss lowers his head. For a moment, he looks less like a guardian and more like something that misses the wind.\n\nNim whispers: \"Be gentle with it. It remembers being free.\"", player)
	await get_tree().create_timer(0.2).timeout
	# Show the Wind Ribbon after defeating Old Moss
	for item in interactables:
		if item["kind"] == "ribbon":
			var ribbon_node: Node2D = item["node"]
			ribbon_node.visible = true
			break
