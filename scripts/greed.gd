extends Node2D
const Story := preload("res://scripts/story.gd")
const Palette := preload("res://scripts/palette.gd")
const Settings := preload("res://scripts/game_settings.gd")
const RunState := preload("res://scripts/run_state.gd")

signal region_cleared(region_name: String)
signal return_to_hub
signal collectible_found(collectible_type: String)

var player: CharacterBody2D
var stats_label: Label
var hud_layer: CanvasLayer
var prompt_label: Label
var dialogue_panel: Panel
var dialogue_label: Label
var dialogue_location_label: Label
var dialogue_portrait: TextureRect
var dialogue_portrait_text := ""
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
var secret_cache_found := false

# The Collector fight
const COLLECTOR_SCRIPT := preload("res://scripts/collector.gd")
const GREEDY_MITE := preload("res://scripts/greedy_mite.gd")
const COIN_GUARD := preload("res://scripts/coin_guard.gd")
const ARENA_LOCK_X := 2000.0   # left lock wall while the fight is on (marker is at 2130)
const ARENA_END_X := 2750.0    # permanent end wall of Greed
const COLLECTOR_X := 2500.0
const VAULT_END_X := -1930.0   # far left wall, past the vault
const VAULT_GROUND := Rect2(-1900, 470, 570, 60)   # the old treasury floor
const VAULT_EXIT_POS := Vector2(-1730, 440)

# Main route deliberately has three readable breaks. They are short enough to
# jump, but make the garden feel like terrain rather than one uninterrupted floor.
# Keep these rectangles in sync for both drawing and collision.
const MAIN_GROUND := [
	Rect2(0, 570, 600, 90),
	Rect2(700, 570, 550, 90),
	Rect2(1370, 570, 460, 90),
	Rect2(1920, 570, 830, 90),
]

# Extra shelves: Rect2(left, top, width, height). One shared silhouette helper
# defines both the visible rock shape and its collision polygon.
const EXTRA_PLATFORMS := [
	# Opening ledge: one optional pickup, not a chain of tutorial blocks.
	Rect2(440, 490, 120, 20),
	# Vault Route: a deliberate climb out over the broken garden wall.
	Rect2(250, 520, 110, 50),
	Rect2(70, 470, 110, 18),
	Rect2(-110, 420, 110, 18),
	Rect2(-290, 370, 110, 18),
	Rect2(-470, 320, 110, 18),
	Rect2(-650, 270, 110, 18),
	Rect2(-830, 320, 110, 18),
	Rect2(-1010, 370, 110, 18),
	Rect2(-1190, 420, 110, 18),
	# Hidden treasury shelf: the upper pocket is reached with the Featherweight Charm.
	Rect2(-1830, 410, 100, 18),
	Rect2(-1830, 300, 100, 18),
	# Gold Ridge: four broad, rising shelves form one readable climb to the seal.
	# The first is a substantial broken outcrop; the next three keep a steady jump rhythm.
	Rect2(1240, 500, 150, 70),
	Rect2(1405, 445, 155, 24),
	Rect2(1575, 390, 155, 24),
	Rect2(1745, 335, 165, 24),
]
const MOUNTAIN_X := 2580.0
var collector: CharacterBody2D
var arena_wall: StaticBody2D
var boss_item: Dictionary = {}
var fight_active := false
var mountain_visible := true
var offering_line_shown := false
var shrine_line_shown := false
var weight_line_shown := false
var banner_time := 0.0
var scene_id := 0
var has_open_hand := false
var has_gold_key := false
const SEALS_NEEDED := 2
var seals: Array = []   # "vault" (Coin Guard) and "ridge" (end of the Gold Ridge)

# Expanded content
var post_boss_open := false
var vault_exit: Node2D = null
var miniboss_defeated := false
var coin_guard: CharacterBody2D = null

# Spawn points
var respawn_point := Vector2(280, 520)
var checkpoint_unlocked := false

const GRAVITY := 1200.0

func _ready() -> void:
	add_to_group("gold_holder")
	_create_background()
	_create_ground()
	if not is_instance_valid(player):
		_create_player()
	_create_hud()
	_create_greed_level()
	_create_expanded_content()
	_connect_signals()
	_update_hud()
	Story.play(self, dialogue_panel, dialogue_label, Story.GREED_ENTER)

var bg_drawn := false

func _create_background() -> void:
	# Background is drawn in _draw()
	pass

func _draw() -> void:
	# Golden garden sky
	draw_rect(Rect2(-3000, -2000, 8000, 4000), Palette.GREED_SKY)

	# Distant ridgelines make the golden garden feel like a landscape, not a flat room.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-3000, 470), Vector2(-2600, 360), Vector2(-2200, 430),
		Vector2(-1750, 300), Vector2(-1320, 430), Vector2(-900, 330),
		Vector2(-450, 430), Vector2(0, 320), Vector2(420, 420),
		Vector2(850, 310), Vector2(1280, 420), Vector2(1680, 300),
		Vector2(2100, 420), Vector2(2550, 330), Vector2(3000, 450),
		Vector2(3000, 610), Vector2(-3000, 610)
	]), Color(0.91, 0.82, 0.55, 1.0))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-3000, 520), Vector2(-2500, 450), Vector2(-2050, 500),
		Vector2(-1600, 405), Vector2(-1150, 510), Vector2(-650, 440),
		Vector2(-150, 510), Vector2(350, 430), Vector2(800, 510),
		Vector2(1300, 425), Vector2(1800, 510), Vector2(2250, 430),
		Vector2(3000, 510), Vector2(3000, 610), Vector2(-3000, 610)
	]), Color(0.86, 0.72, 0.40, 1.0))

	# Broken garden columns: a hint of an older place being swallowed by flowers.
	for i in range(7):
		var x := -1850.0 + i * 680.0
		var h := 115.0 + float((i * 47) % 90)
		draw_rect(Rect2(x, 570.0 - h, 22, h), Color(0.68, 0.53, 0.30, 1.0))
		draw_rect(Rect2(x - 5, 570.0 - h, 32, 8), Color(0.78, 0.64, 0.37, 1.0))
		draw_rect(Rect2(x + 3, 570.0 - h * 0.55, 17, 5), Color(0.55, 0.41, 0.24, 0.9))
		if i % 2 == 0:
			draw_line(Vector2(x + 10, 570.0 - h + 18), Vector2(x + 4, 570.0 - h + 47), Color(0.48, 0.36, 0.22, 0.85), 2.0)
			draw_line(Vector2(x + 4, 570.0 - h + 47), Vector2(x + 15, 570.0 - h + 68), Color(0.48, 0.36, 0.22, 0.85), 2.0)

	# A broken compass monument marks the crossroads where routes diverge.
	draw_rect(Rect2(1035, 390, 18, 180), Color(0.68, 0.53, 0.30, 1.0))
	draw_rect(Rect2(1000, 390, 88, 12), Color(0.78, 0.64, 0.37, 1.0))
	draw_rect(Rect2(1016, 365, 56, 8), Color(0.55, 0.41, 0.24, 0.9))
	draw_circle(Vector2(1044, 350), 17.0, Color(0.96, 0.80, 0.35, 0.95))
	draw_circle(Vector2(1044, 350), 8.0, Color(0.56, 0.39, 0.18, 1.0))

	# The broken arch frames the approach to the Collector.
	draw_rect(Rect2(1980, 300, 24, 270), Color(0.61, 0.45, 0.25, 1.0))
	draw_rect(Rect2(2240, 345, 24, 225), Color(0.61, 0.45, 0.25, 1.0))
	draw_rect(Rect2(1980, 290, 180, 22), Color(0.73, 0.56, 0.30, 1.0))
	draw_rect(Rect2(2140, 290, 100, 22), Color(0.73, 0.56, 0.30, 1.0))
	draw_line(Vector2(2160, 290), Vector2(2178, 312), Color(0.48, 0.35, 0.20, 1.0), 3.0)

	if not bg_drawn:
		# Golden flowers (decorative) - only seed once
		randomize()
		bg_drawn = true

	for i in range(64):
		var x := fposmod(float(i * 173 + 42), 5600.0) - 2800.0
		var y := fposmod(float(i * 97 + 17), 440.0) + 80.0
		var size := 2.0 + fposmod(float(i * 13), 4.0)
		draw_circle(Vector2(x, y), size, Color(0.94, 0.72, 0.24, 0.48))
		if i % 3 == 0:
			draw_circle(Vector2(x + 4, y - 3), size * 0.55, Color(1.0, 0.9, 0.54, 0.72))

	# Distant golden trees
	for i in range(6):
		var x := -200 + i * 400
		draw_rect(Rect2(x - 8, 350, 16, 260), Color(0.65, 0.52, 0.3, 1.0))
		draw_circle(Vector2(x, 340), 45, Color(0.75, 0.65, 0.35, 1.0))
		draw_circle(Vector2(x - 25, 360), 30, Color(0.8, 0.7, 0.4, 1.0))
		draw_circle(Vector2(x + 25, 360), 30, Color(0.8, 0.7, 0.4, 1.0))

	# Ground and platforms (same rectangles as the colliders in _create_ground)
	var ground := Palette.GREED_GROUND
	var top := Palette.GREED_GROUND_TOP
	for section: Rect2 in MAIN_GROUND:
		draw_rect(section, ground)
		draw_rect(Rect2(section.position, Vector2(section.size.x, 5)), top)
		for blade in range(int(section.size.x / 34.0)):
			var bx := section.position.x + 16.0 + blade * 34.0
			draw_line(Vector2(bx, section.position.y + 3), Vector2(bx - 3, section.position.y - 7), Color(0.77, 0.68, 0.34, 1.0), 2.0)
			draw_line(Vector2(bx, section.position.y + 3), Vector2(bx + 5, section.position.y - 5), Color(0.77, 0.68, 0.34, 1.0), 2.0)
	for plat: Rect2 in EXTRA_PLATFORMS:
		var rock := _platform_world_points(plat)
		draw_colored_polygon(rock, ground)
		var outline := rock.duplicate()
		outline.append(rock[0])
		draw_polyline(outline, Palette.GOLD_OUTLINE, 2.0)
		# A restrained highlight follows the irregular top edge instead of outlining a rectangle.
		draw_line(rock[1], rock[2], top, 3.0)
		draw_line(rock[2], rock[3], top, 3.0)
		draw_line(rock[3], rock[4], top, 3.0)
	# The treasury floor remains a broad, solid stone shelf.
	draw_rect(VAULT_GROUND, ground)
	draw_rect(Rect2(VAULT_GROUND.position, Vector2(VAULT_GROUND.size.x, 5)), top)

	# A small glint hints at the treasury pocket without exposing its cache marker.
	if not secret_cache_found:
		draw_line(Vector2(-1800, 407), Vector2(-1780, 390), Color(1.0, 0.83, 0.38, 0.8), 2.0)
		draw_circle(Vector2(-1780, 390), 3.0, Color(1.0, 0.9, 0.55, 0.85))

	# Miniboss wayfinding: point players into the left vault branch and mark the arena.
	draw_string(ThemeDB.fallback_font, Vector2(-1110, 392), "VAULT ROUTE  →", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.36, 0.22, 0.08, 1.0))
	if not miniboss_defeated:
		draw_circle(Vector2(-1400, 440), 48.0, Color(1.0, 0.76, 0.20, 0.12))
		draw_arc(Vector2(-1400, 440), 40.0, 0.0, TAU, 32, Color(1.0, 0.77, 0.22, 0.9), 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(-1505, 385), "COIN GUARD", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.32, 0.20, 0.08, 1.0))

	# Foreground flower clumps make the garden feel overgrown.
	for i in range(42):
		var fx := fposmod(float(i * 113 + 31), 3000.0) - 150.0
		var fy := 568.0 - fposmod(float(i * 29), 16.0)
		var petal := Color(0.94, 0.75, 0.25, 0.95) if i % 3 != 0 else Color(0.95, 0.86, 0.52, 0.95)
		draw_line(Vector2(fx, fy + 3), Vector2(fx - 2, fy - 9), Color(0.34, 0.48, 0.24, 1.0), 2.0)
		draw_circle(Vector2(fx - 3, fy - 10), 3.0, petal)
		draw_circle(Vector2(fx + 2, fy - 12), 3.0, petal)
		draw_circle(Vector2(fx, fy - 11), 2.0, Color(0.48, 0.31, 0.13, 1.0))

	for item in interactables:
		if item.get("used", false) or not is_instance_valid(item["node"]) or not item["node"].visible:
			continue
		var kind: String = item["kind"]
		if kind == "coin" or kind == "coin_extra":
			_draw_pickup_coin(item["node"].position)
		elif kind == "seal":
			_draw_pickup_seal(item["node"].position)
		elif kind == "open_hand_manual":
			_draw_open_hand_manual(item["node"].position)
		elif kind == "secret_cache":
			_draw_secret_cache(item["node"].position)

	if mountain_visible:
		_draw_mountain()

# Pickups need a body: a coin, and a seal. Dark outline so they read on the pale ground.
func _draw_pickup_coin(c: Vector2) -> void:
	draw_circle(c, 13.0, Palette.GOLD_OUTLINE)
	draw_circle(c, 10.0, Color(0.94, 0.72, 0.16))
	draw_circle(c, 5.5, Color(1.0, 0.92, 0.55))
	# The garden's wrongness is subtle: the coins look almost like faces.
	draw_circle(c + Vector2(-3.0, -1.0), 1.4, Color(0.35, 0.23, 0.10, 0.9))
	draw_circle(c + Vector2(3.0, -1.0), 1.4, Color(0.35, 0.23, 0.10, 0.9))
	draw_line(c + Vector2(-2.0, 4.0), c + Vector2(2.0, 4.0), Color(0.35, 0.23, 0.10, 0.8), 1.2)

func _draw_pickup_seal(c: Vector2) -> void:
	draw_circle(c, 24.0, Color(1.0, 0.85, 0.3, 0.25))
	draw_circle(c, 17.0, Palette.GOLD_OUTLINE)
	draw_circle(c, 14.0, Color(0.85, 0.52, 0.16))
	draw_circle(c, 8.0, Color(1.0, 0.88, 0.45))
	draw_circle(c + Vector2(-4, -4), 2.5, Color(1, 1, 1, 0.9))

func _draw_open_hand_manual(c: Vector2) -> void:
	# A small old book with a palm mark: a visual cue for the vault's style reward.
	draw_circle(c, 28.0, Color(1.0, 0.82, 0.42, 0.16))
	draw_rect(Rect2(c + Vector2(-17, -12), Vector2(34, 24)), Color(0.48, 0.29, 0.13, 1.0))
	draw_rect(Rect2(c + Vector2(-17, -12), Vector2(34, 24)), Palette.GOLD_OUTLINE, false, 2.0)
	draw_line(c + Vector2(0, -9), c + Vector2(0, 9), Color(1.0, 0.85, 0.52, 0.95), 2.0)
	draw_line(c + Vector2(-6, 4), c + Vector2(-6, -4), Color(1.0, 0.85, 0.52, 0.95), 2.0)
	draw_line(c + Vector2(0, 4), c + Vector2(0, -7), Color(1.0, 0.85, 0.52, 0.95), 2.0)
	draw_line(c + Vector2(6, 4), c + Vector2(6, -4), Color(1.0, 0.85, 0.52, 0.95), 2.0)

func _draw_secret_cache(c: Vector2) -> void:
	# Only drawn when Lumi is close enough to reveal the hidden treasury pocket.
	draw_circle(c, 24.0, Color(1.0, 0.78, 0.24, 0.14))
	var pouch := PackedVector2Array([
		c + Vector2(-12, -7), c + Vector2(-8, -14), c + Vector2(8, -14),
		c + Vector2(12, -7), c + Vector2(10, 8), c + Vector2(0, 15),
		c + Vector2(-10, 8), c + Vector2(-12, -7)
	])
	draw_colored_polygon(pouch, Color(0.38, 0.24, 0.12, 1.0))
	draw_polyline(pouch, Palette.GOLD_OUTLINE, 2.0)
	draw_line(c + Vector2(-7, -7), c + Vector2(7, -7), Color(1.0, 0.83, 0.38, 1.0), 2.0)
	draw_circle(c + Vector2(-4, 2), 3.0, Color(1.0, 0.85, 0.35, 1.0))
	draw_circle(c + Vector2(4, 5), 2.5, Color(1.0, 0.92, 0.58, 1.0))

func _draw_mountain() -> void:
	# The Collector's mountain of coins. He swallows it in phase two.
	draw_colored_polygon(PackedVector2Array([
		Vector2(MOUNTAIN_X - 150, 570), Vector2(MOUNTAIN_X - 60, 470),
		Vector2(MOUNTAIN_X, 430), Vector2(MOUNTAIN_X + 60, 470),
		Vector2(MOUNTAIN_X + 150, 570)
	]), Color(0.86, 0.66, 0.2, 1.0))
	draw_polyline(PackedVector2Array([
		Vector2(MOUNTAIN_X - 150, 570), Vector2(MOUNTAIN_X - 60, 470), Vector2(MOUNTAIN_X, 430),
		Vector2(MOUNTAIN_X + 60, 470), Vector2(MOUNTAIN_X + 150, 570)
	]), Palette.GOLD_OUTLINE, 3.0)
	for i in range(34):
		var row := i / 7
		var col := i % 7
		var cx := MOUNTAIN_X - 105.0 + col * 35.0 + (row % 2) * 14.0 - row * 6.0
		var cy := 556.0 - row * 24.0
		if absf(cx - MOUNTAIN_X) < 150.0 - row * 34.0:
			draw_circle(Vector2(cx, cy), 11, Color(0.94, 0.76, 0.24, 1.0))
			draw_circle(Vector2(cx, cy), 6.5, Color(1.0, 0.9, 0.5, 1.0))

	# Vault exit post-boss
	if post_boss_open:
		var d := VAULT_EXIT_POS
		draw_rect(Rect2(d.x - 34, d.y - 150, 68, 180), Color(0.4, 0.32, 0.16, 1.0))
		draw_rect(Rect2(d.x - 34, d.y - 150, 68, 180), Palette.GOLD_OUTLINE, false, 3.0)
		draw_circle(d + Vector2(0, -110), 34, Color(0.98, 0.84, 0.38, 0.9))
		draw_circle(d + Vector2(0, -110), 20, Color(1.0, 0.94, 0.6, 1.0))
		draw_rect(Rect2(d.x - 18, d.y - 44, 36, 74), Color(0.22, 0.17, 0.08, 1.0))


func _create_ground() -> void:
	# Main route: broken ground creates three small traversal decisions.
	for i in range(MAIN_GROUND.size()):
		var section: Rect2 = MAIN_GROUND[i]
		_create_ground_section(section.get_center(), section.size, "GreedGround%d" % (i + 1))

	# Every visible platform is created from EXTRA_PLATFORMS below. Do not add
	# one-off colliders here: that caused invisible platforms after layout edits.

	# Expanded wings: the Gold Ridge over the road to the arena, and the long
	# Vault Route out over the pit to the old treasury. See EXTRA_PLATFORMS.
	for rect: Rect2 in EXTRA_PLATFORMS:
		_create_platform(rect.get_center(), rect.size)
	_create_ground_section(VAULT_GROUND.get_center(), VAULT_GROUND.size, "VaultApproach")

	# Boundary walls
	_create_boundary(Vector2(ARENA_END_X, 0))
	_create_boundary(Vector2(VAULT_END_X, 0))

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
	platform.name = "GreedRockShelf"
	var collision := CollisionPolygon2D.new()
	collision.polygon = _platform_local_points(Rect2(Vector2.ZERO, size))
	platform.add_child(collision)
	add_child(platform)

# A single silhouette function feeds both drawing and collision. Broad tops and
# bevelled sides read as broken stone outcrops rather than floating rectangles.
func _platform_local_points(rect: Rect2) -> PackedVector2Array:
	var half := rect.size * 0.5
	var bevel := minf(10.0, half.y * 0.65)
	return PackedVector2Array([
		Vector2(-half.x, half.y),
		Vector2(-half.x + 8.0, -half.y + bevel),
		Vector2(-half.x * 0.28, -half.y),
		Vector2(half.x * 0.24, -half.y + 2.0),
		Vector2(half.x - 8.0, -half.y + bevel),
		Vector2(half.x, half.y),
	])

func _platform_world_points(rect: Rect2) -> PackedVector2Array:
	var points := _platform_local_points(rect)
	for i in range(points.size()):
		points[i] += rect.get_center()
	return points

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
	camera.position = Vector2(0, -100)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	# The vault is west of spawn; clamping at x=0 hid the entire branch off-screen.
	camera.limit_left = int(VAULT_END_X - 100.0)
	camera.limit_right = int(ARENA_END_X + 100.0)
	# Let the camera travel vertically so the high ridge reads as a real climb.
	camera.limit_top = -200
	camera.limit_bottom = 900
	player.add_child(camera)

func _create_hud() -> void:
	hud_layer = CanvasLayer.new()
	add_child(hud_layer)
	var hud := hud_layer

	var title := Label.new()
	title.position = Vector2(24, 18)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.91, 0.91, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0.12, 0.10, 0.24))
	title.add_theme_constant_override("outline_size", 6)
	title.text = "WHAT THE WATER KEEPS  •  THE GILDED GARDEN"
	hud.add_child(title)

	stats_label = Label.new()
	stats_label.position = Vector2(24, 128)
	stats_label.add_theme_font_size_override("font_size", 20)
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
	help.add_theme_font_size_override("font_size", 17)
	help.add_theme_color_override("font_color", Color(0.82, 0.83, 0.9))
	help.add_theme_color_override("font_outline_color", Color(0.12, 0.10, 0.24))
	help.add_theme_constant_override("outline_size", 5)
	help.text = "A/D move   SPACE jump   J lantern swing   LEFT SHIFT dash   Q heal   E interact   ESC menu"
	hud.add_child(help)

	prompt_label = Label.new()
	prompt_label.position = Vector2(0, 610)
	prompt_label.size = Vector2(1280, 32)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 23)
	prompt_label.add_theme_color_override("font_color", Color(0.80, 0.94, 1.0))
	prompt_label.add_theme_color_override("font_outline_color", Color(0.12, 0.10, 0.24))
	prompt_label.add_theme_constant_override("outline_size", 6)
	hud.add_child(prompt_label)

	dialogue_panel = Panel.new()
	dialogue_panel.position = Vector2(100, 468)
	dialogue_panel.size = Vector2(1080, 182)
	dialogue_panel.visible = false
	var dialogue_style := StyleBoxFlat.new()
	dialogue_style.bg_color = Color(0.07, 0.08, 0.14, 0.88)
	dialogue_style.border_color = Color(1.0, 0.78, 0.30, 1.0)
	dialogue_style.set_border_width_all(2)
	dialogue_style.set_corner_radius_all(16)
	dialogue_style.shadow_color = Color(0.04, 0.03, 0.10, 0.45)
	dialogue_style.shadow_size = 12
	dialogue_style.shadow_offset = Vector2(0, 5)
	dialogue_panel.add_theme_stylebox_override("panel", dialogue_style)
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
	dialogue_location_label.text = "THE GILDED GARDEN"
	dialogue_location_label.add_theme_font_size_override("font_size", 17)
	dialogue_location_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.30, 1.0))
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

func _create_greed_level() -> void:
	# Lore tablets
	var lore_positions := [Vector2(380, 570), Vector2(-1835, 440), Vector2(1600, 570)]
	var lore_messages := [
		"I only wanted enough. Then enough was a little more.",
		"The flowers grew from the coins we dropped. Nobody remembered who dropped them.",
		"I counted it every night so I wouldn't have to count what I'd lost."
	]
	for i in range(lore_messages.size()):
		var lore := _make_interactable("TABLET %d\n[E] READ" % (i + 1), lore_positions[i], Color(0.85, 0.75, 0.45))
		interactables.append({"node": lore, "message": lore_messages[i], "kind": "lore", "used": false})

	# Shrines (offer gold to reduce weight)
	var shrine_positions := [Vector2(520, 470), Vector2(-1600, 430), Vector2(1640, 545)]
	for i in range(shrine_positions.size()):
		var shrine := _make_interactable("SHRINE\n[E] OFFER", shrine_positions[i], Color(0.95, 0.85, 0.5))
		interactables.append({"node": shrine, "message": "A small golden bowl. \"Give what you carry.\"\n\nPress E to offer all carried gold.", "kind": "shrine", "used": false, "shrine_id": i})

	# Coin pickups
	var coin_positions := [Vector2(300, 560), Vector2(500, 470), Vector2(730, 545), Vector2(960, 545), Vector2(1140, 425), Vector2(1380, 545), Vector2(1540, 435), Vector2(1730, 545), Vector2(1860, 350)]
	for i in range(coin_positions.size()):
		var coin := _make_interactable("COIN", coin_positions[i], Color(1.0, 0.85, 0.3))
		interactables.append({"node": coin, "message": "A gleaming gold coin. It feels heavier than it should.\n\n+10 Gold", "kind": "coin", "used": false, "value": 10})

	# The Featherweight Charm unlocks the player's double jump.
	var charm := _make_interactable("FEATHERWEIGHT\n[E] TAKE", Vector2(1545, 435), Color(0.72, 0.9, 1.0))
	interactables.append({
		"node": charm,
		"message": "A feather-light charm rests among the flowers.\n\nLumi feels able to rise once more in mid-air.",
		"kind": "featherweight",
		"used": false
	})

	# The vault's combat manual is the reward for defeating its guardian.
	# It can be seen before the fight, but cannot be learned until the Coin Guard falls.
	var manual := _make_interactable("OPEN HAND MANUAL\n[E] LEARN", Vector2(-1615, 425), Color(1.0, 0.83, 0.55))
	interactables.append({
		"node": manual,
		"message": "The old manual teaches Lumi to turn a held coin into an offering, then let it go.\n\nOPEN HAND UNLOCKED: palm combos, Rising Palm, Falling Petals, Wide Offering, Coin Toss, Open Palm guard, and Seven Hands.",
		"kind": "open_hand_manual",
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

	var ridge_seal := _make_interactable("SEAL\n[E] TAKE", Vector2(1885, 325), Color(1.0, 0.9, 0.5))
	interactables.append({"node": ridge_seal, "message": "A heavy gold seal, warm from the sun.", "kind": "seal", "seal_id": "ridge", "used": false})

	# Optional secret: an upper shelf beyond the treasury tablet. No stat buff.
	var secret_cache := _make_interactable("???", Vector2(-1780, 260), Color(0.95, 0.82, 0.5))
	interactables.append({
		"node": secret_cache,
		"message": "A forgotten purse spills 35 gold into Lumi's hands.",
		"kind": "secret_cache",
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
	label.position = Vector2(-85, -82)
	label.size = Vector2(170, 74)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", tint)
	label.add_theme_color_override("font_outline_color", Color(0.12, 0.10, 0.24))
	label.add_theme_constant_override("outline_size", 5)
	marker.add_child(label)
	add_child(marker)
	return marker

func set_region_active(active: bool) -> void:
	visible = active
	hud_layer.visible = active
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	if not active and is_instance_valid(player):
		player.set("move_speed_mod", 1.0)
		player.set("jump_power_mod", 1.0)
		player.set("vulnerable", 0)
		player.set("weighed_down", false)

func _connect_signals() -> void:
	player.health_changed.connect(_update_hud)
	player.heals_changed.connect(_update_hud)
	player.status_changed.connect(_show_status)

func _process(delta: float) -> void:
	if is_instance_valid(dialogue_label):
		_update_dialogue_portrait(dialogue_label.text)
	# Apply weight debuff to player
	if weight_debuff > 0.0:
		# Escalating costs. Above 30 weight: slower, lower jumps. From 50: +1 damage
		# per hit. From 60: no dash or double jump.
		var felt := minf(1.0, weight_debuff * RunState.debuff_scale())
		player.set("move_speed_mod", 1.0 - felt * 0.5)
		player.set("jump_power_mod", 1.0 - felt * 0.5)
		player.set("vulnerable", 1 if felt >= 0.5 else 0)
		player.set("weighed_down", felt >= 0.6)
	else:
		player.set("move_speed_mod", 1.0)
		player.set("jump_power_mod", 1.0)
		player.set("vulnerable", 0)
		player.set("weighed_down", false)

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

	if bool(get_meta("story_busy", false)):
		prompt_label.text = ""
		return

	# Keep the secret's label hidden until Lumi is close enough to notice the glint.
	for item in interactables:
		if item["kind"] == "secret_cache" and is_instance_valid(item["node"]):
			item["node"].visible = not secret_cache_found and player.global_position.distance_to(item["node"].global_position) < 220.0

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
	queue_redraw()
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
			var msg := "A small golden bowl. \"Give what you carry.\"\n\n(Carry no gold to offer.)"
			if offered > 0:
				weight_debuff = maxf(0.0, weight_debuff - 0.3)
				msg = "Lumi offers %d gold to the shrine. The bowl glows warmly.\n\nThe weight lifts slightly." % offered
			if not shrine_line_shown:
				shrine_line_shown = true
				Story.play(self, dialogue_panel, dialogue_label, Story.GREED_SHRINE + [[msg, 3.6]])
			else:
				_show_dialogue(msg, target)
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
		"open_hand_manual":
			if not miniboss_defeated:
				_show_dialogue("The manual is sealed beneath a heavy coin clasp. The Coin Guard still carries the key.", target)
				return
			item["used"] = true
			target.visible = false
			has_open_hand = true
			if is_instance_valid(player):
				player.call("unlock_style", "open_hand")
			collectible_found.emit("open_hand")
			_show_dialogue(item["message"], target)
			_show_status("OPEN HAND LEARNED. TAB SWAPS STYLES.")
		"boss":
			if boss_defeated:
				_show_dialogue("The mountain is gone. Only a small, quiet shine is left in the bowl.", target)
			elif seals.size() < SEALS_NEEDED:
				_show_dialogue("The mountain's gate is shut tight.\n\nSEALS %d/%d. Two seals lie far from the main road." % [seals.size(), SEALS_NEEDED], target)
			else:
				_start_collector_fight()
		"bowl":
			_offer_at_bowl(target)
		"exit":
			return_to_hub.emit()
		"seal":
			item["used"] = true
			target.visible = false
			_grant_seal(item["seal_id"])
			_show_status("SEAL %d/%d" % [seals.size(), SEALS_NEEDED])
			_show_dialogue(item["message"], target)
		"vault_exit":
			# Lands Lumi on the hub's upper platform instead of the start.
			get_tree().call_group("game_main", "_return_to_hub", true)
		"coin_extra":
			if item.get("used", false):
				return
			item["used"] = true
			if item.has("marker") and is_instance_valid(item["marker"]):
				item["marker"].visible = false
			var val: int = item.get("value", 15)
			add_gold(val)
			_show_dialogue("Lumi picks up %d gold." % val)
		"secret_cache":
			item["used"] = true
			target.visible = false
			secret_cache_found = true
			add_gold(35)
			_show_dialogue(item["message"], target)
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
	if weight_debuff > 0.3 and not weight_line_shown:
		weight_line_shown = true
		Story.play(self, dialogue_panel, dialogue_label, Story.GREED_WEIGHT)
	if carried_gold >= 60:
		_show_status("BURDEN: You held on too tightly.")

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
	dialogue_portrait.texture = load("res://assets/portraits/lumi/lumi_%s.png" % expression)

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

func _update_hud(_value: int = 0) -> void:
	if not is_instance_valid(player) or not is_instance_valid(stats_label):
		return
	var parts: Array[String] = []
	if carried_gold > 0:
		parts.append("GOLD: %d" % carried_gold)
	var felt := minf(1.0, weight_debuff * RunState.debuff_scale())
	if felt >= 0.6:
		parts.append("WEIGHT: CRUSHING (+1 DAMAGE, NO DASH OR DOUBLE JUMP)")
	elif felt >= 0.5:
		parts.append("WEIGHT: HEAVY (+1 DAMAGE)")
	elif weight_debuff > 0.3:
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

func save_state() -> Dictionary:
	return {
		"featherweight_found": featherweight_found,
		"boss_defeated": boss_defeated,
		"has_open_hand": has_open_hand,
		"has_gold_key": has_gold_key,
		"secret_cache_found": secret_cache_found,
		"coin_guard_defeated": miniboss_defeated,
		"seals": seals.duplicate()
	}

# Puts Greed back the way a save left it: the charm taken, the Collector gone.
func apply_save(d: Dictionary) -> void:
	if bool(d.get("featherweight_found", false)):
		featherweight_found = true
		has_featherweight = true
		if is_instance_valid(player):
			player.set("can_double_jump", true)
		for item in interactables:
			if item["kind"] == "featherweight":
				item["used"] = true
				item["node"].visible = false
	if bool(d.get("secret_cache_found", false)):
		secret_cache_found = true
		for item in interactables:
			if item["kind"] == "secret_cache":
				item["used"] = true
				item["node"].visible = false
	if bool(d.get("has_open_hand", false)):
		has_open_hand = true
		if is_instance_valid(player) and not player.get("unlocked_styles").has("open_hand"):
			player.get("unlocked_styles").append("open_hand")
		for item in interactables:
			if item["kind"] == "open_hand_manual":
				item["used"] = true
				item["node"].visible = false
	for id in d.get("seals", []):
		_grant_seal(str(id))
		_hide_seal_marker(str(id))
	if bool(d.get("coin_guard_defeated", false)):
		miniboss_defeated = true
		_grant_seal("vault")
		if is_instance_valid(coin_guard):
			coin_guard.queue_free()
	if bool(d.get("boss_defeated", false)):
		boss_defeated = true
		has_gold_key = bool(d.get("has_gold_key", true))
		boss_item["used"] = true
		boss_item["node"].visible = false
		mountain_visible = false
		if is_instance_valid(collector):
			collector.queue_free()
		queue_redraw()
	queue_redraw()
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

func spend_gold(amount: int) -> int:
	var spent := mini(amount, carried_gold)
	carried_gold -= spent
	_update_weight()
	_update_hud()
	return spent

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
	banner_time = maxf(seconds, Story.reading_time(text))

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
		var seconds := maxf(float(line[1]), Story.reading_time(str(line[0])))
		_banner(str(line[0]), seconds)
		await get_tree().create_timer(seconds).timeout
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
		if is_ancestor_of(coin):
			coin.queue_free()
	mountain_visible = true
	queue_redraw()
	if is_instance_valid(collector):
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
	for coin in get_tree().get_nodes_in_group("collector_coin"):
		if is_ancestor_of(coin):
			coin.queue_free()
	if is_instance_valid(arena_wall):
		arena_wall.queue_free()
	scene_id += 1
	var my_id := scene_id
	var lines := [
		["THE COLLECTOR: I only wanted to keep them. I only wanted to keep everyone.", 3.6],
		["NIM: ...You can let go. It's okay.", 2.6],
		["(He puts the coin in the offering bowl. He fades.)", 3.0],
		["THE COLLECTOR: It's so light.", 2.6],
		["THE GOLD KEY IS YOURS. THE OLD TREASURY HAS ITS OWN REWARD.", 3.4]
	]
	for line in lines:
		var seconds := maxf(float(line[1]), Story.reading_time(str(line[0])))
		_banner(str(line[0]), seconds)
		await get_tree().create_timer(seconds).timeout
		if my_id != scene_id:
			return
	has_gold_key = true
	collectible_found.emit("gold_key")
	_open_vault_route()
	region_cleared.emit("greed")

func _create_expanded_content() -> void:
	# Small mobs spread across expanded areas
	var mite_positions := [Vector2(790, 550), Vector2(1110, 550), Vector2(1495, 550), Vector2(1760, 550), Vector2(1550, 405), Vector2(1880, 325), Vector2(-55, 395), Vector2(-415, 295), Vector2(-775, 295), Vector2(-955, 345)]
	for pos in mite_positions:
		var mite := CharacterBody2D.new()
		mite.set_script(GREEDY_MITE)
		mite.position = pos
		var collision := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 16.0
		collision.shape = shape
		mite.add_child(collision)
		add_child(mite)
		if mite.has_signal("dropped_coin"):
			mite.connect("dropped_coin", Callable(self, "_on_mite_dropped"))

	# Mini-boss: Coin Guard deeper in left wing
	if not miniboss_defeated:
		coin_guard = CharacterBody2D.new()
		coin_guard.set_script(COIN_GUARD)
		coin_guard.position = Vector2(-1400, 440)
		var c2 := CollisionShape2D.new()
		var s2 := CapsuleShape2D.new()
		s2.radius = 26.0
		s2.height = 40.0
		c2.shape = s2
		coin_guard.add_child(c2)
		add_child(coin_guard)
		if coin_guard.has_signal("dropped_coins"):
			coin_guard.connect("dropped_coins", Callable(self, "_on_guard_dropped"))
		if coin_guard.has_signal("defeated"):
			coin_guard.connect("defeated", Callable(self, "_on_coin_guard_defeated"))

	# Extra coins in expanded wings
	var extra_coins := [Vector2(1610, 405), Vector2(125, 440), Vector2(-305, 340), Vector2(-665, 240), Vector2(-1025, 340), Vector2(-1205, 390), Vector2(1380, 490)]
	for pos in extra_coins:
		var marker := _make_interactable("GOLD\n[E] TAKE", pos, Color(1.0, 0.9, 0.5))
		interactables.append({"node": marker, "message": "Lumi picks up gold.", "kind": "coin_extra", "used": false, "value": 15, "marker": marker})

func _on_mite_dropped(amount: int) -> void:
	add_gold(amount)

func _on_guard_dropped(amount: int) -> void:
	add_gold(amount)

func _on_coin_guard_defeated() -> void:
	miniboss_defeated = true
	_grant_seal("vault")
	_show_status("COIN GUARD DEFEATED. VAULT MANUAL UNSEALED. SEAL %d/%d" % [seals.size(), SEALS_NEEDED])

func _grant_seal(id: String) -> void:
	if not seals.has(id):
		seals.append(id)

func _hide_seal_marker(id: String) -> void:
	for item in interactables:
		if item["kind"] == "seal" and item.get("seal_id", "") == id:
			item["used"] = true
			item["node"].visible = false
			queue_redraw()

func _open_vault_route() -> void:
	post_boss_open = true
	queue_redraw()
	vault_exit = _make_interactable("VAULT EXIT\n[E] RETURN", VAULT_EXIT_POS, Color(1.0, 0.92, 0.6))
	interactables.append({"node": vault_exit, "message": "A heavy golden door leads back to the Still Pond from the old vault.\n\nReturn to hub?", "kind": "vault_exit", "used": false})
	_show_status("VAULT ROUTE OPEN - EXIT THROUGH THE OLD TREASURY")

func get_respawn_point() -> Vector2:
	return respawn_point
