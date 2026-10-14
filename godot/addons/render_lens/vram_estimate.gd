extends RefCounted

## Game-side Video RAM estimate.
## RenderingServer has no GDScript binding for texture_debug_usage / mesh_debug_usage
## (servers/debugger/servers_debugger.cpp builds that list). Bytes here come from
## Texture2D size and format, and from Mesh surface vertex/index counts.
## RenderingServer.get_rendering_info remains the device total.

const RESOURCE_CAP := 2000


static func texture_bytes(width: int, height: int, format: int, mipmaps: bool) -> int:
	if width <= 0 or height <= 0:
		return 0
	var block := _block(format)
	var bytes := 0
	if block.x > 1:
		var tiles_x := int(ceil(float(width) / float(block.x)))
		var tiles_y := int(ceil(float(height) / float(block.y)))
		bytes = tiles_x * tiles_y * block.z
	else:
		bytes = width * height * block.z
	if mipmaps and bytes > 0:
		bytes = int(ceil(float(bytes) * 4.0 / 3.0))
	return maxi(bytes, 0)


static func mesh_bytes(mesh: Mesh) -> int:
	return int(_mesh_totals(mesh)[0])


## [bytes, vertices] in one pass, so a mesh without stored lengths builds its arrays once.
static func _mesh_totals(mesh: Mesh) -> Array:
	if mesh == null:
		return [0, 0]
	var total := 0
	var vertices := 0
	var surfaces: int = mesh.get_surface_count()
	for i in surfaces:
		var counted: Dictionary = _surface_counts(mesh, i)
		var verts := int(counted.get("verts", 0))
		var indices := int(counted.get("indices", 0))
		var fmt := int(counted.get("format", 0))
		var stride := _vertex_stride(fmt)
		var index_bytes := 2
		if verts > 65535:
			index_bytes = 4
		total += verts * stride + indices * index_bytes
		vertices += verts
	return [total, vertices]


static func _surface_counts(mesh: Mesh, surface: int) -> Dictionary:
	# ArrayMesh exposes the lengths. PrimitiveMesh only builds arrays on demand.
	if mesh.has_method("surface_get_array_len"):
		return {
			"verts": int(mesh.surface_get_array_len(surface)),
			"indices": int(mesh.surface_get_array_index_len(surface)),
			"format": int(mesh.surface_get_format(surface)),
		}
	# PrimitiveMesh and ImmediateMesh expose no lengths, so their buffers are read back from the GPU
	# (mesh_surface_get_arrays; PrimitiveMesh.get_mesh_arrays does the same): once per mesh, through _mesh_totals.
	var arrays: Array = mesh.surface_get_arrays(surface)
	var verts := 0
	var indices := 0
	var fmt := 0
	if arrays.size() > Mesh.ARRAY_VERTEX and arrays[Mesh.ARRAY_VERTEX] != null:
		verts = int(arrays[Mesh.ARRAY_VERTEX].size())
		fmt |= Mesh.ARRAY_FORMAT_VERTEX
	if arrays.size() > Mesh.ARRAY_NORMAL and arrays[Mesh.ARRAY_NORMAL] != null:
		fmt |= Mesh.ARRAY_FORMAT_NORMAL
	if arrays.size() > Mesh.ARRAY_TANGENT and arrays[Mesh.ARRAY_TANGENT] != null:
		fmt |= Mesh.ARRAY_FORMAT_TANGENT
	if arrays.size() > Mesh.ARRAY_COLOR and arrays[Mesh.ARRAY_COLOR] != null:
		fmt |= Mesh.ARRAY_FORMAT_COLOR
	if arrays.size() > Mesh.ARRAY_TEX_UV and arrays[Mesh.ARRAY_TEX_UV] != null:
		fmt |= Mesh.ARRAY_FORMAT_TEX_UV
	if arrays.size() > Mesh.ARRAY_TEX_UV2 and arrays[Mesh.ARRAY_TEX_UV2] != null:
		fmt |= Mesh.ARRAY_FORMAT_TEX_UV2
	if arrays.size() > Mesh.ARRAY_INDEX and arrays[Mesh.ARRAY_INDEX] != null:
		indices = int(arrays[Mesh.ARRAY_INDEX].size())
		fmt |= Mesh.ARRAY_FORMAT_INDEX
	return {"verts": verts, "indices": indices, "format": fmt}


static func collect(root: Node) -> Dictionary:
	var resources: Array = []
	var seen := {}
	var nodes_left := [8000]
	var truncated := false
	if root != null:
		truncated = _walk_node(root, seen, resources, nodes_left)
	resources.sort_custom(func(a, b):
		return int(a.get("vram_bytes", 0)) > int(b.get("vram_bytes", 0))
	)
	var total := 0
	for item in resources:
		total += int(item.get("vram_bytes", 0))
	var info := {}
	info["TEXTURE_MEM_USED"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED)
	info["BUFFER_MEM_USED"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_BUFFER_MEM_USED)
	info["VIDEO_MEM_USED"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED)
	var device := {"available": false}  # no RenderingDevice on Compatibility
	var rd := RenderingServer.get_rendering_device()
	if rd != null:
		device = {
			"available": true,
			"memory_textures": rd.get_memory_usage(RenderingDevice.MEMORY_TEXTURES),
			"memory_buffers": rd.get_memory_usage(RenderingDevice.MEMORY_BUFFERS),
			"memory_total": rd.get_memory_usage(RenderingDevice.MEMORY_TOTAL),
		}
	return {
		"ok": true,
		"source": "game_resource_estimate",
		"resources": resources,
		"resource_count": resources.size(),
		"total_bytes": total,
		"truncated": truncated or seen.has("capped"),
		"resource_cap": RESOURCE_CAP,
		"rendering_info": info,
		"device": device,
		"note": "Per-resource bytes are estimated in the game from Texture2D get_size/get_format (mip chain approximated as 4/3) and Mesh surface strides. This is not ServersDebugger::ResourceUsage. rendering_info is RenderingServer.get_rendering_info in the game process. A resident RenderingDevice texture is marked rd_resident via texture_get_rd_texture; its byte size is still the estimate.",
	}


static func _walk_node(root: Node, seen: Dictionary, resources: Array, nodes_left: Array) -> bool:
	# Iterative: GDScript's call stack stops at 1024 frames and generated scenes can nest deeper.
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		if int(nodes_left[0]) <= 0:
			return true
		nodes_left[0] = int(nodes_left[0]) - 1
		var node: Node = stack.pop_back()
		_node_resources(node, seen, resources)
		var children := node.get_children()
		for index in range(children.size() - 1, -1, -1):
			stack.push_back(children[index])
	return false


static func _node_resources(node: Node, seen: Dictionary, resources: Array) -> void:
	for prop in node.get_property_list():
		var pname := str(prop.get("name", ""))
		if pname == "script" or pname == "owner":
			continue
		# Hidden properties (usage NONE, e.g. GPUParticles3D draw_pass_2 with one pass) make the getter print an engine error.
		if int(prop.get("type", -1)) != TYPE_OBJECT or int(prop.get("usage", 0)) & (PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR) == 0:
			continue
		var value = node.get(pname)
		if is_instance_valid(value) and value is Resource and not (value is Script):  # an exported Node reference can be freed
			_consider(value, seen, resources)


static func _consider(res: Resource, seen: Dictionary, resources: Array) -> void:
	var key: int = res.get_instance_id()
	if seen.has(key):
		return
	seen[key] = true
	if res is ViewportTexture:
		return  # its memory is the SubViewport's render target, and get_size() errors while no viewport is set
	# At the cap, containers still descend so every texture or mesh left out marks the result truncated.
	var full := resources.size() >= RESOURCE_CAP
	if full and (res is Texture2D or res is Mesh):
		seen["capped"] = true  # string key cannot collide with instance ids
	if res is Texture2D:
		if not full:
			_add_texture(res, resources)
	elif res is Mesh:
		if not full:
			_add_mesh(res, resources)
		for i in res.get_surface_count():
			var surface_material: Material = res.surface_get_material(i)
			if surface_material != null:
				_consider(surface_material, seen, resources)
	elif res is SpriteFrames:
		for anim in res.get_animation_names():
			for i in res.get_frame_count(anim):
				var frame: Texture2D = res.get_frame_texture(anim, i)
				if frame != null:
					_consider(frame, seen, resources)
	elif res is Material or res is Environment or res is Sky:
		for prop in res.get_property_list():
			var pname := str(prop.get("name", ""))
			if int(prop.get("type", -1)) != TYPE_OBJECT or int(prop.get("usage", 0)) & (PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR) == 0:
				continue
			var nested = res.get(pname)
			if is_instance_valid(nested) and nested is Resource and not (nested is Script):
				_consider(nested, seen, resources)


static func _add_texture(tex: Texture2D, resources: Array) -> void:
	var size: Vector2 = tex.get_size()
	var format := Image.FORMAT_RGBA8
	if tex.has_method("get_format"):
		format = int(tex.get_format())
	var mips := false
	if tex.has_method("has_mipmaps"):
		mips = bool(tex.has_mipmaps())
	var bytes := texture_bytes(int(size.x), int(size.y), format, mips)
	var rd_resident := false
	if RenderingServer.get_rendering_device() != null and RenderingServer.has_method("texture_get_rd_texture"):
		var rd_tex: RID = RenderingServer.texture_get_rd_texture(tex.get_rid())
		rd_resident = rd_tex.is_valid()
	var path: String = tex.resource_path
	if path == "":
		path = "texture:%d" % tex.get_instance_id()
	resources.append({
		"path": path,
		"format": "%dx%d %s" % [int(size.x), int(size.y), _format_name(format)],
		"type": tex.get_class(),
		"vram_bytes": bytes,
		"rd_resident": rd_resident,
		"estimate": true,
	})


static func _add_mesh(mesh: Mesh, resources: Array) -> void:
	var totals := _mesh_totals(mesh)
	var bytes := int(totals[0])
	if bytes <= 0:
		return
	var path: String = mesh.resource_path
	if path == "":
		path = "mesh:%d" % mesh.get_instance_id()
	var verts := int(totals[1])
	resources.append({
		"path": path,
		"format": "%d Vertices" % verts,
		"type": mesh.get_class(),
		"vram_bytes": bytes,
		"estimate": true,
	})


static func _format_name(format: int) -> String:
	match format:
		Image.FORMAT_RGBA8:
			return "RGBA8"
		Image.FORMAT_RGB8:
			return "RGB8"
		Image.FORMAT_DXT1, Image.FORMAT_DXT5:
			return "BCn"
		_:
			return "format %d" % format


static func _vertex_stride(fmt: int) -> int:
	var stride := 0
	var two_d := (fmt & Mesh.ARRAY_FLAG_USE_2D_VERTICES) != 0
	if (fmt & Mesh.ARRAY_FORMAT_VERTEX) != 0:
		if two_d:
			stride += 8
		else:
			stride += 12
	if (fmt & Mesh.ARRAY_FORMAT_NORMAL) != 0:
		stride += 12
	if (fmt & Mesh.ARRAY_FORMAT_TANGENT) != 0:
		stride += 16
	if (fmt & Mesh.ARRAY_FORMAT_COLOR) != 0:
		stride += 4
	if (fmt & Mesh.ARRAY_FORMAT_TEX_UV) != 0:
		stride += 8
	if (fmt & Mesh.ARRAY_FORMAT_TEX_UV2) != 0:
		stride += 8
	if (fmt & Mesh.ARRAY_FORMAT_CUSTOM0) != 0:
		stride += 16
	if (fmt & Mesh.ARRAY_FORMAT_CUSTOM1) != 0:
		stride += 16
	if (fmt & Mesh.ARRAY_FORMAT_CUSTOM2) != 0:
		stride += 16
	if (fmt & Mesh.ARRAY_FORMAT_CUSTOM3) != 0:
		stride += 16
	if (fmt & Mesh.ARRAY_FORMAT_BONES) != 0:
		stride += 8
	if (fmt & Mesh.ARRAY_FORMAT_WEIGHTS) != 0:
		stride += 16
	if stride <= 0:
		stride = 12
	return stride


static func _block(format: int) -> Vector3i:
	# x, y = block size in pixels. z = bytes per block (or bytes per pixel when x == 1).
	match format:
		Image.FORMAT_L8, Image.FORMAT_R8:
			return Vector3i(1, 1, 1)
		Image.FORMAT_LA8, Image.FORMAT_RG8, Image.FORMAT_RGB565, Image.FORMAT_RGBA4444, Image.FORMAT_RH:
			return Vector3i(1, 1, 2)
		Image.FORMAT_RGB8:
			return Vector3i(1, 1, 3)
		Image.FORMAT_RGBA8, Image.FORMAT_RF, Image.FORMAT_RGBE9995, Image.FORMAT_RGH:
			return Vector3i(1, 1, 4)
		Image.FORMAT_RGBH:
			return Vector3i(1, 1, 6)
		Image.FORMAT_RGF, Image.FORMAT_RGBAH:
			return Vector3i(1, 1, 8)
		Image.FORMAT_RGBF:
			return Vector3i(1, 1, 12)
		Image.FORMAT_RGBAF:
			return Vector3i(1, 1, 16)
		Image.FORMAT_DXT1, Image.FORMAT_RGTC_R, Image.FORMAT_ETC, Image.FORMAT_ETC2_R11, Image.FORMAT_ETC2_R11S, Image.FORMAT_ETC2_RGB8, Image.FORMAT_ETC2_RGB8A1:
			return Vector3i(4, 4, 8)
		Image.FORMAT_DXT3, Image.FORMAT_DXT5, Image.FORMAT_RGTC_RG, Image.FORMAT_BPTC_RGBA, Image.FORMAT_BPTC_RGBF, Image.FORMAT_BPTC_RGBFU, Image.FORMAT_ETC2_RG11, Image.FORMAT_ETC2_RG11S, Image.FORMAT_ETC2_RGBA8, Image.FORMAT_ETC2_RA_AS_RG, Image.FORMAT_DXT5_RA_AS_RG, Image.FORMAT_ASTC_4x4, Image.FORMAT_ASTC_4x4_HDR:
			return Vector3i(4, 4, 16)
		Image.FORMAT_ASTC_8x8, Image.FORMAT_ASTC_8x8_HDR:
			return Vector3i(8, 8, 16)
		_:
			return Vector3i(1, 1, 4)
