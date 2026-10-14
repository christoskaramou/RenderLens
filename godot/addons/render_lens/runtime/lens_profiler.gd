extends EngineProfiler

## Registered with EngineDebugger.register_profiler from the game autoload.
## _tick receives the same frame, process, physics, and physics-frame times
## ServersDebugger::ServersProfiler stores in a ServersProfilerFrame header
## (core/debugger/engine_debugger.cpp iteration). It does not receive per-function
## script times. Those stay inside ScriptLanguage::profiling_get_frame_data,
## which GDScript cannot call.


var active := false
var target := 1
var samples: Array = []
var fallback_samples: Array = []
var ticked_this_frame := false


func _toggle(enable: bool, options: Array) -> void:
	active = enable
	ticked_this_frame = false
	if enable:
		samples.clear()
		fallback_samples.clear()
		if options.size() > 0:
			target = maxi(1, int(options[0]))


func _add_frame(_data: Array) -> void:
	pass


func _tick(frame_time: float, process_time: float, physics_time: float, physics_frame_time: float) -> void:
	if not active:
		return
	ticked_this_frame = true
	if samples.size() >= target:
		active = false
		return
	samples.append(_row(frame_time, process_time, physics_time, physics_frame_time))
	if samples.size() >= target:
		active = false


func add_fallback(frame_time: float, process_time: float, physics_time: float, physics_frame_time: float) -> void:
	if fallback_samples.size() >= target:
		return
	fallback_samples.append(_row(frame_time, process_time, physics_time, physics_frame_time))


func _row(frame_time: float, process_time: float, physics_time: float, physics_frame_time: float) -> Dictionary:
	return {
		"ok": true,
		"frame_time_sec": frame_time,
		"process_time_sec": process_time,
		"physics_time_sec": physics_time,
		"physics_frame_time_sec": physics_frame_time,
		"script_time_sec": 0.0,
		"servers": [],
		"script_functions": [],
	}
