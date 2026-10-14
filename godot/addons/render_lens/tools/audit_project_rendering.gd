extends Node

## audit_project_rendering
## Static subset of the shared rule set: project settings and a scene scan.
## Does not apply changes.

const FileHelper = preload("res://addons/render_lens/file_helper.gd")
const Metrics = preload("res://addons/render_lens/metrics_snapshot.gd")
const SceneScan = preload("res://addons/render_lens/scene_scan.gd")
const Rules = preload("res://addons/render_lens/rule_engine.gd")
const Advisor = preload("res://addons/render_lens/advisor_context.gd")

static func execute(params: Dictionary) -> Dictionary:
	var top_n := int(params.get("top", 20))
	if top_n < 1:
		top_n = 1
	if top_n > 80:
		top_n = 80
	var focus := str(params.get("focus", "all"))
	if focus != "all" and not Rules.AREAS.has(focus):
		return _error("focus must be all, performance, visual, missing or to_check")
	var scene_path := str(params.get("scene", ""))
	var scanned: Dictionary = SceneScan.scan_path(scene_path) if scene_path != "" else SceneScan.scan()
	if str(scanned.get("error", "")) != "":
		return _error(str(scanned.error))
	var snap: Dictionary = Metrics.collect()
	var ctx: Dictionary = Advisor.make(snap, scanned, {}, [])
	var findings: Array = Rules.evaluate(ctx, "static")
	var packed: Dictionary = Rules.package(findings, {}, top_n, "static", focus)
	var payload := {
		"applied": false,
		"mode": "static",
		"shader_scan": scanned.get("shader_scan", {}),
		"material_scan": scanned.get("material_scan", {}),
		"file_walk": scanned.get("file_walk", {}),
		"script_scan": scanned.get("script_scan", {}),
		"scenes": scanned.get("scenes", []),
		"rule_count": Rules.load_rules().size(),
		"finding_count": packed.get("finding_count", 0),
		"category_counts": _categories(findings),
		"groups": group_findings(findings),
		"focus": focus,
		"area_counts": packed.get("area_counts", {}),
		"godot_warned_count": packed.get("godot_warned_count", 0),
		"top": _brief_list(packed.get("top", [])),
		"findings": packed.get("findings", []),
		"optional_quality": packed.get("optional_quality", []),
		"configuration_findings": packed.get("configuration_findings", []),
		"info": packed.get("info", []),
	}
	var path := FileHelper.write_json(payload, "audit_project_rendering")
	if path.is_empty():
		return _error("Failed to write audit JSON")
	return {
		"content": [{
			"type": "text",
			"text": JSON.stringify({
				"path": path,
				"applied": false,
				"mode": "static",
				"shader_scan": payload.shader_scan,
				"material_scan": payload.material_scan,
				"file_walk": payload.file_walk,
				"script_scan": payload.script_scan,
				"scenes": payload.scenes,
				"rule_count": payload.rule_count,
				"finding_count": payload.finding_count,
				"category_counts": payload.category_counts,
				"groups": group_ids(findings),
				"focus": focus,
				"area_counts": payload.area_counts,
				"godot_warned_count": payload.godot_warned_count,
				"top": payload.top,
			}, "\t")
		}]
	}


static func group_findings(findings: Array) -> Dictionary:
	var groups := {}
	for item in findings:
		var category := str(item.get("category", ""))
		if not groups.has(category):
			groups[category] = []
		(groups[category] as Array).append(item)
	var out := {}
	for category in groups.keys():
		var rows: Array = groups[category]
		rows.sort_custom(func(a, b):
			var share_a := float(a.get("measured_share", 0.0))
			var share_b := float(b.get("measured_share", 0.0))
			if absf(share_a - share_b) > 0.001:
				return share_a > share_b
			return _severity_rank(a) > _severity_rank(b)
		)
		out[category] = _brief_list(rows)
	return out


static func _severity_rank(item: Dictionary) -> int:
	match str(item.get("severity", "")):
		"high":
			return 3
		"medium":
			return 2
		"low":
			return 1
		_:
			return 0


static func group_ids(findings: Array) -> Dictionary:
	var grouped: Dictionary = group_findings(findings)
	var out := {}
	for category in grouped.keys():
		var ids: Array = []
		for item in grouped[category]:
			ids.append(str(item.get("id", "")))
		out[category] = ids
	return out


static func _categories(findings: Array) -> Dictionary:
	var counts := {}
	for item in findings:
		var category := str(item.get("category", ""))
		counts[category] = int(counts.get(category, 0)) + 1
	return counts


static func _brief_list(items: Array) -> Array:
	var out: Array = []
	for item in items:
		out.append(_brief(item))
	return out


static func _brief(item: Dictionary) -> Dictionary:
	var evidence: Dictionary = item.get("measured_evidence", {})
	var brief: Dictionary = {
		"id": item.get("id", ""),
		"category": item.get("category", ""),
		"title": item.get("title", ""),
		"severity": item.get("severity", ""),
		"kind": item.get("kind", ""),
		"area": item.get("area", ""),
		"heuristic": item.get("heuristic", false),
		"upstream_check": item.get("upstream_check", ""),
		"attribution": item.get("attribution", ""),
		"measured_share": item.get("measured_share", 0.0),
		"measured_evidence": evidence.get("text", ""),
		"pass": evidence.get("pass", null),
		"suggestion": item.get("suggestion", ""),
		"setting": item.get("setting", ""),
		"node_property": item.get("node_property", ""),
		"offenders": item.get("offenders", []),
		"tradeoff": item.get("tradeoff", ""),
		"expected_effect": item.get("expected_effect", ""),
		"verify_step": item.get("verify_step", ""),
		"source": item.get("source", ""),
		"optional": item.get("optional", false),
		"optional_reason": item.get("optional_reason", ""),
		"applied": false,
	}
	# measure_change finding=<id> tries it in the running game.
	if not item.get("experiment", []).is_empty():
		brief["experiment"] = item["experiment"]
	# Godot already shows it (editor or run time); such findings follow the rest of their area.
	if str(item.get("godot_warns", "")) != "":
		brief["godot_warns"] = item["godot_warns"]
	if item.has("same_pass"):
		brief["same_pass"] = item["same_pass"].map(func(member): return {
			"id": member.get("id", ""),
			"title": member.get("title", ""),
			"severity": member.get("severity", ""),
			"suggestion": member.get("suggestion", ""),
			"setting": member.get("setting", ""),
			"node_property": member.get("node_property", ""),
			"offenders": member.get("offenders", []),
			"tradeoff": member.get("tradeoff", ""),
			"expected_effect": member.get("expected_effect", ""),
			"verify_step": member.get("verify_step", ""),
			"source": member.get("source", ""),
			"heuristic": member.get("heuristic", false),
			"optional": member.get("optional", false),
		})
	if item.has("count"):
		brief["count"] = int(item["count"])
	if str(item.get("vendor_note", "")) != "":
		brief["vendor_note"] = str(item.get("vendor_note", ""))
	if str(item.get("engine_version_note", "")) != "":
		brief["engine_version_note"] = str(item.get("engine_version_note", ""))
	return brief


static func _error(message: String) -> Dictionary:
	return {
		"isError": true,
		"content": [{"type": "text", "text": message}]
	}
