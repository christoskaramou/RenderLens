extends RefCounted

const Pacing = preload("res://addons/render_lens/pacing.gd")

static func request(params: Dictionary, operation: String, timeout: float = 135.0) -> Dictionary:
	var debugger = params.get("_debugger_plugin")
	if debugger == null or not debugger.has_method("request_measurement"):
		return error("Start the game from the editor to measure it. Use source=editor explicitly for an editor-only capture.")
	var arguments := params.duplicate()
	for key in arguments.keys():
		if str(key).begins_with("_"):
			arguments.erase(key)
	arguments["source"] = "game"
	if operation == "frame_timing":
		arguments["_embedded_play_note"] = Pacing.current_embedded_play_note()
	return await debugger.request_measurement(operation, arguments, timeout)

## The message of a tool error result (its content texts), not the stringified content array.
static func error_text(response: Dictionary) -> String:
	var texts := PackedStringArray()
	for item in response.get("content", []):
		if typeof(item) == TYPE_DICTIONARY:
			texts.append(str(item.get("text", "")))
	return " ".join(texts)

static func error(message: String) -> Dictionary:
	return {"isError": true, "content": [{"type": "text", "text": message}]}
