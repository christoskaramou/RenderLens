extends Node

## scan_scene
## Counts lights, meshes, particles, decals, probes, and materials.
## Does not modify the scene.

const Game = preload("res://addons/render_lens/game_bridge.gd")
const FileHelper = preload("res://addons/render_lens/file_helper.gd")
const SceneScan = preload("res://addons/render_lens/scene_scan.gd")
const ProjectScan = preload("res://addons/render_lens/project_scan.gd")

static func execute(params: Dictionary) -> Dictionary:
	var scanned: Dictionary = await gather(params)
	if scanned.has("error") and str(scanned.get("error", "")) != "":
		return _error(str(scanned.error))
	var payload := {
		"applied": false,
		"scenes": scanned.get("scenes", []),
		"counts": scanned.get("counts", {}),
		"offenders": scanned.get("offenders", {}),
		"shader_scan": scanned.get("shader_scan", {}),
		"material_scan": scanned.get("material_scan", {}),
		"file_walk": scanned.get("file_walk", {}),
		"script_scan": scanned.get("script_scan", {}),
	}
	var path := FileHelper.write_json(payload, "scan_scene")
	if path.is_empty():
		return _error("Failed to write scan_scene JSON")
	var nonzero := {}
	var counts: Dictionary = payload.counts
	for key in counts.keys():
		if float(counts[key]) != 0.0:
			nonzero[key] = counts[key]
	return {
		"content": [{
			"type": "text",
			"text": JSON.stringify({
				"path": path,
				"applied": false,
				"scenes": payload.scenes,
				"nonzero_counts": nonzero,
				"offenders": payload.offenders,
				"shader_scan": payload.shader_scan,
				"material_scan": payload.material_scan,
				"file_walk": payload.file_walk,
				"script_scan": payload.script_scan,
			}, "\t")
		}]
	}


static func gather(params: Dictionary) -> Dictionary:
	var scene_path := str(params.get("scene", ""))
	if scene_path != "":
		return SceneScan.scan_path(scene_path)
	if Engine.is_editor_hint() and str(params.get("source", "game")) != "editor":
		var response: Dictionary = await Game.request(params, "scene_snapshot", 20.0)
		if response.get("isError", false):
			return {"error": Game.error_text(response)}
		# The game scanned only its nodes; project files are read here so a large project does not stall the game.
		var project := {"counts": response.get("counts", {}), "offenders": response.get("offenders", {})}
		ProjectScan.apply(project, false)
		for key in ["shader_scan", "script_scan", "file_walk"]:
			response[key] = project.get(key, {})
		return response
	return SceneScan.scan()


static func _error(message: String) -> Dictionary:
	return {
		"isError": true,
		"content": [{"type": "text", "text": message}]
	}
