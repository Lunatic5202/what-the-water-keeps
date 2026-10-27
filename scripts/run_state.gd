extends RefCounted
# Settings for the current run: difficulty and the secret no-hit mode.
# Use it from any script with:
#   const RunState := preload("res://scripts/run_state.gd")
# The Gentle Mode accessibility toggle (game_settings.gd) always wins and acts
# as the Gentle difficulty.

const Settings := preload("res://scripts/game_settings.gd")

const LEVELS := ["gentle", "normal", "hard"]

static var difficulty := "normal"
static var no_hit := false          # secret challenge: any damage ends the run
static var damage_carry := 0.0

static func level() -> String:
	if no_hit:
		return "normal"
	return "gentle" if Settings.gentle_mode else difficulty

static func label() -> String:
	if no_hit:
		return "NO-HIT"
	return level().to_upper()

# Damage Lumi takes. Hearts are whole numbers, so the fraction is carried over
# (gentle: every fourth hit is absorbed, hard: every second hit hurts double).
static func damage(amount: int) -> int:
	var factor := 1.0
	match level():
		"gentle":
			factor = 0.75
		"hard":
			factor = 1.5
	if factor == 1.0:
		return amount
	damage_carry += amount * factor
	var whole := int(damage_carry)
	damage_carry -= whole
	return whole

# How fast debuffs build and how hard they bite.
static func debuff_scale() -> float:
	match level():
		"gentle":
			return 0.5
		"hard":
			return 1.4
	return 1.0

static func max_heals() -> int:
	match level():
		"gentle":
			return 4
		"hard":
			return 2
	return 3

# Seconds Lumi sleeps when Drowse fills.
static func sleep_seconds() -> float:
	match level():
		"gentle":
			return 3.0
		"hard":
			return 5.0
	return 4.0

static func start_run(chosen: String, challenge := false) -> void:
	difficulty = chosen if LEVELS.has(chosen) else "normal"
	no_hit = challenge
	damage_carry = 0.0
