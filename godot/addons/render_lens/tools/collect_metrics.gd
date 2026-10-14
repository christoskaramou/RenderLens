extends Node

## collect_metrics
## Both packages can capture the running game or explicitly inspect the editor.

const FileHelper = preload("res://addons/render_lens/file_helper.gd")
const Game = preload("res://addons/render_lens/game_bridge.gd")
const Metrics = preload("res://addons/render_lens/metrics_snapshot.gd")

static func execute(params: Dictionary) -> Dictionary:
	var gathered: Dictionary = await gather(params)
	if params.get("source", "auto") == "game" and gathered.active_source != "game":
		return _error("Game metrics unavailable: " + str(gathered.game_error))
	var payload := {
		"applied": false,
		"active_source": gathered.get("active_source", "editor"),
		"game_error": gathered.get("game_error", ""),
		"editor": gathered.get("editor", {}),
		"game": gathered.get("game", null),
	}
	var path := FileHelper.write_json(payload, "collect_metrics")
	if path.is_empty():
		return _error("Failed to write collect_metrics JSON")
	return {
		"content": [{
			"type": "text",
			"text": JSON.stringify(_summary(payload, path), "\t")
		}]
	}


static func gather(params: Dictionary) -> Dictionary:
	var editor_snap: Dictionary = Metrics.collect()
	var game_snap = null
	var game_error := ""
	var source := str(params.get("source", "auto"))
	if source != "editor":
		var response: Dictionary = await Game.request(params, "metrics_snapshot", 10.0)
		if response.get("isError", false):
			game_error = Game.error_text(response)
		else:
			game_snap = response
	var active_source := "editor"
	if game_snap != null:
		active_source = "game"
	return {
		"editor": editor_snap,
		"game": game_snap,
		"game_error": game_error,
		"active_source": active_source,
		"active": game_snap if game_snap != null else editor_snap,
	}


static func _summary(payload: Dictionary, path: String) -> Dictionary:
	var active: Dictionary = payload.get("editor", {})
	if payload.get("active_source") == "game" and typeof(payload.get("game")) == TYPE_DICTIONARY:
		active = payload.game
	var metrics: Dictionary = active.get("metrics", {})
	var view: Dictionary = active.get("viewport", {})
	return {
		"path": path,
		"applied": false,
		"active_source": payload.get("active_source", "editor"),
		"game_error": payload.get("game_error", ""),
		"godot_version": active.get("godot_version", ""),
		"renderer": active.get("renderer", ""),
		"adapter": active.get("adapter", {}),
		"monitor_count": active.get("monitors", {}).size(),
		"custom_monitor_count": active.get("custom_monitors", {}).size(),
		"device": active.get("device", {}),
		"TIME_FPS": metrics.get("TIME_FPS", null),
		"TIME_PROCESS": metrics.get("TIME_PROCESS", null),
		"TIME_PHYSICS_PROCESS": metrics.get("TIME_PHYSICS_PROCESS", null),
		"RENDER_TOTAL_DRAW_CALLS_IN_FRAME": metrics.get("RENDER_TOTAL_DRAW_CALLS_IN_FRAME", null),
		"RENDER_TOTAL_OBJECTS_IN_FRAME": metrics.get("RENDER_TOTAL_OBJECTS_IN_FRAME", null),
		"RENDER_TOTAL_PRIMITIVES_IN_FRAME": metrics.get("RENDER_TOTAL_PRIMITIVES_IN_FRAME", null),
		"RENDER_VIDEO_MEM_USED": metrics.get("RENDER_VIDEO_MEM_USED", null),
		"RENDER_TEXTURE_MEM_USED": metrics.get("RENDER_TEXTURE_MEM_USED", null),
		"RENDER_BUFFER_MEM_USED": metrics.get("RENDER_BUFFER_MEM_USED", null),
		"OBJECT_ORPHAN_NODE_COUNT": metrics.get("OBJECT_ORPHAN_NODE_COUNT", null),
		"PIPELINE_COMPILATIONS_SPECIALIZATION": metrics.get("PIPELINE_COMPILATIONS_SPECIALIZATION", null),
		"viewport": view,
		"setting_count": active.get("settings", {}).size(),
	}


static func _error(message: String) -> Dictionary:
	return {
		"isError": true,
		"content": [{"type": "text", "text": message}]
	}
