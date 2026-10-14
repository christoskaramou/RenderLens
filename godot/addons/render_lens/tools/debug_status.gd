extends Node

## debug_status Tool
## Diagnostics for debugger plugin status

static func execute(params: Dictionary) -> Dictionary:
	"""Execute debug_status tool"""
	var debugger_plugin = params.get("_debugger_plugin")
	
	if not debugger_plugin:
		return _build_error("Not available: the Render Lens debugger plugin is missing")
	
	var status: Dictionary = debugger_plugin.get_debug_status()
	
	return {
		"content": [{
			"type": "text",
			"text": JSON.stringify(status, "\t")
		}]
	}

static func _build_error(message: String) -> Dictionary:
	return {
		"isError": true,
		"content": [{
			"type": "text",
			"text": message
		}]
	}
