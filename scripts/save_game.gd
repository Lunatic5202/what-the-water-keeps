extends RefCounted
# Bench saves, stored as JSON in user://save.json. Only resting at a bench or
# hammock writes it. Use: SaveGame.has_save(), SaveGame.write(dict),
# SaveGame.read(), SaveGame.erase().

const VERSION := 1

static var path := "user://save.json"  # tests point this somewhere else

static func has_save() -> bool:
	return not read().is_empty()

static func write(data: Dictionary) -> bool:
	data["version"] = VERSION
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true

# Returns {} if there is no save, it cannot be parsed or it is from another version.
static func read() -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var data: Dictionary = parsed
	if int(data.get("version", 0)) != VERSION:
		return {}
	return data

static func erase() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
