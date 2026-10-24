extends Node2D

signal region_entered(region_name: String)

var player: CharacterBody2D
var stats_label: Label
var prompt_label: Label
var dialogue_panel: ColorRect
var dialogue_label: Label
var dialogue_target: Node2D
var interactables: Array[Dictionary] = []
var dialogue_open := false
var status_id := 0

# World state
var unlocked_regions: Array[String] = []  # Regions cleared
var current_region := "wake"
var respawn_point := Vector2(250, 680)
var regions_unlocked := 0  # How many regions (doors) are open

# Hub elements
var doors: Array[Node2D] = []
var reflection: Node2D = null
var door_lights: Array[Node2D] = []

const DOOR_POSITIONS := {
	"greed": Vector2(300, 640),
	"sloth": Vector2(500, 580),
	"gluttony": Vector2(850, 480),
	"envy": Vector2(1500, 380),
	"lust": Vector2(1950, 480),
	"wrath": Vector2(2250, 580),
	"pride": Vector2(2700, 640)
}

const DOOR_SYMBOLS := {
	"greed": "coin",
	"sloth": "hammock",
	"gluttony": "spoon",
	"envy": "window",
	"lust": "ribbon",
	"wrath": "kettle",
	"pride": "crown"
}

const DOOR_NAMES := {
	"greed": "THE GILDED GARDEN",
	"sloth": "SLUMBER HOLLOW",
	"gluttony": "THE ENDLESS TABLE",
	"envy": "THE GALLERY OF GLASS",
	"lust": "THE RIBBON ORCHARD",
	"wrath": "THE ASHEN KETTLE",
	"pride": "THE TOWER OF APPLAUSE"
}

func _ready() -> void:
	_create_background()
	_create_ground()
	_create_hub_elements()
	_create_hud()
	_create_npcs()
	_create_doors()

	# Only create player if not transitioning from Wake
	if not is_instance_valid(player):
		_create_player()

	# A transferred player is parented immediately after _ready().
	call_deferred("_finish_player_setup")

	_update_hud()

func _finish_player_setup() -> void:
	if not is_instance_valid(player):
		return
	_connect_signals()
	_update_hud()

func _create_background() -> void:
	# Background is drawn in _draw()
	# Reflection placeholder (will be animated)
	reflection = Node2D.new()
	reflection.position = Vector2(640, 485)
	add_child(reflection)

func _draw() -> void:
	# Hub palette per art doc: lavender, peach, mint, deep indigo
	# #C9B8F0, #FFD9C0, #CFF1E0, #4A3A7A

	# Sky - lavender gradient
	draw_rect(Rect2(-3000, -2000, 8000, 4000), Color(0.79, 0.72, 0.94, 1.0))

	# Distant hills - peach and mint
	for i in range(15):
		var x := -800 + i * 300
		var height := 180 + sin(i * 1.5) * 60
		var hill := PackedVector2Array([
			Vector2(x - 150, 750), Vector2(x, 750 - height),
			Vector2(x + 150, 750)
		])
		var hill_color := Color(0.81, 0.85, 0.88, 1.0) if i % 2 == 0 else Color(0.82, 0.87, 0.94, 1.0)
		draw_colored_polygon(hill, hill_color)

	# The Still Pond - center high platform
	# Soft blues and silvers per spec
	draw_circle(Vector2(1200, 400), 180, Color(0.73, 0.8, 0.9, 0.5))
	draw_circle(Vector2(1200, 400), 150, Color(0.75, 0.85, 0.95, 0.6))
	draw_circle(Vector2(1200, 400), 110, Color(0.68, 0.82, 0.92, 0.75))

	# Platform visuals - deep indigo #4A3A7A
	var platform_color := Color(0.29, 0.23, 0.48, 1.0)
	var platform_highlight := Color(0.51, 0.47, 0.63, 1.0)

	# Bottom ground
	draw_rect(Rect2(200 - 400, 720 - 30, 800, 60), platform_color)
	draw_rect(Rect2(200 - 400, 720 - 30, 800, 3), platform_highlight)

	# Mid-left ascending
	draw_rect(Rect2(450 - 150, 620 - 20, 300, 40), platform_color)
	draw_rect(Rect2(450 - 150, 620 - 20, 300, 3), platform_highlight)
	draw_rect(Rect2(700 - 125, 520 - 20, 250, 40), platform_color)
	draw_rect(Rect2(700 - 125, 520 - 20, 250, 3), platform_highlight)

	# Pond platform
	draw_rect(Rect2(1200 - 300, 420 - 25, 600, 50), platform_color)
	draw_rect(Rect2(1200 - 300, 420 - 25, 600, 3), platform_highlight)

	# Right descending
	draw_rect(Rect2(1850 - 140, 520 - 20, 280, 40), platform_color)
	draw_rect(Rect2(1850 - 140, 520 - 20, 280, 3), platform_highlight)
	draw_rect(Rect2(2150 - 175, 620 - 20, 350, 40), platform_color)
	draw_rect(Rect2(2150 - 175, 620 - 20, 350, 3), platform_highlight)

	# Far right ground
	draw_rect(Rect2(2600 - 300, 720 - 30, 600, 60), platform_color)
	draw_rect(Rect2(2600 - 300, 720 - 30, 600, 3), platform_highlight)

	# Mirror Gate platform
	draw_rect(Rect2(1200 - 200, 280 - 20, 400, 40), platform_color)
	draw_rect(Rect2(1200 - 200, 280 - 20, 400, 3), platform_highlight)

func _create_ground() -> void:
	# Multi-tier platformer hub with vertical layout

	# Bottom ground - starting area
	_add_platform(Vector2(200, 720), Vector2(800, 60))

	# Mid-left platforms ascending
	_add_platform(Vector2(450, 620), Vector2(300, 40))
	_add_platform(Vector2(700, 520), Vector2(250, 40))

	# Pond level - center high platform
	_add_platform(Vector2(1200, 420), Vector2(600, 50))

	# Right side descending platforms
	_add_platform(Vector2(1850, 520), Vector2(280, 40))
	_add_platform(Vector2(2150, 620), Vector2(350, 40))

	# Far right ground
	_add_platform(Vector2(2600, 720), Vector2(600, 60))

	# Upper tier for Mirror Gate
	_add_platform(Vector2(1200, 280), Vector2(400, 40))

func _add_platform(pos: Vector2, size: Vector2) -> void:
	var platform := StaticBody2D.new()
	platform.position = pos
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	platform.add_child(collision)
	add_child(platform)

func _create_hub_elements() -> void:
	# Bench - bottom left
	var bench := _make_interactable("BENCH\n[E]", Vector2(250, 680), Color(0.6, 0.55, 0.5))
	interactables.append({"node": bench, "message": "Rest here.", "kind": "bench", "used": false})

	# Altar - mid platform left
	var altar := _make_interactable("ALTAR\n[E]", Vector2(700, 480), Color(0.9, 0.85, 0.7))
	interactables.append({"node": altar, "message": "Artifact slots.", "kind": "altar", "used": false})

	# Pond at center high platform
	reflection = Node2D.new()
	reflection.position = Vector2(1200, 400)
	add_child(reflection)

	# Memory Tree - right mid platform
	var tree := _make_interactable("TREE\n[E]", Vector2(1900, 480), Color(0.7, 0.85, 0.65))
	interactables.append({"node": tree, "message": "Memory tree.", "kind": "tree", "used": false})

	# Nim's Post - far right ground
	var nim := _make_interactable("NIM\n[E]", Vector2(2650, 680), Color(0.95, 0.9, 0.6))
	interactables.append({"node": nim, "message": "Nim waits.", "kind": "nim", "used": false})

	# Mirror Gate - top platform
	var gate := _make_interactable("GATE\n[E]", Vector2(1200, 240), Color(0.85, 0.88, 0.95))
	interactables.append({"node": gate, "message": "Sealed.", "kind": "gate", "used": false})

func _create_npcs() -> void:
	var marl := _make_interactable("MARL\n[E]", Vector2(1100, 380), Color(0.95, 0.95, 0.9))
	interactables.append({"node": marl, "message": "Paper boats.", "kind": "marl", "used": false})

	var orrin := _make_interactable("ORRIN\n[E]", Vector2(250, 660), Color(0.5, 0.55, 0.5))
	interactables.append({"node": orrin, "message": "Stone frog waits.", "kind": "orrin", "used": false})

func _create_doors() -> void:
	var door_symbols := {
		"greed": "COIN",
		"sloth": "MOON",
		"gluttony": "SPOON",
		"envy": "WINDOW",
		"lust": "THREAD",
		"wrath": "FLAME",
		"pride": "CROWN"
	}

	for region_key: Variant in DOOR_POSITIONS.keys():
		var region: String = str(region_key)
		var pos: Vector2 = DOOR_POSITIONS[region]
		var symbol: String = str(door_symbols.get(region, "?"))
		var door_marker := _make_interactable("%s\n[E] ENTER" % symbol, pos, Color(0.7, 0.68, 0.75))
		doors.append(door_marker)

		var msg := "The door to %s sleeps peacefully." % DOOR_NAMES[region]
		if region == "greed":
			msg = "The first door. Golden flowers bloom around it, but something in the garden glittered wrong.\n\nEnter Greed?"
		elif unlocked_regions.has(region):
			msg = "The door to %s is open. A warm light spills from within.\n\nEnter?" % DOOR_NAMES[region]

		interactables.append({"node": door_marker, "message": msg, "kind": "door_%s" % region, "used": false, "region": region})

func _create_player() -> void:
	player = CharacterBody2D.new()
	player.name = "Lumi"
	player.position = respawn_point
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
	camera.limit_left = -200
	camera.limit_right = 3000
	camera.limit_top = 100
	camera.limit_bottom = 850
	player.add_child(camera)

func _create_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)

	var title := Label.new()
	title.position = Vector2(24, 18)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.91, 0.91, 1.0))
	title.text = "WHAT THE WATER KEEPS  •  THE STILL POND"
	hud.add_child(title)

	stats_label = Label.new()
	stats_label.position = Vector2(24, 58)
	stats_label.add_theme_font_size_override("font_size", 18)
	stats_label.add_theme_color_override("font_color", Color(0.77, 0.88, 1.0))
	hud.add_child(stats_label)

	var help := Label.new()
	help.position = Vector2(24, 670)
	help.add_theme_font_size_override("font_size", 16)
	help.add_theme_color_override("font_color", Color(0.82, 0.83, 0.9))
	help.text = "A/D move   SPACE jump   J lantern swing   LEFT SHIFT dash   Q heal   E interact"
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

func _make_interactable(marker_text: String, at: Vector2, tint: Color) -> Node2D:
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

func _connect_signals() -> void:
	player.health_changed.connect(_update_hud)
	player.heals_changed.connect(_update_hud)
	player.status_changed.connect(_show_status)

func _process(_delta: float) -> void:
	# Reflection follows player with delay
	if is_instance_valid(reflection) and is_instance_valid(player):
		var target_pos := Vector2(1200, 585) + Vector2(player.global_position.x - 1200, 0) * 0.3
		reflection.position = reflection.position.lerp(target_pos, 0.02)

	if dialogue_open:
		var walked_away := not is_instance_valid(dialogue_target)
		if is_instance_valid(dialogue_target):
			walked_away = player.global_position.distance_to(dialogue_target.global_position) > 95.0
		if walked_away or Input.is_action_just_pressed("interact"):
			dialogue_panel.visible = false
			dialogue_open = false
			dialogue_target = null
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

func _interact(item: Dictionary) -> void:
	var kind: String = item["kind"]
	var target: Node2D = item["node"]

	match kind:
		"bench":
			player.respawn_point = respawn_point
			player.health = player.max_health
			player.heals = 3
			player.health_changed.emit(player.health)
			player.heals_changed.emit(player.heals)
			_show_dialogue("Lumi rests at the bench. The world is quiet. Health and heals restored.", target)
		"altar":
			_show_dialogue("Three empty slots wait for artifacts. Each style changes how Lumi fights.\n\n(Current: Lantern Swing - balanced and reliable)", target)
		"tree":
			_show_dialogue("The Memory Tree stands bare. Collecting Memory Petals in each region will bloom its branches with quiet memories.\n\n(0/35 petals found)", target)
		"nim":
			_show_dialogue("Nim flutters excitedly around the lantern post.\n\n“We did it! Seven doors, seven lessons. The reflection is watching, but... it feels less scary now.”", target)
		"gate":
			if regions_unlocked >= 7:
				_show_dialogue("All seven keys turn in the locks. The Mirror Gate begins to open...\n\n(The final path awaits.)", target)
			else:
				_show_dialogue("Seven keyholes mark the gate. It will only open when all seven regions are cleared.\n\n(%d/7 keys collected)" % regions_unlocked, target)
		"marl":
			_show_dialogue("Marl looks up from folding another boat.\n\n“I keep writing. Even if no one answers. It helps to put the words somewhere.”", target)
		"orrin":
			_show_dialogue("Orrin's stone eyes are fixed on the horizon.\n\n“Sometimes I think they're just late. ...Sometimes I think I forgot where to look.”", target)
		_:
			if kind.begins_with("door_"):
				var region: String = item.get("region", "")
				if unlocked_regions.has(region) or region == "greed":
					region_entered.emit(region)
				else:
					_show_dialogue("The door to %s is sealed. It will open when its region is completed." % DOOR_NAMES.get(region, region), target)
				return
			_show_dialogue(item["message"], target)

func _show_dialogue(message: String, target: Node2D = null) -> void:
	dialogue_label.text = message
	dialogue_panel.visible = true
	dialogue_open = true
	dialogue_target = target

func _update_hud(_value: int = 0) -> void:
	if not is_instance_valid(player) or not is_instance_valid(stats_label):
		return
	var hearts := ""
	for i in range(player.max_health):
		hearts += "♥ " if i < player.health else "♡ "
	var region_text := "    REGIONS CLEARED: %d/7" % regions_unlocked
	stats_label.text = "HEARTS: %s    HEALS: %d%s" % [hearts.strip_edges(), player.heals, region_text]

func _show_status(message: String) -> void:
	status_id += 1
	var my_id := status_id
	stats_label.text = message
	await get_tree().create_timer(1.6).timeout
	if my_id == status_id:
		_update_hud()

func unlock_region(region_name: String) -> void:
	if not unlocked_regions.has(region_name):
		unlocked_regions.append(region_name)
		regions_unlocked += 1
		_update_hud()

func get_respawn_point() -> Vector2:
	return respawn_point