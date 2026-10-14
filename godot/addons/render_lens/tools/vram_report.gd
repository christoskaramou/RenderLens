extends Node

## vram_report
## Asks the running game for the Video RAM list (debugger message servers:memory,
## reply servers:memory_usage). Names each resource by path, type, format, and bytes.
## Also reports RenderingServer memory counters and RenderingDevice.get_memory_usage
## when a device exists. Does not change the project.

const FileHelper = preload("res://addons/render_lens/file_helper.gd")
const Pacing = preload("res://addons/render_lens/pacing.gd")

static func execute(params: Dictionary) -> Dictionary:
	var gathered: Dictionary = await gather(params)
	if str(gathered.get("list_error", "")) != "":
		return _error(str(gathered.list_error))
	var path := FileHelper.write_json(gathered, "vram_report")
	if path.is_empty():
		return _error("Failed to write vram_report JSON")
	gathered["path"] = path
	return {
		"content": [{
			"type": "text",
			"text": JSON.stringify(_summary(gathered), "\t")
		}]
	}


static func gather(params: Dictionary) -> Dictionary:
	var resources: Array = []
	var total := 0
	var list_error := ""
	var source := ""
	# Only the game's own counters are reported: the editor process has different VRAM numbers.
	var rendering_info := {}
	var device := {}
	var truncated := false
	var resource_cap := 0
	var note := ""
	var debugger_plugin = params.get("_debugger_plugin")
	if debugger_plugin != null and debugger_plugin.has_method("request_game_vram"):
		var status: Dictionary = {}
		if debugger_plugin.has_method("get_debug_status"):
			status = debugger_plugin.get_debug_status()
		if int(status.get("active_sessions", 0)) <= 0:
			list_error = "No active debugger session. Run the game from the editor so the game can list its own resources."
		else:
			debugger_plugin.attach_session_debug_data()
			var asked_game := bool(debugger_plugin.request_game_vram())
			var asked_servers := false
			# Godot's servers:memory request crashes a game on the Separate render thread (see Pacing.separate_render_thread).
			# Only once this game has reported its thread model (a startup breakpoint can come before that report).
			if debugger_plugin.has_method("request_video_memory") and bool(debugger_plugin.ready_received) and not Pacing.separate_render_thread() and not bool(debugger_plugin.game_separate_render_thread):
				asked_servers = bool(debugger_plugin.request_video_memory())
			var started := Time.get_ticks_msec()
			var game: Dictionary = {}
			var servers: Dictionary = {}
			# The game answers on its next debugger poll after walking up to 8,000 nodes; slow frames need more than 2 s.
			var game_at := -1
			while Time.get_ticks_msec() - started < 15000:
				await Engine.get_main_loop().process_frame
				game = debugger_plugin.take_game_vram()
				servers = debugger_plugin.take_vram()
				# Keep waiting for the game reply after servers:memory_usage: it carries the game's counters, and Godot drops an oversized servers reply.
				if bool(game.get("ok", false)):
					# Godot's own list can arrive a frame or more after the game's reply; give it up to 1 s.
					if not asked_servers or bool(servers.get("ok", false)):
						break
					if game_at < 0:
						game_at = Time.get_ticks_msec()
					elif Time.get_ticks_msec() - game_at > 1000:
						break
			if bool(game.get("ok", false)):
				if typeof(game.get("rendering_info", {})) == TYPE_DICTIONARY:
					rendering_info = game.get("rendering_info", {})
				if typeof(game.get("device", {})) == TYPE_DICTIONARY:
					device = game.get("device", {})
			if bool(servers.get("ok", false)):
				resources = servers.get("resources", [])
				total = int(servers.get("total_bytes", 0))
				source = "servers:memory_usage"
				note = "The resource list is ServersDebugger::ResourceUsage (path, format, type, vram bytes), delivered on debug_data because ScriptEditorDebugger consumes servers:memory_usage before plugins. Godot 4.4 sends textures. Godot 4.7 also sends meshes."
			elif bool(game.get("ok", false)):
				resources = game.get("resources", [])
				total = int(game.get("total_bytes", 0))
				source = str(game.get("source", "game_resource_estimate"))
				truncated = bool(game.get("truncated", false))
				resource_cap = int(game.get("resource_cap", 0))
				note = str(game.get("note", ""))
				if truncated:
					note += " The list is incomplete: the walk hit its limit (" + str(resource_cap) + " resources or 8000 nodes), so listed_total_bytes undercounts."
			elif not asked_game and not asked_servers:
				list_error = str(debugger_plugin.last_error)
			else:
				list_error = "The game did not return render_lens:vram. The per-resource list is collected in the running game, not by searching the editor UI for the debugger panel."
	else:
		list_error = "No debugger session. The per-resource list needs a game started from the editor with Render Lens enabled."
	var largest := 0
	if not resources.is_empty() and typeof(resources[0]) == TYPE_DICTIONARY:
		largest = int(resources[0].get("vram_bytes", 0))
	return {
		"applied": false,
		"list_error": list_error,
		"source": source,
		"resource_count": resources.size(),
		"listed_total_bytes": total,
		"largest_bytes": largest,
		"resources": resources,
		"truncated": truncated,
		"resource_cap": resource_cap,
		"rendering_info": rendering_info,
		"device": device,
		"counters_source": "game" if not rendering_info.is_empty() else "",
		"note": note,
	}


static func _summary(payload: Dictionary) -> Dictionary:
	var listed: Array = payload.get("resources", [])
	var top: Array = []
	for item in listed:
		if top.size() >= 12:
			break
		top.append(item)
	return {
		"path": payload.get("path", ""),
		"applied": false,
		"list_error": payload.get("list_error", ""),
		"source": payload.get("source", ""),
		"resource_count": payload.get("resource_count", 0),
		"listed_total_bytes": payload.get("listed_total_bytes", 0),
		"largest_bytes": payload.get("largest_bytes", 0),
		"truncated": payload.get("truncated", false),
		"counters_source": payload.get("counters_source", ""),
		"top": top,
		"rendering_info": payload.get("rendering_info", {}),
		"device": payload.get("device", {}),
		"note": payload.get("note", ""),
	}


static func _error(message: String) -> Dictionary:
	return {"isError": true, "content": [{"type": "text", "text": message}]}
