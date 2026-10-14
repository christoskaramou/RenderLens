extends RefCounted

const ShaderChecks = preload("res://addons/render_lens/shader_checks.gd")
const Checks = preload("res://addons/render_lens/scene_checks.gd")
const ServerSync = preload("res://addons/render_lens/server_sync_calls.gd")

## Project-wide counts that are not one scene node: GDScript files, .import
## files, audio buses, and autoloads. Does not modify the project.

const MAX_WALK_ENTRIES := 100000
const MAX_SCRIPTS := 4096
const MAX_SCRIPT_BYTES := 1048576
const FRAME_CALLBACKS := "_process|_physics_process|_integrate_forces"
## Methods the class reference documents as costly (or, for impulses, frame-rate dependent) when called every frame.
## Names listed in RECEIVER_CALLS must be called on an object (".name(") to match; others also match bare calls.
const FRAME_CALLS := {
	"frame_texture_readback": ["get_image"],
	"frame_mesh_bake": ["bake_mesh_from_current_blend_shape_mix", "bake_mesh_from_current_skeleton_pose"],
	"frame_multimesh_buffer": ["multimesh_get_buffer"],
	"frame_global_shader_get": ["global_shader_parameter_get", "global_shader_parameter_get_list", "global_shader_parameter_get_type"],
	"frame_force_sync": ["force_sync"],
	"frame_find_nodes": ["find_child", "find_children", "find_parent"],
	"frame_group_calls": ["call_group", "notify_group", "set_group"],
	"frame_output_latency": ["get_output_latency"],
	"frame_window_title": ["window_set_title"],
	"frame_capture_rect": ["capture_rect"],
	"frame_tile_update": ["notify_runtime_tile_data_update", "update_internals"],
	"frame_bone_global_pose": ["set_bone_global_pose"],
	"frame_navigation_parse": ["parse_source_geometry_data"],
	"frame_navigation_reachable": ["is_target_reachable"],
	"frame_navigation_force_update": ["map_force_update"],
	"frame_navigation_bake": ["bake_navigation_mesh"],
	"frame_image_texture_set": ["set_image"],
	"frame_file_flush": ["flush"],
	"frame_impulse": [
		"apply_impulse", "apply_central_impulse", "apply_torque_impulse", "body_apply_impulse", "body_apply_central_impulse",
		"body_apply_torque_impulse", "soft_body_apply_central_impulse", "soft_body_apply_point_impulse",
	],
}
const RECEIVER_CALLS := ["get_image", "set_image", "flush"]


## audio: read this process's AudioServer; the editor merging a game scan passes false and keeps the game's live buses.
static func apply(state: Dictionary, audio := true) -> void:
	var files := project_files(state)
	_scripts(state, files[".gd"], files["_paths"])
	_resource_path_case(state, files[".tscn"] + files[".tres"], files["_paths"])
	for mismatch in path_case_mismatches(_setting_paths(), files["_paths"], false):
		Checks.check(state, "path_case_mismatch", true, "res://project.godot -> %s" % mismatch)
	_imports(state, files[".import"])
	if audio:
		_audio_buses(state)
	_autoloads(state)
	var shaders: Array = files[".glsl"]
	shaders.sort()
	ShaderChecks.scan(shaders, state)


## One bounded walk of res:// (".godot" skipped) for every file type the project scan reads.
static func project_files(state: Dictionary) -> Dictionary:
	# "_paths" maps every walked path, lowercased, to its on-disk spelling (an Array when a case-sensitive file system
	# holds several, e.g. Foo.png and foo.png on Linux).
	var files := {".gd": [], ".import": [], ".glsl": [], ".tscn": [], ".tres": [], "_paths": {}}
	var walk := {"entries": 0, "max_entries": MAX_WALK_ENTRIES, "truncated": false}
	state["file_walk"] = walk
	_walk("res://", files, walk)
	return files


static func _scripts(state: Dictionary, files: Array, paths: Dictionary = {}) -> void:
	var counts: Dictionary = state["counts"]
	var coverage := {"scripts": 0, "skipped_scripts": 0, "max_scripts": MAX_SCRIPTS, "max_script_bytes": MAX_SCRIPT_BYTES}
	state["script_scan"] = coverage
	var patterns := _frame_patterns()
	# Declarations and calls are matched in code_only() text, so comments, strings and _process_queue() do not count.
	var process_func := RegEx.create_from_string("(?m)^\\s*(?:static\\s+)?func\\s+_process\\s*\\(")
	var physics_func := RegEx.create_from_string("(?m)^\\s*(?:static\\s+)?func\\s+_physics_process\\s*\\(")
	var bake_call := RegEx.create_from_string("(?<![\\w])(bake_navigation_mesh|parse_source_geometry_data)\\s*\\(")
	for path in files:
		var text := str(path)
		if text.find("addons/render_lens/") >= 0:
			continue
		var file := FileAccess.open(text, FileAccess.READ)
		if file == null:
			continue
		if coverage.scripts >= MAX_SCRIPTS or file.get_length() > MAX_SCRIPT_BYTES:
			coverage.skipped_scripts += 1
			continue
		coverage.scripts += 1
		var source := file.get_as_text()
		file.close()
		var code := code_only(source)  # once per script; the checks below share it
		frame_calls(source, text, state, patterns, code)
		Checks.check(state, "navigation_runtime_bake", bake_call.search(code) != null, text)
		script_warnings(source, text, state, code)
		for mismatch in path_case_mismatches(without_comments(source, code), paths, false):
			Checks.check(state, "path_case_mismatch", true, "%s -> %s" % [text, mismatch])
		if process_func.search(code) != null:
			counts["script_file_process_count"] = int(counts.get("script_file_process_count", 0)) + 1
			_note(state, "script_process_files", text)
		if physics_func.search(code) != null:
			counts["script_file_physics_process_count"] = int(counts.get("script_file_physics_process_count", 0)) + 1
			_note(state, "script_physics_files", text)


static func _frame_patterns() -> Dictionary:
	var patterns := {}
	for key in FRAME_CALLS:
		var names: Array = FRAME_CALLS[key]
		var free: Array = names.filter(func(name): return name not in RECEIVER_CALLS)
		var bound: Array = names.filter(func(name): return name in RECEIVER_CALLS)
		var parts: Array = []
		if not free.is_empty():
			parts.append("(?<![\\w])(%s)\\s*\\(" % "|".join(free))
		if not bound.is_empty():
			parts.append("\\.(%s)\\s*\\(" % "|".join(bound))
		patterns[key] = RegEx.create_from_string("|".join(parts))
	# Server getters that wait for the server thread; reported only when that server runs on its own thread.
	for entry in [["frame_rendering_sync", "RenderingServer", ServerSync.RENDERING], ["frame_physics_3d_sync", "PhysicsServer3D", ServerSync.PHYSICS_3D],
			["frame_physics_2d_sync", "PhysicsServer2D", ServerSync.PHYSICS_2D]]:
		patterns[entry[0]] = RegEx.create_from_string("(?<![\\w])%s\\s*\\.\\s*(%s)\\s*\\(" % [entry[1], "|".join(entry[2])])
	return patterns


## Reports documented per-frame costs in unconditional top-level statements of _process,
## _physics_process and _integrate_forces (scanning of a body stops at its first return),
## draw_line calls inside loops in _draw, and _use_tile_data_runtime_update returning true for every tile.
static func frame_calls(source: String, path: String, state: Dictionary, patterns: Dictionary = {}, stripped: String = "") -> void:
	if patterns.is_empty():
		patterns = _frame_patterns()
	var header_pattern := "^(\\s*)(?:static\\s+)?func\\s+(%s|_draw|_use_tile_data_runtime_update)\\s*\\(\\s*(\\w*)" % FRAME_CALLBACKS
	if RegEx.create_from_string("(?m)" + header_pattern).search(source) == null:
		return
	var header := RegEx.create_from_string(header_pattern)
	var draw_line := RegEx.create_from_string("(?<![\\w])draw_line\\s*\\(")
	# A one-line block (if hit: tex.get_image()) runs only sometimes, like any other branch.
	var block_line := RegEx.create_from_string("^(?:if|elif|else|for|while|match)\\b")
	var lines := (stripped if not stripped.is_empty() else code_only(source)).split("\n")
	var index := 0
	while index < lines.size():
		var found := header.search(lines[index])
		index += 1
		if found == null:
			continue
		var callback := found.get_string(2)
		# An impulse scaled by the frame time is a frame-rate-independent force; in _integrate_forces the time is state.step.
		var delta_name := found.get_string(3) if callback != "_integrate_forces" else ""
		var delta := RegEx.create_from_string(("(?<![\\w])%s(?![\\w])|" % delta_name if not delta_name.is_empty() else "") + "\\.step\\b|get_(?:physics_)?process_delta_time")
		if callback == "_use_tile_data_runtime_update" and lines[index - 1].strip_edges().ends_with(": return true"):
			Checks.check(state, "tile_runtime_update_all", true, "%s:%d" % [path, index])
		var base := found.get_string(1).length()
		var body := -1
		var exited := false
		var loops: Array[int] = []
		while index < lines.size():
			var raw := lines[index]
			var code := raw.strip_edges()
			if code.is_empty():
				index += 1
				continue
			var indent := raw.length() - raw.lstrip(" \t").length()
			if indent <= base:
				break
			if body < 0:
				body = indent
				if callback == "_use_tile_data_runtime_update":
					Checks.check(state, "tile_runtime_update_all", code == "return true", "%s:%d" % [path, index + 1])
			if callback == "_draw":
				while not loops.is_empty() and loops.back() >= indent:
					loops.pop_back()
				var loop := code.begins_with("for ") or code.begins_with("while ")
				if (loop or not loops.is_empty()) and draw_line.search(code) != null:
					Checks.check(state, "draw_line_loop", true, "%s:%d draw_line() in a loop in _draw" % [path, index + 1])
				if loop and code.ends_with(":"):
					loops.append(indent)
				index += 1
				continue
			exited = exited or code.begins_with("return") or code.contains(": return")
			if indent == body and not exited and callback != "_use_tile_data_runtime_update" and block_line.search(code) == null:
				for key in patterns:
					var call: RegExMatch = patterns[key].search(code)
					if call != null and not (key == "frame_impulse" and delta.search(code) != null):
						var name: String = call.get_string(1) if not call.get_string(1).is_empty() else call.get_string(2)
						Checks.check(state, key, true, "%s:%d %s() in %s" % [path, index + 1, name, found.get_string(2)])
			index += 1


## The source with comments removed but string contents kept: code_only keeps each line's columns up to its comment.
static func without_comments(source: String, stripped: String) -> String:
	var lines := source.split("\n")
	var kept := stripped.split("\n")
	for i in mini(lines.size(), kept.size()):
		lines[i] = lines[i].substr(0, kept[i].length())
	return "\n".join(lines)


## GDScript source with comments removed and string-literal contents replaced by spaces, keeping quotes,
## newlines and columns, so text matching and indentation see only code. Handles triple-quoted strings,
## escapes and raw strings (r"...").
static func code_only(source: String) -> String:
	var special := RegEx.create_from_string("[#\"']")
	var stops := {"\"": RegEx.create_from_string("[\\\\\\n\"]"), "'": RegEx.create_from_string("[\\\\\\n']")}
	var blank := RegEx.create_from_string("[^\\n]")
	var parts := PackedStringArray()
	var start := 0
	var found := special.search(source)
	while found != null:
		var index := found.get_start()
		var mark := source[index]
		if mark == "#":
			parts.append(source.substr(start, index - start))
			start = source.find("\n", index)
			if start < 0:
				return "".join(parts)
			found = special.search(source, start)
			continue
		var quote := mark.repeat(3) if source.substr(index, 3) == mark.repeat(3) else mark
		var raw := index > 0 and source[index - 1] == "r" and (index == 1 or not _word_character(source[index - 2]))
		var content := index + quote.length()
		parts.append(source.substr(start, content - start))
		var cursor := content
		var close := -1
		while true:
			var stop: RegExMatch = stops[mark].search(source, cursor)
			if stop == null:
				break
			var at := stop.get_start()
			if source[at] == "\n" and quote.length() == 1:
				close = at
				break
			if source[at] == "\\":
				# A raw string keeps its backslashes, but one still consumes a following quote or backslash (gdscript_tokenizer.cpp).
				var escaped := source.substr(at + 1, 1)
				cursor = at + (2 if not raw or escaped == mark or escaped == "\\" else 1)
			elif source[at] == mark and source.substr(at, quote.length()) == quote:
				close = at
				break
			else:
				cursor = at + 1
		var end := source.length() if close < 0 else close
		parts.append(blank.sub(source.substr(content, end - content), " ", true))
		if close < 0:
			return "".join(parts)
		start = close + (quote.length() if source[close] == mark else 0)
		parts.append(source.substr(close, start - close))
		found = special.search(source, start)
	parts.append(source.substr(start))
	return "".join(parts)


static func _word_character(character: String) -> bool:
	return character == "_" or (character >= "a" and character <= "z") or (character >= "A" and character <= "Z") or (character >= "0" and character <= "9")


static func _imports(state: Dictionary, files: Array) -> void:
	var counts: Dictionary = state["counts"]
	for path in files:
		var text := str(path)
		var fields := _read_import(text)
		var importer := str(fields.get("importer", ""))
		# Layered importers share the 2D texture importer's compress/mipmap options in 4.4 and 4.7.2.
		if importer in ["texture", "2d_array_texture", "cubemap_texture", "cubemap_array_texture", "3d_texture"]:
			var mode := str(fields.get("compress/mode", ""))
			# Lossless and mipmap-less are the recommended 2D defaults; plain textures used in 3D are judged by scene usage (textures.*).
			var layered := importer != "texture"
			if mode == "0" and layered:
				counts["import_texture_lossless_count"] = int(counts["import_texture_lossless_count"]) + 1
				_note(state, "import_texture_lossless", text.trim_suffix(".import"))
			elif mode == "3":
				counts["import_texture_uncompressed_count"] = int(counts["import_texture_uncompressed_count"]) + 1
				_note(state, "import_texture_uncompressed", text.trim_suffix(".import"))
			# BC7/ASTC high quality uses 8 bits per pixel where S3TC would pick 4-bit DXT1 for opaque images.
			if mode == "2" and str(fields.get("compress/high_quality", "")).to_lower() == "true":
				counts["import_texture_high_quality_count"] = int(counts["import_texture_high_quality_count"]) + 1
				_note(state, "import_texture_high_quality", text.trim_suffix(".import"))
			var source := text.trim_suffix(".import").to_lower()
			if mode == "2" and (source.ends_with(".exr") or source.ends_with(".hdr")) and str(fields.get("compress/hdr_compression", "")) == "0":
				counts["import_texture_hdr_uncompressed_count"] = int(counts["import_texture_hdr_uncompressed_count"]) + 1
				_note(state, "import_texture_hdr_uncompressed", text.trim_suffix(".import"))
			if layered and str(fields.get("mipmaps/generate", "")).to_lower() == "false":
				counts["import_texture_no_mipmaps_count"] = int(counts["import_texture_no_mipmaps_count"]) + 1
				_note(state, "import_texture_no_mipmaps", text.trim_suffix(".import"))
		elif importer == "scene" or importer == "gltf" or text.ends_with(".gltf.import") or text.ends_with(".glb.import") or text.ends_with(".fbx.import"):
			if str(fields.get("meshes/generate_lods", "")).to_lower() == "false":
				counts["import_mesh_lods_off_count"] = int(counts["import_mesh_lods_off_count"]) + 1
				_note(state, "import_mesh_lods_off", text.trim_suffix(".import"))
			if str(fields.get("meshes/create_shadow_meshes", "")).to_lower() == "false":
				counts["import_mesh_shadow_off_count"] = int(counts["import_mesh_shadow_off_count"]) + 1
				_note(state, "import_mesh_shadow_off", text.trim_suffix(".import"))
			# 3 = Embed as Uncompressed: embedded glTF images skip VRAM compression (default 1 extracts them).
			if str(fields.get("gltf/embedded_image_handling", "")) == "3":
				counts["import_gltf_embedded_uncompressed_count"] = int(counts["import_gltf_embedded_uncompressed_count"]) + 1
				_note(state, "import_gltf_embedded_uncompressed", text.trim_suffix(".import"))
			if str(fields.get("meshes/force_disable_compression", "")).to_lower() == "true":
				counts["import_mesh_uncompressed_count"] = int(counts["import_mesh_uncompressed_count"]) + 1
				_note(state, "import_mesh_uncompressed", text.trim_suffix(".import"))
		elif importer == "wavefront_obj":
			if str(fields.get("generate_lods", "")).to_lower() == "false":
				counts["import_obj_lods_off_count"] = int(counts["import_obj_lods_off_count"]) + 1
				_note(state, "import_obj_lods_off", text.trim_suffix(".import"))
			if str(fields.get("generate_shadow_mesh", "")).to_lower() == "false":
				counts["import_obj_shadow_off_count"] = int(counts["import_obj_shadow_off_count"]) + 1
				_note(state, "import_obj_shadow_off", text.trim_suffix(".import"))
		elif importer == "wav":
			if str(fields.get("compress/mode", "")) == "0":
				counts["import_audio_pcm_count"] = int(counts["import_audio_pcm_count"]) + 1
				_note(state, "import_audio_pcm", text.trim_suffix(".import"))


static func _audio_buses(state: Dictionary) -> void:
	var counts: Dictionary = state["counts"]
	var buses := AudioServer.get_bus_count()
	var effects := 0
	var coverage := {"enabled_effects": 0, "uninspected_effects": 0, "spectrum_history_effects": 0}
	for i in buses:
		effects += AudioServer.get_bus_effect_count(i)
		var bypassed := AudioServer.is_bus_bypassing_effects(i)
		for index in AudioServer.get_bus_effect_count(i):
			var enabled := not bypassed and AudioServer.is_bus_effect_enabled(i, index)
			if enabled:
				coverage.enabled_effects += 1
			var effect := AudioServer.get_bus_effect(i, index)
			if effect == null or effect.get_script() != null or effect.get_class() not in ["AudioEffectPitchShift", "AudioEffectChorus", "AudioEffectReverb", "AudioEffectStereoEnhance", "AudioEffectEQ6", "AudioEffectEQ10", "AudioEffectEQ21", "AudioEffectSpectrumAnalyzer"]:
				if enabled:
					coverage.uninspected_effects += 1
				continue
			var path := "Audio bus '%s' / effect %d (%s)" % [AudioServer.get_bus_name(i), index, effect.get_class()]
			if effect is AudioEffectSpectrumAnalyzer:
				coverage.spectrum_history_effects += 1
				Checks.check(state, "spectrum_history", is_finite(effect.buffer_length) and effect.buffer_length > 4.0, path)
			if not enabled:
				continue
			if effect is AudioEffectPitchShift and not is_equal_approx(effect.pitch_scale, 1.0):
				var frames: int = [256, 512, 1024, 2048, 4096][effect.fft_size]
				Checks.check(state, "pitch_shift_oversampling", effect.oversampling > 4 and effect.oversampling <= frames, path)
				Checks.check(state, "audio_pitch_zero_hop", effect.oversampling > frames, path)
			elif effect is AudioEffectChorus:
				var voices := 0
				for voice in effect.voice_count:
					voices += int(effect.get_voice_cutoff_hz(voice) != 0.0)
				Checks.check(state, "chorus_voices", voices > 2 and effect.wet != 0.0, path)
				Checks.check(state, "chorus_dry_only", voices > 0 and effect.wet == 0.0 and effect.dry == 1.0, path)
			elif effect is AudioEffectReverb:
				Checks.check(state, "reverb_dry_only", effect.wet == 0.0 and effect.dry == 1.0, path)
			elif effect is AudioEffectStereoEnhance:
				Checks.check(state, "stereo_neutral", effect.pan_pullout == 1.0 and effect.time_pullout_ms == 0.0 and effect.surround == 0.0, path)
			elif effect is AudioEffectEQ:
				Checks.check(state, "eq_many_bands", effect.get_band_count() > 10, path)
	counts["audio_bus_count"] = buses
	counts["audio_bus_effect_count"] = effects
	state["audio_scan"] = coverage


static func _autoloads(state: Dictionary) -> void:
	var counts: Dictionary = state["counts"]
	var total := 0
	for prop in ProjectSettings.get_property_list():
		if typeof(prop) != TYPE_DICTIONARY:
			continue
		var path := str(prop.get("name", ""))
		if path.begins_with("autoload/"):
			total += 1
			_note(state, "autoloads", path)
	counts["autoload_count"] = total


static func _read_import(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var out := {}
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.find("=") < 0 or line.begins_with("["):
			continue
		var parts := line.split("=", true, 1)
		if parts.size() == 2:
			out[parts[0]] = parts[1].strip_edges().trim_prefix("\"").trim_suffix("\"")
	file.close()
	return out


## Godot editor builds on Windows and macOS warn when a res:// path opens a file whose on-disk case differs; exported packs are
## case-sensitive, so the load fails there. Lines with a uid:// reference are skipped in text resources (Godot loads by UID first).
static func path_case_mismatches(source: String, paths: Dictionary, skip_uid_lines: bool) -> Array:
	var found: Array = []
	if paths.is_empty() or source.find("res://") < 0:
		return found
	var pattern := RegEx.create_from_string("res://[^\"'\\n\\)\\]]+")  # quoted paths may contain spaces
	for line in source.split("\n"):
		if line.find("res://") < 0 or (skip_uid_lines and line.find("uid=\"uid://") >= 0):
			continue
		for match in pattern.search_all(line):
			var path := match.get_string().get_slice("::", 0)
			var actual = paths.get(path.to_lower(), "")
			var spellings: Array = actual if actual is Array else [actual]
			if not str(spellings[0]).is_empty() and not spellings.has(path) and not found.has(path):
				found.append(path)
	return found


## Paths in the project settings Godot opens at startup. project.godot text is not scanned: stale sections (Godot 3 [locale]) are never read.
static func _setting_paths() -> String:
	var values: Array = []
	for key in ["application/run/main_scene", "application/config/icon", "application/boot_splash/image", "gui/theme/custom", "gui/theme/custom_font", "internationalization/locale/translations"]:
		values.append(ProjectSettings.get_setting(key, ""))
	for property in ProjectSettings.get_property_list():
		if str(property.name).begins_with("autoload/"):
			values.append(str(ProjectSettings.get_setting(property.name)).trim_prefix("*"))
	var remaps = ProjectSettings.get_setting("internationalization/locale/translation_remaps", {})
	if remaps is Dictionary:
		for source in remaps:
			values.append(source)
			for target in remaps[source]:
				# Remap targets end in ":<locale>".
				values.append(str(target).get_slice(":", 0) + ":" + str(target).get_slice(":", 1))
	var lines: PackedStringArray = []
	for value in values:
		if value is PackedStringArray or value is Array:
			for item in value:
				lines.append('"%s"' % item)
		else:
			lines.append('"%s"' % value)
	return "\n".join(lines)


static func _resource_path_case(state: Dictionary, files: Array, paths: Dictionary) -> void:
	# Reported beside the script counts, so a large scene left unread is visible.
	var coverage: Dictionary = state.get_or_add("script_scan", {})
	coverage["resources"] = 0
	coverage["skipped_resources"] = 0
	for path in files:
		var text := str(path)
		if text.find("addons/render_lens/") >= 0:
			continue
		if int(coverage.resources) >= MAX_SCRIPTS:
			coverage.skipped_resources += 1
			continue
		var file := FileAccess.open(text, FileAccess.READ)
		if file == null:
			continue
		if file.get_length() > MAX_SCRIPT_BYTES:
			coverage.skipped_resources += 1
			continue
		coverage.resources += 1
		var source := file.get_as_text()
		file.close()
		for mismatch in path_case_mismatches(source, paths, true):
			Checks.check(state, "path_case_mismatch", true, "%s -> %s" % [text, mismatch])
		resource_text_checks(source, text, state)


## Script calls Godot warns about at runtime (docs/GODOT_RUNTIME_WARNINGS.json): deprecated APIs that do nothing,
## draw arguments that are ignored, theme reads in _init, PhysicsServer3D settings Jolt ignores and manual particle emission.
## Comments and string contents are ignored; only literal arguments are judged.
static func script_warnings(source: String, path: String, state: Dictionary, code: String = "") -> void:
	if code.is_empty():
		code = code_only(source)
	var deprecated := "reflection_probe_set_resolution|region_bake_navigation_mesh|draw_command_insert_label|full_barrier"
	if Engine.get_version_info().minor >= 6:
		deprecated += "|environment_set_ssr_roughness_quality"
	var calls := {
		"script_deprecated_call": RegEx.create_from_string("(?<![\\w])(%s)\\s*\\(|\\.(barrier)\\s*\\(|NavigationMeshGenerator\\s*\\.\\s*(bake)\\s*\\(" % deprecated),
		"script_jolt_server_call": RegEx.create_from_string("PhysicsServer3D\\s*\\.\\s*(space_set_param|body_set_user_flags|body_set_contacts_reported_depth_threshold)\\s*\\("),
		"script_emit_particle": RegEx.create_from_string("(?<![\\w])(emit_particle)\\s*\\("),
	}
	for key in calls:
		var found: RegExMatch = calls[key].search(code)
		if found != null:
			var name := ""
			for group in range(1, found.get_group_count() + 1):
				name = name if not name.is_empty() else found.get_string(group)
			Checks.check(state, key, true, "%s:%d %s()" % [path, code.substr(0, found.get_start()).count("\n") + 1, name])
	for found in RegEx.create_from_string("(?<![\\w])(draw_rect|draw_circle|draw_polyline|draw_multiline)\\s*\\(").search_all(code):
		var args := _call_arguments(code, found.get_end())
		var name := found.get_string(1)
		var ignored := false
		if name == "draw_rect" or name == "draw_circle":
			# filled == true with a literal width other than -1.
			var filled := 2 if name == "draw_rect" else 3
			ignored = args.size() > filled + 1 and args[filled] == "true" and args[filled + 1].is_valid_float() and float(args[filled + 1]) != -1.0
		else:
			# Antialiasing requested on a negative-width (line strip) polyline or multiline.
			ignored = args.size() > 3 and args[3] == "true" and args[2].is_valid_float() and float(args[2]) < 0.0
		if ignored:
			Checks.check(state, "script_draw_ignored", true, "%s:%d %s()" % [path, code.substr(0, found.get_start()).count("\n") + 1, name])
	# Theme getters inside _init run before NOTIFICATION_POSTINITIALIZE.
	var lines := code.split("\n")
	var header := RegEx.create_from_string("^(\\s*)func\\s+_init\\s*\\(")
	var theme := RegEx.create_from_string("(?<![\\w.])(get_theme_\\w+|has_theme_\\w+)\\s*\\(")  # on another object it is fine
	for index in lines.size():
		var start := header.search(lines[index])
		if start == null:
			continue
		var base := start.get_string(1).length()
		for body in range(index + 1, mini(lines.size(), index + 400)):
			var raw: String = lines[body]
			if raw.strip_edges().is_empty():
				continue
			if raw.length() - raw.lstrip(" \t").length() <= base:
				break
			var call := theme.search(raw)
			if call != null:
				Checks.check(state, "script_theme_in_init", true, "%s:%d %s() in _init" % [path, body + 1, call.get_string(1)])
				break


## Top-level comma-separated arguments of a call whose "(" ends at start; stops at the matching ")".
static func _call_arguments(code: String, start: int) -> PackedStringArray:
	var args: PackedStringArray = []
	var depth := 0
	var current := ""
	for index in range(start, mini(code.length(), start + 2000)):
		var character := code[index]
		if character in "([{":
			depth += 1
		elif character in ")]}":
			if depth == 0:
				args.append(current.strip_edges())
				return args
			depth -= 1
		elif character == "," and depth == 0:
			args.append(current.strip_edges())
			current = ""
			continue
		current += character
	return PackedStringArray()


## Saved text resources Godot repairs with a warning on load: ext_resource UIDs that no longer resolve (as
## resource_format_text.cpp tests them in editor builds), pre-4.0 ShaderMaterial parameter names, and ArrayMesh surfaces
## saved without the current format version (upgraded on every load).
static func resource_text_checks(source: String, path: String, state: Dictionary) -> void:
	var field := RegEx.create_from_string("(\\w+)=\"([^\"]*)\"")
	var surface_format := RegEx.create_from_string("\"format\":\\s*(\\d+)")
	var section := ""
	var resource_type := ""
	var line_number := 0
	for line in source.split("\n"):
		line_number += 1
		if line.begins_with("["):
			var fields := {}
			for match in field.search_all(line):
				fields[match.get_string(1)] = match.get_string(2)
			if line.begins_with("[gd_resource"):
				resource_type = fields.get("type", "")
			section = resource_type if line.begins_with("[resource]") else fields.get("type", "")
			if line.begins_with("[ext_resource") and fields.has("uid") and fields.has("path"):
				var id := ResourceUID.text_to_id(fields.uid)
				# A .uid sidecar holds the UID of a file this editor has no loader for (C# scripts in a non-.NET build).
				if id != ResourceUID.INVALID_ID and not ResourceUID.has_id(id) and ResourceLoader.get_resource_uid(fields.path) != id \
						and not (FileAccess.file_exists(fields.path + ".uid") and FileAccess.get_file_as_string(fields.path + ".uid").strip_edges() == fields.uid):
					Checks.check(state, "ext_resource_uid_invalid", true, "%s:%d %s" % [path, line_number, fields.uid])
			continue
		if section == "ShaderMaterial" and (line.begins_with("shader_param/") or line.begins_with("param/") or line.begins_with("shader_uniform/")):
			Checks.check(state, "shader_param_old_names", true, "%s:%d" % [path, line_number])
		elif section == "ArrayMesh" and line.contains("\"format\""):
			for match in surface_format.search_all(line):
				var format := int(match.get_string(1))
				if format != 0 and ((format >> 35) & 0xFF) == 0:
					Checks.check(state, "mesh_old_surface_format", true, "%s:%d" % [path, line_number])


static func _walk(root: String, files: Dictionary, walk: Dictionary) -> void:
	var dir := DirAccess.open(root)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if walk.entries >= MAX_WALK_ENTRIES:
			walk.truncated = true
			break
		walk.entries += 1
		if name != "." and name != ".." and name != ".godot":
			var full := root.path_join(name)
			var known = files["_paths"].get(full.to_lower())
			if known == null:
				files["_paths"][full.to_lower()] = full
			elif known is Array:
				known.append(full)
			else:
				files["_paths"][full.to_lower()] = [known, full]
			if dir.current_is_dir():
				# Like EditorFileSystem: skip dot folders and folders holding .gdignore or another project.godot.
				if not name.begins_with(".") and not FileAccess.file_exists(full.path_join(".gdignore")) and not FileAccess.file_exists(full.path_join("project.godot")):
					_walk(full, files, walk)
			elif files.has("." + name.get_extension()):
				files["." + name.get_extension()].append(full)
		name = dir.get_next()
	dir.list_dir_end()


static func _note(state: Dictionary, key: String, path: String) -> void:
	var offenders: Dictionary = state["offenders"]
	if not offenders.has(key):
		offenders[key] = []
	var listed: Array = offenders[key]
	if listed.size() >= 12:
		return
	if not listed.has(path):
		listed.append(path)
