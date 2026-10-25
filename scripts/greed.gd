extends Node2D
const Settings := preload("res://scripts/game_settings.gd")

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

# The Collector fight
const COLLECTOR_SCRIPT := preload("res://scripts/collector.gd")
const ARENA_LOCK_X := 2000.0   # left lock wall while the fight is on (marker is at 2130)
const ARENA_END_X := 2750.0    # permanent end wall of Greed
const COLLECTOR_X := 2500.0
const MOUNTAIN_X := 2580.0
var collector: CharacterBody2D
var arena_wall: StaticBody2D
var boss_item: Dictionary = {}
var fight_active := false
var mountain_visible := true
var offering_line_shown := false
var banner_time := 0.0
var scene_id := 0
var has_open_hand := false
var has_gold_key := false

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

	if mountain_visible:
		_draw_mountain()

func _draw_mountain() -> void:
	# The Collector's mountain of coins. He swallows it in phase two.
	draw_colored_polygon(PackedVector2Array([
		Vector2(MOUNTAIN_X - 150, 570), Vector2(MOUNTAIN_X - 60, 470),
		Vector2(MOUNTAIN_X, 430), Vector2(MOUNTAIN_X + 60, 470),
		Vector2(MOUNTAIN_X + 150, 570)
	]), Color(0.86, 0.66, 0.2, 1.0))
	for i in range(34):
		var row := i / 7
		var col := i % 7
		var cx := MOUNTAIN_X - 105.0 + col * 35.0 + (row % 2) * 14.0 - row * 6.0
		var cy := 556.0 - row * 24.0
		if absf(cx - MOUNTAIN_X) < 150.0 - row * 34.0:
			draw_circle(Vector2(cx, cy), 11, Color(0.94, 0.76, 0.24, 1.0))
			draw_circle(Vector2(cx, cy), 6.5, Color(1.0, 0.9, 0.5, 1.0))

func _create_ground() -> void:
	# Ground sections - leaving gaps for platforms
	_create_ground_section(Vector2(300, 610), Vector2(600, 80), "GreedGround1")
	_create_ground_section(Vector2(700, 610), Vector2(600, 80), "GreedGround2")
	_create_ground_section(Vector2(1500, 610), Vector2(1000, 80), "GreedGround3")
	_create_ground_section(Vector2(2375, 610), Vector2(750, 80), "GreedArena")

	# Platforms
	_create_platform(Vector2(500, 500), Vector2(120, 20))
	_create_platform(Vector2(900, 450), Vector2(100, 20))
	_create_platform(Vector2(1100, 380), Vector2(100, 20))

	# Boundary walls
	_create_boundary(Vector2(50, 0))
	_create_boundary(Vector2(ARENA_END_X, 0))

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
	player.set("respawn_point", respawn_point)
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
	camera.limit_right = 2850
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
	stats_label.position = Vector2(24, 128)
	stats_label.add_theme_font_size_override("font_size", 18)
	stats_label.add_theme_color_override("font_color", Color(0.77, 0.88, 1.0))
	stats_label.add_theme_color_override("font_outline_color", Color(0.12, 0.10, 0.24))
	stats_label.add_theme_constant_override("outline_size", 5)
	hud.add_child(stats_label)

	var meter := Control.new()
	meter.set_script(load("res://scripts/lantern_meter.gd"))
	meter.position = Vector2(24, 52)
	hud.add_child(meter)

	var help := Label.new()
	help.position = Vector2(24, 670)
	help.add_theme_font_size_override("font_size", 16)
	help.add_theme_color_override("font_color", Color(0.82, 0.83, 0.9))
	help.add_theme_color_override("font_outline_color", Color(0.12, 0.10, 0.24))
	help.add_theme_constant_override("outline_size", 5)
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

	# The Collector's arena: E starts the fight. Two offering bowls sit inside it.
	var boss_area := _make_interactable("THE COLLECTOR\n[E] APPROACH", Vector2(2130, 570), Color(0.9, 0.75, 0.4))
	boss_item = {
		"node": boss_area,
		"message": "A mountain of golden coins sits before a towering plush bear in a tiny crown.",
		"kind": "boss",
		"used": false
	}
	interactables.append(boss_item)
	for bowl_x in [2230.0, 2660.0]:
		var bowl := _make_interactable("BOWL\n[E] OFFER", Vector2(bowl_x, 570), Color(0.95, 0.85, 0.5))
		interactables.append({"node": bowl, "message": "An offering bowl.", "kind": "bowl", "used": false})
	_create_collector()

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

func _process(delta: float) -> void:
	# Apply weight debuff to player
	if weight_debuff > 0.0:
		var felt := weight_debuff * (0.5 if Settings.gentle_mode else 1.0)
		player.set("move_speed_mod", 1.0 - felt * 0.5)
		player.set("jump_power_mod", 1.0 - felt * 0.3)
	else:
		player.set("move_speed_mod", 1.0)
		player.set("jump_power_mod", 1.0)

	# Killbox
	if player.global_position.y > 900.0:
		player.global_position = respawn_point
		player.velocity = Vector2.ZERO
		_show_status("THE WEIGHT PULLS LUMI DOWN. BACK TO SAFE GROUND.")

	_update_collector_fight(delta)
	if banner_time > 0.0:
		banner_time -= delta
		if banner_time <= 0.0:
			dialogue_panel.visible = false
		else:
			prompt_label.text = ""
			return

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
			if boss_defeated:
				_show_dialogue("The mountain is gone. Only a small, quiet shine is left in the bowl.", target)
			else:
				_start_collector_fight()
		"bowl":
			_offer_at_bowl(target)
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
	var parts: Array[String] = []
	if carried_gold > 0:
		parts.append("GOLD: %d" % carried_gold)
	if weight_debuff > 0.3:
		parts.append("WEIGHT: %.0f%%" % (weight_debuff * 100))
	if has_featherweight:
		parts.append("DOUBLE JUMP: UNLOCKED")
	stats_label.text = "    ".join(parts)

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

func add_gold(amount: int) -> void:
	carried_gold += amount
	_update_weight()
	_update_hud()
	collectible_found.emit("coin")

func steal_all_gold() -> int:
	var amount := carried_gold
	carried_gold = 0
	_update_weight()
	_update_hud()
	return amount

func _create_collector() -> void:
	collector = CharacterBody2D.new()
	collector.name = "TheCollector"
	collector.position = Vector2(COLLECTOR_X, 500)
	collector.set_script(COLLECTOR_SCRIPT)
	# Layer 2, no mask: Lumi's swing can hit him, but he never blocks her.
	collector.collision_layer = 2
	collector.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 70.0
	collision.shape = shape
	collector.add_child(collision)
	add_child(collector)
	collector.set("mountain_x", MOUNTAIN_X)
	collector.set("arena_right", ARENA_END_X - 20.0)
	collector.defeated.connect(_on_collector_defeated)
	collector.phase_changed.connect(_on_collector_phase)
	collector.gold_stolen.connect(_on_gold_stolen)
	collector.grab_whiffed.connect(_on_grab_whiffed)
	collector.mountain_swallowed.connect(_on_mountain_swallowed)

func _banner(text: String, seconds: float) -> void:
	dialogue_open = false
	dialogue_label.text = text
	dialogue_panel.visible = true
	banner_time = seconds

func _start_collector_fight() -> void:
	if fight_active or boss_defeated or not is_instance_valid(collector):
		return
	fight_active = true
	arena_wall = StaticBody2D.new()
	arena_wall.position = Vector2(ARENA_LOCK_X, 0)
	var wall_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, 1600)
	wall_shape.shape = rect
	arena_wall.add_child(wall_shape)
	add_child(arena_wall)
	_collector_intro()

func _collector_intro() -> void:
	scene_id += 1
	var my_id := scene_id
	var lines := [
		["THE COLLECTOR: Oh. A visitor. Come, come, sit. Isn't it all lovely? I've kept it all safe.", 3.4],
		["THE COLLECTOR: Nobody takes what's mine anymore. I had a family once. A cozy house. Then the winter came and it all slipped away. So I held on. Tighter.", 5.0],
		["NIM: He sounds sad.", 1.8],
		["THE COLLECTOR: Sad? I'm not sad. I'm full. I have so much.", 3.0]
	]
	for line in lines:
		_banner(line[0], line[1])
		await get_tree().create_timer(line[1]).timeout
		if my_id != scene_id:
			return
	if is_instance_valid(collector):
		collector.call("start_fight")

func _update_collector_fight(delta: float) -> void:
	if not fight_active or not is_instance_valid(collector):
		return
	# The arena shrinks as he grows: the left wall creeps inward.
	if is_instance_valid(arena_wall):
		var size: float = collector.get("body_size")
		var goal := ARENA_LOCK_X + clampf((size - 1.0) * 200.0, 0.0, 150.0)
		arena_wall.position.x = move_toward(arena_wall.position.x, goal, 18.0 * delta)
		collector.set("arena_left", arena_wall.position.x + 20.0)
	# If Lumi was sent back (death), the fight resets.
	if player.global_position.x < ARENA_LOCK_X - 60.0:
		_reset_collector_fight()

func _reset_collector_fight() -> void:
	scene_id += 1
	fight_active = false
	banner_time = 0.0
	offering_line_shown = false
	dialogue_panel.visible = false
	if is_instance_valid(arena_wall):
		arena_wall.queue_free()
	for coin in get_tree().get_nodes_in_group("collector_coin"):
		coin.queue_free()
	mountain_visible = true
	queue_redraw()
	collector.call("reset")

func _offer_at_bowl(target: Node2D) -> void:
	var offered := _offer_gold()
	if offered <= 0:
		_show_dialogue("An offering bowl. \"Give what you carry.\"\n\n(Carry no gold to offer.)", target)
		return
	if fight_active and is_instance_valid(collector):
		collector.call("take_offering", offered)
		_show_status("LUMI GIVES %d GOLD. THE COLLECTOR SHRINKS." % offered)
		if not offering_line_shown:
			offering_line_shown = true
			_banner("THE COLLECTOR: Why would you... why would you just give it?", 3.0)
	else:
		_show_dialogue("Lumi offers %d gold. The bowl glows warmly, and the weight lifts." % offered, target)

func _on_collector_phase(new_phase: int) -> void:
	if new_phase == 2:
		_banner("THE COLLECTOR: Give it back! It's mine! It's all I have!", 3.0)
	elif new_phase == 3:
		_banner("THE COLLECTOR: If I let go of one thing, I'll let go of everything!", 3.0)

func _on_gold_stolen(amount: int) -> void:
	_show_status("THE COLLECTOR TAKES %d GOLD AND HEALS." % amount)

func _on_grab_whiffed() -> void:
	_show_status("EMPTY HANDS. HIS GRAB FINDS NOTHING. HE IS WIDE OPEN!")

func _on_mountain_swallowed() -> void:
	mountain_visible = false
	queue_redraw()

func _on_collector_defeated() -> void:
	boss_defeated = true
	fight_active = false
	boss_item["used"] = true
	boss_item["node"].visible = false
	if is_instance_valid(arena_wall):
		arena_wall.queue_free()
	scene_id += 1
	var my_id := scene_id
	var lines := [
		["THE COLLECTOR: I only wanted to keep them. I only wanted to keep everyone.", 3.6],
		["NIM: ...You can let go. It's okay.", 2.6],
		["(He puts the coin in the offering bowl. He fades.)", 3.0],
		["THE COLLECTOR: It's so light.", 2.6],
		["THE OPEN HAND (OFFERING STYLE) AND THE GOLD KEY ARE YOURS.", 3.4]
	]
	for line in lines:
		_banner(line[0], line[1])
		await get_tree().create_timer(line[1]).timeout
		if my_id != scene_id:
			return
	has_open_hand = true
	has_gold_key = true
	collectible_found.emit("open_hand")
	collectible_found.emit("gold_key")
	region_cleared.emit("greed")

func get_respawn_point() -> Vector2:
	return respawn_point