extends Node2D

var player: CharacterBody2D
var jelly: CharacterBody2D
var stats_label: Label
var prompt_label: Label
var dialogue_panel: ColorRect
var dialogue_label: Label
var dialogue_target: Node2D
var interactables: Array[Dictionary] = []
var dialogue_open := false
var has_wind_ribbon := false
var reached_greed := false

const SIGN_MESSAGES := [
    "Walk! (it's easy, I believe in you)",
    "Jump over the tiny puddle.",
    "Swing your lantern. Hit the little jelly. He is very forgiving.",
    "Healing takes a moment. Be brave, but not silly."
]

func _ready() -> void:
    _create_ground()
    _create_player()
    _create_jelly()
    _create_hud()
    _create_wake_tutorial()
    player.health_changed.connect(_update_hud)
    player.heals_changed.connect(_update_hud)
    player.status_changed.connect(_show_status)
    jelly.defeated.connect(_jelly_defeated)
    _update_hud()

func _process(_delta: float) -> void:
    # Falling below the level sends Lumi safely back to the shore.
    if player.global_position.y > 900.0:
        player.global_position = Vector2(240, 570)
        player.velocity = Vector2.ZERO
        _show_status("THE WATER CATCHES LUMI. BACK TO THE SHORE.")

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

func _draw() -> void:
    # Temporary twilight background, moon, and stars.
    draw_rect(Rect2(-3000, -1000, 8000, 1800), Color(0.08, 0.09, 0.16, 1))
    draw_circle(Vector2(1040, 125), 46, Color(0.77, 0.85, 1.0, 0.13))
    draw_circle(Vector2(1040, 125), 30, Color(0.82, 0.88, 1.0, 0.82))
    for i in range(55):
        var x := fposmod(float(i * 173 + 61), 2600.0) - 500.0
        var y := fposmod(float(i * 97 + 23), 500.0) - 250.0
        draw_circle(Vector2(x, y), 1.2, Color(0.78, 0.86, 1.0, 0.55))
    # Two ground sections leave the first dash gap open.
    draw_rect(Rect2(-3000, 610, 4100, 150), Color(0.12, 0.15, 0.24, 1))
    draw_rect(Rect2(-3000, 610, 4100, 5), Color(0.38, 0.48, 0.62, 1))
    draw_rect(Rect2(1350, 610, 3650, 150), Color(0.12, 0.15, 0.24, 1))
    draw_rect(Rect2(1350, 610, 3650, 5), Color(0.38, 0.48, 0.62, 1))
    # Visible stone posts mark the solid boundaries at both ends of Wake.
    draw_rect(Rect2(35, 475, 40, 135), Color(0.23, 0.27, 0.39, 1))
    draw_rect(Rect2(35, 475, 40, 5), Color(0.56, 0.65, 0.82, 1))
    draw_rect(Rect2(1760, 475, 40, 135), Color(0.23, 0.27, 0.39, 1))
    draw_rect(Rect2(1760, 475, 40, 5), Color(0.56, 0.65, 0.82, 1))
    # A faint glow marks the gap edges.
    draw_line(Vector2(1100, 610), Vector2(1100, 650), Color(0.55, 0.72, 0.92, 0.8), 3.0)
    draw_line(Vector2(1350, 610), Vector2(1350, 650), Color(0.55, 0.72, 0.92, 0.8), 3.0)

func _create_ground() -> void:
    _create_ground_section(Vector2(-950, 650), Vector2(4100, 80), "GroundLeft")
    _create_ground_section(Vector2(3175, 650), Vector2(3650, 80), "GroundRight")
    # Invisible solid walls keep Lumi inside the Wake tutorial area.
    _create_boundary(Vector2(55, 0), "StartBoundary")
    _create_boundary(Vector2(1780, 0), "EndBoundary")

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
    player.add_child(camera)

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

func _create_hud() -> void:
    var hud := CanvasLayer.new()
    add_child(hud)

    var title := Label.new()
    title.position = Vector2(24, 18)
    title.add_theme_font_size_override("font_size", 24)
    title.add_theme_color_override("font_color", Color(0.91, 0.91, 1.0))
    title.text = "WHAT THE WATER KEEPS  •  WAKE"
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

func _create_wake_tutorial() -> void:
    var sign_positions := [Vector2(355, 570), Vector2(465, 570), Vector2(735, 570), Vector2(850, 570)]
    for i in range(SIGN_MESSAGES.size()):
        var sign := _make_marker("SIGN %d\n[E] READ" % (i + 1), sign_positions[i], Color(0.70, 0.78, 0.94))
        interactables.append({"node": sign, "message": SIGN_MESSAGES[i], "kind": "sign", "used": false})

    var ribbon := _make_marker("✧\nWIND RIBBON", Vector2(985, 565), Color(0.57, 0.91, 1.0))
    interactables.append({
        "node": ribbon,
        "message": "Nim flutters warmly inside your lantern.\n\n“Pretend you're a leaf in a breeze.”\n\nWind Ribbon found. Your dash can carry you over the gap ahead.",
        "kind": "ribbon",
        "used": false
    })

    var door := _make_marker("THE DOOR OF\nGREED", Vector2(1540, 565), Color(1.0, 0.81, 0.47))
    interactables.append({
        "node": door,
        "message": "The first golden door waits quietly. Beyond it, something has mistaken holding on for being safe.\n\nWake is complete. (Greed entrance marked for the next step.)",
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
    if kind == "ribbon":
        has_wind_ribbon = true
        item["used"] = true
        target.visible = false
    elif kind == "door":
        reached_greed = true
        item["used"] = true
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
    var ribbon_text := "    WIND RIBBON: FOUND" if has_wind_ribbon else ""
    stats_label.text = "HEARTS: %s    HEALS: %d%s" % [hearts.strip_edges(), player.heals, ribbon_text]

func _show_status(message: String) -> void:
    stats_label.text = message
    await get_tree().create_timer(1.6).timeout
    _update_hud()

func _jelly_defeated() -> void:
    stats_label.text = "THE LITTLE JELLY IS RESTING. (IT WAS VERY FORGIVING.)"
