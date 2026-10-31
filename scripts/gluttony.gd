extends "res://scripts/sloth.gd"
# The Endless Table (Gluttony): region 3. See docs/game-bible.md, Region 3.
# Built on the Slumber Hollow scene (HUD, dialogue box, benches, seals, saving)
# with its own level, mechanic and boss.
# Mechanic: Fullness. Eating heals but fills the bar; at 100 Lumi is Stuffed for
# 20s (no dash, slower swings, healing halved). Moving burns it off. Eating when
# hurt (3 hearts or fewer) is mindful: bigger heal, no Fullness.
# Branches: the Pantry Loft (high) and the Syrup Cellar (low, Cutlery Knight)
# each give a seal. Two seals open the Host's fog.

const CRUMB := preload("res://scripts/crumb_swarm.gd")
const GULPER := preload("res://scripts/jelly_gulper.gd")
const SPRITE := preload("res://scripts/cutlery_sprite.gd")
const KNIGHT := preload("res://scripts/cutlery_knight.gd")
const HOST := preload("res://scripts/host.gd")
const PIE := preload("res://scripts/pie_platform.gd")

const LOCK_X := 3700.0
const END_X := 4900.0
const STUFFED_SECONDS := 20.0
const MINDFUL_HEALTH := 3

# Solid platforms: Rect2(left, top, width, height). Steps up are 55px or less,
# gaps are 60px or more, same rules as the other regions.
const TABLE_GROUND := [
	Rect2(-100, 600, 1100, 120),     # start table
	Rect2(1120, 600, 980, 120),
	Rect2(2220, 600, 480, 120),      # rim of the Syrup Cellar
	Rect2(2700, 760, 620, 80),       # cellar floor
	Rect2(3380, 600, 120, 120),
	Rect2(3600, 600, 1330, 120),     # the long table (arena)
]
const TABLE_PIES := [
	Rect2(420, 545, 110, 20), Rect2(1160, 545, 110, 20), Rect2(2560, 545, 110, 20),
	Rect2(3080, 705, 90, 18), Rect2(3230, 650, 90, 18),                 # cellar climb out
	# Pantry Loft: a stair up from the second table to a shelf.
	Rect2(1300, 545, 100, 18), Rect2(1470, 490, 100, 18), Rect2(1640, 435, 100, 18),
	Rect2(1810, 380, 100, 18), Rect2(1980, 325, 100, 18), Rect2(2150, 270, 100, 18),
	Rect2(2320, 270, 440, 24),
]
const TABLE_SPAWNS := [
	{"type": "crumb", "pos": Vector2(700, 470)},
	{"type": "gulper", "pos": Vector2(880, 570), "patrol": 90.0},
	{"type": "sprite", "pos": Vector2(1260, 420)},
	{"type": "crumb", "pos": Vector2(1750, 450)},
	{"type": "gulper", "pos": Vector2(1900, 570), "patrol": 100.0},
	{"type": "sprite", "pos": Vector2(2480, 420)},
	{"type": "crumb", "pos": Vector2(2900, 640)},
	{"type": "gulper", "pos": Vector2(3050, 730), "patrol": 80.0},
	{"type": "sprite", "pos": Vector2(3440, 470)},
	{"type": "crumb", "pos": Vector2(2000, 220)},
]
const FOODS := [
	Vector2(560, 575), Vector2(1215, 520), Vector2(2380, 575), Vector2(2640, 245),
	Vector2(3010, 735), Vector2(3440, 575),
]
const TABLETS := [
	[Vector2(330, 560), "It was never about the food."],
	[Vector2(1240, 560), "Every plate filled a little of the quiet."],
	[Vector2(2300, 560), "I kept saying one more. I kept saying it kindly."],
	[Vector2(1900, 560), "I ate until the feeling went away. Then I ate because the feeling was coming back."],
	[Vector2(3790, 560), "A table set for many is the loudest kind of quiet."],
]
const GLUT_BENCHES := [Vector2(220, 560), Vector2(2500, 560), Vector2(3440, 560)]

var fullness := 0.0
var stuffed_time := 0.0
var warned_full := false
var intro_done := false
var host: CharacterBody2D = null
var knight: CharacterBody2D = null
var knight_defeated := false
var has_spoon := false
var has_scarf := false
var has_honey_key := false
var pies: Array[Node] = []
var table_exit: Node2D = null
var pantry_seal_hint := false

func _ready() -> void:
	add_to_group("fullness_holder")
	super._ready()
	remove_from_group("drowse_holder")
	if is_instance_valid(dialogue_location_label):
		dialogue_location_label.text = "THE ENDLESS TABLE"
	for node in hud_layer.get_children():
		if node is Label:
			if node.text.contains("SLUMBER HOLLOW"):
				node.text = "WHAT THE WATER KEEPS  •  THE ENDLESS TABLE"
			elif node.text == "DROWSE":
				node.text = "FULLNESS"

# --- Building -----------------------------------------------------------------

func _create_ground() -> void:
	for rect: Rect2 in TABLE_GROUND:
		_solid(rect)
	for rect: Rect2 in TABLE_PIES:
		_solid(rect)
	_solid(Rect2(10, -400, 40, 1400))
	_solid(Rect2(END_X, -400, 40, 1400))

func _create_level() -> void:
	for i in range(TABLETS.size()):
		var tablet := _make_interactable("TABLET %d\n[E] READ" % (i + 1), TABLETS[i][0], Color(1.0, 0.94, 0.88))
		interactables.append({"node": tablet, "message": TABLETS[i][1], "kind": "lore", "used": false})
	for pos: Vector2 in GLUT_BENCHES:
		var bench := _make_interactable("CHAIR\n[E] REST", pos, Color(0.85, 0.95, 0.9))
		interactables.append({"node": bench, "message": "", "kind": "bench", "used": false})
	for pos: Vector2 in FOODS:
		var food := _make_interactable("", pos, Color(1, 0.9, 0.8))
		interactables.append({"node": food, "message": "", "kind": "food", "used": false, "pos": pos})
	var exit := _make_interactable("EXIT TO HUB\n[E] RETURN", Vector2(80, 560), Color(0.8, 0.88, 1.0))
	interactables.append({"node": exit, "message": "Return to The Still Pond?", "kind": "exit", "used": false})
	var boss_area := _make_interactable("THE HOST\n[E] APPROACH", Vector2(3640, 560), Color(1.0, 0.85, 0.9))
	boss_item = {"node": boss_area, "message": "A long table, set for a feast that has never ended.", "kind": "host", "used": false}
	interactables.append(boss_item)
	var seal := _make_interactable("SEAL\n[E] TAKE", Vector2(2420, 242), Color(1.0, 0.85, 0.9))
	interactables.append({"node": seal, "message": "A sugared seal, still warm.", "kind": "seal", "seal_id": "pantry", "used": false})
	_create_host()

func _create_sloth_expanded() -> void:
	# Called deferred by the base scene: the cellar mini-boss lives here.
	if not knight_defeated:
		knight = CharacterBody2D.new()
		knight.set_script(KNIGHT)
		knight.position = Vector2(3000, 725)
		knight.set("left_x", 2780.0)
		knight.set("right_x", 3240.0)
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = Vector2(40, 90)
		shape.shape = box
		knight.add_child(shape)
		add_child(knight)
		knight.connect("defeated", Callable(self, "_on_knight_defeated"))

func _create_host() -> void:
	host = CharacterBody2D.new()
	host.name = "TheHost"
	host.set_script(HOST)
	host.collision_layer = 2
	host.collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 100.0
	shape.shape = circle
	host.add_child(shape)
	add_child(host)
	host.set("arena_left", LOCK_X + 50.0)
	host.set("arena_right", END_X - 50.0)
	host.set("floor_y", 600.0)
	host.defeated.connect(_on_host_defeated)
	host.phase_changed.connect(_on_host_phase)
	host.line.connect(func(text: String) -> void: _banner(text, 2.6))
	dreamer = host   # the base scene resets "dreamer" on death; keeps it harmless

func _spawn_enemies() -> void:
	for node in enemies:
		if is_instance_valid(node):
			node.queue_free()
	enemies.clear()
	if not fight_active:
		for t in get_tree().get_nodes_in_group("enemy_projectile"):
			if is_ancestor_of(t):
				t.queue_free()
	for spawn in TABLE_SPAWNS:
		var enemy := CharacterBody2D.new()
		enemy.position = spawn["pos"]
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		match spawn["type"]:
			"crumb":
				enemy.set_script(CRUMB)
				circle.radius = 18.0
				enemy.collision_layer = 2
				enemy.collision_mask = 0
			"gulper":
				enemy.set_script(GULPER)
				circle.radius = 22.0
				enemy.set("patrol", spawn["patrol"])
			"sprite":
				enemy.set_script(SPRITE)
				circle.radius = 14.0
				enemy.collision_layer = 2
				enemy.collision_mask = 0
		shape.shape = circle
		enemy.add_child(shape)
		add_child(enemy)
		enemies.append(enemy)

# --- Fullness -----------------------------------------------------------------

func add_fullness(amount: float) -> void:
	if not is_instance_valid(player) or player.get_parent() != self:
		return
	fullness = clampf(fullness + amount * RunState.debuff_scale(), 0.0, 100.0)

func _update_drowse(delta: float) -> void:
	var busy := dialogue_open or banner_time > 0.0
	if not busy and player.velocity.length() > 20.0 and stuffed_time <= 0.0:
		fullness = maxf(0.0, fullness - 1.0 * delta)   # moving works it off
	if stuffed_time > 0.0:
		stuffed_time -= delta
		fullness = maxf(0.0, fullness - 3.0 * delta)
		if stuffed_time <= 0.0:
			fullness = 50.0
			_show_status("THE WEIGHT EASES.")
	elif fullness >= 100.0:
		stuffed_time = STUFFED_SECONDS * RunState.debuff_scale()
		_show_status("STUFFED: There was still room. There was never room.")
	elif fullness >= 75.0 and not warned_full:
		warned_full = true
		_banner("NIM: You look... heavy. Maybe stop? One more won't hurt. Then maybe one more... Oh no. I'm doing it too.", 4.2)
	if fullness < 50.0:
		warned_full = false
	var stuffed := stuffed_time > 0.0
	player.set("dash_blocked", stuffed)
	player.set("attack_speed_mod", 0.75 if stuffed else 1.0)
	player.set("heal_amount_mod", 0.5 if stuffed else 1.0)
	player.set("move_speed_mod", 0.88 if stuffed else 1.0)
	drowse_fill.size.x = 200.0 * fullness / 100.0
	drowse_fill.color = Color(0.74, 0.92, 0.83).lerp(Color(0.96, 0.45, 0.62), fullness / 100.0)

func add_drowse(_amount: float) -> void:
	pass

func _update_overlay() -> void:
	overlay.color.a = 0.0

func _clear_player_debuffs() -> void:
	super._clear_player_debuffs()
	player.set("dash_blocked", false)
	player.set("attack_speed_mod", 1.0)
	player.set("heal_amount_mod", 1.0)

func _update_hud(_value: int = 0) -> void:
	if not is_instance_valid(player) or not is_instance_valid(stats_label):
		return
	var parts: Array[String] = []
	if stuffed_time > 0.0:
		parts.append("STUFFED: NO DASH, SLOW SWINGS, HALF HEALING")
	if int(player.health) <= MINDFUL_HEALTH:
		parts.append("HURT: EATING NOW IS MINDFUL")
	if has_scarf:
		parts.append("HUNGRY WIND SCARF")
	stats_label.text = "    ".join(parts)

# --- Interaction --------------------------------------------------------------

func _interact(item: Dictionary) -> void:
	var kind: String = item["kind"]
	var target: Node2D = item["node"]
	match kind:
		"food":
			_eat(item)
		"host":
			if boss_defeated:
				_show_dialogue("An empty chair at the head of the table. One spoon, laid down.", target)
			elif seals.size() < SEALS_NEEDED:
				_show_dialogue("The long table is shut behind warm, sugary fog.\n\nSEALS %d/%d. Two seals are kept away from the main table: one high in the pantry, one low in the cellar." % [seals.size(), SEALS_NEEDED], target)
			else:
				_start_fight()
		"table_exit":
			get_tree().call_group("game_main", "_return_to_hub", true)
		_:
			super._interact(item)

func _eat(item: Dictionary) -> void:
	item["used"] = true
	item["node"].visible = false
	var mindful: bool = int(player.health) <= MINDFUL_HEALTH
	var heal := 2 if mindful else 1
	if stuffed_time > 0.0:
		heal = 0
	player.health = mini(player.max_health, player.health + heal)
	player.health_changed.emit(player.health)
	if mindful:
		_show_status("A MINDFUL BITE. +%d HEARTS." % heal)
	else:
		add_fullness(25.0)
		_show_status("ONE MORE BITE. +%d HEART, FULLER." % heal if heal > 0 else "TOO FULL TO TASTE IT.")
	queue_redraw()

func _rest(at: Vector2) -> void:
	fullness = 0.0
	stuffed_time = 0.0
	for item in interactables:
		if item["kind"] == "food":
			item["used"] = false
			item["node"].visible = true
	super._rest(at)
	get_tree().call_group("game_main", "save_game", "gluttony", respawn_point)

func _on_player_died() -> void:
	if player.get_parent() != self:
		return
	fullness = 0.0
	stuffed_time = 0.0
	if fight_active:
		_reset_fight()
	_spawn_enemies()

# --- Cellar mini-boss and seals ----------------------------------------------

func _on_knight_defeated() -> void:
	knight_defeated = true
	var at := knight.global_position if is_instance_valid(knight) else Vector2(3000, 725)
	_drop_seal("cellar", at + Vector2(0, -20))
	_show_status("CUTLERY KNIGHT DEFEATED. A SEAL DROPPED.")

func _drop_seal(id: String, at: Vector2) -> void:
	if seals.has(id):
		return
	var marker := _make_interactable("SEAL\n[E] TAKE", at, Color(1.0, 0.85, 0.9))
	interactables.append({"node": marker, "message": "A sugared seal, still warm.", "kind": "seal", "seal_id": id, "used": false})
	queue_redraw()

# --- Boss fight ---------------------------------------------------------------

func _start_fight() -> void:
	if fight_active or boss_defeated or not is_instance_valid(host):
		return
	fight_active = true
	lock_wall = _solid(Rect2(LOCK_X - 20, -400, 40, 1400))
	scene_id += 1
	var my_id := scene_id
	var lines := [
		["THE HOST: Welcome, welcome! Sit! You must be hungry. Nobody ever leaves my table hungry.", 4.0],
		["THE HOST: I've kept the feast going for a very long time. As long as there's food, nobody is lonely.", 4.6],
		["NIM: Are you lonely?", 2.0],
		["THE HOST: ...Eat something, dear.", 2.6]
	]
	for line in lines:
		var seconds := maxf(float(line[1]), Story.reading_time(str(line[0])))
		_banner(str(line[0]), seconds)
		await get_tree().create_timer(seconds).timeout
		if my_id != scene_id:
			return
	host.call("start_fight")

func _update_fight() -> void:
	if not fight_active:
		return
	if player.global_position.x < LOCK_X - 60.0:
		_reset_fight()

func _reset_fight() -> void:
	scene_id += 1
	fight_active = false
	banner_time = 0.0
	dialogue_panel.visible = false
	if is_instance_valid(lock_wall):
		lock_wall.queue_free()
	for pie in pies:
		if is_instance_valid(pie):
			pie.queue_free()
	pies.clear()
	if is_instance_valid(host):
		host.call("reset")
	queue_redraw()

func _on_host_phase(phase: int) -> void:
	if phase == 2:
		_banner("THE HOST: Have the main course! There's always room!", 3.0)
		for x in [3950.0, 4350.0, 4700.0]:
			var pie := AnimatableBody2D.new()
			pie.set_script(PIE)
			pie.position = Vector2(x, 500.0 if x != 4350.0 else 440.0)
			var shape := CollisionShape2D.new()
			var box := RectangleShape2D.new()
			box.size = Vector2(140, 18)
			shape.shape = box
			pie.add_child(shape)
			add_child(pie)
			pies.append(pie)
	elif phase == 3:
		_banner("THE HOST: Please, don't leave. If the plates are empty, I'll have to hear the silence.", 3.6)

func _on_host_defeated() -> void:
	boss_defeated = true
	fight_active = false
	boss_item["used"] = true
	boss_item["node"].visible = false
	if is_instance_valid(lock_wall):
		lock_wall.queue_free()
	scene_id += 1
	var my_id := scene_id
	var lines := [
		["(The Host deflates to a small cat with a single spoon.)", 3.0],
		["THE HOST: I'm so full. Why am I still so empty?", 3.2],
		["NIM: Sometimes you're not hungry. You're just... sad.", 3.2],
		["THE HOLLOW SPOON (DEVOUR STYLE), THE HUNGRY WIND SCARF AND THE HONEY KEY ARE YOURS.", 3.8]
	]
	for line in lines:
		var seconds := maxf(float(line[1]), Story.reading_time(str(line[0])))
		_banner(str(line[0]), seconds)
		await get_tree().create_timer(seconds).timeout
		if my_id != scene_id:
			return
	_grant_rewards()
	_open_table_exit()
	region_cleared.emit("gluttony")

func _grant_rewards() -> void:
	has_spoon = true
	has_honey_key = true
	has_scarf = true
	player.call("unlock_style", "devour")
	player.set("can_super_dash", true)
	_show_status("HUNGRY WIND SCARF: YOUR DASH GOES FURTHER. TAB SWAPS TO DEVOUR STYLE.")

func _open_table_exit() -> void:
	table_exit = _make_interactable("TABLE EXIT\n[E] RETURN", Vector2(2680, 245), Color(0.9, 1.0, 0.92))
	interactables.append({"node": table_exit, "message": "", "kind": "table_exit", "used": false})
	_show_status("THE WAY OUT IS ALONG THE PANTRY SHELF.")

# --- Saving -------------------------------------------------------------------

func save_state() -> Dictionary:
	return {
		"boss_defeated": boss_defeated,
		"has_spoon": has_spoon,
		"has_scarf": has_scarf,
		"has_honey_key": has_honey_key,
		"knight_defeated": knight_defeated,
		"seals": seals.duplicate()
	}

func apply_save(d: Dictionary) -> void:
	has_spoon = bool(d.get("has_spoon", false))
	if has_spoon and is_instance_valid(player) and not player.unlocked_styles.has("devour"):
		player.unlocked_styles.append("devour")
	has_scarf = bool(d.get("has_scarf", false))
	has_honey_key = bool(d.get("has_honey_key", false))
	for id in d.get("seals", []):
		_grant_seal(str(id))
		_hide_seal_marker(str(id))
	if bool(d.get("knight_defeated", false)):
		knight_defeated = true
		_grant_seal("cellar")
		if is_instance_valid(knight):
			knight.queue_free()
	if bool(d.get("boss_defeated", false)):
		boss_defeated = true
		boss_item["used"] = true
		boss_item["node"].visible = false
		if is_instance_valid(host):
			host.queue_free()
		_open_table_exit()
	_update_hud()

# --- Drawing ------------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(-3000, -2000, 11000, 4000), Color.html("#FFF0E0"))
	# Cake-hill backdrop and jelly chandeliers.
	for i in range(14):
		var x := -300.0 + i * 420.0
		var h := 130.0 + sin(i * 1.9) * 50.0
		var dome := PackedVector2Array()
		for k in range(25):
			var ang := PI + PI * float(k) / 24.0
			dome.append(Vector2(x + cos(ang) * h, 600.0 + sin(ang) * h))
		draw_colored_polygon(dome, Color.html("#F6A6C1") if i % 2 == 0 else Color.html("#BDEBD3"))
		draw_arc(Vector2(x, 600.0), h, PI, TAU, 24, Color(0.42, 0.25, 0.2, 0.5), 3.0)
	for i in range(10):
		var cx := 100.0 + i * 520.0
		draw_line(Vector2(cx, -200), Vector2(cx, 60), Color(0.42, 0.25, 0.2, 0.6), 3.0)
		draw_circle(Vector2(cx, 80), 28.0, Color(1.0, 0.8, 0.5, 0.6))
		draw_circle(Vector2(cx, 80), 14.0, Color(1.0, 0.95, 0.75, 0.9))
	var choc := Color.html("#6B4034")
	var icing := Color.html("#F6A6C1")
	for rect: Rect2 in TABLE_GROUND + TABLE_PIES:
		draw_rect(rect, choc)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 6)), icing)
		draw_rect(rect, Color(0.25, 0.14, 0.12), false, 2.0)
	if fight_active:
		draw_rect(Rect2(LOCK_X - 20, 100, 40, 520), Color(1.0, 0.8, 0.9, 0.35))
	for item in interactables:
		if item.get("used", false) or not is_instance_valid(item["node"]):
			continue
		var c: Vector2 = item["node"].position
		if item["kind"] == "food":
			draw_circle(c + Vector2(0, 4), 16.0, Color(0.42, 0.25, 0.2))
			draw_circle(c + Vector2(0, 2), 14.0, Color(0.98, 0.78, 0.5))
			draw_circle(c + Vector2(0, -8), 7.0, Color(0.92, 0.3, 0.38))
			draw_circle(c + Vector2(-3, -10), 2.0, Color(1, 1, 1, 0.8))
		elif item["kind"] == "seal":
			draw_circle(c, 24.0, Color(1.0, 0.8, 0.9, 0.3))
			draw_circle(c, 17.0, Color(0.42, 0.25, 0.2))
			draw_circle(c, 14.0, Color(0.96, 0.55, 0.7))
			draw_circle(c, 8.0, Color(1.0, 0.92, 0.95))
			draw_circle(c + Vector2(-4, -4), 2.5, Color(1, 1, 1))
	if is_instance_valid(table_exit):
		var d := table_exit.position
		draw_rect(Rect2(d.x - 30, d.y - 70, 60, 90), choc)
		draw_rect(Rect2(d.x - 30, d.y - 70, 60, 90), icing, false, 3.0)
		draw_circle(d + Vector2(0, -40), 12.0, Color(1.0, 0.94, 0.7))
