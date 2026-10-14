extends RefCounted

## Parsers for the debugger payloads Godot's ServersDebugger serializes.
## ResourceUsage and ServersProfilerFrame in
## servers/debugger/servers_debugger.cpp (4.4-stable and 4.7.2-stable).
## Script function times in that file are microseconds divided by 1000000.


static func parse_memory_usage(data: Array) -> Dictionary:
	if data.is_empty():
		return {"ok": false, "error": "empty memory message", "resources": [], "total_bytes": 0, "count": 0}
	var declared := int(data[0])
	if declared % 4 != 0:
		return {"ok": false, "error": "ResourceUsage size is not a multiple of 4", "resources": [], "total_bytes": 0, "count": 0}
	if data.size() < 1 + declared:
		return {"ok": false, "error": "ResourceUsage message shorter than declared size", "resources": [], "total_bytes": 0, "count": 0}
	var resources: Array = []
	var total := 0
	var idx := 1
	while idx < 1 + declared:
		var bytes := int(data[idx + 3])
		total += bytes
		resources.append({
			"path": str(data[idx]),
			"format": str(data[idx + 1]),
			"type": str(data[idx + 2]),
			"vram_bytes": bytes,
		})
		idx += 4
	resources.sort_custom(func(a, b):
		return int(a.get("vram_bytes", 0)) > int(b.get("vram_bytes", 0))
	)
	return {"ok": true, "error": "", "resources": resources, "total_bytes": total, "count": resources.size()}


static func parse_signature(data: Array) -> Dictionary:
	if data.size() < 2:
		return {"ok": false, "name": "", "id": -1}
	return {"ok": true, "name": str(data[0]), "id": int(data[1])}


static func parse_profile_frame(data: Array, signatures: Dictionary) -> Dictionary:
	if data.size() < 8:
		return {"ok": false, "error": "ServersProfilerFrame message too short"}
	var frame_number := int(data[0])
	var frame_time := float(data[1])
	var process_time := float(data[2])
	var physics_time := float(data[3])
	var physics_frame_time := float(data[4])
	var script_time := float(data[5])
	var servers_left := int(data[6])
	var idx := 7
	var servers: Array = []
	while servers_left > 0:
		if idx + 2 > data.size():
			return {"ok": false, "error": "truncated server block"}
		servers_left -= 1
		var server_name := str(data[idx])
		var sub := int(data[idx + 1])
		idx += 2
		if sub < 0 or idx + sub > data.size():
			return {"ok": false, "error": "truncated server functions"}
		var functions: Array = []
		var pair := 0
		while pair < sub / 2:
			functions.append({"name": str(data[idx]), "time": float(data[idx + 1])})
			idx += 2
			pair += 1
		servers.append({"name": server_name, "functions": functions})
	if idx >= data.size():
		return {"ok": false, "error": "missing script function size"}
	var func_size := int(data[idx])
	idx += 1
	if func_size < 0 or idx + func_size > data.size():
		return {"ok": false, "error": "truncated script functions"}
	var script_functions: Array = []
	var count := func_size / 5
	for _i in count:
		var sig_id := int(data[idx])
		var sig_name := ""
		if signatures.has(sig_id):
			sig_name = str(signatures[sig_id])
		script_functions.append({
			"signature_id": sig_id,
			"signature": sig_name,
			"call_count": int(data[idx + 1]),
			"self_time_sec": float(data[idx + 2]),
			"total_time_sec": float(data[idx + 3]),
			"internal_time_sec": float(data[idx + 4]),
		})
		idx += 5
	return {
		"ok": true,
		"error": "",
		"frame_number": frame_number,
		"frame_time_sec": frame_time,
		"process_time_sec": process_time,
		"physics_time_sec": physics_time,
		"physics_frame_time_sec": physics_frame_time,
		"script_time_sec": script_time,
		"servers": servers,
		"script_functions": script_functions,
	}


static func parse_visual_frame(data: Array) -> Dictionary:
	if data.size() < 2:
		return {"ok": false, "error": "VisualProfilerFrame message too short", "areas": []}
	var declared := int(data[1])
	if declared < 0 or data.size() < 2 + declared:
		return {"ok": false, "error": "truncated visual areas", "areas": []}
	var areas: Array = []
	var idx := 2
	var count := declared / 3
	for _i in count:
		areas.append({
			"name": str(data[idx]),
			"cpu_msec": float(data[idx + 1]),
			"gpu_msec": float(data[idx + 2]),
		})
		idx += 3
	return {"ok": true, "error": "", "frame_number": int(data[0]), "areas": areas}


static func summarize_profile(frames: Array) -> Dictionary:
	var used: Array = []
	for raw in frames:
		if typeof(raw) == TYPE_DICTIONARY and bool(raw.get("ok", false)):
			used.append(raw)
	if used.is_empty():
		return {
			"frame_count": 0,
			"frame_time_sec": 0.0,
			"process_time_sec": 0.0,
			"physics_time_sec": 0.0,
			"physics_frame_time_sec": 0.0,
			"script_time_sec": 0.0,
			"top_self_sec": 0.0,
			"servers": [],
			"script_functions": [],
		}
	var n := float(used.size())
	var frame_time := 0.0
	var process_time := 0.0
	var physics_time := 0.0
	var physics_frame_time := 0.0
	var script_time := 0.0
	var server_acc := {}
	var func_acc := {}
	for raw in used:
		var frame: Dictionary = raw
		frame_time += float(frame.get("frame_time_sec", 0.0))
		process_time += float(frame.get("process_time_sec", 0.0))
		physics_time += float(frame.get("physics_time_sec", 0.0))
		physics_frame_time += float(frame.get("physics_frame_time_sec", 0.0))
		script_time += float(frame.get("script_time_sec", 0.0))
		for server_raw in frame.get("servers", []):
			if typeof(server_raw) != TYPE_DICTIONARY:
				continue
			var server: Dictionary = server_raw
			var server_name := str(server.get("name", ""))
			if not server_acc.has(server_name):
				server_acc[server_name] = {}
			var bucket: Dictionary = server_acc[server_name]
			for fn_raw in server.get("functions", []):
				if typeof(fn_raw) != TYPE_DICTIONARY:
					continue
				var fn: Dictionary = fn_raw
				var fn_name := str(fn.get("name", ""))
				bucket[fn_name] = float(bucket.get(fn_name, 0.0)) + float(fn.get("time", 0.0))
		for fn_raw in frame.get("script_functions", []):
			if typeof(fn_raw) != TYPE_DICTIONARY:
				continue
			var fn: Dictionary = fn_raw
			var key := str(fn.get("signature", ""))
			if key == "":
				key = "id:%s" % str(fn.get("signature_id", ""))
			if not func_acc.has(key):
				func_acc[key] = {"signature": key, "self_time_sec": 0.0, "total_time_sec": 0.0, "call_count": 0.0}
			var row: Dictionary = func_acc[key]
			row["self_time_sec"] = float(row["self_time_sec"]) + float(fn.get("self_time_sec", 0.0))
			row["total_time_sec"] = float(row["total_time_sec"]) + float(fn.get("total_time_sec", 0.0))
			row["call_count"] = float(row["call_count"]) + float(fn.get("call_count", 0.0))
	var servers: Array = []
	for server_name in server_acc.keys():
		var functions: Array = []
		var bucket: Dictionary = server_acc[server_name]
		for fn_name in bucket.keys():
			functions.append({"name": fn_name, "time": float(bucket[fn_name]) / n})
		functions.sort_custom(func(a, b):
			return float(a.get("time", 0.0)) > float(b.get("time", 0.0))
		)
		servers.append({"name": server_name, "functions": functions})
	var script_functions: Array = []
	var top_self := 0.0
	for key in func_acc.keys():
		var row: Dictionary = func_acc[key]
		var self_mean := float(row["self_time_sec"]) / n
		if self_mean > top_self:
			top_self = self_mean
		script_functions.append({
			"signature": key,
			"self_time_sec": self_mean,
			"total_time_sec": float(row["total_time_sec"]) / n,
			"call_count": float(row["call_count"]) / n,
		})
	script_functions.sort_custom(func(a, b):
		return float(a.get("self_time_sec", 0.0)) > float(b.get("self_time_sec", 0.0))
	)
	return {
		"frame_count": used.size(),
		"frame_time_sec": frame_time / n,
		"process_time_sec": process_time / n,
		"physics_time_sec": physics_time / n,
		"physics_frame_time_sec": physics_frame_time / n,
		"script_time_sec": script_time / n,
		"top_self_sec": top_self,
		"servers": servers,
		"script_functions": script_functions,
	}
