extends Node2D

# Combat impact and feedback system
class_name CombatFeedback

var screenshake_timer := 0.0
var screenshake_intensity := 0.0
var hit_freeze_frames := 0
var parent: Node2D

func _init(p: Node2D) -> void:
	parent = p

func _process(delta: float) -> void:
	if screenshake_timer > 0.0:
		screenshake_timer -= delta
		if screenshake_timer <= 0.0:
			parent.offset = Vector2.ZERO

	if hit_freeze_frames > 0:
		hit_freeze_frames -= 1
		get_tree().paused = true
	elif get_tree().paused:
		get_tree().paused = false

func apply_hit_freeze(frames: int = 4) -> void:
	# 4 frames at 60fps = 0.066s freeze
	hit_freeze_frames = frames

func screenshake(intensity: float = 1.0, duration: float = 0.1) -> void:
	screenshake_intensity = intensity
	screenshake_timer = duration
	_do_screenshake()

func _do_screenshake() -> void:
	if screenshake_timer > 0.0:
		var offset := Vector2(
			randi_range(-int(screenshake_intensity * 2), int(screenshake_intensity * 2)),
			randi_range(-int(screenshake_intensity), int(screenshake_intensity))
		)
		parent.offset = offset
