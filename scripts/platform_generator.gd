extends Node2D

# Procedural platform generation for Wake
class_name PlatformGenerator

var rng: RandomNumberGenerator
var seed_value: int
var platforms: Array[Dictionary] = []
var difficulty: float = 1.0  # Scales with progression

const MIN_GAP := 40.0
const MAX_GAP := 150.0
const PLATFORM_WIDTH_MIN := 80.0
const PLATFORM_WIDTH_MAX := 200.0
const PLATFORM_HEIGHT := 20.0
const PLATFORM_SPACING_Y := 60.0  # Vertical distance between platform rows

func _init(seed: int = 0) -> void:
	rng = RandomNumberGenerator.new()
	seed_value = seed if seed > 0 else randi()
	rng.seed = seed_value

func generate_platforms(start_x: float, end_x: float, start_y: float, end_y: float, required_gadgets: Array[String] = []) -> Array[Dictionary]:
	platforms.clear()

	var current_y := end_y - PLATFORM_SPACING_Y
	var current_x := start_x + 100.0

	while current_y > start_y:
		var platform_width := rng.randf_range(PLATFORM_WIDTH_MIN, PLATFORM_WIDTH_MAX)
		var gap := rng.randf_range(MIN_GAP, MAX_GAP)

		# Ensure player can reach next platform
		gap = clampf(gap, MIN_GAP, MAX_GAP * difficulty)

		var platform: Dictionary = {
			"x": current_x,
			"y": current_y,
			"width": platform_width,
			"height": PLATFORM_HEIGHT,
			"type": "normal"  # Can be "normal", "breakable", "moving", etc.
		}

		# Occasionally add challenging platforms
		if rng.randf() < 0.15 * difficulty:
			var types := ["moving", "narrow"]
			platform["type"] = types[rng.randi() % types.size()]

		platforms.append(platform)

		current_x += gap + platform_width * 0.5
		current_y -= PLATFORM_SPACING_Y

		# Wrap around if needed
		if current_x > end_x - 100.0:
			current_x = start_x + 50.0
			current_y -= PLATFORM_SPACING_Y * 2

	return platforms

func set_difficulty(new_difficulty: float) -> void:
	difficulty = clampf(new_difficulty, 0.5, 2.0)
