extends SceneTree

var server

func _init() -> void:
	server = load("res://addons/render_lens/mcp_server.gd").new()
	server.tcp_server = TCPServer.new()
	var port := int(OS.get_environment("RENDER_LENS_TEST_PORT"))
	assert(server.tcp_server.listen(port, "127.0.0.1") == OK)
	server.is_running = true

func _process(delta: float) -> bool:
	server._process(delta)
	return false

func _finalize() -> void:
	server.stop_server()
	server.free()
