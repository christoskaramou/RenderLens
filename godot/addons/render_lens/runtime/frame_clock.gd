extends EngineProfiler

var sample: Dictionary = {}

func _toggle(_enabled: bool, _options: Array) -> void:
	sample = {}

func _add_frame(_data: Array) -> void:
	pass

func _tick(frame_time: float, process_time: float, physics_time: float, _physics_frame_time: float) -> void:
	sample = {"work_ms": frame_time * 1000.0, "process_ms": process_time * 1000.0, "physics_ms": physics_time * 1000.0}
