extends Node

## MCP Streamable-HTTP Server
## Implements MCP protocol over HTTP/JSON-RPC on localhost

signal client_connected(client_id: String)
signal client_disconnected(client_id: String)
signal tool_called(tool_name: String, params: Dictionary)
signal log_message(level: String, message: String)

const PORT := 43788  # Uncommon port to avoid conflicts
const VERSION := "2.0.0"
const TOOL_TIMEOUT_SEC := 150.0
const LONGEST_TOOL_RUN_SEC := 615.0  # session_summary: 60 rows of 10 s plus setup
const QUEUE_MARGIN_SEC := 60.0
const SUPPORTED_PROTOCOLS := ["2024-11-05", "2025-03-26", "2025-06-18"]
const MAX_REQUEST_BYTES := 1048576
const WRITE_STALL_MS := 10000  # a client that accepts no bytes for this long is dropped

var tcp_server: TCPServer
var connected_clients := {}
var next_client_id := 0
var is_running := false
var oauth_shim: Node

# Async tool execution (non-blocking)
var pending_async_tools := []  # Queue of {client_peer, request_id, tool_name, tool_params, start_time}
var active_tool_execution: Dictionary = {}  # Current executing tool

# Debugger plugin (set by plugin.gd)
var debugger_plugin

# Protocol negotiation
var client_protocol_version := "2024-11-05"

func _init() -> void:
	oauth_shim = preload("res://addons/render_lens/oauth_shim.gd").new()
	add_child(oauth_shim)

func _ready() -> void:
	start_server()

func start_server() -> bool:
	if is_running:
		_log("warn", "Server already running")
		return false
	
	tcp_server = TCPServer.new()
	var err := tcp_server.listen(PORT, "127.0.0.1")
	
	if err != OK:
		_log("error", "Failed to start server on 127.0.0.1:%d: %s" % [PORT, error_string(err)])
		return false
	
	is_running = true
	_log("info", "MCP server started on http://127.0.0.1:%d" % PORT)
	
	set_process(true)
	return true

func stop_server() -> void:
	if not is_running:
		return
	
	set_process(false)
	
	# Disconnect all clients
	for client_id in connected_clients.keys():
		_disconnect_client(client_id)
	
	if tcp_server:
		tcp_server.stop()
		tcp_server = null
	
	is_running = false
	_log("info", "MCP server stopped")

func _process(_delta: float) -> void:
	if not is_running or not tcp_server:
		return
	
	# Process async tool queue
	_process_async_tool_queue()
	
	# Accept new connections
	if tcp_server.is_connection_available():
		var peer := tcp_server.take_connection()
		var client_id := str(next_client_id)
		next_client_id += 1
		
		connected_clients[client_id] = {
			"peer": peer,
			"buffer": PackedByteArray(),
			"out": PackedByteArray(),
			"close_after": false,
			"write_progress_ms": 0,
			"connected_at": Time.get_unix_time_from_system()
		}
		
		_log("info", "Client %s connected" % client_id)
		client_connected.emit(client_id)
	
	# Process existing connections
	var clients_to_remove := []
	
	for client_id in connected_clients.keys():
		var client_data: Dictionary = connected_clients[client_id]
		var peer: StreamPeerTCP = client_data.peer
		
		# get_status() is cached until poll(); poll() also notices a closed peer.
		peer.poll()
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			clients_to_remove.append(client_id)
			continue
		
		# Read available data (every response closes the connection, so nothing more is read once one is queued)
		var available := peer.get_available_bytes()
		if available > 0 and not client_data.close_after:
			var chunk := peer.get_data(available)
			if chunk[0] == OK:
				client_data.buffer.append_array(chunk[1])
				
				# Try to parse HTTP request
				_process_client_buffer(client_id, client_data)
		
		if not _flush_client(client_data) or (client_data.close_after and client_data.out.is_empty()):
			clients_to_remove.append(client_id)
	
	# Clean up disconnected clients
	for client_id in clients_to_remove:
		_disconnect_client(client_id)

func _process_client_buffer(_client_id: String, client_data: Dictionary) -> void:
	var buffer: PackedByteArray = client_data.buffer
	if buffer.size() > MAX_REQUEST_BYTES:
		_send_error_response(client_data.peer, 413, "Request too large")
		return
	# Headers are ASCII; decode the body only after all Content-Length bytes arrive.
	var buffer_str := buffer.get_string_from_ascii()
	
	# Look for HTTP request end (double CRLF)
	var header_end := buffer_str.find("\r\n\r\n")
	if header_end == -1:
		return  # Not enough data yet
	
	# Parse HTTP request
	var request_result := _parse_http_request(buffer_str, header_end)
	if not request_result:
		_send_error_response(client_data.peer, 400, "Bad Request")
		client_data.buffer.clear()
		return
	
	var method: String = request_result.method
	var path: String = request_result.path
	var query := ""
	if "?" in path:
		query = path.substr(path.find("?") + 1)
		path = path.substr(0, path.find("?"))
	var headers: Dictionary = request_result.headers
	var body: String = request_result.body
	if headers.has("transfer-encoding"):
		_send_error_response(client_data.peer, 400, "Transfer-Encoding is not supported")
		return
	var length_text := str(headers.get("content-length", "0"))
	if not length_text.is_valid_int() or int(length_text) < 0 or int(length_text) > MAX_REQUEST_BYTES:
		_send_error_response(client_data.peer, 400, "Invalid Content-Length")
		return
	var request_end := header_end + 4 + int(length_text)
	if buffer.size() < request_end:
		return
	body = buffer.slice(header_end + 4, request_end).get_string_from_utf8()
	
	# Origin check (loopback only)
	if headers.has("origin"):
		var origin: String = headers.origin
		if not _local_origin(origin):
			_log("warn", "Rejected non-localhost Origin: %s" % origin)
			_send_error_response(client_data.peer, 403, "Forbidden: non-localhost origin")
			return
	
	# Route request
	var response := ""
	if method == "GET" and path == "/oauth/authorize":
		response = oauth_shim.handle_authorize_request(query)
	elif method == "POST" and path == "/oauth/token":
		response = oauth_shim.handle_token_request()
	elif method == "POST" and (path == "/" or path == "/mcp"):
		var jsonrpc_result: Dictionary = _handle_jsonrpc_request_parsed(body, headers)
		
		# Check if this is an async tool call that needs queueing
		if jsonrpc_result.has("__async_queued"):
			_queue_async_tool(client_data.peer, jsonrpc_result.request_id, jsonrpc_result.tool_name, jsonrpc_result.tool_params, headers)
			# Don't send response yet - will send when tool completes
			client_data.buffer.clear()
			return
		else:
			response = jsonrpc_result.http_response
	elif method == "OPTIONS":
		response = _build_http_response(204, "No Content", "text/plain", "", headers)
	elif method == "GET" and (path == "/" or path == "/mcp"):
		# Streamable HTTP: a server without a server-initiated SSE stream answers GET with 405.
		response = _build_http_response(405, "Method Not Allowed", "text/plain", "Method Not Allowed", headers).replace("Connection: close\r\n", "Allow: POST, OPTIONS\r\nConnection: close\r\n")
	else:
		response = _build_http_response(404, "Not Found", "text/plain", "Not Found")
	
	# Send response
	_send(client_data.peer, response)
	
	# Clear buffer
	client_data.buffer.clear()

static func _local_origin(origin: String) -> bool:
	var pattern := RegEx.new()
	pattern.compile("^http://(localhost|127\\.0\\.0\\.1|\\[::1\\])(:[0-9]{1,5})?$")
	if pattern.search(origin) == null:
		return false
	var authority := origin.trim_prefix("http://")
	var port := authority.rsplit(":", true, 1)
	return port.size() == 1 or authority.ends_with("]") or (int(port[1]) > 0 and int(port[1]) <= 65535)

func _parse_http_request(request_str: String, header_end: int) -> Dictionary:
	var lines := request_str.substr(0, header_end).split("\r\n")
	if lines.size() == 0:
		return {}
	
	# Parse request line
	var request_line := lines[0].split(" ")
	if request_line.size() < 2:
		return {}
	
	var method := request_line[0]
	var path := request_line[1]
	
	# Parse headers
	var headers := {}
	for i in range(1, lines.size()):
		var line := lines[i]
		var colon_pos := line.find(":")
		if colon_pos > 0:
			var key := line.substr(0, colon_pos).strip_edges().to_lower()
			var value := line.substr(colon_pos + 1).strip_edges()
			headers[key] = value
	
	# Extract body
	var body_start := header_end + 4  # Skip \r\n\r\n
	var body := request_str.substr(body_start)
	
	return {
		"method": method,
		"path": path,
		"headers": headers,
		"body": body
	}

func _handle_jsonrpc_request_parsed(body: String, headers: Dictionary) -> Dictionary:
	"""Parse JSON-RPC request and return either HTTP response or async queue info"""
	# Parse JSON-RPC request
	var json := JSON.new()
	var parse_result := json.parse(body)
	
	if parse_result != OK:
		return {"http_response": _build_jsonrpc_error_response(null, -32700, "Parse error", 400)}
	
	if typeof(json.data) != TYPE_DICTIONARY:
		return {"http_response": _build_jsonrpc_error_response(null, -32600, "Expected one JSON-RPC object", 400)}
	var request: Dictionary = json.data
	
	if not request.has("jsonrpc") or request.jsonrpc != "2.0":
		return {"http_response": _build_jsonrpc_error_response(request.get("id"), -32600, "Invalid Request: missing jsonrpc 2.0")}
	
	if not request.has("method"):
		return {"http_response": _build_jsonrpc_error_response(request.get("id"), -32600, "Invalid Request: missing method")}
	
	if typeof(request.method) != TYPE_STRING or typeof(request.get("params", {})) != TYPE_DICTIONARY:
		return {"http_response": _build_jsonrpc_error_response(request.get("id"), -32600, "Invalid method or params")}
	var method: String = request.method
	var params = request.get("params", {})
	var request_id = request.get("id")
	# MCP 2025-06-18: an invalid or unsupported MCP-Protocol-Version is a 400. initialize negotiates in its body, so it is exempt.
	if method != "initialize" and headers.has("mcp-protocol-version") and not str(headers["mcp-protocol-version"]) in SUPPORTED_PROTOCOLS:
		return {"http_response": _build_jsonrpc_error_response(request_id, -32000, "Bad Request: unsupported MCP-Protocol-Version: %s" % headers["mcp-protocol-version"], 400)}
	if not request.has("id"):
		return {"http_response": _build_http_response(202, "Accepted", "application/json", "", headers)}
	
	# Handle MCP methods
	var result
	
	match method:
		"initialize":
			result = _handle_initialize(params)
		"tools/list":
			result = _handle_tools_list(params)
		"tools/call":
			result = _handle_tools_call(params)
		"prompts/list":
			result = _handle_prompts_list(params)
		"resources/list":
			result = _handle_resources_list(params)
		"ping":
			result = _handle_ping(params)
		_:
			return {"http_response": _build_jsonrpc_error_response(request_id, -32601, "Method not found: %s" % method)}
	
	# Check if async tool
	if result is Dictionary and result.has("__async_queued"):
		return {
			"__async_queued": true,
			"request_id": request_id,
			"tool_name": result.tool_name,
			"tool_params": result.tool_params
		}
	
	# Build JSON-RPC response
	return {"http_response": _build_jsonrpc_success_response(request_id, result, headers)}

func _handle_initialize(params: Dictionary) -> Dictionary:
	# Negotiate protocol version
	var requested_version := str(params.get("protocolVersion", "2024-11-05"))
	
	# MCP: answer the requested version when supported, otherwise the latest supported one.
	client_protocol_version = requested_version if requested_version in SUPPORTED_PROTOCOLS else SUPPORTED_PROTOCOLS.back()

	_log("info", "MCP client initialized (protocol: %s)" % client_protocol_version)

	var project := _project_info()
	return {
		"protocolVersion": client_protocol_version,
		"serverInfo": {
			"name": "render-lens",
			"version": VERSION
		},
		"instructions": "Render Lens is attached to project \"%s\" at %s. If this is not the project you meant, another editor owns port %d." % [project.name, project.path, PORT],
		"capabilities": {
			"tools": {},
			"prompts": {},
			"resources": {}
		}
	}

func _handle_tools_list(_params: Dictionary) -> Dictionary:
	var listed := {
		"tools": [
			{
				"name": "ping_render_lens",
				"description": "Ping the Render Lens MCP server to verify connectivity",
				"inputSchema": {
					"type": "object",
					"properties": {},
					"required": []
				}
			},
			{
				"name": "render_stats",
				"description": "Get current rendering statistics: draw calls, objects, primitives, VRAM, with VISIBLE/SHADOW/CANVAS split",
				"inputSchema": {
					"type": "object",
					"properties": {},
					"required": []
				}
			},
			{
				"name": "frame_timing",
				"description": "Measure GPU/CPU frame timing with warm-up, percentiles, and target-FPS budget analysis. The game runs with V-Sync and max_fps off while sampling and gets its own values back afterwards.",
				"inputSchema": {
					"type": "object",
					"properties": {
						"frames": {
							"type": "integer",
							"description": "Number of frames to measure (10-1000)",
							"default": 120
						},
						"warmup": {
							"type": "integer",
							"description": "Warm-up frames to drop (0-frames)",
							"default": 10
						},
						"target_fps": {
							"type": "integer",
							"description": "Target FPS for budget analysis (1-240)",
							"default": 60
						}
					},
					"required": []
				}
			},
			{
				"name": "capture_viewport",
				"description": "Capture viewport as PNG with optional debug draw modes (normal, overdraw)",
				"inputSchema": {
					"type": "object",
					"properties": {
						"settle_frames": {
							"type": "integer",
							"description": "Frames to wait before capture (0-30)",
							"default": 2
						},
						"debug_draw": {
							"type": "string",
							"description": "Debug draw mode: normal, overdraw",
							"enum": ["normal", "overdraw"],
							"default": "normal"
						},
						"max_width": {
							"type": "integer",
							"description": "Maximum width for captured image",
							"default": 1920
						}
					},
					"required": []
				}
			},
			{
				"name": "audit_project_rendering",
				"description": "Evaluate the static rule set (project settings and a scene scan). Findings come in areas, listed in this order: performance, visual (optional quality upgrades) and missing (nodes or resources that are absent or misconfigured); area_counts gives each total. Writes the full finding list. Does not change the project.",
				"inputSchema": {
					"type": "object",
					"properties": {
						"scene": {
							"type": "string",
							"description": "Optional res:// scene to scan. Default scans the scene open in the editor, or the main scene when none is open."
						},
						"top": {
							"type": "integer",
							"description": "How many findings to return inline from each area (1-80). The file contains the full list.",
							"default": 20
						},
						"focus": {
							"type": "string",
							"description": "Return only one area inline: performance, visual, missing or to_check. all returns every area in that order, with a short preview of to_check.",
							"enum": ["all", "performance", "visual", "missing", "to_check"],
							"default": "all"
						}
					},
					"required": []
				}
			},
			{
				"name": "collect_metrics",
				"description": "Snapshot every Performance monitor, RenderingServer counter, and rendering project setting from the running game or editor, in both packages.",
				"inputSchema": {
					"type": "object",
					"properties": {
						"source": {
							"type": "string",
							"description": "auto (game if a session is active, otherwise editor), editor, or game",
							"enum": ["auto", "editor", "game"],
							"default": "auto"
						}
					},
					"required": []
				}
			},
			{
				"name": "scan_scene",
				"description": "Count lights, shadows, meshes, particles, decals, probes, GI, and materials. Returns counts and offender node paths. Does not change the scene.",
				"inputSchema": {
					"type": "object",
					"properties": {
						"scene": {
							"type": "string",
							"description": "Optional res:// scene for a static scan. Default scans the running game's scene and its autoloads."
						}
					},
					"required": []
				}
			},
			{
				"name": "gpu_passes",
				"description": "Per-pass GPU timing (Forward+/Mobile only, requires running game). The game runs with V-Sync and max_fps off while recording and gets its own values back afterwards.",
				"inputSchema": {
					"type": "object",
					"properties": {
						"frames": {
							"type": "integer",
							"description": "Number of frames to measure (10-300)",
							"default": 60
						}
					},
					"required": []
				}
			},
			{
				"name": "measure_change",
				"description": "Try a change in the running game only and measure what it saves: frame and GPU time before, with the change, and after restoring it (the drift between the two 'before' captures is the noise), plus the GPU passes that moved. Nothing in the project is changed. Pass finding (the id of an advise finding that offers an experiment) or changes. GPU times need Forward+ or Mobile.",
				"inputSchema": {
					"type": "object",
					"properties": {
						"finding": {
							"type": "string",
							"description": "Id of an advise finding with a ready-made experiment (its experiment field), for example pass.ssr or shadows.omni_shadow_count"
						},
						"changes": {
							"type": "array",
							"items": {"type": "object"},
							"description": "Changes to try, each {value} plus one target: {node: path from the scene root, property}, {class: node class or script class_name, property} (every such node), {environment: true, property} (every Environment in use), {camera_attributes: true, property}, {viewport: true, property} (the root viewport), or {setting: project setting path} for settings a running game can change. Only the rendering properties advice suggests can change (light shadows and fades, environment effects, depth of field, camera far, geometry shadow and LOD, decal fade and size, material transparency/culling/filtering, viewport anti-aliasing and scaling), plus visible on 3D nodes; a refusal lists them. property may be indexed (environment:ssr_enabled); only_above: n changes only objects whose current value is above n. Values are JSON scalars; a value Godot refuses fails the experiment."
						},
						"frames": {
							"type": "integer",
							"description": "Frames per capture (10-300); each of the three captures times this many frames and GPU passes",
							"default": 60
						},
						"settle_seconds": {
							"type": "number",
							"description": "Wait after applying and after restoring, so shader compiles and temporal effects settle (0-10)",
							"default": 1.0
						}
					},
					"required": []
				}
			},
			{
				"name": "stutter_report",
				"description": "Detect and attribute stutters/hitches over time",
				"inputSchema": {
					"type": "object",
					"properties": {
						"seconds": {
							"type": "number",
							"description": "Duration to monitor (5-120 seconds)",
							"default": 30.0
						}
					},
					"required": []
				}
			},
			{
				"name": "advise",
				"description": "Combine live game measurements, taken with V-Sync and max_fps off, and sourced rules. Findings come in four areas, listed in this order: performance (measured costs, one entry per measured GPU pass with the other rules for that pass under same_pass), visual (optional quality upgrades), missing (nodes or resources that are absent or misconfigured) and to_check (candidates no measurement in this run ties to a cost; collapsed to a short preview unless focus is to_check); area_counts gives each total. CPU waits are not attributed to nodes. Does not edit the project or require validation layers.",
				"inputSchema": {
					"type": "object",
					"properties": {
						"target_fps": {
							"type": "integer",
							"description": "Target FPS for the frame budget (15-240)",
							"default": 60
						},
						"top": {
							"type": "integer",
							"description": "How many suggestions to return inline from each area (1-40). The file contains the full list.",
							"default": 8
						},
						"focus": {
							"type": "string",
							"description": "Return only one area inline: performance, visual, missing or to_check. all returns every area in that order, with a short preview of to_check.",
							"enum": ["all", "performance", "visual", "missing", "to_check"],
							"default": "all"
						},
						"timing_frames": {
							"type": "integer",
							"description": "frame_timing sample count",
							"default": 40
						},
						"pass_frames": {
							"type": "integer",
							"description": "gpu_passes sample count when a game is running",
							"default": 30
						},
						"profile_frames": {
							"type": "integer",
							"description": "Script profiler sample count (1-120)",
							"default": 12
						},
					},
					"required": []
				}
			},
			{
				"name": "script_profile",
				"description": "While a game is running, records frame/process/physics time with an EngineProfiler in the game and, when the debugger session can deliver them, the servers profiler function rows. Does not search the editor UI for the debugger panel. Does not change the project.",
				"inputSchema": {
					"type": "object",
					"properties": {
						"frames": {
							"type": "integer",
							"description": "Profile frames to keep (1-120)",
							"default": 20
						},
						"max_functions": {
							"type": "integer",
							"description": "Max script functions requested per frame (16-512)",
							"default": 32
						},
						"include_visual": {
							"type": "boolean",
							"description": "Also toggle the visual profiler. Leave false while gpu_passes is recording.",
							"default": false
						}
					},
					"required": []
				}
			},
			{
				"name": "vram_report",
				"description": "While a game is running, lists resources from the game (texture size and format, mesh vertex buffers, RenderingServer.get_rendering_info). Uses the debugger Video RAM list when the session delivers servers:memory_usage. Does not search the editor UI. Does not change the project.",
				"inputSchema": {
					"type": "object",
					"properties": {},
					"required": []
				}
			},
			{
				"name": "capture_compare",
				"description": "Compare two captures for regressions (exit codes: 0=pass, 1=regression, 2=degradation)",
				"inputSchema": {
					"type": "object",
					"properties": {
						"baseline": {
							"type": "string",
							"description": "Path to baseline capture JSON, inside res://.render_lens/captures/"
						},
						"current": {
							"type": "string",
							"description": "Path to current capture JSON, inside res://.render_lens/captures/"
						}
					},
					"required": ["baseline", "current"]
				}
			},
			{
				"name": "session_summary",
				"description": "Record session timeline with 10s rows and trend analysis",
				"inputSchema": {
					"type": "object",
					"properties": {
						"duration": {
							"type": "number",
							"description": "Duration in seconds (30-600)",
							"default": 300.0
						}
					},
					"required": []
				}
			},
			{
				"name": "run_game",
				"description": "Start the game session in the editor (for testing gpu_passes/stutter_report/session_summary)",
				"inputSchema": {
					"type": "object",
					"properties": {
						"use_main_scene": {
							"type": "boolean",
							"description": "Start main scene (true) or current scene (false)",
							"default": true
						}
					},
					"required": []
				}
			},
			{
				"name": "stop_game",
				"description": "Stop the game session in the editor",
				"inputSchema": {
					"type": "object",
					"properties": {},
					"required": []
				}
			},
			{
				"name": "debug_status",
				"description": "Get debugger plugin diagnostics (debugger session count, ready state, last messages)",
				"inputSchema": {
					"type": "object",
					"properties": {},
					"required": []
				}
			}
		]
	}
	for definition in listed.tools:
		definition.inputSchema["additionalProperties"] = false
		if definition.name in ["frame_timing", "render_stats", "capture_viewport", "stutter_report", "session_summary", "scan_scene"]:
			definition.inputSchema.properties["source"] = {"type": "string", "enum": ["game", "editor"], "default": "game", "description": "Measure the running game, or explicitly inspect the editor"}
	listed.tools = listed.tools.filter(func(tool):
		return tool.name == "ping_render_lens" or FileAccess.file_exists("res://addons/render_lens/tools/%s.gd" % tool.name))
	return listed

func _handle_tools_call(params: Dictionary) -> Dictionary:
	if not params.has("name"):
		return _build_tool_error("Missing tool name")
	if typeof(params.name) != TYPE_STRING or typeof(params.get("arguments", {})) != TYPE_DICTIONARY:
		return _build_tool_error("Tool name must be a string and arguments must be an object")
	
	var tool_name: String = params.name
	var tool_params: Dictionary = params.get("arguments", {})
	var available := false
	for definition in _handle_tools_list({}).tools:
		if definition.name != tool_name:
			continue
		available = true
		for required in definition.inputSchema.get("required", []):
			if not tool_params.has(required):
				return _build_tool_error("Missing argument: %s" % required)
		for key in tool_params:
			if str(key).begins_with("_"):
				return _build_tool_error("Internal arguments are not accepted")
			var spec: Dictionary = definition.inputSchema.get("properties", {}).get(key, {})
			if spec.is_empty():
				return _build_tool_error("Unknown argument: %s" % key)
			var value = tool_params[key]
			if spec.has("enum") and not spec.enum.has(value):
				return _build_tool_error("Invalid value for %s" % key)
			match str(spec.get("type", "")):
				"integer", "number":
					if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)):
						return _build_tool_error("%s must be a finite number" % key)
					if spec.type == "integer" and float(value) != floor(float(value)):
						return _build_tool_error("%s must be an integer" % key)
				"string":
					if typeof(value) != TYPE_STRING:
						return _build_tool_error("%s must be a string" % key)
				"boolean":
					if typeof(value) != TYPE_BOOL:
						return _build_tool_error("%s must be a boolean" % key)
				"array":
					if typeof(value) != TYPE_ARRAY:
						return _build_tool_error("%s must be an array" % key)
	if not available:
		return _build_tool_error("Tool unavailable in this package: %s" % tool_name)
	
	_log("info", "Tool called: %s" % tool_name)
	tool_called.emit(tool_name, tool_params)
	
	# Inject debugger plugin reference for tools that need it
	if tool_name in ["gpu_passes", "measure_change", "stutter_report", "session_summary", "debug_status", "collect_metrics", "advise", "script_profile", "vram_report", "frame_timing", "render_stats", "capture_viewport", "scan_scene"]:
		tool_params["_debugger_plugin"] = debugger_plugin
	
	# Inject for run_game to check session status
	if tool_name == "run_game":
		tool_params["_debugger_plugin"] = debugger_plugin
	
	# Sync tools (immediate)
	match tool_name:
		"ping_render_lens":
			return _tool_ping()
		"audit_project_rendering":
			return _call_tool_script("audit_project_rendering", tool_params)
	
	# More sync tools (immediate)
	if tool_name == "debug_status":
		return _call_tool_script("debug_status", tool_params)
	
	# Async tools (need main thread + await)
	match tool_name:
		"render_stats", "scan_scene", "frame_timing", "capture_viewport", "gpu_passes", "measure_change", "stutter_report", "advise", "capture_compare", "session_summary", "run_game", "stop_game", "collect_metrics", "script_profile", "vram_report":
			# Queue for async execution, return immediately
			return {"__async_queued": true, "tool_name": tool_name, "tool_params": tool_params}
		_:
			return _build_tool_error("Unknown tool: %s" % tool_name)

func _queue_async_tool(peer: StreamPeerTCP, request_id: Variant, tool_name: String, tool_params: Dictionary, headers: Dictionary) -> void:
	"""Queue an async tool for execution"""
	pending_async_tools.append({
		"peer": peer,
		"request_id": request_id,
		"tool_name": tool_name,
		"tool_params": tool_params,
		"headers": headers,
		"start_time": Time.get_ticks_msec()
	})
	_log("info", "Queued async tool: %s" % tool_name)

func _process_async_tool_queue() -> void:
	"""Process async tool queue (called from _process)"""
	# Check for timeouts
	var now := Time.get_ticks_msec()
	# Queued work waits for the active tool, which may legitimately run as long as the longest tool.
	var timeout_ms := maxf(TOOL_TIMEOUT_SEC, LONGEST_TOOL_RUN_SEC + QUEUE_MARGIN_SEC) * 1000
	
	var i := 0
	while i < pending_async_tools.size():
		var task: Dictionary = pending_async_tools[i]
		var elapsed: int = now - task.start_time
		
		if not _peer_connected(task.peer):
			# The client gave up (and may have retried); a 300 s session_summary nobody reads would block the retry.
			_log("info", "Dropped queued tool %s: its client disconnected" % task.tool_name)
			pending_async_tools.remove_at(i)
		elif elapsed > timeout_ms:
			_log("error", "Tool timeout: %s (%.1fs)" % [task.tool_name, elapsed / 1000.0])
			var busy := str(active_tool_execution.get("tool_name", "another tool"))
			var error_result := _build_tool_error("%s did not run: %s was still running after %.0f s. Call it again when that finishes, or call stop_game to end the measurement." % [task.tool_name, busy, elapsed / 1000.0])
			var response := _build_jsonrpc_success_response(task.request_id, error_result, task.headers)
			_send(task.peer, response)
			pending_async_tools.remove_at(i)
		elif task.tool_name == "stop_game" and not active_tool_execution.is_empty():
			# Stopping the game is how a long measurement is cut short, so it must not wait behind one.
			pending_async_tools.remove_at(i)
			_run_beside_active_tool(task)
		else:
			i += 1

	# Start next tool if none active
	if active_tool_execution.is_empty() and not pending_async_tools.is_empty():
		var task: Dictionary = pending_async_tools.pop_front()
		active_tool_execution = task
		_execute_async_tool_deferred()

func _execute_async_tool_deferred() -> void:
	"""Execute the active async tool"""
	if active_tool_execution.is_empty():
		return
	
	var tool_name: String = active_tool_execution.tool_name
	var tool_params: Dictionary = active_tool_execution.tool_params
	
	_log("info", "Executing async tool: %s" % tool_name)
	
	var script_path := "res://addons/render_lens/tools/%s.gd" % tool_name
	
	if not FileAccess.file_exists(script_path):
		_finish_async_tool(_build_tool_error("Tool script not found: %s" % script_path))
		return
	
	var tool_script := load(script_path)
	if not tool_script or not tool_script.has_method("execute"):
		_finish_async_tool(_build_tool_error("Invalid tool script: %s" % script_path))
		return
	
	# Execute (may await)
	var result = await tool_script.execute(tool_params)
	_finish_async_tool(result)

func _finish_async_tool(result) -> void:
	"""Finish async tool execution and send response"""
	if active_tool_execution.is_empty():
		return
	var task := active_tool_execution
	active_tool_execution = {}
	_respond(task, result)


func _run_beside_active_tool(task: Dictionary) -> void:
	_respond(task, await load("res://addons/render_lens/tools/%s.gd" % task.tool_name).execute(task.tool_params))


func _respond(task: Dictionary, result) -> void:
	var elapsed: int = Time.get_ticks_msec() - task.start_time
	_log("info", "Tool completed: %s (%.1fs)" % [task.tool_name, elapsed / 1000.0])
	var response := _build_jsonrpc_success_response(task.request_id, _checked_result(task.tool_name, result), task.headers)
	_send(task.peer, response)


## A script error inside a tool makes its typed execute() return {}; report that instead of an empty success.
func _checked_result(tool_name: String, result) -> Dictionary:
	if typeof(result) == TYPE_DICTIONARY and result.get("content") is Array and not result.content.is_empty():
		return result
	return _build_tool_error("%s stopped with a script error; the editor's Output panel has the details." % tool_name)

func _call_tool_script(tool_name: String, tool_params: Dictionary) -> Dictionary:
	"""Call a tool script synchronously"""
	var script_path := "res://addons/render_lens/tools/%s.gd" % tool_name
	
	if not FileAccess.file_exists(script_path):
		return _build_tool_error("Tool script not found: %s" % script_path)
	
	var tool_script := load(script_path)
	if not tool_script:
		return _build_tool_error("Failed to load tool script: %s" % script_path)
	
	if not tool_script.has_method("execute"):
		return _build_tool_error("Tool script missing execute() method: %s" % script_path)
	
	return _checked_result(tool_name, tool_script.execute(tool_params))

static func _project_info() -> Dictionary:
	return {
		"name": str(ProjectSettings.get_setting("application/config/name", "")),
		"path": ProjectSettings.globalize_path("res://")
	}

func _tool_ping() -> Dictionary:
	return {
		"content": [
			{
				"type": "text",
				"text": JSON.stringify({
					"ok": true,
					"version": VERSION,
					"project": _project_info(),
					"timestamp": Time.get_unix_time_from_system()
				}, "\t")
			}
		]
	}

func _handle_prompts_list(_params: Dictionary) -> Dictionary:
	# Stub for M1; skill packs in M4
	return {
		"prompts": []
	}

func _handle_resources_list(_params: Dictionary) -> Dictionary:
	# Stub for M1
	return {
		"resources": []
	}

func _handle_ping(_params: Dictionary) -> Dictionary:
	return {"status": "ok"}

func _build_tool_error(error_message: String) -> Dictionary:
	# MCP rule: tool errors as isError, NOT JSON-RPC errors
	return {
		"isError": true,
		"content": [
			{
				"type": "text",
				"text": error_message
			}
		]
	}

func _build_jsonrpc_success_response(request_id, result, headers: Dictionary) -> String:
	var response_data := {
		"jsonrpc": "2.0",
		"id": request_id,
		"result": result
	}
	
	var body := JSON.stringify(response_data)
	var status_code := 200
	var content_type := "application/json"
	
	return _build_http_response(status_code, "OK", content_type, body, headers)

## A JSON-RPC error answers a request the transport accepted, so it is HTTP 200; only a body that is not a JSON-RPC object is a transport 400.
func _build_jsonrpc_error_response(request_id, code: int, message: String, http_status := 200) -> String:
	var response_data := {
		"jsonrpc": "2.0",
		"id": request_id,
		"error": {
			"code": code,
			"message": message
		}
	}
	
	var body := JSON.stringify(response_data)
	return _build_http_response(http_status, "OK" if http_status == 200 else "Bad Request", "application/json", body)

func _build_http_response(status_code: int, status_text: String, content_type: String, body: String, request_headers: Dictionary = {}) -> String:
	var response := "HTTP/1.1 %d %s\r\n" % [status_code, status_text]
	response += "Content-Type: %s\r\n" % content_type
	response += "Content-Length: %d\r\n" % body.to_utf8_buffer().size()
	response += "Connection: close\r\n"
	
	# CORS headers for local development
	if request_headers.has("origin"):
		response += "Access-Control-Allow-Origin: %s\r\n" % request_headers.origin
		response += "Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n"
		response += "Access-Control-Allow-Headers: Content-Type, MCP-Protocol-Version\r\n"
	
	response += "\r\n"
	response += body
	
	return response

func _build_cors_preflight_response() -> String:
	return _build_http_response(204, "No Content", "text/plain", "")

func _send_error_response(peer: StreamPeerTCP, status_code: int, message: String) -> void:
	var response := _build_http_response(status_code, message, "text/plain", message)
	_send(peer, response)

## The only place a response is written: queued here, flushed without blocking from _process, then the connection closes.
func _send(peer: StreamPeerTCP, response: String) -> void:
	for client_data in connected_clients.values():
		if client_data.peer == peer:
			if client_data.out.is_empty():
				client_data.write_progress_ms = Time.get_ticks_msec()
			client_data.out.append_array(response.to_utf8_buffer())
			client_data.close_after = true
			client_data.buffer.clear()
			return

func _peer_connected(peer) -> bool:
	if peer is StreamPeerTCP:
		peer.poll()  # the queue runs before _process polls the clients; get_status() is cached until poll()
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			return false
	for client_data in connected_clients.values():
		if client_data.peer == peer:
			return true
	return false

## Returns false when the connection failed or the client stopped reading for WRITE_STALL_MS.
func _flush_client(client_data: Dictionary) -> bool:
	if client_data.out.is_empty():
		return true
	var result: Array = client_data.peer.put_partial_data(client_data.out)
	if result[0] != OK:
		return false
	if result[1] > 0:
		client_data.out = client_data.out.slice(result[1])
		client_data.write_progress_ms = Time.get_ticks_msec()
	return client_data.out.is_empty() or Time.get_ticks_msec() - client_data.write_progress_ms < WRITE_STALL_MS

func _disconnect_client(client_id: String) -> void:
	if not connected_clients.has(client_id):
		return
	
	var client_data: Dictionary = connected_clients[client_id]
	var peer: StreamPeerTCP = client_data.peer
	peer.disconnect_from_host()
	
	connected_clients.erase(client_id)
	_log("info", "Client %s disconnected" % client_id)
	client_disconnected.emit(client_id)

func _log(level: String, message: String) -> void:
	var prefix := "[Render Lens MCP]"
	
	# Guard against being called after removal from tree
	if not is_inside_tree():
		match level:
			"error":
				push_error("%s %s" % [prefix, message])
			"warn":
				push_warning("%s %s" % [prefix, message])
			_:
				print("%s %s" % [prefix, message])
		return
	
	match level:
		"error":
			push_error("%s %s" % [prefix, message])
		"warn":
			push_warning("%s %s" % [prefix, message])
		_:
			print("%s %s" % [prefix, message])
	
	log_message.emit(level, message)

func get_port() -> int:
	return PORT

func get_connected_client_count() -> int:
	return connected_clients.size()
