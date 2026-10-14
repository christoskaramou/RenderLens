extends Node

## stop_game Tool
## Stop the game session in the editor

const Context = preload("res://addons/render_lens/context.gd")

static func execute(params: Dictionary) -> Dictionary:
	"""Execute stop_game tool"""
	# In Godot 4.2+, EditorInterface is a global singleton class
	if not EditorInterface:
		return _build_error("EditorInterface not available (not running in editor)")
	
	# Check if playing
	if not EditorInterface.is_playing_scene():
		return _build_error("Game is not running")
	
	# Stop the game
	EditorInterface.stop_playing_scene()
	
	# Wait for game to stop (timeout after 3 seconds)
	var timeout := 3.0
	var elapsed := 0.0
	var delta := 0.1
	
	while elapsed < timeout:
		await Engine.get_main_loop().create_timer(delta).timeout
		elapsed += delta
		
		if not EditorInterface.is_playing_scene():
			return {
				"content": [{
					"type": "text",
					"text": JSON.stringify({
						"status": "stopped",
						"elapsed_ms": "%.0f" % (elapsed * 1000.0)
					}, "\t")
				}]
			}
	
	return _build_error("Game did not stop within timeout")

static func _build_error(message: String) -> Dictionary:
	return {
		"isError": true,
		"content": [{
			"type": "text",
			"text": message
		}]
	}
