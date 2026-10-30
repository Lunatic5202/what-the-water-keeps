extends Node2D
# Slumber Hollow (Sloth): region 2. See docs/game-bible.md, Region 2.
# Souls-like pieces: benches that save your spot and respawn enemies, enemies
# that respawn when you die, a fog-gated boss. Platforming pieces: bobbing
# pillows over a pit (needs double jump or dash) and a hammock climb.
# Mechanic: Drowse. Idle or ignore the lanterns and it builds; light lanterns.

const Palette := preload("res://scripts/palette.gd")
const Settings := preload("res://scripts/game_settings.gd")
const BOSS_HEALTH_BAR := preload("res://scripts/boss_health_bar.gd")
const RunState := preload("res://scripts/run_state.gd")
const Story := preload("res://scripts/story.gd")
const BOB := preload("res://scripts/bob_platform.gd")
const DREAMER := preload("res://scripts/dreamer.gd")
const WARDEN := preload("res://scripts/dozy_warden.gd")
const SNAIL := preload("res://scripts/snoozle_snail.gd")
const NIMBUS := preload("res://scripts/nimbus.gd")
const SPIDER := preload("res://scripts/hammock_spider.gd")

signal region_cleared(region_name: String)
signal return_to_hub

const INK := Color(0.12, 0.10, 0.24)
const START := Vector2(150, 560)
const ARENA_LOCK_X := 4330.0
const ARENA_END_X := 5190.0
const GROUND_TOP := 600.0

# Solid platforms: Rect2(left, top, width, height). Same list draws and collides.
# Steps up are 55px or less; gaps are 60px or more (Lumi is 26px wide).
const PLATFORMS := [
	Rect2(-100, 600, 1000, 120),   # start ground
	Rect2(1530, 500, 170, 30),     # landing after the pillow gap
	Rect2(1790, 540, 510, 60),     # first ledge (bench)
	Rect2(2390, 490, 110, 24),     # hammock climb
	Rect2(2560, 440, 110, 24),
	Rect2(2730, 390, 110, 24),
	Rect2(2900, 340, 110, 24),
	Rect2(3070, 290, 110, 24),
	Rect2(3240, 240, 110, 24),
	Rect2(3410, 240, 550, 40),     # high ledge
	Rect2(3700, 600, 1550, 120),   # pre-boss ground and arena
]
# Extra routes. Same rules as PLATFORMS, drawn and solid.
# Loft: a stair of ledges up and left from the first landing, with lanterns.
# Sky route: from the high ledge across the roof of the arena, past the Dozy
# Warden's ledge, and down into the arena's far end.
const EXTRA_PLATFORMS := [
	Rect2(1350, 480, 90, 18), Rect2(1180, 440, 90, 18), Rect2(1010, 400, 90, 18),
	Rect2(840, 360, 90, 18), Rect2(670, 320, 90, 18), Rect2(250, 280, 340, 18),
	Rect2(4020, 200, 110, 20), Rect2(4190, 160, 110, 20), Rect2(4360, 120, 340, 24),
	Rect2(4760, 160, 110, 20), Rect2(4930, 200, 110, 20), Rect2(5100, 240, 70, 20),
]
# Bobbing pillows over the first pit: [centre, phase]
const PILLOWS := [[Vector2(1025, 560), 0.0], [Vector2(1235, 520), 1.6]]

const LORE := [
	[Vector2(420, 560), "I'll start tomorrow."],
	[Vector2(1860, 500), "It's not that I didn't want to. It's that it was so far from where I was."],
	[Vector2(2200, 500), "I was tired. Nobody asked me why I was tired."],
	[Vector2(3520, 200), "I looked at the mountain and thought: not today. Then every day was not today."],
	[Vector2(4150, 560), "The hardest part was never the work. It was the first step. And the second. And the third."]
]
const LANTERNS := [
	Vector2(300, 560), Vector2(700, 560), Vector2(1950, 500), Vector2(2150, 500),
	Vector2(3600, 200), Vector2(3850, 560), Vector2(4200, 560)
]
const BENCHES := [Vector2(180, 560), Vector2(1900, 500), Vector2(3830, 560)]
const SPAWNS := [
	{"type": "snail", "pos": Vector2(560, 570), "patrol": 120.0},
	{"type": "spider", "pos": Vector2(780, 400), "anchor": 300.0, "floor": 570.0},
	{"type": "nimbus", "pos": Vector2(1130, 400)},
	{"type": "snail", "pos": Vector2(2020, 510), "patrol": 110.0},
	{"type": "spider", "pos": Vector2(2100, 400), "anchor": 330.0, "floor": 510.0},
	{"type": "nimbus", "pos": Vector2(2950, 200)},
	{"type": "nimbus", "pos": Vector2(3550, 100)},
	{"type": "spider", "pos": Vector2(3700, 150), "anchor": 40.0, "floor": 210.0},
	{"type": "snail", "pos": Vector2(4050, 570), "patrol": 110.0},
	{"type": "nimbus", "pos": Vector2(800, 250)},
	{"type": "snail", "pos": Vector2(1055, 370), "patrol": 25.0},
	{"type": "nimbus", "pos": Vector2(4850, 90)},
]

var player: CharacterBody2D
var hud_layer: CanvasLayer
var overlay_layer: CanvasLayer
var overlay: ColorRect
var stats_label: Label
var prompt_label: Label
var dialogue_panel: Panel
var dialogue_label: Label
var dialogue_location_label: Label
var dialogue_portrait: TextureRect
var dialogue_portrait_text := ""
var dialogue_target: Node2D
var drowse_fill: ColorRect
var interactables: Array[Dictionary] = []
var lantern_items: Array[Dictionary] = []
var enemies: Array[Node] = []
var dialogue_open := false
var status_id := 0
var banner_time := 0.0
var scene_id := 0

var respawn_point := START
var drowse := 0.0
var drowse_stage := 0      # 0 clear, 1 nodding off (25), 2 heavy (50)
var nim_lantern_line := false
var dim := 0.0             # blanket darkness, 0 to 1
var has_hourglass := false
var has_dusk_key := false
var has_snail_grips := false

var dreamer: CharacterBody2D
var boss_item: Dictionary = {}
var boss_defeated := false
var fight_active := false
var lock_wall: StaticBody2D
var climb_walls: Array[Node] = []
var wall_age := 0.0  # seconds since the climb walls appeared (phase 3 only)
var boss_lanterns: Array[Node] = []
var dream_exit: Node2D = null
var dream_exit_open := false
var sloth_miniboss: CharacterBody2D = null
var sloth_miniboss_defeated := false
const SEALS_NEEDED := 2
var seals: Array = []   # "sky" (Dozy Warden) and "loft" (top of the loft stair)

func _ready() -> void:
	add_to_group("drowse_holder")
	Settings.load_settings()
	_create_ground()
	_create_hud()
	_create_level()
	_spawn_enemies()
	call_deferred("_create_sloth_expanded")
	_connect_signals()
	_update_hud()

# --- Building -----------------------------------------------------------------

func _solid(rect: Rect2, group_name := "") -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.add_child(shape)
	if group_name != "":
		body.add_to_group(group_name)
	add_child(body)
	return body

func _create_ground() -> void:
	for rect: Rect2 in PLATFORMS:
		_solid(rect)
	_solid(Rect2(10, -400, 40, 1400))             # left wall
	_solid(Rect2(ARENA_END_X, -400, 40, 1400))    # right wall
	for entry in PILLOWS:
		var pillow := AnimatableBody2D.new()
		pillow.set_script(BOB)
		pillow.position = entry[0]
		pillow.set("phase", entry[1])
		add_child(pillow)

func _make_interactable(marker_text: String, at: Vector2, tint: Color) -> Node2D:
	var marker := Node2D.new()
	marker.position = at
	var label := Label.new()
	label.text = marker_text
	label.position = Vector2(-85, -82)
	label.size = Vector2(170, 74)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", tint)
	label.add_theme_color_override("font_outline_color", INK)
	label.add_theme_constant_override("outline_size", 5)
	marker.add_child(label)
	add_child(marker)
	return marker

func _create_level() -> void:
	for i in range(LORE.size()):
		var tablet := _make_interactable("TABLET %d\n[E] READ" % (i + 1), LORE[i][0], Color(0.97, 0.91, 0.63))
		interactables.append({"node": tablet, "message": LORE[i][1], "kind": "lore", "used": false})
	for pos: Vector2 in LANTERNS:
		_add_lantern(pos)
	for pos: Vector2 in BENCHES:
		var bench := _make_interactable("HAMMOCK\n[E] REST", pos, Color(0.85, 0.95, 1.0))
		interactables.append({"node": bench, "message": "", "kind": "bench", "used": false})
	var exit := _make_interactable("EXIT TO HUB\n[E] RETURN", Vector2(80, 560), Color(0.8, 0.88, 1.0))
	interactables.append({"node": exit, "message": "Return to The Still Pond?", "kind": "exit", "used": false})
	var boss_area := _make_interactable("THE DREAMER\n[E] APPROACH", Vector2(4440, 560), Color(0.97, 0.91, 0.63))
	boss_item = {
		"node": boss_area,
		"message": "A gigantic sloth sleeps in a hammock between two glowing moons.",
		"kind": "boss",
		"used": false
	}
	interactables.append(boss_item)
	_create_dreamer()

func _add_lantern(pos: Vector2) -> Dictionary:
	var marker := _make_interactable("LANTERN\n[E] LIGHT", pos, Color(1.0, 0.92, 0.7))
	var item := {"node": marker, "message": "", "kind": "lantern", "used": false, "lit": false, "pos": pos}
	interactables.append(item)
	lantern_items.append(item)
	return item

func _create_dreamer() -> void:
	dreamer = CharacterBody2D.new()
	dreamer.name = "TheDreamer"
	dreamer.position = Vector2(4750, 300)
	dreamer.set_script(DREAMER)
	dreamer.collision_layer = 2
	dreamer.collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 74.0
	shape.shape = circle
	dreamer.add_child(shape)
	add_child(dreamer)
	dreamer.set("arena_left", 4350.0)
	dreamer.set("arena_right", 5150.0)
	dreamer.set("floor_y", GROUND_TOP)
	dreamer.set("heart_pos", Vector2(5015, 230))
	dreamer.defeated.connect(_on_dreamer_defeated)
	dreamer.phase_changed.connect(_on_dreamer_phase)

func _spawn_enemies() -> void:
	for node in enemies:
		if is_instance_valid(node):
			node.queue_free()
	enemies.clear()
	if not fight_active:
		for t in get_tree().get_nodes_in_group("enemy_projectile"):
			if is_ancestor_of(t):
				t.queue_free()
	for spawn in SPAWNS:
		var enemy := CharacterBody2D.new()
		enemy.position = spawn["pos"]
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		match spawn["type"]:
			"snail":
				enemy.set_script(SNAIL)
				circle.radius = 20.0
				enemy.set("patrol", spawn["patrol"])
			"nimbus":
				enemy.set_script(NIMBUS)
				circle.radius = 24.0
				enemy.collision_layer = 2
			"spider":
				enemy.set_script(SPIDER)
				circle.radius = 14.0
				enemy.collision_layer = 2
				enemy.set("anchor_y", spawn["anchor"])
				enemy.set("floor_y", spawn["floor"])
		shape.shape = circle
		enemy.add_child(shape)
		add_child(enemy)
		enemies.append(enemy)

func _create_hud() -> void:
	overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 0
	add_child(overlay_layer)
	overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.color = Color(0.08, 0.06, 0.25, 0.0)
	overlay_layer.add_child(overlay)

	hud_layer = CanvasLayer.new()
	add_child(hud_layer)
	var hud := hud_layer

	var title := Label.new()
	title.position = Vector2(24, 18)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.91, 0.91, 1.0))
	title.add_theme_color_override("font_outline_color", INK)
	title.add_theme_constant_override("outline_size", 6)
	title.text = "WHAT THE WATER KEEPS  •  SLUMBER HOLLOW"
	hud.add_child(title)

	var meter := Control.new()
	meter.set_script(load("res://scripts/lantern_meter.gd"))
	meter.position = Vector2(24, 52)
	hud.add_child(meter)

	stats_label = Label.new()
	stats_label.position = Vector2(24, 128)
	stats_label.add_theme_font_size_override("font_size", 20)
	stats_label.add_theme_color_override("font_color", Color(0.77, 0.88, 1.0))
	stats_label.add_theme_color_override("font_outline_color", INK)
	stats_label.add_theme_constant_override("outline_size", 5)
	hud.add_child(stats_label)

	var bar_back := ColorRect.new()
	bar_back.position = Vector2(24, 160)
	bar_back.size = Vector2(204, 14)
	bar_back.color = INK
	hud.add_child(bar_back)
	drowse_fill = ColorRect.new()
	drowse_fill.position = Vector2(26, 162)
	drowse_fill.size = Vector2(0, 10)
	hud.add_child(drowse_fill)
	var bar_label := Label.new()
	bar_label.position = Vector2(236, 154)
	bar_label.text = "DROWSE"
	bar_label.add_theme_font_size_override("font_size", 17)
	bar_label.add_theme_color_override("font_color", Color(0.97, 0.91, 0.63))
	bar_label.add_theme_color_override("font_outline_color", INK)
	bar_label.add_theme_constant_override("outline_size", 5)
	hud.add_child(bar_label)

	var help := Label.new()
	help.position = Vector2(24, 670)
	help.add_theme_font_size_override("font_size", 17)
	help.add_theme_color_override("font_color", Color(0.82, 0.83, 0.9))
	help.add_theme_color_override("font_outline_color", INK)
	help.add_theme_constant_override("outline_size", 5)
	help.text = "A/D move   SPACE jump   J swing   K heavy   L skill   I guard   SHIFT dash   E interact   ESC menu"
	hud.add_child(help)

	prompt_label = Label.new()
	prompt_label.position = Vector2(0, 610)
	prompt_label.size = Vector2(1280, 32)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 23)
	prompt_label.add_theme_color_override("font_color", Color(0.80, 0.94, 1.0))
	prompt_label.add_theme_color_override("font_outline_color", INK)
	prompt_label.add_theme_constant_override("outline_size", 6)
	hud.add_child(prompt_label)

	dialogue_panel = Panel.new()
	dialogue_panel.position = Vector2(100, 468)
	dialogue_panel.size = Vector2(1080, 182)
	dialogue_panel.visible = false
	var dialogue_style := StyleBoxFlat.new()
	dialogue_style.bg_color = Color(0.07, 0.08, 0.14, 0.88)
	dialogue_style.border_color = Color(0.77, 0.70, 1.0, 1.0)
	dialogue_style.set_border_width_all(2)
	dialogue_style.set_corner_radius_all(16)
	dialogue_style.shadow_color = Color(0.04, 0.03, 0.10, 0.45)
	dialogue_style.shadow_size = 12
	dialogue_style.shadow_offset = Vector2(0, 5)
	dialogue_panel.add_theme_stylebox_override("panel", dialogue_style)
	dialogue_panel.add_to_group("boss_dialogue_panel")
	hud.add_child(dialogue_panel)

	dialogue_portrait = TextureRect.new()
	dialogue_portrait.position = Vector2(18, 13)
	dialogue_portrait.size = Vector2(156, 156)
	dialogue_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dialogue_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dialogue_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_panel.add_child(dialogue_portrait)

	dialogue_location_label = Label.new()
	dialogue_location_label.position = Vector2(190, 12)
	dialogue_location_label.size = Vector2(860, 26)
	dialogue_location_label.text = "SLUMBER HOLLOW"
	dialogue_location_label.add_theme_font_size_override("font_size", 17)
	dialogue_location_label.add_theme_color_override("font_color", Color(0.77, 0.70, 1.0, 1.0))
	dialogue_location_label.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.10, 0.8))
	dialogue_location_label.add_theme_constant_override("outline_size", 2)
	dialogue_panel.add_child(dialogue_location_label)

	dialogue_label = Label.new()
	dialogue_label.position = Vector2(190, 43)
	dialogue_label.size = Vector2(860, 124)
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.clip_text = true
	dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_label.add_theme_font_size_override("font_size", 21)
	dialogue_label.add_theme_color_override("font_color", Color(0.97, 0.97, 1.0))
	dialogue_label.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.10, 0.7))
	dialogue_label.add_theme_constant_override("outline_size", 1)
	dialogue_panel.add_child(dialogue_label)

	var boss_bar := Control.new()
	boss_bar.set_script(BOSS_HEALTH_BAR)
	boss_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(boss_bar)

func _connect_signals() -> void:
	player.health_changed.connect(_update_hud)
	player.heals_changed.connect(_update_hud)
	player.status_changed.connect(_show_status)
	player.died.connect(_on_player_died)

func set_region_active(active: bool) -> void:
	visible = active
	hud_layer.visible = active
	overlay_layer.visible = active
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	if is_instance_valid(player):
		_clear_player_debuffs()

# --- Drawing ------------------------------------------------------------------

func _process(delta: float) -> void:
	if is_instance_valid(dialogue_label):
		_update_dialogue_portrait(dialogue_label.text)
	_update_drowse(delta)
	_update_overlay()
	if player.global_position.y > 900.0:
		player.global_position = player.get("respawn_point")
		player.velocity = Vector2.ZERO
		_show_status("THE FOG SWALLOWS LUMI. BACK TO THE LAST LIGHT.")
	_update_fight()
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
	if bool(get_meta("story_busy", false)):
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
	wall_age += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-3000, -2000, 11000, 4000), Palette.SLOTH_SKY)
	for item in interactables:
		if item["kind"] == "seal" and not item.get("used", false) and is_instance_valid(item["node"]):
			var c: Vector2 = item["node"].position
			draw_circle(c, 26.0, Color(0.75, 0.85, 1.0, 0.3))
			draw_circle(c, 17.0, Color(0.16, 0.14, 0.34))
			draw_circle(c, 14.0, Color(0.55, 0.7, 1.0))
			draw_circle(c, 8.0, Color(0.9, 0.95, 1.0))
			draw_circle(c + Vector2(-4, -4), 2.5, Color(1, 1, 1))
	# Far hills.
	for i in range(18):
		var x := -400.0 + i * 340.0
		var h := 150.0 + sin(i * 1.7) * 60.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 220, 700), Vector2(x, 700 - h), Vector2(x + 220, 700)]), Palette.SLOTH_FAR)
	# Hammocks in the background. The sleepers breathe, then slowly stop.
	for x in [380.0, 1250.0, 2000.0, 2650.0, 3300.0, 4100.0]:
		_draw_sleeper(x)
	# Soft fog bands.
	for i in range(6):
		var y := 330.0 + i * 70.0
		draw_rect(Rect2(-300, y, 5800, 38), Color(Palette.FOG, 0.10))
	# Platforms.
	for rect: Rect2 in PLATFORMS + EXTRA_PLATFORMS:
		draw_rect(rect, Palette.SLOTH_GROUND)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 5)), Palette.SLOTH_GROUND_TOP)
	# Lanterns.
	for item in lantern_items:
		_draw_lantern(item)
	# Fight walls.
	if fight_active and is_instance_valid(lock_wall):
		draw_rect(Rect2(ARENA_LOCK_X - 20, 100, 40, 520), Color(Palette.FOG, 0.35))
	_draw_climb_walls()
	# Wayfinding for the optional sky-route miniboss; keep the cue visible before the fight.
	draw_string(ThemeDB.fallback_font, Vector2(3820, 178), "SKY ROUTE  →  DOZY WARDEN", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.94, 0.91, 1.0, 1.0))
	if not sloth_miniboss_defeated:
		draw_circle(Vector2(4530, 90), 58.0, Color(0.77, 0.72, 1.0, 0.13))
		draw_arc(Vector2(4530, 90), 45.0, 0.0, TAU, 32, Color(0.86, 0.81, 1.0, 0.95), 3.0)

# The Snail Grips walls: pale stitched cloth that rises from the ground when
# phase 3 starts. Bright on purpose so they read through the dim overlay.
func _draw_climb_walls() -> void:
	var rise := clampf(wall_age / 1.0, 0.0, 1.0)
	for wall in climb_walls:
		if not is_instance_valid(wall):
			continue
		var x: float = wall.position.x
		var height := 600.0 * ease(rise, 0.4)
		var rect := Rect2(x - 15.0, 600.0 - height, 30.0, height)
		draw_rect(rect, Color(0.80, 0.76, 0.98))
		draw_rect(Rect2(rect.position.x + 5.0, rect.position.y, 20.0, rect.size.y), Color(0.64, 0.60, 0.90))
		# Stitched rungs show it can be climbed.
		var y := 600.0 - 24.0
		while y > rect.position.y + 10.0:
			draw_line(Vector2(x - 11.0, y), Vector2(x + 11.0, y), INK, 3.0)
			y -= 40.0
		draw_rect(rect, INK, false, 3.0)

func _draw_sleeper(x: float) -> void:
	var breathing := clampf(1.0 - maxf(0.0, x - 1900.0) / 1800.0, 0.0, 1.0)
	var chest := sin(Time.get_ticks_msec() * 0.0015 + x) * 2.5 * breathing
	var y := 380.0
	draw_line(Vector2(x - 70, y - 90), Vector2(x - 70, y + 40), Color(0.35, 0.33, 0.6), 4.0)
	draw_line(Vector2(x + 70, y - 90), Vector2(x + 70, y + 40), Color(0.35, 0.33, 0.6), 4.0)
	draw_arc(Vector2(x, y - 30), 70.0, 0.25, PI - 0.25, 18, Color(0.36, 0.36, 0.62), 6.0)
	draw_circle(Vector2(x - 12, y + 22), 17.0 + chest, Color(0.45, 0.43, 0.72))
	draw_circle(Vector2(x + 20, y + 24), 12.0, Color(0.5, 0.48, 0.76))

func _draw_lantern(item: Dictionary) -> void:
	var pos: Vector2 = item["pos"]
	var lit: bool = item["lit"]
	draw_line(pos + Vector2(0, 38), pos + Vector2(0, -16), Palette.SLOTH_GROUND, 5.0)
	if lit:
		draw_circle(pos + Vector2(0, -26), 130.0, Color(Palette.MOON, 0.07))
		draw_circle(pos + Vector2(0, -26), 80.0, Color(Palette.MOON, 0.12))
		draw_circle(pos + Vector2(0, -26), 15.0, Color(1.0, 0.92, 0.6))
	else:
		draw_circle(pos + Vector2(0, -26), 15.0, Color(0.42, 0.4, 0.62))
	draw_arc(pos + Vector2(0, -26), 15.0, 0.0, TAU, 16, INK, 3.0)

# --- Drowse -------------------------------------------------------------------

func _unlit_near() -> int:
	var count := 0
	for item in lantern_items:
		if not item["lit"] and is_instance_valid(item["node"]) \
				and player.global_position.distance_to(item["pos"]) < 700.0:
			count += 1
	return count

func add_drowse(amount: float) -> void:
	var factor := RunState.debuff_scale() if amount > 0.0 else 1.0
	drowse = clampf(drowse + amount * factor, 0.0, 100.0)

func _update_drowse(delta: float) -> void:
	var busy := dialogue_open or banner_time > 0.0 or float(player.get("asleep_timer")) > 0.0
	if not busy:
		var still: bool = player.velocity.length() < 20.0
		if still:
			add_drowse(1.0 * delta)
		elif _unlit_near() > 0:
			add_drowse(0.5 * delta)
	if drowse >= 100.0:
		drowse = 70.0
		player.call("fall_asleep", RunState.sleep_seconds())
		_show_status("DROWSE: LUMI FALLS ASLEEP. SLEEPERS TAKE MORE DAMAGE.")
	var stage := 0 if drowse < 25.0 else (1 if drowse < 50.0 else (2 if drowse < 80.0 else 3))
	if stage > drowse_stage:
		if stage == 1:
			_banner("NIM: It's so peaceful. I could just... rest a bit. Just a moment.", 3.0)
		elif stage == 2:
			_banner("DROWSE: You put it off again. Heavy limbs, hits hurt more.", 2.8)
		else:
			_banner("DROWSE: Eyes closing. No healing. Light a lantern or keep moving!", 2.8)
	drowse_stage = stage
	_apply_drowse_penalties(stage)
	drowse_fill.size.x = 200.0 * drowse / 100.0
	drowse_fill.color = Color(0.97, 0.91, 0.63).lerp(Color(0.62, 0.45, 0.95), drowse / 100.0)

# Escalating costs. Stage 2 (50): slower, shorter jumps, +1 damage per hit.
# Stage 3 (80): slower still, no healing. Falling asleep (100) leaves Lumi
# helpless for a few seconds and takes +1 damage on top.
func _apply_drowse_penalties(stage: int) -> void:
	var speed := 1.0
	var jump := 1.0
	match stage:
		2:
			speed = 0.8
			jump = 0.92
		3:
			speed = 0.65
			jump = 0.85
	player.set("move_speed_mod", speed)
	player.set("jump_power_mod", jump)
	player.set("vulnerable", 1 if stage >= 2 else 0)
	player.set("heal_blocked", stage >= 3)

func _update_overlay() -> void:
	var sleepy := clampf((drowse - 40.0) / 60.0, 0.0, 1.0) * 0.55
	var asleep := 0.3 if float(player.get("asleep_timer")) > 0.0 else 0.0
	overlay.color.a = maxf(maxf(sleepy, asleep), dim * 0.38)

# --- Interaction --------------------------------------------------------------

func _interact(item: Dictionary) -> void:
	queue_redraw()
	var kind: String = item["kind"]
	var target: Node2D = item["node"]
	match kind:
		"lantern":
			item["lit"] = true
			item["used"] = true
			var label := target.get_child(0) as Label
			label.text = "LIT"
			add_drowse(-20.0)
			_show_status("A LANTERN LIGHTS. THE FOG BACKS AWAY. DROWSE -20.")
			if not nim_lantern_line and drowse_stage >= 1:
				nim_lantern_line = true
				_banner("NIM: Better. Every little light helps. Funny. Doing something is easier than I remembered.", 3.4)
		"bench":
			_rest(target.global_position)
		"dream_exit":
			# Lands Lumi on the hub's upper platform instead of the start.
			get_tree().call_group("game_main", "_return_to_hub", true)
		"exit":
			return_to_hub.emit()
		"boss":
			if boss_defeated:
				_show_dialogue("Only a small hammock, swaying with no one in it.", target)
			elif seals.size() < SEALS_NEEDED:
				_show_dialogue("The fog before the hammock will not part.\n\nSEALS %d/%d. Two seals are kept in the high places of this hollow." % [seals.size(), SEALS_NEEDED], target)
			else:
				_start_fight()
		"seal":
			item["used"] = true
			target.visible = false
			_grant_seal(item["seal_id"])
			_show_status("SEAL %d/%d" % [seals.size(), SEALS_NEEDED])
			_show_dialogue(item["message"], target)
		_:
			_show_dialogue(item["message"], target)

func save_state() -> Dictionary:
	return {
		"boss_defeated": boss_defeated,
		"has_hourglass": has_hourglass,
		"has_dusk_key": has_dusk_key,
		"has_snail_grips": has_snail_grips,
		"warden_defeated": sloth_miniboss_defeated,
		"seals": seals.duplicate()
	}

# Puts Slumber Hollow back the way a save left it: the Dreamer at rest.
func apply_save(d: Dictionary) -> void:
	has_hourglass = bool(d.get("has_hourglass", false))
	has_dusk_key = bool(d.get("has_dusk_key", false))
	has_snail_grips = bool(d.get("has_snail_grips", false))
	for id in d.get("seals", []):
		_grant_seal(str(id))
		_hide_seal_marker(str(id))
	if bool(d.get("warden_defeated", false)):
		sloth_miniboss_defeated = true
		_grant_seal("sky")
		if is_instance_valid(sloth_miniboss):
			sloth_miniboss.queue_free()
	if bool(d.get("boss_defeated", false)):
		boss_defeated = true
		boss_item["used"] = true
		boss_item["node"].visible = false
		if is_instance_valid(dreamer):
			dreamer.queue_free()
	_update_hud()

func _rest(at: Vector2) -> void:
	respawn_point = at + Vector2(0, -10)
	player.set("respawn_point", respawn_point)
	player.health = player.max_health
	player.heals = RunState.max_heals()
	player.health_changed.emit(player.health)
	player.heals_changed.emit(player.heals)
	drowse = 0.0
	for trail in get_tree().get_nodes_in_group("drowsy_trail"):
		trail.queue_free()
	if not fight_active:
		_spawn_enemies()
	get_tree().call_group("game_main", "save_game", "sloth", respawn_point)
	_show_status("LUMI RESTS. THE HOLLOW STIRS.%s" % ("" if RunState.no_hit else " GAME SAVED."))

func _on_player_died() -> void:
	if player.get_parent() != self:
		return
	drowse = 0.0
	if fight_active:
		_reset_fight()
	_spawn_enemies()

func _update_dialogue_portrait(message: String) -> void:
	if not is_instance_valid(dialogue_portrait):
		return
	var lower := message.to_lower()
	var expression := "neutral"
	if lower.contains("exhaust") or lower.contains("tired") or lower.contains("sleep") or lower.contains("drowse") or lower.contains("can't move"):
		expression = "exhausted"
	elif lower.contains("surprise") or lower.contains("what?") or lower.contains("oh!") or lower.contains("hello!") or lower.contains("suddenly"):
		expression = "surprised"
	elif lower.contains("promise") or lower.contains("brave") or lower.contains("keep going") or lower.contains("determined") or lower.contains("fight"):
		expression = "determined"
	elif lower.contains("sorry") or lower.contains("miss") or lower.contains("lost") or lower.contains("lonely") or lower.contains("sad") or lower.contains("hurt") or lower.contains("forgive"):
		expression = "sad"
	if expression == dialogue_portrait_text and dialogue_portrait.texture != null:
		return
	dialogue_portrait_text = expression
	dialogue_portrait.texture = Story.portrait(expression)

func _show_dialogue(message: String, target: Node2D = null) -> void:
	dialogue_label.text = message
	dialogue_panel.visible = true
	dialogue_open = true
	dialogue_target = target
	var shown_text := message
	await get_tree().create_timer(Story.reading_time(shown_text)).timeout
	# Do not let an older timer hide a newer line or a story beat.
	if dialogue_open and dialogue_label.text == shown_text and not bool(get_meta("story_busy", false)):
		dialogue_panel.visible = false
		dialogue_open = false
		dialogue_target = null

func _banner(text: String, seconds: float) -> void:
	dialogue_open = false
	dialogue_label.text = text
	dialogue_panel.visible = true
	banner_time = maxf(seconds, Story.reading_time(text))

func _show_status(message: String) -> void:
	status_id += 1
	var my_id := status_id
	stats_label.text = message
	await get_tree().create_timer(1.6).timeout
	if my_id == status_id:
		_update_hud()

func _update_hud(_value: int = 0) -> void:
	if not is_instance_valid(player) or not is_instance_valid(stats_label):
		return
	var parts: Array[String] = []
	if drowse >= 80.0:
		parts.append("DROWSE: DEFENCELESS (+1 DAMAGE, NO HEALING)")
	elif drowse >= 50.0:
		parts.append("DROWSE: HEAVY (+1 DAMAGE)")
	if _unlit_near() > 0:
		parts.append("UNLIT LANTERNS NEARBY")
	if bool(player.get("can_wall_climb")):
		parts.append("SNAIL GRIPS")
	stats_label.text = "    ".join(parts)

# --- The Dreamer --------------------------------------------------------------

func _start_fight() -> void:
	if fight_active or boss_defeated or not is_instance_valid(dreamer):
		return
	fight_active = true
	lock_wall = _solid(Rect2(ARENA_LOCK_X - 20, -400, 40, 1400))
	scene_id += 1
	var my_id := scene_id
	var lines := [
		["THE DREAMER: ...Oh. Hello. Sorry. I'm so... tired.", 3.0],
		["THE DREAMER: I used to run, you know. I carried everything. Everyone else's work. Then one day I put one thing down. Then another. Then I couldn't pick any of it up.", 5.2],
		["NIM: You're not lazy. You're exhausted.", 2.4],
		["THE DREAMER: Is there a difference? Everyone called me lazy.", 3.0]
	]
	for line in lines:
		var seconds := maxf(float(line[1]), Story.reading_time(str(line[0])))
		_banner(str(line[0]), seconds)
		await get_tree().create_timer(seconds).timeout
		if my_id != scene_id:
			return
	dreamer.call("start_fight")

func _update_fight() -> void:
	if not fight_active:
		return
	if player.global_position.x < ARENA_LOCK_X - 60.0:
		_reset_fight()

func _reset_fight() -> void:
	scene_id += 1
	fight_active = false
	banner_time = 0.0
	dim = 0.0
	dialogue_panel.visible = false
	if is_instance_valid(lock_wall):
		lock_wall.queue_free()
	_clear_climb_walls()
	for post in boss_lanterns:
		if is_instance_valid(post):
			post.queue_free()
	boss_lanterns.clear()
	_prune_dead_items()
	if is_instance_valid(dreamer):
		dreamer.call("reset")
	queue_redraw()

func _prune_dead_items() -> void:
	var kept: Array[Dictionary] = []
	for item in interactables:
		if is_instance_valid(item["node"]) and not item["node"].is_queued_for_deletion():
			kept.append(item)
	interactables = kept
	var kept_lanterns: Array[Dictionary] = []
	for item in lantern_items:
		if is_instance_valid(item["node"]) and not item["node"].is_queued_for_deletion():
			kept_lanterns.append(item)
	lantern_items = kept_lanterns

func _on_dreamer_phase(phase: int) -> void:
	if phase == 2:
		_banner("THE DREAMER: Just a little longer... just rest...", 3.0)
		for x in [4570.0, 4950.0]:
			var item := _add_lantern(Vector2(x, 560))
			boss_lanterns.append(item["node"])
	elif phase == 3:
		_banner("THE DREAMER: I'll get up tomorrow. I promise. I promise.", 3.2)
		dim = 1.0
		for wall_x in [4420.0, 5110.0]:
			var wall := _solid(Rect2(wall_x - 15, 0, 30, 600), "climbable")
			climb_walls.append(wall)
		wall_age = 0.0
		_grant_grips()
		# Tutorial box after her line, long enough to read.
		var my_id := scene_id
		await get_tree().create_timer(3.4).timeout
		if my_id == scene_id and fight_active:
			_banner("SNAIL GRIPS: jump at a wall while holding toward it, then hold Space to climb. Swing (J) at the glowing lantern-heart. Your swing points away from the wall.", 8.0)

func _grant_grips() -> void:
	has_snail_grips = true
	player.set("can_wall_climb", true)
	_show_status("SNAIL GRIPS! HOLD TOWARD A WALL TO CLING, HOLD JUMP TO CLIMB.")

func _clear_player_debuffs() -> void:
	player.set("move_speed_mod", 1.0)
	player.set("jump_power_mod", 1.0)
	player.set("vulnerable", 0)
	player.set("heal_blocked", false)
	player.set("weighed_down", false)

func _clear_climb_walls() -> void:
	for wall in climb_walls:
		if is_instance_valid(wall):
			wall.queue_free()
	climb_walls.clear()

func _on_dreamer_defeated() -> void:
	boss_defeated = true
	_clear_climb_walls()
	fight_active = false
	boss_item["used"] = true
	boss_item["node"].visible = false
	dim = 0.0
	if is_instance_valid(lock_wall):
		lock_wall.queue_free()
	scene_id += 1
	var my_id := scene_id
	var lines := [
		["THE DREAMER: Just a little longer... just rest...", 2.6],
		["(She smiles and curls up small.)", 2.6],
		["THE DREAMER: I was so tired for so long. Thank you for staying awake with me.", 3.8],
		["(Her hammock lifts, and light spills in.)", 3.0],
		["THE HOURGLASS SHARD (TEMPO STYLE), THE SNAIL GRIPS AND THE DUSK KEY ARE YOURS.", 3.6]
	]
	for line in lines:
		var seconds := maxf(float(line[1]), Story.reading_time(str(line[0])))
		_banner(str(line[0]), seconds)
		await get_tree().create_timer(seconds).timeout
		if my_id != scene_id:
			return
	has_hourglass = true
	has_dusk_key = true
	if not has_snail_grips:
		_grant_grips()
	_open_dream_exit()
	region_cleared.emit("sloth")

func _create_sloth_expanded() -> void:
	for rect: Rect2 in EXTRA_PLATFORMS:
		_solid(rect)
	var seal_marker := _make_interactable("SEAL\n[E] TAKE", Vector2(570, 262), Color(0.75, 0.85, 1.0))
	interactables.append({"node": seal_marker, "message": "A cool, pale seal rests on the ledge.", "kind": "seal", "seal_id": "loft", "used": false})
	for pos in [Vector2(1055, 360), Vector2(420, 240), Vector2(4245, 120)]:
		_add_lantern(pos)
	if not sloth_miniboss_defeated:
		sloth_miniboss = CharacterBody2D.new()
		sloth_miniboss.set_script(WARDEN)
		sloth_miniboss.position = Vector2(4530, 90)
		sloth_miniboss.set("left_x", 4390.0)
		sloth_miniboss.set("right_x", 4670.0)
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 30.0
		shape.shape = circle
		sloth_miniboss.add_child(shape)
		add_child(sloth_miniboss)
		sloth_miniboss.connect("defeated", Callable(self, "_on_sloth_mb_defeated"))

func _on_sloth_mb_defeated() -> void:
	sloth_miniboss_defeated = true
	_grant_seal("sky")
	_show_status("DOZY WARDEN DEFEATED. SEAL %d/%d" % [seals.size(), SEALS_NEEDED])

func _grant_seal(id: String) -> void:
	if not seals.has(id):
		seals.append(id)

func _hide_seal_marker(id: String) -> void:
	for item in interactables:
		if item["kind"] == "seal" and item.get("seal_id", "") == id:
			item["used"] = true
			item["node"].visible = false
			queue_redraw()

func _open_dream_exit() -> void:
	dream_exit_open = true
	dream_exit = _make_interactable("DREAM EXIT\n[E] RETURN", Vector2(270, 262), Color(0.88, 0.84, 1.0))
	interactables.append({"node": dream_exit, "message": "A shimmering doorway of half-remembered pillows leads back to the Still Pond through the Dream.\n\nReturn to hub?", "kind": "dream_exit", "used": false})
	_show_status("DREAM EXIT OPEN - WAKE THROUGH THE DREAMING")

func get_respawn_point() -> Vector2:
	return respawn_point
