extends Node

## capture_compare Tool
## Compares two captures for regressions
## Regression = >5% AND >0.5 ms, context-hash gated

const Context = preload("res://addons/render_lens/context.gd")
const FileHelper = preload("res://addons/render_lens/file_helper.gd")

const REGRESSION_PERCENT_THRESHOLD := 5.0
const REGRESSION_MS_THRESHOLD := 0.5

static func execute(params: Dictionary) -> Dictionary:
	"""Execute capture_compare tool"""
	var baseline_path: String = params.get("baseline", "")
	var current_path: String = params.get("current", "")
	
	# Validate paths
	if baseline_path.is_empty():
		return _build_error("baseline path required")
	if current_path.is_empty():
		return _build_error("current path required")
	
	# Load captures
	var baseline := _load_capture(baseline_path)
	if baseline.has("error"):
		return _build_error("Failed to load baseline: %s" % baseline.error)
	
	var current := _load_capture(current_path)
	if current.has("error"):
		return _build_error("Failed to load current: %s" % current.error)
	
	# Check context compatibility
	var baseline_hash := Context.compute_hash(baseline.get("context", {}))
	var current_hash := Context.compute_hash(current.get("context", {}))
	
	if baseline_hash != current_hash:
		return _build_error("Context mismatch - captures are from different settings/scenes")
	
	# Compare
	var comparison := _compare_captures(baseline, current)
	if comparison.has("error"):
		return _build_error(comparison.error)
	comparison.baseline_path = baseline_path
	comparison.current_path = current_path
	comparison.context_hash = baseline_hash
	
	# Write result
	var path := FileHelper.write_json(comparison, "comparison")
	if path.is_empty():
		return _build_error("Failed to write comparison")
	
	# Build summary with exit code for CI
	var summary := _build_summary(comparison, path)
	
	return {
		"content": [{
			"type": "text",
			"text": JSON.stringify(summary, "\t")
		}]
	}

static func _load_capture(path: String) -> Dictionary:
	"""Load capture JSON file"""
	if not FileHelper.is_capture_path(path):
		return {"error": "Path must be a saved capture inside res://.render_lens/captures/ (or its user:// fallback): %s" % path}
	path = path.simplify_path()
	if not FileAccess.file_exists(path):
		return {"error": "File not found: %s" % path}

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {"error": "Failed to open file: %s" % path}
	if file.get_length() > FileHelper.MAX_COMPARE_BYTES:
		return {"error": "Capture is larger than 64 MiB: %s" % path}

	var json_text := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var parse_result := json.parse(json_text)
	
	if parse_result != OK:
		return {"error": "Invalid JSON: %s" % json.get_error_message()}
	if typeof(json.data) != TYPE_DICTIONARY or typeof(json.data.get("context")) != TYPE_DICTIONARY:
		return {"error": "Capture must be an object with a context object"}
	
	return json.data

static func _compare_captures(baseline: Dictionary, current: Dictionary) -> Dictionary:
	"""Compare two captures for regressions"""
	var regressions := []
	var compared_fields := 0
	
	# Compare timing fields
	var timing_fields := [
		["median_total_ms", "median frame time"],
		["p95_ms", "p95 frame time"],
		["median_gpu_ms", "median GPU time"]
	]
	
	for field_info in timing_fields:
		var field: String = field_info[0]
		var label: String = field_info[1]
		
		var baseline_val := _get_nested_field(baseline, field)
		var current_val := _get_nested_field(current, field)
		
		if baseline_val != null and current_val != null:
			if not _valid_metric(baseline_val) or not _valid_metric(current_val):
				return {"error": "Invalid numeric capture field: " + field}
			compared_fields += 1
			var regression := _check_ms_regression(baseline_val, current_val, label)
			if regression:
				regressions.append(regression)
	
	if compared_fields == 0:
		return {"error": "No matching timing measurements to compare"}
	# Determine verdict
	var verdict := "pass"
	var exit_code := 0
	
	if not regressions.is_empty():
		var has_high := false
		for r in regressions:
			if r.get("severity", "medium") == "high":
				has_high = true
				break
		
		if has_high:
			verdict = "regression"
			exit_code = 1
		else:
			verdict = "degradation"
			exit_code = 2
	
	return {
		"verdict": verdict,
		"exit_code": exit_code,
		"regressions": regressions,
		"regression_count": regressions.size()
	}

static func _valid_metric(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) >= 0.0

static func _check_ms_regression(baseline: float, current: float, label: String) -> Variant:
	"""Check if ms value regressed"""
	if baseline <= 0:
		return null
	
	var diff_ms := current - baseline
	var diff_percent := (diff_ms / baseline) * 100.0
	
	# Regression: >5% AND >0.5 ms
	if diff_percent > REGRESSION_PERCENT_THRESHOLD and diff_ms > REGRESSION_MS_THRESHOLD:
		return {
			"field": label,
			"baseline_ms": baseline,
			"current_ms": current,
			"diff_ms": diff_ms,
			"diff_percent": diff_percent,
			"severity": "high" if diff_ms > 2.0 else "medium"
		}
	
	return null

static func _get_nested_field(data: Dictionary, field_name: String) -> Variant:
	"""Get field from nested dict (handles timing.median_ms, memory.vram, etc.)"""
	# Try direct access first
	if data.has(field_name):
		return data[field_name]
	if field_name == "median_total_ms" and typeof(data.get("timing")) == TYPE_DICTIONARY:
		return data.timing.get("median_ms")
	if field_name == "median_gpu_ms" and typeof(data.get("gpu")) == TYPE_DICTIONARY:
		return data.gpu.get("median_ms")
	
	# Try nested access
	var parts := field_name.split("_")
	if parts.size() >= 2:
		var category := parts[0]
		if data.has(category) and data[category] is Dictionary:
			var sub_dict: Dictionary = data[category]
			# Try with full suffix
			if sub_dict.has(field_name):
				return sub_dict[field_name]
			# Try without category prefix
			var suffix := "_".join(parts.slice(1))
			if sub_dict.has(suffix):
				return sub_dict[suffix]
	
	# Special handling for common fields
	if data.has("timing") and data.timing is Dictionary:
		if data.timing.has(field_name):
			return data.timing[field_name]
	
	if data.has("memory") and data.memory is Dictionary:
		if data.memory.has(field_name):
			return data.memory[field_name]
	
	if data.has("gpu") and data.gpu is Dictionary:
		if data.gpu.has(field_name):
			return data.gpu[field_name]
	
	return null

static func _build_summary(comparison: Dictionary, path: String) -> Dictionary:
	"""Build summary with CI exit code"""
	return {
		"path": path,
		"verdict": comparison.verdict,
		"exit_code": comparison.exit_code,
		"regressions_found": comparison.regression_count,
		"message": _get_verdict_message(comparison)
	}

static func _get_verdict_message(comparison: Dictionary) -> String:
	"""Get human-readable verdict message"""
	match comparison.verdict:
		"pass":
			return "No regressions detected"
		"degradation":
			return "%d minor degradations found (exit 2)" % comparison.regression_count
		"regression":
			return "%d regressions found (exit 1)" % comparison.regression_count
		_:
			return "Unknown verdict"

static func _build_error(message: String) -> Dictionary:
	return {
		"isError": true,
		"content": [{
			"type": "text",
			"text": message
		}]
	}
