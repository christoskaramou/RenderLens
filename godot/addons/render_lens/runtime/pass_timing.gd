extends RefCounted

## Turn RenderingDevice absolute timestamps into inclusive and exclusive pass times.
## '>' opens a region, '<' closes it. A region's inclusive time is end - begin.
## Exclusive time is inclusive minus the inclusive time of direct children.
## An unmarked timestamp is a leaf; its time is the delta to the next timestamp.

const Pacing = preload("res://addons/render_lens/pacing.gd")

const NS_TO_MS := 1000000.0
const ZERO_MS := 0.0005


static func process_timestamps(timestamps: Array) -> Dictionary:
	if timestamps.is_empty():
		return {"passes": [], "tree": [], "total_gpu_ms": 0.0, "total_cpu_ms": 0.0}

	var roots: Array = []
	var stack: Array = []

	for i in range(timestamps.size()):
		var ts: Dictionary = timestamps[i]
		var cleaned := str(ts.get("name", "")).strip_edges()
		var gpu_ns := float(ts.get("gpu_ns", 0.0))
		var cpu_ns := float(ts.get("cpu_ns", 0.0))

		if cleaned.begins_with(">"):
			stack.push_back({
				"name": cleaned.trim_prefix(">").strip_edges(),
				"begin_gpu": gpu_ns,
				"begin_cpu": cpu_ns,
				"children": [],
				"inclusive_gpu_ms": 0.0,
				"inclusive_cpu_ms": 0.0,
				"exclusive_gpu_ms": 0.0,
				"exclusive_cpu_ms": 0.0,
			})
		elif cleaned.begins_with("<"):
			if stack.is_empty():
				continue
			var node: Dictionary = stack.pop_back()
			_close_region(node, gpu_ns, cpu_ns)
			_attach(stack, roots, node)
		else:
			# The last marker has no timestamp after it, so its duration is unknown (in a frame cut off at the timestamp
			# limit it is a pass that kept running); counting it as a 0 ms call would skew per-pass medians and counts.
			if i + 1 >= timestamps.size():
				continue
			var nxt: Dictionary = timestamps[i + 1]
			var dur_gpu := _ms(float(nxt.get("gpu_ns", 0.0)) - gpu_ns)
			var dur_cpu := _ms(float(nxt.get("cpu_ns", 0.0)) - cpu_ns)
			_attach(stack, roots, {
				"name": cleaned,
				"inclusive_gpu_ms": dur_gpu,
				"inclusive_cpu_ms": dur_cpu,
				"exclusive_gpu_ms": dur_gpu,
				"exclusive_cpu_ms": dur_cpu,
				"children": [],
			})

	if not timestamps.is_empty() and not stack.is_empty():
		var last: Dictionary = timestamps[timestamps.size() - 1]
		var last_gpu := float(last.get("gpu_ns", 0.0))
		var last_cpu := float(last.get("cpu_ns", 0.0))
		while not stack.is_empty():
			var open_node: Dictionary = stack.pop_back()
			# Closed at the last timestamp, not by its own "<" marker: in a frame cut off at the timestamp limit its time
			# is partial (measure_change does not compare such a pass across cut-off captures).
			open_node["incomplete"] = true
			_close_region(open_node, last_gpu, last_cpu)
			_attach(stack, roots, open_node)

	var first: Dictionary = timestamps[0]
	var end: Dictionary = timestamps[timestamps.size() - 1]
	var total_gpu := _ms(float(end.get("gpu_ns", 0.0)) - float(first.get("gpu_ns", 0.0)))
	var total_cpu := _ms(float(end.get("cpu_ns", 0.0)) - float(first.get("cpu_ns", 0.0)))

	var flat: Array = []
	for root in roots:
		_flatten(root, flat, 0, "")

	return {
		"passes": flat,
		"tree": roots,
		"total_gpu_ms": total_gpu,
		"total_cpu_ms": total_cpu,
	}


static func aggregate_frames(frames: Array) -> Dictionary:
	var frame_gpu: Array = []
	var frame_cpu: Array = []
	var viewport_gpu: Array = []
	var rejected_max := -1.0
	var acc := {}
	var truncated := 0
	var limit := 0

	for frame in frames:
		var fd: Dictionary = frame
		limit = int(fd.get("timestamp_limit", 0))
		if limit > 0 and int(fd.get("timestamp_count", 0)) >= limit:
			truncated += 1
		frame_gpu.append(float(fd.get("total_gpu_ms", 0.0)))
		frame_cpu.append(float(fd.get("total_cpu_ms", 0.0)))
		var raw_viewport := float(fd.get("viewport_gpu_ms", 0.0))
		var sane_viewport := Pacing.sane_viewport_ms(raw_viewport)
		if sane_viewport < 0.0:
			if raw_viewport > rejected_max:
				rejected_max = raw_viewport
		else:
			viewport_gpu.append(sane_viewport)

		var sums := {}
		var passes: Array = fd.get("passes", [])
		for item in passes:
			var pd: Dictionary = item
			var name := str(pd.get("name", "")).strip_edges()
			if name.is_empty():
				continue
			if not sums.has(name):
				sums[name] = {
					"ex": 0.0,
					"inc": 0.0,
					"n": 0,
					"parent": str(pd.get("parent", "")),
					"depth": int(pd.get("depth", 0)),
					"incomplete": false,
				}
			sums[name].incomplete = sums[name].incomplete or bool(pd.get("incomplete", false))
			sums[name].ex += float(pd.get("exclusive_gpu_ms", 0.0))
			sums[name].inc += float(pd.get("inclusive_gpu_ms", 0.0))
			sums[name].n += 1

		for name in sums.keys():
			if not acc.has(name):
				acc[name] = {"ex": [], "inc": [], "n": [], "parent": sums[name].parent, "depth": sums[name].depth, "incomplete": false}
			acc[name].incomplete = acc[name].incomplete or sums[name].incomplete
			acc[name].ex.append(float(sums[name].ex))
			acc[name].inc.append(float(sums[name].inc))
			acc[name].n.append(int(sums[name].n))

	frame_gpu.sort()
	frame_cpu.sort()
	viewport_gpu.sort()
	var median_frame := percentile(frame_gpu, 50.0)
	var median_viewport := 0.0
	var p95_viewport := 0.0
	if viewport_gpu.is_empty() and rejected_max >= 0.0:
		median_viewport = -1.0
		p95_viewport = -1.0
	elif not viewport_gpu.is_empty():
		median_viewport = percentile(viewport_gpu, 50.0)
		p95_viewport = percentile(viewport_gpu, 95.0)

	var all_passes: Array = []
	var hierarchy: Array = []
	var share_sum := 0.0

	for name in acc.keys():
		var ex: Array = acc[name].ex
		var inc: Array = acc[name].inc
		var counts: Array = acc[name].n
		ex.sort()
		inc.sort()
		counts.sort()
		var ex_med := percentile(ex, 50.0)
		var ex_p95 := percentile(ex, 95.0)
		var inc_med := percentile(inc, 50.0)
		var inc_p95 := percentile(inc, 95.0)
		if ex_med <= ZERO_MS and inc_med <= ZERO_MS:
			continue
		var share := 0.0
		if median_frame > ZERO_MS:
			# The median is the cost when the pass runs; a pass in 5 of 60 frames costs a twelfth of that per frame.
			share = (ex_med * ex.size() / maxf(frame_gpu.size(), 1.0) / median_frame) * 100.0
		if ex_med > ZERO_MS:
			share_sum += share
		var calls := int(round(percentile(counts, 50.0)))
		# measure_change compares a pass across cut-off captures only when every frame ran it as often.
		var calls_vary: bool = counts.front() != counts.back()
		var row := {
			"name": name,
			"parent": acc[name].parent,
			"depth": acc[name].depth,
			"exclusive_median_ms": ex_med,
			"exclusive_p95_ms": ex_p95,
			"inclusive_median_ms": inc_med,
			"inclusive_p95_ms": inc_p95,
			"share_pct": share,
			"calls_per_frame": calls,
			"calls_vary": calls_vary,
			"incomplete": acc[name].incomplete,
			"frames": ex.size(),
		}
		all_passes.append(row)
		hierarchy.append({
			"name": name,
			"parent": acc[name].parent,
			"depth": acc[name].depth,
			"inclusive_median_ms": inc_med,
			"inclusive_p95_ms": inc_p95,
			"exclusive_median_ms": ex_med,
			"calls_per_frame": calls,
			"calls_vary": calls_vary,
			"incomplete": acc[name].incomplete,
		})

	all_passes.sort_custom(func(a, b): return float(a.share_pct) > float(b.share_pct))
	hierarchy.sort_custom(func(a, b): return int(a.depth) < int(b.depth))

	var top: Array = []
	for row in all_passes:
		if float(row.exclusive_median_ms) <= ZERO_MS:
			continue
		top.append(row)
		if top.size() >= 8:
			break

	return {
		"frame_count": frames.size(),
		"median_frame_gpu_ms": median_frame,
		"p95_frame_gpu_ms": percentile(frame_gpu, 95.0),
		"median_frame_cpu_ms": percentile(frame_cpu, 50.0),
		"median_viewport_gpu_ms": median_viewport,
		"p95_viewport_gpu_ms": p95_viewport,
		"viewport_rejected_max_ms": rejected_max,
		"timestamp_limit": limit,
		"timestamp_truncated_frames": truncated,
		"share_basis": "exclusive pass GPU time / median frame GPU time from the timestamp span (last captured GPU timestamp minus first)",
		"exclusive_share_sum_pct": share_sum,
		"passes": all_passes,
		"top_passes": top,
		"hierarchy": hierarchy,
	}


static func percentile(sorted_arr: Array, p: float) -> float:
	if sorted_arr.is_empty():
		return 0.0
	var index := (p / 100.0) * float(sorted_arr.size() - 1)
	var lower := int(floor(index))
	var upper := int(ceil(index))
	var lo := float(sorted_arr[lower])
	var hi := float(sorted_arr[upper])
	if lower == upper:
		return lo
	var weight := index - float(lower)
	return lo * (1.0 - weight) + hi * weight


static func _ms(delta_ns: float) -> float:
	var ms := delta_ns / NS_TO_MS
	if ms < ZERO_MS:
		return 0.0
	return ms


static func _close_region(node: Dictionary, end_gpu_ns: float, end_cpu_ns: float) -> void:
	var inc_gpu := _ms(end_gpu_ns - float(node.begin_gpu))
	var inc_cpu := _ms(end_cpu_ns - float(node.begin_cpu))
	var child_gpu := 0.0
	var child_cpu := 0.0
	var children: Array = node.children
	for child_item in children:
		var child: Dictionary = child_item
		child_gpu += float(child.inclusive_gpu_ms)
		child_cpu += float(child.inclusive_cpu_ms)
	node.inclusive_gpu_ms = inc_gpu
	node.inclusive_cpu_ms = inc_cpu
	node.exclusive_gpu_ms = maxf(0.0, inc_gpu - child_gpu)
	node.exclusive_cpu_ms = maxf(0.0, inc_cpu - child_cpu)
	if float(node.exclusive_gpu_ms) < ZERO_MS:
		node.exclusive_gpu_ms = 0.0
	node.erase("begin_gpu")
	node.erase("begin_cpu")


static func _attach(stack: Array, roots: Array, node: Dictionary) -> void:
	if stack.is_empty():
		roots.push_back(node)
		return
	var parent: Dictionary = stack[stack.size() - 1]
	var children: Array = parent.children
	children.push_back(node)


static func _flatten(node: Dictionary, out: Array, depth: int, parent_name: String) -> void:
	out.append({
		"name": str(node.get("name", "")),
		"inclusive_gpu_ms": float(node.get("inclusive_gpu_ms", 0.0)),
		"exclusive_gpu_ms": float(node.get("exclusive_gpu_ms", 0.0)),
		"inclusive_cpu_ms": float(node.get("inclusive_cpu_ms", 0.0)),
		"exclusive_cpu_ms": float(node.get("exclusive_cpu_ms", 0.0)),
		"depth": depth,
		"parent": parent_name,
		"incomplete": bool(node.get("incomplete", false)),
	})
	var children: Array = node.get("children", [])
	var node_name := str(node.get("name", ""))
	for child_item in children:
		_flatten(child_item, out, depth + 1, node_name)
