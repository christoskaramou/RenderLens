@tool
extends VBoxContainer

## Dock Panel for Render Lens MCP Server
## Shows status, configuration, and tool log

var mcp_server: Node
const MAX_LOG_LINES := 500

@onready var status_value: Label = %StatusValue
@onready var port_value: Label = %PortValue
@onready var clients_value: Label = %ClientsValue
@onready var config_text: TextEdit = %ConfigText
@onready var log_text: TextEdit = %LogText

func _ready() -> void:
	if not mcp_server:
		return
	
	# Connect signals
	mcp_server.client_connected.connect(_on_client_connected)
	mcp_server.client_disconnected.connect(_on_client_disconnected)
	mcp_server.tool_called.connect(_on_tool_called)
	mcp_server.log_message.connect(_on_log_message)
	
	# Update initial status
	_update_status()
	
	# Update status periodically
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_update_status)
	add_child(timer)
	timer.start()

func _update_status() -> void:
	if not mcp_server:
		return
	
	if mcp_server.is_running:
		status_value.text = "Running"
		status_value.modulate = Color.GREEN
	else:
		status_value.text = "Stopped"
		status_value.modulate = Color.RED
	
	port_value.text = str(mcp_server.get_port())
	clients_value.text = str(mcp_server.get_connected_client_count())
	
	# Update config text with current port
	var config := {
		"mcpServers": {
			"render-lens": {
				"url": "http://127.0.0.1:%d" % mcp_server.get_port()
			}
		}
	}
	config_text.text = JSON.stringify(config, "\t")

func _on_client_connected(client_id: String) -> void:
	_add_log("Client %s connected" % client_id)

func _on_client_disconnected(client_id: String) -> void:
	_add_log("Client %s disconnected" % client_id)

func _on_tool_called(tool_name: String, params: Dictionary) -> void:
	_add_log("Tool called: %s" % tool_name)

func _on_log_message(level: String, message: String) -> void:
	_add_log("[%s] %s" % [level.to_upper(), message])

func _add_log(message: String) -> void:
	var timestamp := Time.get_datetime_string_from_system()
	var log_line := "[%s] %s\n" % [timestamp, message]
	
	var lines := (log_text.text + log_line).split("\n")
	log_text.text = "\n".join(lines.slice(maxi(0, lines.size() - MAX_LOG_LINES)))
	# Setting text records an undo step holding the whole log (TextEdit::_set_text).
	log_text.clear_undo_history()
	
	# Auto-scroll to bottom
	await get_tree().process_frame
	log_text.scroll_vertical = log_text.get_line_count()
