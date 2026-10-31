extends RefCounted
# Story beats from docs/game-bible.md, kept in one place. Each beat is a list
# of [text, seconds]. Use Story.play() to show one in a scene's dialogue box.
# Only text that is in the bible goes here. Do not invent lore.
# The Reflection is never named or explained here. Players should find out
# about it slowly, so Nim and the narration never point at the pond.

const ARRIVAL := [
	["(Lumi wakes beside the pond. A tiny glow flutters out of the lantern.)", 3.2],
	["NIM: Oh! You're awake. Hello. I'm Nim. I live in your lantern. I think. I've been in it a very long time.", 4.6],
	["NIM: Do you remember anything? No? ...That's okay. Neither do I. Isn't that funny?", 4.0],
	["NIM: See the Gate? Seven keyholes. I think we need seven keys. And there are seven doors. I think the doors are the way.", 5.2],
	["NIM: Let's start small. Come on, I'll teach you to move.", 3.4]
]

const GREED_ENTER := [
	["NIM: It's so pretty! Careful. Things that shine are usually watching.", 4.0]
]
const GREED_SHRINE := [
	["NIM: A little bowl. It says \"give what you carry.\" Odd. I thought we were supposed to collect things.", 5.0]
]
const GREED_WEIGHT := [
	["NIM: You're slower. It's the coins. Maybe... put some down?", 3.6]
]

const AFTER_GREED := [
	["NIM: He wasn't a monster, was he. He was just... holding on.", 3.8],
	["(The first door glows green-white. The second door opens: SLOTH. The hub's music loses a note.)", 4.4]
]

const AFTER_SLOTH := [
	["NIM: She wasn't lazy. She was drowning. Quietly.", 3.4],
	["(Lumi stands still by the pond. Nim hovers.)", 3.0],
	["NIM: Funny. In there, standing still was dangerous. Here, it feels like the only thing I can do.", 4.8],
	["(The third door opens: GLUTTONY.)", 3.0]
]

const AFTER_GLUTTONY := [
	["NIM: He kept feeding everyone so no one would leave. That's a kind of love, isn't it?", 4.2],
	["(The fourth door opens: ENVY.)", 3.0]
]

# Nim's post gives a gentle hint for wherever the player is in the game.
# These are gameplay hints (the lessons each region teaches), not new lore.
const NIM_HINTS := {
	0: "Nim: The first door is Greed. Golden things shine. Some of them want you to carry them. Maybe put some down?",
	1: "Nim: The second door is Slumber Hollow. Keep moving, and light the lanterns. Standing still is how it gets you.",
	2: "Nim: Two keys. The other doors are asleep. I think they wake when the ones before them are done."
}

static func after(region: String) -> Array:
	match region:
		"greed":
			return AFTER_GREED
		"sloth":
			return AFTER_SLOTH
		"gluttony":
			return AFTER_GLUTTONY
	return []

static func hint(cleared: int) -> String:
	return NIM_HINTS.get(mini(cleared, 2), "")

# Estimate reading time from the visible text. Existing authored durations are
# minimums, not hard limits, so longer lines never vanish before they can be read.
# Lumi's dialogue portrait. Uses the imported texture when Godot has one, and
# falls back to reading the PNG straight from disk so a missing or stale import
# never leaves the dialogue box with an empty portrait slot.
static var _portrait_cache := {}
static func portrait(expression: String) -> Texture2D:
	if _portrait_cache.has(expression):
		return _portrait_cache[expression]
	var path := "res://assets/portraits/lumi/lumi_%s.png" % expression
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	if tex == null:
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img != null and not img.is_empty():
			tex = ImageTexture.create_from_image(img)
	if tex != null:
		_portrait_cache[expression] = tex
	return tex

static func reading_time(text: String) -> float:
	return maxf(2.8, 1.2 + float(text.length()) / 17.0)

# Shows lines one after another in a scene's dialogue box. Playing a new beat
# cancels the old one. While a beat plays the scene has meta "story_busy".
static func play(scene: Node, panel: Control, label: Label, lines: Array) -> void:
	var token := int(scene.get_meta("story_token", 0)) + 1
	scene.set_meta("story_token", token)
	scene.set_meta("story_busy", true)
	for line in lines:
		label.text = line[0]
		panel.visible = true
		var seconds := maxf(float(line[1]), reading_time(str(line[0])))
		await scene.get_tree().create_timer(seconds).timeout
		if not is_instance_valid(scene) or int(scene.get_meta("story_token", 0)) != token:
			return
	panel.visible = false
	scene.set_meta("story_busy", false)
