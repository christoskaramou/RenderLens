extends RefCounted

## Evaluates res://addons/render_lens/rules/*.json.
## Does not write ProjectSettings or scene nodes.

const RULES_DIR := "res://addons/render_lens/rules"
const Pacing = preload("res://addons/render_lens/pacing.gd")
const PASS_LABEL_NOTE := " Pass names are substrings of Godot's RENDER_TIMESTAMP labels for the renderer in use (Forward+ and Mobile label some passes differently, and 4.6 renamed the SSR pass to Process SSR), checked against the 4.4, 4.5.2, 4.6.3 and 4.7.2 sources. They are not a public API."
const COMBINED_PASS_NOTE := " That timestamp covers several passes run together, so its share is not this rule's cost alone."
## Measured shares below this percent of the frame rank last among performance findings. A review cut, not an engine limit.
const MIN_RANKED_SHARE := 1.0
## Renderer ids a pass name can be qualified with ("mobile:Render Shadows").
const RENDERERS := ["forward_plus", "mobile", "gl_compatibility"]
## Advice areas in report order; package() takes one of these as focus, or "all".
const AREAS := ["performance", "visual", "missing", "to_check"]
## To check is collapsed: with focus "all", top previews this many of its findings; focus "to_check" lists them.
const TO_CHECK_PREVIEW := 3

static var _cached: Array = []
static var _newest_verified := 0


static func load_rules() -> Array:
	if not _cached.is_empty():
		return _cached
	var dir := DirAccess.open(RULES_DIR)
	if dir == null:
		return []
	var files: Array[String] = []
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir() and name.ends_with(".json"):
			files.append(RULES_DIR + "/" + name)
		name = dir.get_next()
	dir.list_dir_end()
	files.sort()
	var loaded: Array = []
	for path in files:
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(parsed) != TYPE_ARRAY:
			push_error("Render Lens rules failed to parse: %s" % path)
			continue
		for rule in parsed:
			if typeof(rule) == TYPE_DICTIONARY:
				loaded.append(rule)
				for version in rule.get("applies_to", {}).get("versions", []):
					_newest_verified = maxi(_newest_verified, _version_key(str(version)))
	_cached = loaded
	return _cached


static func clear_cache() -> void:
	_cached.clear()
	_newest_verified = 0


static func _version_key(text: String) -> int:
	var parts := text.split(".")
	return int(parts[0]) * 1000 + (int(parts[1]) if parts.size() > 1 else 0)


## A rule's listed versions are the verified ones. It also applies between them and,
## when verified on the catalog's newest version, to later minors of that major.
static func version_applies(spec: Dictionary, current: int) -> bool:
	var min_version := str(spec.get("min_version", ""))
	var max_version := str(spec.get("max_version", ""))
	if min_version != "" and current < _version_key(min_version):
		return false
	if max_version != "" and current > _version_key(max_version):
		return false
	var verified: Array = spec.get("versions", []).map(func(version): return _version_key(str(version)))
	if verified.is_empty() or verified.has(current):
		return true
	if _newest_verified == 0:
		load_rules()
	if current / 1000 != int(verified.min()) / 1000 or current < int(verified.min()):
		return false
	return current < int(verified.max()) or int(verified.max()) >= _newest_verified


static func evaluate(ctx: Dictionary, mode: String) -> Array:
	var findings: Array = []
	for rule in load_rules():
		if typeof(rule) != TYPE_DICTIONARY:
			continue
		if not _applies(rule, ctx):
			continue
		if mode == "static" and _requires_measured(rule):
			continue
		if not _inputs_present(rule, ctx):
			continue
		var ev := {"settings": {}, "scene": {}, "metrics": {}}
		if not _eval(rule.get("condition", {}), ctx, ev):
			continue
		findings.append(_build(rule, ctx, ev))
	return _dedupe(findings)


## top lists up to top_n findings from each area in AREAS order (or from the focus area only), so a long performance
## list never hides visual or missing-part findings. Every finding stays in the per-kind lists and in findings.
static func package(findings: Array, frame: Dictionary, top_n: int, rank_mode: String = "measured", focus: String = "all") -> Dictionary:
	var within := true
	var headroom := {}
	var measured := rank_mode != "static" and not frame.is_empty() and frame.has("budget_ms")
	if measured:
		var budget := float(frame["budget_ms"])
		var median := float(frame.get("median_ms", 0.0))
		var head := float(frame.get("headroom_ms", budget - median))
		within = not Pacing.over_budget(median, budget) if budget > 0.0 else head >= 0.0
		var pct = frame.get("over_budget_percent", null)
		var pct_n := 0.0
		if pct != null:
			pct_n = float(pct)
		if not within and pct_n <= 0.0 and budget > 0.0:
			pct_n = (median - budget) / budget * 100.0
		headroom = {
			"budget_ms": budget,
			"median_frame_ms": median,
			"headroom_ms": head,
			"over_budget": not within,
			"bound": str(frame.get("bound", "")),
			"source": str(frame.get("source", "")),
			"over_budget_percent": pct_n,
			"process_frame_ms": float(frame.get("process_frame_ms", 0.0)),
			"gpu_span_ms": float(frame.get("gpu_span_ms", frame.get("median_gpu_ms", 0.0))),
			"gpu_span_over_budget_percent": float(frame.get("gpu_span_over_budget_percent", 0.0)),
		}
		var embed_note := str(frame.get("embed_note", ""))
		if embed_note != "":
			headroom["embedded_play_note"] = embed_note
		headroom["note"] = "Process/frame time includes rendering synchronization. An unexplained gap is not proof of CPU work. Static node findings are candidates, not per-node measured costs."
	var performance: Array = []
	var configuration: Array = []
	var quality: Array = []
	var info: Array = []
	for item in findings:
		var kind := str(item.get("kind", "performance"))
		if kind == "correctness":
			item["optional"] = false
			item["optional_reason"] = "Configuration finding; frame-time headroom does not establish correctness."
			configuration.append(item)
		elif kind == "quality_up":
			item["optional"] = true
			item["optional_reason"] = "Optional quality-for-cost tradeoff. Nothing is changed automatically."
			quality.append(item)
		elif kind == "info":
			item["optional"] = true
			item["optional_reason"] = "Informational. Nothing is changed automatically."
			info.append(item)
		else:
			if not measured:
				item["optional"] = false
				item["optional_reason"] = ""
			elif within:
				item["optional"] = true
				item["optional_reason"] = "The frame median is inside the target budget. This cost cut is optional."
			else:
				item["optional"] = false
				item["optional_reason"] = ""
			performance.append(item)
	performance = _group_by_pass(performance)
	_sort_by_share(performance)
	_sort_by_severity(quality)
	_sort_by_severity(configuration)
	# Measured costs lead the performance area, then unmeasured candidates, then measured costs too small to matter.
	var costed := performance.filter(func(item): return float(item.get("measured_share", 0.0)) >= MIN_RANKED_SHARE)
	var uncosted := performance.filter(func(item): return float(item.get("measured_share", 0.0)) <= 0.0)
	var negligible := performance.filter(func(item): return float(item.get("measured_share", 0.0)) > 0.0 and float(item.get("measured_share", 0.0)) < MIN_RANKED_SHARE)
	for item in negligible:
		item["severity"] = "low"
		item["optional"] = true
		item["optional_reason"] = "Measured below %.0f%% of the frame (%.2f%%), so it ranks after every other performance finding." % [MIN_RANKED_SHARE, float(item["measured_share"])]
	# In a measured run, a candidate that no measurement ties to a cost goes to To check, collapsed after missing parts.
	var to_check: Array = []
	if measured:
		# Measured means a pass share or measured monitor values; a rule gated only on the frame being over budget is not.
		to_check = uncosted.filter(func(item): return item.get("measured_evidence", {}).get("metrics", {}).is_empty())
		uncosted = uncosted.filter(func(item): return not item.get("measured_evidence", {}).get("metrics", {}).is_empty())
		for item in to_check:
			item["optional"] = true
			item["optional_reason"] = "No measurement in this run ties it to a cost. Check it when the measured costs are not enough."
	# Findings Godot itself already shows (editor configuration warnings, run-time warnings) follow the rest of their area.
	quality = _godot_warned_last(quality)
	configuration = _godot_warned_last(configuration)
	uncosted = _godot_warned_last(uncosted)
	to_check = _godot_warned_last(to_check)
	performance = costed + uncosted + negligible
	var areas := {"performance": performance, "visual": quality, "missing": configuration, "to_check": to_check, "info": info}
	# Findings listed under another on the same pass share its area, priority and severity.
	for item in performance:
		for member in item.get("same_pass", []):
			member["grouped_under"] = item["id"]
			member["optional"] = item["optional"]
			member["optional_reason"] = item["optional_reason"]
			member["area"] = "performance"
			if float(item.get("measured_share", 0.0)) < MIN_RANKED_SHARE:
				member["severity"] = "low"
	var top: Array = []
	for area in areas:
		for item in areas[area]:
			item["area"] = area
		if AREAS.has(area) and (focus == "all" or focus == area):
			top += areas[area].slice(0, mini(top_n, TO_CHECK_PREVIEW) if area == "to_check" and focus == "all" else top_n)
	return {
		"within_budget": within if measured else null,
		"measured": measured,
		"headroom": headroom,
		"focus": focus,
		"area_counts": {"performance": performance.size(), "visual": quality.size(), "missing": configuration.size(), "to_check": to_check.size(), "info": info.size()},
		"godot_warned_count": findings.filter(func(item): return str(item.get("godot_warns", "")) != "").size(),
		"top": top,
		"optional_quality": quality,
		"performance_findings": performance,
		"configuration_findings": configuration,
		"to_check": to_check,
		"info": info,
		"findings": findings,
		"finding_count": findings.size(),
		"applied": false,
	}


static func _applies(rule: Dictionary, ctx: Dictionary) -> bool:
	var spec: Dictionary = rule.get("applies_to", {})
	var vendors: Array = spec.get("vendors", [])
	if not vendors.is_empty():
		var adapter: Dictionary = ctx.get("adapter", {})
		var label := (str(adapter.get("vendor", "")) + " " + str(adapter.get("name", ""))).to_lower()
		var vendor := ""
		if "nvidia" in label:
			vendor = "nvidia"
		elif "amd" in label or "radeon" in label or "advanced micro devices" in label:
			vendor = "amd"
		elif "arm" in label or "mali" in label:
			vendor = "arm"
		elif "imagination" in label or "powervr" in label:
			vendor = "imagination"
		if not vendors.has(vendor):
			return false
	var current := int(ctx.get("version_major", 0)) * 1000 + int(ctx.get("version_minor", 0))
	# An unverified version uses the nearest verified renderer list at or below it.
	var renderers: Array = spec.get("renderers", [])
	var chosen := -1
	var by_version: Dictionary = spec.get("renderers_by_version", {})
	for key in by_version:
		var at := _version_key(str(key))
		if at <= current and at > chosen:
			chosen = at
			renderers = by_version[key]
	var renderer := str(ctx.get("renderer", ""))
	if not renderers.is_empty() and not renderers.has(renderer):
		return false
	return version_applies(spec, current)


static func _requires_measured(rule: Dictionary) -> bool:
	var req: Array = rule.get("requires", [])
	for item in req:
		var name := str(item)
		if name == "metrics" or name == "passes" or name == "frame":
			return true
	return false


static func _inputs_present(rule: Dictionary, ctx: Dictionary) -> bool:
	var req: Array = rule.get("requires", [])
	for item in req:
		var name := str(item)
		if name == "passes" and typeof(ctx.get("passes")) != TYPE_ARRAY:
			return false
		if name == "metrics" and typeof(ctx.get("metrics")) != TYPE_DICTIONARY:
			return false
		if name == "frame":
			var frame = ctx.get("frame", {})
			if typeof(frame) != TYPE_DICTIONARY or frame.is_empty():
				return false
		if name == "scene" and typeof(ctx.get("scene")) != TYPE_DICTIONARY:
			return false
		if name == "settings" and typeof(ctx.get("settings")) != TYPE_DICTIONARY:
			return false
	return true


static func _eval(cond, ctx: Dictionary, ev: Dictionary) -> bool:
	if typeof(cond) != TYPE_DICTIONARY:
		return false
	if cond.has("all"):
		for child in cond["all"]:
			if not _eval(child, ctx, ev):
				return false
		return true
	if cond.has("any"):
		for child in cond["any"]:
			if _eval(child, ctx, ev):
				return true
		return false
	if cond.has("not"):
		return not _eval(cond["not"], ctx, ev)
	if cond.has("setting_eq"):
		return _cmp_setting(cond["setting_eq"], ctx, ev, "eq")
	if cond.has("setting_neq"):
		return _cmp_setting(cond["setting_neq"], ctx, ev, "neq")
	if cond.has("setting_gt"):
		return _cmp_setting(cond["setting_gt"], ctx, ev, "gt")
	if cond.has("setting_gte"):
		return _cmp_setting(cond["setting_gte"], ctx, ev, "gte")
	if cond.has("setting_lt"):
		return _cmp_setting(cond["setting_lt"], ctx, ev, "lt")
	if cond.has("setting_lte"):
		return _cmp_setting(cond["setting_lte"], ctx, ev, "lte")
	if cond.has("scene_eq"):
		return _cmp_scene(cond["scene_eq"], ctx, ev, "eq")
	if cond.has("scene_gte"):
		return _cmp_scene(cond["scene_gte"], ctx, ev, "gte")
	if cond.has("scene_gt"):
		return _cmp_scene(cond["scene_gt"], ctx, ev, "gt")
	if cond.has("metric_gt"):
		return _cmp_metric(cond["metric_gt"], ctx, ev, "gt")
	if cond.has("metric_gte"):
		return _cmp_metric(cond["metric_gte"], ctx, ev, "gte")
	if cond.has("metric_eq"):
		return _cmp_metric(cond["metric_eq"], ctx, ev, "eq")
	if cond.has("metric_gt_budget_ratio"):
		return _metric_ratio(cond["metric_gt_budget_ratio"], ctx, ev)
	if cond.has("pass_present"):
		return not _match_named(ctx, cond["pass_present"]).is_empty()
	if cond.has("pass_share_gte"):
		return _pass_share(cond["pass_share_gte"], ctx)
	if cond.has("frame_over_budget"):
		return bool(cond["frame_over_budget"]) == _frame_over(ctx)
	if cond.has("frame_bound"):
		return str(_frame(ctx).get("bound", "")) == str(cond["frame_bound"])
	if cond.has("adapter_listed_in_setting"):
		return _adapter_listed(cond["adapter_listed_in_setting"], ctx, ev)
	if cond.has("cluster_budget_exceeded"):
		return _cluster_over(ctx, ev)
	if cond.has("opengl_light_limit_exceeded"):
		return _gl_lights(ctx, ev)
	if cond.has("message_queue_ratio_gte"):
		return _queue_ratio(cond["message_queue_ratio_gte"], ctx, ev)
	if cond.has("max_fps_below_target"):
		return _max_fps_below(ctx, ev)
	if cond.has("fps_below_target"):
		return _fps_below(ctx, ev)
	if cond.has("metric_gt_metric"):
		return _metric_gt_metric(cond["metric_gt_metric"], ctx, ev)
	return false


static func _cmp_setting(spec: Dictionary, ctx: Dictionary, ev: Dictionary, op: String) -> bool:
	var path := str(spec.get("path", ""))
	var settings: Dictionary = ctx.get("settings", {})
	if not settings.has(path):
		return false
	var value = settings[path]
	ev["settings"][path] = value
	var expected = spec.get("value")
	return _compare(value, expected, op)


static func _cmp_scene(spec: Dictionary, ctx: Dictionary, ev: Dictionary, op: String) -> bool:
	var key := str(spec.get("name", ""))
	var scene: Dictionary = ctx.get("scene", {})
	if not scene.has(key):
		return false
	var value = scene[key]
	ev["scene"][key] = value
	return _compare(value, spec.get("value"), op)


static func _cmp_metric(spec: Dictionary, ctx: Dictionary, ev: Dictionary, op: String) -> bool:
	var key := str(spec.get("name", ""))
	var metrics: Dictionary = ctx.get("metrics", {})
	if not metrics.has(key):
		return false
	var value = metrics[key]
	ev["metrics"][key] = value
	return _compare(value, spec.get("value"), op)


static func _compare(value, expected, op: String) -> bool:
	if op == "eq":
		return value == expected
	if op == "neq":
		return value != expected
	if not _is_number(value) or not _is_number(expected):
		return false
	var left := float(value)
	var right := float(expected)
	if op == "gt":
		return left > right
	if op == "gte":
		return left >= right
	if op == "lt":
		return left < right
	if op == "lte":
		return left <= right
	return false


static func _is_number(value) -> bool:
	var kind := typeof(value)
	return kind == TYPE_INT or kind == TYPE_FLOAT


static func _metric_ratio(spec: Dictionary, ctx: Dictionary, ev: Dictionary) -> bool:
	var key := str(spec.get("name", ""))
	var metrics: Dictionary = ctx.get("metrics", {})
	if not metrics.has(key):
		return false
	var frame := _frame(ctx)
	if not frame.has("budget_ms"):
		return false
	var budget_sec := float(frame["budget_ms"]) / 1000.0
	if budget_sec <= 0.0:
		return false
	ev["metrics"][key] = metrics[key]
	var value := float(metrics[key])
	# minus_gpu: a monitor that also times the renderer's wait for the GPU (TIME_PROCESS) is compared without it.
	if bool(spec.get("minus_gpu", false)):
		var gpu_sec := maxf(float(frame.get("median_gpu_ms", 0.0)), 0.0) / 1000.0
		ev["metrics"]["MEDIAN_GPU_SEC"] = gpu_sec
		value -= gpu_sec
	return value > budget_sec * float(spec.get("ratio", 1.0))


static func _pass_share(spec: Dictionary, ctx: Dictionary) -> bool:
	var found := _match_named(ctx, {"names": spec.get("names", [str(spec.get("name", ""))])})
	if found.is_empty():
		return false
	return float(found.get("share", 0.0)) >= float(spec.get("share", 0.0))


static func _frame(ctx: Dictionary) -> Dictionary:
	var frame = ctx.get("frame", {})
	if typeof(frame) != TYPE_DICTIONARY:
		return {}
	return frame


static func _frame_over(ctx: Dictionary) -> bool:
	var frame := _frame(ctx)
	if frame.is_empty():
		return false
	if frame.has("median_ms") and float(frame.get("budget_ms", 0.0)) > 0.0:
		return Pacing.over_budget(float(frame["median_ms"]), float(frame["budget_ms"]))
	if frame.has("headroom_ms"):
		return float(frame["headroom_ms"]) < 0.0
	if frame.has("over_budget"):
		return bool(frame["over_budget"])
	return false


static func _adapter_listed(spec: Dictionary, ctx: Dictionary, ev: Dictionary) -> bool:
	var path := str(spec.get("path", ""))
	var settings: Dictionary = ctx.get("settings", {})
	if not settings.has(path):
		return false
	ev["settings"][path] = settings[path]
	var adapter: Dictionary = ctx.get("adapter", {})
	var hay := (str(adapter.get("vendor", "")) + " " + str(adapter.get("name", ""))).to_lower()
	if hay.strip_edges() == "":
		return false
	for part in str(settings[path]).split(","):
		var token := part.strip_edges().to_lower()
		if token != "" and hay.findn(token) >= 0:
			return true
	return false


static func _cluster_over(ctx: Dictionary, ev: Dictionary) -> bool:
	var settings: Dictionary = ctx.get("settings", {})
	var path := "rendering/limits/cluster_builder/max_clustered_elements"
	if not settings.has(path):
		return false
	var scene: Dictionary = ctx.get("scene", {})
	# ClusterBuilderRD caps each element type at this limit on its own (cluster_builder_rd.h); directional lights are not clustered.
	var largest := 0
	for key in ["omni_light_count", "spot_light_count", "area_light_count", "decal_count", "reflection_probe_count"]:
		largest = maxi(largest, int(scene.get(key, 0)))
	ev["settings"][path] = settings[path]
	ev["scene"]["cluster_element_estimate"] = largest
	return float(largest) > float(settings[path])


static func _gl_lights(ctx: Dictionary, ev: Dictionary) -> bool:
	if str(ctx.get("renderer", "")) != "gl_compatibility":
		return false
	var settings: Dictionary = ctx.get("settings", {})
	var path := "rendering/limits/opengl/max_renderable_lights"
	if not settings.has(path):
		return false
	var scene: Dictionary = ctx.get("scene", {})
	# The renderer caps omni, spot and area lights each on its own (rasterizer_scene_gles3.cpp); directional lights are separate.
	var over := false
	for key in ["omni_light_count", "spot_light_count", "area_light_count"]:
		if scene.has(key):
			ev["scene"][key] = scene[key]
			over = over or float(scene[key]) > float(settings[path])
	ev["settings"][path] = settings[path]
	return over


static func _queue_ratio(spec: Dictionary, ctx: Dictionary, ev: Dictionary) -> bool:
	var metrics: Dictionary = ctx.get("metrics", {})
	var settings: Dictionary = ctx.get("settings", {})
	var metric_name := "MEMORY_MESSAGE_BUFFER_MAX"
	var path := "memory/limits/message_queue/max_size_mb"
	if not metrics.has(metric_name) or not settings.has(path):
		return false
	ev["metrics"][metric_name] = metrics[metric_name]
	ev["settings"][path] = settings[path]
	var cap := float(settings[path]) * 1024.0 * 1024.0
	if cap <= 0.0:
		return false
	return float(metrics[metric_name]) >= cap * float(spec.get("ratio", 1.0))


static func _target_fps(ctx: Dictionary) -> float:
	var frame := _frame(ctx)
	if not frame.has("budget_ms"):
		return 0.0
	var budget := float(frame["budget_ms"])
	if budget <= 0.0:
		return 0.0
	return 1000.0 / budget


static func _max_fps_below(ctx: Dictionary, ev: Dictionary) -> bool:
	var settings: Dictionary = ctx.get("settings", {})
	var path := "application/run/max_fps"
	if not settings.has(path):
		return false
	var cap := float(settings[path])
	var target := _target_fps(ctx)
	if cap <= 0.0 or target <= 0.0:
		return false
	ev["settings"][path] = settings[path]
	return cap < target


static func _fps_below(ctx: Dictionary, ev: Dictionary) -> bool:
	var metrics: Dictionary = ctx.get("metrics", {})
	if not metrics.has("TIME_FPS"):
		return false
	var fps := float(metrics["TIME_FPS"])
	var target := _target_fps(ctx)
	if fps <= 1.0 or target <= 0.0:
		return false
	ev["metrics"]["TIME_FPS"] = metrics["TIME_FPS"]
	return fps < target


static func _metric_gt_metric(spec: Dictionary, ctx: Dictionary, ev: Dictionary) -> bool:
	var metrics: Dictionary = ctx.get("metrics", {})
	var left := str(spec.get("left", ""))
	var right := str(spec.get("right", ""))
	if not metrics.has(left) or not metrics.has(right):
		return false
	ev["metrics"][left] = metrics[left]
	ev["metrics"][right] = metrics[right]
	return float(metrics[left]) > float(metrics[right])


static func _match_named(ctx: Dictionary, spec: Dictionary) -> Dictionary:
	var names: Array = spec.get("names", [])
	return _best_pass(ctx, names)


static func _best_pass(ctx: Dictionary, names: Array) -> Dictionary:
	var passes = ctx.get("passes")
	if typeof(passes) != TYPE_ARRAY or names.is_empty():
		return {}
	var best := {}
	var best_share := -1.0
	for raw in passes:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var pname := str(raw.get("name", ""))
		var matched := ""
		for wanted in names:
			# "mobile:Render Shadows" is that whole label on that renderer only: Forward+ 4.4 to 4.6 also emits
			# "Render Shadows" (without GI) and "Render GI + Render Shadows (Parallel)", both for the sun and spot lights.
			var name := str(wanted)
			var qualified := name.get_slice(":", 0) in RENDERERS
			if (name.get_slice(":", 0) == str(ctx.get("renderer", "")) and pname == name.substr(name.find(":") + 1)) if qualified else pname.findn(name) >= 0:
				matched = name
				break
		if matched == "":
			continue
		var share := float(raw.get("share", 0.0))
		var excl := float(raw.get("exclusive_median_ms", raw.get("median_ms", 0.0)))
		if excl <= 0.0 and share <= 0.0:
			continue
		if share > best_share:
			best_share = share
			best = {
				"name": pname,
				"exclusive_median_ms": excl,
				"share": share,
				"matched": matched,
			}
	return best


static func _build(rule: Dictionary, ctx: Dictionary, ev: Dictionary) -> Dictionary:
	var when = rule.get("when_pass", [])
	if typeof(when) != TYPE_ARRAY:
		when = []
	var found := _best_pass(ctx, when)
	var share := 0.0
	if not found.is_empty():
		share = float(found.get("share", 0.0))
	if share <= 0.0:
		share = _share_from_metric(rule, ctx)
	var text := str(rule.get("evidence", ""))
	var bits: PackedStringArray = []
	for bucket in ["settings", "scene", "metrics"]:
		var block: Dictionary = ev.get(bucket, {})
		for key in block.keys():
			bits.append("%s=%s" % [str(key), str(block[key])])
	if not bits.is_empty():
		text += " Values: " + ", ".join(bits) + "."
	if not found.is_empty():
		text += " Measured pass '%s' exclusive median %.3f ms (%.1f%% of the timestamp-span frame)." % [
			found.get("name", ""),
			float(found.get("exclusive_median_ms", 0.0)),
			share,
		]
		if str(found.get("name", "")).contains(" + "):
			text += COMBINED_PASS_NOTE
		text += PASS_LABEL_NOTE
	var offenders: Array = _offender_paths(rule, ctx).slice(0, 8)
	return {
		"id": str(rule.get("id", "")),
		"category": str(rule.get("category", "")),
		"title": str(rule.get("title", "")),
		"severity": str(rule.get("severity", "medium")),
		"kind": str(rule.get("kind", "performance")),
		"heuristic": bool(rule.get("heuristic", false)),
		"heuristic_rationale": str(rule.get("heuristic_rationale", "")),
		"upstream_check": str(rule.get("upstream_check", "")),
		"evidence_kind": str(rule.get("evidence_kind", "observed_condition")),
		"attribution": "pass correlation, not per-node cost" if not found.is_empty() else "observed condition, not measured savings",
		"applies_to": rule.get("applies_to", {}),
		"engine_version_note": _version_note(rule, ctx),
		"measured_evidence": {
			"text": text,
			"settings": ev.get("settings", {}),
			"scene": ev.get("scene", {}),
			"metrics": ev.get("metrics", {}),
			"pass": found if not found.is_empty() else null,
		},
		"suggestion": str(rule.get("suggestion", "")),
		"setting": str(rule.get("setting", "")),
		"node_property": str(rule.get("node_property", "")),
		"offenders": offenders,
		"tradeoff": str(rule.get("tradeoff", "")),
		"expected_effect": str(rule.get("expected_effect", "")),
		"verify_step": str(rule.get("verify_step", "")),
		"source": str(rule.get("source", "")),
		"engine_internal": bool(rule.get("engine_internal", false)),
		"validation_id": str(rule.get("validation_id", "")),
		"measured_share": share,
		"pass_only": bool(rule.get("pass_only", false)),
		"dedupe_key": str(rule.get("dedupe_key", "")),
		"experiment": rule.get("experiment", []),
		"godot_warns": str(rule.get("godot_warns", "")),
		"applied": false,
	}


static func _offender_paths(rule: Dictionary, ctx: Dictionary) -> Array:
	var key := str(rule.get("offender_key", ""))
	var all_off: Dictionary = ctx.get("offenders", {})
	var listed = all_off.get(key, []) if key != "" else []
	if typeof(listed) != TYPE_ARRAY:
		return []
	return listed.map(func(item): return str(item))


static func _version_note(rule: Dictionary, ctx: Dictionary) -> String:
	var versions: Array = rule.get("applies_to", {}).get("versions", [])
	var ver := "%d.%d" % [int(ctx.get("version_major", 0)), int(ctx.get("version_minor", 0))]
	if versions.is_empty() or versions.has(ver):
		return ""
	return "Verified on Godot %s, not on %s; applied by version range." % [", ".join(PackedStringArray(versions)), ver]


static func _share_from_metric(rule: Dictionary, ctx: Dictionary) -> float:
	var key := str(rule.get("share_from", ""))
	if key == "":
		return 0.0
	var metrics: Dictionary = ctx.get("metrics", {})
	if not metrics.has(key):
		return 0.0
	var value := float(metrics[key])
	var unit := str(rule.get("share_unit", ""))
	if unit == "seconds":
		var budget := float(_frame(ctx).get("budget_ms", 0.0))
		if budget <= 0.0:
			return 0.0
		return value / (budget / 1000.0) * 100.0
	return 0.0


## A pass-only finding ("SSAO is in the capture") repeats one that names what to change about the same feature
## (dedupe_key) or measured the same pass, and is dropped then. Distinct advice about one feature stays: package lists
## findings on one measured pass under one entry, and an unmeasured one (post.glow_bicubic) keeps its own.
static func _dedupe(findings: Array) -> Array:
	var keys := {}
	var passes := {}
	for item in findings:
		if bool(item.get("pass_only", false)):
			continue
		if str(item.get("dedupe_key", "")) != "":
			keys[str(item.get("dedupe_key", ""))] = true
		var measured = item["measured_evidence"]["pass"]
		if measured != null:
			passes[measured["name"]] = true
	return findings.filter(func(item):
		var measured = item["measured_evidence"]["pass"]
		return not bool(item.get("pass_only", false)) or not (keys.has(str(item.get("dedupe_key", ""))) or (measured != null and passes.has(measured["name"])))
	)


## One entry per measured pass: findings that measured the same pass are listed under the most severe one (same_pass),
## so that pass's cost is counted once. Equal severity: the finding naming more nodes leads (six shadowed spots over one
## sun on the combined directional/spot timestamp).
static func _group_by_pass(items: Array) -> Array:
	var leads := {}
	var out: Array = []
	for item in items:
		var measured = item.get("measured_evidence", {}).get("pass")
		if measured == null:
			out.append(item)
			continue
		var name := str(measured["name"])
		if not leads.has(name):
			leads[name] = item
			out.append(item)
			continue
		var lead: Dictionary = leads[name]
		if _sev(item) > _sev(lead) or (_sev(item) == _sev(lead) and item.get("offenders", []).size() > lead.get("offenders", []).size()):
			item["same_pass"] = lead.get("same_pass", []) + [lead]
			lead.erase("same_pass")
			out[out.find(lead)] = item
			leads[name] = item
		else:
			lead["same_pass"] = lead.get("same_pass", []) + [item]
	for lead in leads.values():
		if lead.has("same_pass"):
			_sort_by_severity(lead["same_pass"])
	return out


static func _godot_warned_last(items: Array) -> Array:
	return items.filter(func(item): return str(item.get("godot_warns", "")) == "") + items.filter(func(item): return str(item.get("godot_warns", "")) != "")


static func _sev(item: Dictionary) -> int:
	match str(item.get("severity", "")):
		"high":
			return 3
		"medium":
			return 2
		"low":
			return 1
		_:
			return 0


## Shares compare in 0.001-point steps, then severity, then id: sort_custom needs a transitive order (a tolerance
## compare is not), it is not stable, and the same inputs must give the same order on every Godot version.
static func _sort_by_share(items: Array) -> void:
	items.sort_custom(func(a, b):
		var share_a := roundi(float(a.get("measured_share", 0.0)) * 1000.0)
		var share_b := roundi(float(b.get("measured_share", 0.0)) * 1000.0)
		if share_a != share_b:
			return share_a > share_b
		if _sev(a) != _sev(b):
			return _sev(a) > _sev(b)
		return str(a.get("id", "")) < str(b.get("id", ""))
	)


static func _sort_by_severity(items: Array) -> void:
	items.sort_custom(func(a, b):
		if _sev(a) != _sev(b):
			return _sev(a) > _sev(b)
		return str(a.get("id", "")) < str(b.get("id", ""))
	)
