extends Node

## File Helper for Render Lens
## Handles .render_lens/captures/ directory and file writing

const CAPTURES_DIR := "res://.render_lens/captures"
# res:// is read-only in exported, remote and Android runs.
const FALLBACK_DIR := "user://.render_lens/captures"
const KEEP_NEWEST := 200
const CLEANUP_EVERY := 20
const MAX_COMPARE_BYTES := 64 * 1024 * 1024

static var _dir := ""
static var _writes := 0

static func ensure_captures_dir(refused: Dictionary = {}) -> String:
	"""Return a writable captures directory (res:// first, then user://), or "" if neither works"""
	# Rewriting the small marker proves the cached folder is still writable (it may have become read-only).
	if _dir != "" and DirAccess.dir_exists_absolute(_dir) and _write_marker(_dir + "/.gitignore", "*\n"):
		return _dir
	_dir = ""
	for dir in [CAPTURES_DIR, FALLBACK_DIR]:
		if refused.has(dir):
			continue
		if not DirAccess.dir_exists_absolute(dir) and DirAccess.make_dir_recursive_absolute(dir) != OK:
			continue
		# The markers keep Godot from importing the captures and git from tracking them; writing them also proves the folder is writable.
		if _write_marker(dir + "/.gdignore", "") and _write_marker(dir + "/.gitignore", "*\n"):
			_dir = dir
			return dir
	return ""

static func _write_marker(path: String, text: String) -> bool:
	# Rewritten even when present: an existing marker does not prove the folder is still writable.
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return false
	file.store_string(text)
	file.close()
	return true

static func is_capture_path(path: String) -> bool:
	"""True when the path, after simplification, lies inside a captures folder"""
	var clean := path.simplify_path()
	return clean.begins_with(CAPTURES_DIR + "/") or clean.begins_with(FALLBACK_DIR + "/")

static func _unique_name(prefix: String, extension: String) -> String:
	var timestamp := Time.get_datetime_string_from_system().replace(":", "-")
	return "%s_%s_%d_%d.%s" % [prefix, timestamp, OS.get_process_id(), Time.get_ticks_usec(), extension]

static func _note_write(dir: String) -> void:
	if _writes % CLEANUP_EVERY == 0:
		cleanup_old_captures(dir)
	_writes += 1

static func write_json(data: Dictionary, prefix: String) -> String:
	"""Write JSON file, return path"""
	return _write(prefix, "json", JSON.stringify(data, "\t").to_utf8_buffer())

static func write_png(image: Image, prefix: String) -> String:
	"""Write PNG file, return path"""
	# Encoded in memory, so a refused file prints no engine error and the next folder is tried.
	return _write(prefix, "png", image.save_png_to_buffer())

static func _write(prefix: String, extension: String, bytes: PackedByteArray) -> String:
	var refused := {}  # for this capture only: the next one tries the project folder again
	while true:
		var dir := ensure_captures_dir(refused)
		if dir.is_empty():
			push_error("No writable captures directory")
			return ""
		var path := "%s/%s" % [dir, _unique_name(prefix, extension)]
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file:
			file.store_buffer(bytes)
			file.close()
			_note_write(dir)
			return path
		refused[dir] = true  # writable markers do not prove the folder accepts new files
		_dir = ""
	return ""

static func cleanup_old_captures(dir_path: String = CAPTURES_DIR, keep: int = KEEP_NEWEST) -> void:
	"""Delete all but the newest `keep` capture files (count, not age: a baseline may be days old)"""
	var dir := DirAccess.open(dir_path)
	if not dir:
		return

	var files: Array = []
	dir.list_dir_begin()
	var filename := dir.get_next()
	while filename != "":
		if not dir.current_is_dir() and not filename.begins_with("."):
			var file_path := "%s/%s" % [dir_path, filename]
			files.append([FileAccess.get_modified_time(file_path), file_path])
		filename = dir.get_next()
	dir.list_dir_end()

	files.sort_custom(func(a, b): return a[0] > b[0])
	for i in range(keep, files.size()):
		DirAccess.remove_absolute(files[i][1])
