extends Node2D
class_name CombatFeedback

const Settings := preload("res://scripts/game_settings.gd")

# This node runs while paused so it can release only the pause it started.
var parent: Node2D
var screenshake_timer := 0.0
var screenshake_intensity := 0.0
var hit_freeze_frames := 0
var owns_tree_pause := false

func _init(camera: Node2D) -> void:
	parent = camera

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if screenshake_timer > 0.0:
		screenshake_timer = maxf(0.0, screenshake_timer - delta)
		if screenshake_timer <= 0.0 and is_instance_valid(parent) and parent is Camera2D:
			(parent as Camera2D).offset = Vector2.ZERO

	if hit_freeze_frames > 0:
		hit_freeze_frames -= 1
		if hit_freeze_frames <= 0 and owns_tree_pause:
			get_tree().paused = false
			owns_tree_pause = false

func apply_hit_freeze(frames: int = 4) -> void:
	if frames <= 0:
		return
	hit_freeze_frames = maxi(hit_freeze_frames, frames)
	if not get_tree().paused:
		owns_tree_pause = true
		get_tree().paused = true

func screenshake(intensity: float = 1.0, duration: float = 0.1) -> void:
	if Settings.reduce_shake:
		return
	screenshake_intensity = maxf(0.0, intensity)
	screenshake_timer = maxf(0.0, duration)
	_do_screenshake()

func _do_screenshake() -> void:
	if screenshake_timer <= 0.0 or not is_instance_valid(parent) or not parent is Camera2D:
		return
	var camera := parent as Camera2D
	camera.offset = Vector2(
		randi_range(-int(screenshake_intensity * 2.0), int(screenshake_intensity * 2.0)),
		randi_range(-int(screenshake_intensity), int(screenshake_intensity))
	)
