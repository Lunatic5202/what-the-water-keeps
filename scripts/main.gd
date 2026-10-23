extends Node2D

var player: CharacterBody2D
var jelly: CharacterBody2D
var stats_label: Label

func _ready() -> void:
    _create_ground()
    _create_player()
    _create_jelly()
    _create_hud()
    player.health_changed.connect(_update_hud)
    player.heals_changed.connect(_update_hud)
    player.status_changed.connect(_show_status)
    jelly.defeated.connect(_jelly_defeated)
    _update_hud()

func _draw() -> void:
    # Temporary twilight background, moon, and stars.
    draw_rect(Rect2(-3000, -1000, 8000, 1800), Color(0.08, 0.09, 0.16, 1))
    draw_circle(Vector2(1040, 125), 46, Color(0.77, 0.85, 1.0, 0.13))
    draw_circle(Vector2(1040, 125), 30, Color(0.82, 0.88, 1.0, 0.82))
    for i in range(55):
        var x := fposmod(float(i * 173 + 61), 2600.0) - 500.0
        var y := fposmod(float(i * 97 + 23), 500.0) - 250.0
        draw_circle(Vector2(x, y), 1.2, Color(0.78, 0.86, 1.0, 0.55))
    draw_rect(Rect2(-3000, 610, 8000, 150), Color(0.12, 0.15, 0.24, 1))
    draw_rect(Rect2(-3000, 610, 8000, 5), Color(0.38, 0.48, 0.62, 1))

func _create_ground() -> void:
    var ground := StaticBody2D.new()
    ground.name = "Ground"
    ground.position = Vector2(640, 650)
    var collision := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(8000, 80)
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
    title.text = "WHAT THE WATER KEEPS"
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
    help.text = "A/D move   SPACE jump   J lantern swing   LEFT SHIFT dash   Q heal"
    hud.add_child(help)

func _update_hud(_value: int = 0) -> void:
    if not is_instance_valid(player) or not is_instance_valid(stats_label):
        return
    var hearts := ""
    for i in range(player.max_health):
        hearts += "♥ " if i < player.health else "♡ "
    stats_label.text = "HEARTS: %s    HEALS: %d" % [hearts.strip_edges(), player.heals]

func _show_status(message: String) -> void:
    stats_label.text = message
    await get_tree().create_timer(1.6).timeout
    _update_hud()

func _jelly_defeated() -> void:
    stats_label.text = "THE LITTLE JELLY IS RESTING. (IT WAS VERY FORGIVING.)"
