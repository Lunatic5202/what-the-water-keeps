extends Node2D

signal region_cleared(region_name: String)
signal return_to_hub
signal collectible_found(collectible_type: String)

var player: CharacterBody2D
var stats_label: Label
var hud_layer: CanvasLayer
var prompt_label: Label
var dialogue_panel: ColorRect
var dialogue_label: Label
var dialogue_target: Node2D
var interactables: Array[Dictionary] = []
var dialogue_open := false
var status_id := 0

# Greed-specific mechanics
var carried_gold := 0
var weight_debuff := 0.0  # 0.0 to 1.0, affects speed/jump
var has_featherweight := false  # Double jump unlocked

# Progress
var shrine_count := 0
var total_shrines := 3
var lore_found := 0
var total_lore := 3
var boss_defeated := false
var featherweight_found := false

# Spawn points
var respawn_point := Vector2(280, 520)
var checkpoint_unlocked := false

const GRAVITY := 1200.0

func _ready() -> void:
	_create_background()
	_create_ground()
	if not is_instance_valid(player):
		_create_player()
	_create_hud()
	_create_greed_level()
	_connect_signals()
	_update_hud()

var bg_drawn := false

func _create_background() -> void:
	# Background is drawn in _draw()
	pass

func _draw() -> void:
	# Golden garden sky
	draw_rect(Rect2(-3000, -2000, 8000, 4000), Color(0.95, 0.88, 0.55, 1.0))

	if not bg_drawn:
		# Golden flowers (decorative) - only seed once
		randomize()
		bg_drawn = true

	for i in range(40):
		var x := fposmod(float(i * 137 + 42), 3000.0) - 500.0
		var y := fposmod(float(i * 89 + 17), 350.0) + 200.0
		var size := 4.0 + fposmod(float(i * 13), 6.0)
		draw_circle(Vector2(x, y), size, Color(0.94, 0.78, 0.31, 0.6))
		draw_circle(Vector2(x, y), size * 0.5, Color(1.0, 0.9, 0.4, 0.8))

	# Distant golden trees
	for i in range(6):
		var x := -200 + i * 400
		draw_rect(Rect2(x - 8, 350, 16, 260), Color(0.65, 0.52, 0.3, 1.0))
		draw_circle(Vector2(x, 340), 45, Color(0.75, 0.65, 0.35, 1.0))
		draw_circle(Vector2(x - 25, 360), 30, Color(0.8, 0.7, 0.4, 1.0))
		draw_circle(Vector2(x + 25, 360), 30, Color(0.8, 0.7, 0.4, 1.0))

func _create_ground() -> void:
	# Ground sections - leaving gaps for platforms
	_create_ground_section(Vector2(300, 610), Vector2(600, 80), "GreedGround1")
	_create_ground_section(Vector2(700, 610), Vector2(600, 80), "GreedGround2")
	_create_ground_section(Vector2(1500, 610), Vector2(1000, 80), "GreedGround3")

	# Platforms
	_create_platform(Vector2(500, 500), Vector2(120, 20))
	_create_platform(Vector2(900, 450), Vector2(100, 20))
	_create_platform(Vector2(1100, 380), Vector2(100, 20))

	# Boundary walls
	_create_boundary(Vector2(50, 0))
	_create_boundary(Vector2(2000, 0))

	# Killbox at bottom
	_create_killbox()

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

func _create_platform(at: Vector2, size: Vector2) -> void:
	var platform := StaticBody2D.new()
	platform.position = at
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	platform.add_child(collision)
	add_child(platform)

func _create_boundary(at: Vector2) -> void:
	var wall := StaticBody2D.new()
	wall.position = at
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(40, 1600)
	collision.shape = shape
	wall.add_child(collision)
	add_child(wall)

func _create_killbox() -> void:
	# Falling below the level
	pass  # Handled in _process

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
	camera.position = Vector2(640, 400)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	camera.limit_left = 0
	camera.limit_right = 2100
	camera.limit_top = 100
	camera.limit_bottom = 750
	player.add_child(camera)

func _create_hud() -> void:
	hud_layer = CanvasLayer.new()
	add_child(hud_layer)
	var hud := hud_layer

	var title := Label.new()
	title.position = Vector2(24, 18)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.91, 0.91, 1.0))
	title.text = "WHAT THE WATER KEEPS  •  THE GILDED GARDEN"
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

func _create_greed_level() -> void:
	# Lore tablets
	var lore_positions := [Vector2(380, 570), Vector2(850, 570), Vector2(1600, 570)]
	var lore_messages := [
		"I only wanted enough. Then enough was a little more.",
		"The flowers grew from the coins we dropped. Nobody remembered who dropped them.",
		"I counted it every night so I wouldn't have to count what I'd lost."
	]
	for i in range(lore_messages.size()):
		var lore := _make_interactable("TABLET %d\n[E] READ" % (i + 1), lore_positions[i], Color(0.85, 0.75, 0.45))
		interactables.append({"node": lore, "message": lore_messages[i], "kind": "lore", "used": false})

	# Shrines (offer gold to reduce weight)
	var shrine_positions := [Vector2(550, 500), Vector2(1050, 440), Vector2(1450, 570)]
	for i in range(shrine_positions.size()):
		var shrine := _make_interactable("SHRINE\n[E] OFFER", shrine_positions[i], Color(0.95, 0.85, 0.5))
		interactables.append({"node": shrine, "message": "A small golden bowl. \"Give what you carry.\"\n\nPress E to offer all carried gold.", "kind": "shrine", "used": false, "shrine_id": i})

	# Coin pickups
	var coin_positions := [Vector2(300, 560), Vector2(450, 490), Vector2(650, 560), Vector2(750, 490), Vector2(950, 560), Vector2(1150, 370), Vector2(1350, 560), Vector2(1550, 490), Vector2(1750, 560)]
	for i in range(coin_positions.size()):
		var coin := _make_interactable("COIN", coin_positions[i], Color(1.0, 0.85, 0.3))
		interactables.append({"node": coin, "message": "A gleaming gold coin. It feels heavier than it should.\n\n+10 Gold", "kind": "coin", "used": false, "value": 10})

	# The Featherweight Charm unlocks the player's double jump.
	var charm := _make_interactable("FEATHERWEIGHT\n[E] TAKE", Vector2(1680, 500), Color(0.72, 0.9, 1.0))
	interactables.append({
		"node": charm,
		"message": "A feather-light charm rests among the flowers.\n\nLumi feels able to rise once more in mid-air.",
		"kind": "featherweight",
		"used": false
	})

	# The Collector boss area
	var boss_area := _make_interactable("THE COLLECTOR\n[E] APPROACH", Vector2(1850, 520), Color(0.9, 0.75, 0.4))
	interactables.append({
		"node": boss_area,
		"message": "A mountain of golden coins sits before a towering plush bear in a tiny crown.\n\nTHE COLLECTOR: Oh. A visitor. Come, come, sit. Isn't it all lovely?",
		"kind": "boss",
		"used": false
	})

	# Exit to hub
	var exit := _make_interactable("EXIT TO HUB\n[E] RETURN", Vector2(100, 520), Color(0.7, 0.8, 0.9))
	interactables.append({"node": exit, "message": "Return to The Still Pond?", "kind": "exit", "used": false})

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

func set_region_active(active: bool) -> void:
	visible = active
	hud_layer.visible = active
	set_process(active)
	set_physics_process(active)

func _connect_signals() -> void:
	player.health_changed.connect(_update_hud)
	player.heals_changed.connect(_update_hud)
	player.status_changed.connect(_show_status)

func _process(_delta: float) -> void:
	# Apply weight debuff to player
	if weight_debuff > 0.0:
		player.set("move_speed_mod", 1.0 - weight_debuff * 0.5)
		player.set("jump_power_mod", 1.0 - weight_debuff * 0.3)
	else:
		player.set("move_speed_mod", 1.0)
		player.set("jump_power_mod", 1.0)

	# Killbox
	if player.global_position.y > 900.0:
		player.global_position = respawn_point
		player.velocity = Vector2.ZERO
		_show_status("THE WEIGHT PULLS LUMI DOWN. BACK TO SAFE GROUND.")

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
		"lore":
			item["used"] = true
			target.visible = false
			lore_found += 1
			collectible_found.emit("lore")
			_show_dialogue(item["message"], target)
		"shrine":
			var offered := _offer_gold()
			if offered > 0:
				weight_debuff = maxf(0.0, weight_debuff - 0.3)
				_show_dialogue("Lumi offers %d gold to the shrine. The bowl glows warmly.\n\nThe weight lifts slightly." % offered, target)
			else:
				_show_dialogue("A small golden bowl. \"Give what you carry.\"\n\n(Carry no gold to offer.)", target)
		"coin":
			item["used"] = true
			target.visible = false
			var value: int = item.get("value", 10)
			carried_gold += value
			_update_weight()
			collectible_found.emit("coin")
			_show_dialogue(item["message"], target)
		"featherweight":
			item["used"] = true
			target.visible = false
			unlock_featherweight()
			_show_dialogue(item["message"], target)
		"boss":
			# Start boss fight - would load boss scene
			_show_dialogue("THE COLLECTOR: Oh. A visitor. Come, come, sit. Isn't it all lovely? I've kept it all safe.\n\n(Boss fight to be implemented)", target)
		"exit":
			return_to_hub.emit()
		_:
			_show_dialogue(item["message"], target)

func _offer_gold() -> int:
	if carried_gold <= 0:
		return 0
	var offered := carried_gold
	carried_gold = 0
	_update_weight()
	return offered

func _update_weight() -> void:
	# More gold = more weight
	weight_debuff = clampf(float(carried_gold) / 100.0, 0.0, 0.7)
	if carried_gold >= 60:
		_show_status("BURDEN: You held on too tightly.")

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

	var gold_text := ""
	if carried_gold > 0:
		gold_text = "    GOLD: %d" % carried_gold

	var weight_text := ""
	if weight_debuff > 0.3:
		weight_text = " (WEIGHT: %.0f%%)" % (weight_debuff * 100)

	var gadget_text := ""
	if has_featherweight:
		gadget_text = "    DOUBLE JUMP: UNLOCKED"

	stats_label.text = "HEARTS: %s    HEALS: %d%s%s%s" % [hearts.strip_edges(), player.heals, gold_text, weight_text, gadget_text]

func _show_status(message: String) -> void:
	status_id += 1
	var my_id := status_id
	stats_label.text = message
	await get_tree().create_timer(1.6).timeout
	if my_id == status_id:
		_update_hud()

func unlock_featherweight() -> void:
	if not featherweight_found:
		featherweight_found = true
		has_featherweight = true
		player.set("can_double_jump", true)
		_update_hud()
		_show_status("FEATHERWEIGHT CHARM FOUND! PRESS JUMP IN MID-AIR TO DOUBLE JUMP!")

func get_respawn_point() -> Vector2:
	return respawn_point