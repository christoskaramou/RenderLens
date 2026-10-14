extends RefCounted

## Order properties every advice package keeps, whatever its inputs. Shares are compared only between findings timed
## the same way (a measured GPU pass); one measured pass is never claimed by two ranked entries.

const AREAS := ["performance", "visual", "missing", "to_check"]
const SEVERITY := {"high": 3, "medium": 2, "low": 1}


static func violations(packed: Dictionary) -> Array:
	var out: Array = []
	var last := 0
	for row in packed.top:
		var index := AREAS.find(str(row.get("area", "")))
		if index < last:
			out.append("top goes back to %s at %s" % [row.get("area"), row.id])
		last = maxi(last, index)
	var claimed := {}
	var previous := INF
	for row in packed.performance_findings:
		var measured = row.get("measured_evidence", {}).get("pass")
		if measured == null:
			continue
		if claimed.has(measured.name):
			out.append("pass '%s' is claimed by %s and %s" % [measured.name, claimed[measured.name], row.id])
		claimed[measured.name] = row.id
		for member in row.get("same_pass", []):
			if member.get("area") != "performance" or member.get("grouped_under") != row.id or member.get("optional") != row.get("optional"):
				out.append("%s under %s does not share its area, link or optional flag" % [member.id, row.id])
			if float(row.measured_share) < 1.0 and member.severity != "low":
				out.append("%s under the %.2f%% entry %s kept severity %s" % [member.id, float(row.measured_share), row.id, member.severity])
		var share := float(row.measured_share)
		if share > previous + 0.001:
			out.append("pass shares rise at %s (%.2f after %.2f)" % [row.id, share, previous])
		previous = share
	for row in packed.get("to_check", []):
		if float(row.get("measured_share", 0.0)) > 0.0 or row.get("measured_evidence", {}).get("pass") != null:
			out.append("%s has a measured cost but sits in to_check" % row.id)
	for key in ["optional_quality", "configuration_findings"]:
		var rank := 4
		var warned := false
		for row in packed[key]:
			# Findings Godot already shows follow the rest, each group in severity order.
			if str(row.get("godot_warns", "")) != "" and not warned:
				warned = true
				rank = 4
			elif str(row.get("godot_warns", "")) == "" and warned:
				out.append("%s lists %s, which Godot does not warn about, after findings it does" % [key, row.id])
			var sev: int = SEVERITY.get(str(row.severity), 0)
			if sev > rank:
				out.append("%s is out of severity order at %s" % [key, row.id])
			rank = sev
	return out
