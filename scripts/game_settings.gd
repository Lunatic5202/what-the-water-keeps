extends RefCounted
# Player settings, saved to user://settings.cfg.
# Use it from any script with:
#   const Settings := preload("res://scripts/game_settings.gd")
#   if Settings.reduce_shake: ...

const PATH := "user://settings.cfg"

static var reduce_shake := false
static var gentle_mode := false
static var fullscreen := false
static var damage_carry := 0.0

static func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	reduce_shake = bool(cfg.get_value("accessibility", "reduce_shake", false))
	gentle_mode = bool(cfg.get_value("accessibility", "gentle_mode", false))
	fullscreen = bool(cfg.get_value("display", "fullscreen", false))

static func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("accessibility", "reduce_shake", reduce_shake)
	cfg.set_value("accessibility", "gentle_mode", gentle_mode)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.save(PATH)

static func apply() -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)

static func set_option(key: String, value: bool) -> void:
	match key:
		"reduce_shake":
			reduce_shake = value
		"gentle_mode":
			gentle_mode = value
		"fullscreen":
			fullscreen = value
			apply()
	save_settings()

static func get_option(key: String) -> bool:
	match key:
		"reduce_shake":
			return reduce_shake
		"gentle_mode":
			return gentle_mode
		"fullscreen":
			return fullscreen
	return false

# Gentle Mode: 25% less damage. Hearts are whole numbers, so the fraction is
# carried over: every fourth hit is fully absorbed.
static func scaled_damage(amount: int) -> int:
	if not gentle_mode:
		return amount
	damage_carry += amount * 0.75
	var whole := int(damage_carry)
	damage_carry -= whole
	return whole
