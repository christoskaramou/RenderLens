extends SceneTree

const Shaders = preload("res://addons/render_lens/shader_checks.gd")


func _init() -> void:
	var limits := Shaders.device_limits()
	assert(limits.size() == 16 and limits.x > 0 and limits.y > 0 and limits.z > 0 and limits.invocations > 0)
	assert(limits.push_constants > 0 and limits.samplers > 0 and limits.sampled_images > 0 and limits.storage_images > 0)
	for key in ["samplers_stage", "sampled_images_stage", "storage_images_stage", "uniform_buffers_stage", "storage_buffers_stage", "bound_sets", "uniform_buffer_size"]:
		assert(limits[key] > 0, key)
	assert((limits.shared_memory > 0) == (Engine.get_version_info().minor >= 5), "4.4 must skip its unimplemented Vulkan shared-memory getter; 4.5 implements it")
	var features := Shaders.device_features()
	assert(features.has("buffer_device_address") and typeof(features.buffer_device_address) == TYPE_BOOL)
	assert(features.has("ray_query") == (Engine.get_version_info().minor >= 7))
	assert(features.has("raytracing_pipeline") == (Engine.get_version_info().minor >= 7))
	if features.has("raytracing_pipeline"):
		assert(features.raytracing_pipeline == RenderingServer.get_rendering_device().has_feature(ClassDB.class_get_integer_constant("RenderingDevice", "SUPPORTS_RAYTRACING_PIPELINE")))
	var over := {"counts": {}, "offenders": {}}
	Shaders.record(Vector3i(limits.x + 1, 1, 1), over, "synthetic metadata, never submitted", limits)
	assert(over.counts.has("check_compute_dimension_limit"))
	var device := RenderingServer.create_local_rendering_device()
	assert(device != null, "A real RenderingDevice is required for the shader compilation check")
	for specialized in [false, true]:
		var source := RDShaderSource.new()
		var layout := "local_size_x_id=0, local_size_y=8, local_size_z=1" if specialized else "local_size_x=8, local_size_y=8, local_size_z=1"
		source.source_compute = "#version 450\nlayout(%s) in;\nlayout(set=0,binding=0,std430) buffer Output { uint data[]; };\nvoid main() { data[gl_GlobalInvocationID.x] = gl_LocalInvocationID.y; }" % layout
		var spirv := device.shader_compile_spirv_from_source(source)
		assert(spirv.compile_error_compute.is_empty(), spirv.compile_error_compute)
		var parsed := Shaders.local_size(spirv.bytecode_compute)
		if specialized:
			assert(parsed.has("skip"), "A specialization-controlled dimension was treated as fixed")
		else:
			assert(parsed.get("size") == Vector3i(8, 8, 1), str(parsed))
			var valid := {"counts": {}, "offenders": {}}
			Shaders.record(parsed.size, valid, "compiled shader", limits)
			assert(not valid.counts.has("check_compute_dimension_limit") and not valid.counts.has("check_compute_invocation_limit"))
	for separate in [false, true]:
		var source := RDShaderSource.new()
		var declarations := "layout(set=0,binding=1) uniform sampler sample_state; layout(set=0,binding=2) uniform texture2D image_data;" if separate else "layout(set=0,binding=1) uniform sampler2D combined_image;"
		var sampler := "sampler2D(image_data, sample_state)" if separate else "combined_image"
		source.source_compute = "#version 450\nlayout(local_size_x=8) in; layout(set=0,binding=0,std430) buffer Output { vec4 data[]; }; shared vec4 tile[32]; %s void main() { tile[gl_LocalInvocationID.x] = textureLod(%s, vec2(0.5), 0.0); barrier(); data[gl_GlobalInvocationID.x] = tile[7-gl_LocalInvocationID.x]; }" % [declarations, sampler]
		var spirv := device.shader_compile_spirv_from_source(source)
		assert(spirv.compile_error_compute.is_empty(), spirv.compile_error_compute)
		var parsed := Shaders.local_size(spirv.bytecode_compute)
		assert(parsed.shared_bytes == 512 and parsed.separate_sampler == separate, str(parsed))
		assert(parsed.descriptor_bytes == (24 if separate else 20), str(parsed))
		assert(parsed.descriptor_counts == {"samplers": 1, "sampled_images": 1, "storage_images": 0, "uniform_buffers": 0, "storage_buffers": 1}, str(parsed))
		assert(parsed.multidimensional_image_access, str(parsed))
		parsed["driver"] = RenderingServer.get_current_rendering_driver_name()
		var state := {"counts": {}, "offenders": {}}
		Shaders.record(parsed.size, state, "compiled sampler/shared-memory shader", limits, parsed)
		assert(state.counts.has("check_compute_nvidia_separate_sampler") == separate)
		assert(not state.counts.has("check_compute_shared_memory_limit"))
	for count in [64, 65]:
		var source := RDShaderSource.new()
		source.source_compute = "#version 450\nlayout(local_size_x=1) in; layout(set=0,binding=0,std430) buffer Output { vec4 data[]; }; layout(set=0,binding=1) uniform sampler2D images[%d]; void main() { data[gl_GlobalInvocationID.x] = textureLod(images[0], vec2(0.5), 0.0); }" % count
		var spirv := device.shader_compile_spirv_from_source(source)
		assert(spirv.compile_error_compute.is_empty(), spirv.compile_error_compute)
		var parsed := Shaders.local_size(spirv.bytecode_compute)
		assert(parsed.descriptor_bytes == count * 4 + 16 and not parsed.separate_sampler, str(parsed))
		assert(parsed.descriptor_counts == {"samplers": count, "sampled_images": count, "storage_images": 0, "uniform_buffers": 0, "storage_buffers": 1}, str(parsed))
	for count in [13, 14, 33]:
		var source := RDShaderSource.new()
		source.source_compute = "#version 450\nlayout(local_size_x=1) in; layout(push_constant,std430) uniform Params { uint values[%d]; }; layout(set=0,binding=0,std430) buffer Output { uint data[]; }; void main() { data[gl_GlobalInvocationID.x] = values[%d]; }" % [count, count - 1]
		var spirv := device.shader_compile_spirv_from_source(source)
		assert(spirv.compile_error_compute.is_empty(), spirv.compile_error_compute)
		var parsed := Shaders.local_size(spirv.bytecode_compute)
		assert(parsed.push_constant_bytes == count * 4, str(parsed))
	var storage_source := RDShaderSource.new()
	storage_source.source_compute = "#version 450\nlayout(local_size_x=1) in; layout(set=0,binding=0,rgba32f) uniform image2D images[17]; void main() { imageStore(images[0], ivec2(gl_GlobalInvocationID.xy), vec4(1.0)); }"
	var storage_spirv := device.shader_compile_spirv_from_source(storage_source)
	assert(storage_spirv.compile_error_compute.is_empty(), storage_spirv.compile_error_compute)
	assert(Shaders.local_size(storage_spirv.bytecode_compute).descriptor_counts == {"samplers": 0, "sampled_images": 0, "storage_images": 17, "uniform_buffers": 0, "storage_buffers": 0})
	assert(Shaders.local_size(storage_spirv.bytecode_compute).multidimensional_image_access)
	for dimension in ["1D", "2D", "3D"]:
		var source := RDShaderSource.new()
		var coordinate: String = {"1D": "0.0", "2D": "vec2(0.0)", "3D": "vec3(0.0)"}[dimension]
		source.source_compute = "#version 450\nlayout(local_size_x=8) in; layout(set=0,binding=0) uniform sampler%s input_image; layout(set=0,binding=1,std430) buffer Output { vec4 data[]; }; void main() { data[gl_GlobalInvocationID.x] = textureLod(input_image, %s, 0.0); }" % [dimension, coordinate]
		var spirv := device.shader_compile_spirv_from_source(source)
		assert(spirv.compile_error_compute.is_empty(), spirv.compile_error_compute)
		assert(Shaders.local_size(spirv.bytecode_compute).multidimensional_image_access == (dimension != "1D"))
	var address_source := RDShaderSource.new()
	for count in [1, 17]:
		var source := RDShaderSource.new()
		var declarations := "layout(set=3,binding=0,std140) uniform Params { layout(offset=80) vec4 value; } params;"
		for binding in count:
			declarations += "layout(set=0,binding=%d,std430) buffer Output%d { vec4 data[]; } output%d;" % [binding, binding, binding]
		source.source_compute = "#version 450\nlayout(local_size_x=1) in; %s void main() { output0.data[gl_GlobalInvocationID.x] = params.value; }" % declarations
		var spirv := device.shader_compile_spirv_from_source(source)
		assert(spirv.compile_error_compute.is_empty(), spirv.compile_error_compute)
		var parsed := Shaders.local_size(spirv.bytecode_compute)
		assert(parsed.bound_sets == 4 and parsed.uniform_buffer_size == 96, str(parsed))
		assert(parsed.descriptor_counts.uniform_buffers == 1 and parsed.descriptor_counts.storage_buffers == count, str(parsed))
		assert(parsed.descriptor_bytes == 8 + 16 * count, str(parsed))
	address_source.source_compute = "#version 450\n#extension GL_EXT_buffer_reference : require\nlayout(local_size_x=1) in; layout(buffer_reference,std430) buffer Values { uint value; }; layout(push_constant,std430) uniform Params { Values values; }; void main() { values.value = gl_GlobalInvocationID.x; }"
	var address_spirv := device.shader_compile_spirv_from_source(address_source)
	assert(address_spirv.compile_error_compute.is_empty(), address_spirv.compile_error_compute)
	assert(Shaders.local_size(address_spirv.bytecode_compute).requires_buffer_device_address)
	if Engine.get_version_info().minor >= 7:
		var query_source := RDShaderSource.new()
		query_source.source_compute = "#version 460\n#extension GL_EXT_ray_query : require\nlayout(local_size_x=1) in; layout(set=0,binding=0) uniform accelerationStructureEXT scene; layout(set=0,binding=1,std430) buffer Output { uint data[]; }; void main() { rayQueryEXT query; rayQueryInitializeEXT(query, scene, 0, 255, vec3(0.0), 0.01, vec3(0.0,0.0,1.0), 100.0); while (rayQueryProceedEXT(query)) {} data[gl_GlobalInvocationID.x] = rayQueryGetIntersectionTypeEXT(query, true); }"
		var query_spirv := device.shader_compile_spirv_from_source(query_source)
		assert(query_spirv.compile_error_compute.is_empty(), query_spirv.compile_error_compute)
		assert(Shaders.local_size(query_spirv.bytecode_compute).requires_ray_query)
	for entry in [["0u", "0.0", "1.0", false, false], ["768u", "0.0", "1.0", true, false], ["48u", "0.0", "1.0", true, false], ["3u", "0.0", "1.0", true, false], ["529u", "0.0", "1.0", false, false], ["0u", "-1.0", "1.0", false, true], ["0u", "2.0", "1.0", false, true], ["0u", "1.0", "1.0", false, false], ["special_flags", "special_min", "1.0", false, false]]:
		var query_source := RDShaderSource.new()
		query_source.source_compute = "#version 460\n#extension GL_EXT_ray_query : require\nlayout(local_size_x=1) in; layout(constant_id=2) const uint special_flags=768u; layout(constant_id=3) const float special_min=-1.0; layout(set=0,binding=0) uniform accelerationStructureEXT world; void main() { rayQueryEXT query; rayQueryInitializeEXT(query, world, %s, 255u, vec3(0.0), %s, vec3(0.0,0.0,1.0), %s); }" % [entry[0], entry[1], entry[2]]
		var query_spirv := device.shader_compile_spirv_from_source(query_source)
		assert(query_spirv.compile_error_compute.is_empty(), query_spirv.compile_error_compute)
		var parsed := Shaders.local_size(query_spirv.bytecode_compute)
		assert(parsed.ray_query_flags == entry[3] and parsed.ray_query_distance == entry[4], str(entry, parsed))
	for entry in [["uint", "value / 0u", true], ["int", "value / 0", true], ["float", "mod(value, 0.0)", true], ["float", "value / 0.0", false], ["uint", "value / 1u", false], ["uint", "value / divisor", false]]:
		var source := RDShaderSource.new()
		source.source_compute = "#version 450\nlayout(local_size_x=1) in; layout(constant_id=2) const uint divisor=0u; layout(set=0,binding=0,std430) buffer Values { %s value; %s result_value; }; void main() { result_value = %s; }" % [entry[0], entry[0], entry[1]]
		var spirv := device.shader_compile_spirv_from_source(source)
		assert(spirv.compile_error_compute.is_empty(), spirv.compile_error_compute)
		var parsed := Shaders.local_size(spirv.bytecode_compute)
		assert(parsed.zero_divisor == entry[2], str(entry, parsed))
	for entry in [["vec2(pow(-1.0,value))", true, false, false], ["vec2(pow(1.0,value))", false, false, false], ["pow(vec2(value,-1.0),other)", true, false, false], ["atan(vec2(0.0,value),vec2(0.0,1.0))", false, true, false], ["atan(vec2(0.0,value),vec2(1.0,1.0))", false, false, false], ["atan(vec2(value,0.0),vec2(value,0.0))", false, true, false], ["vec2(min(value,uintBitsToFloat(2143289344u)))", false, false, true], ["vec2(max(value,uintBitsToFloat(2143289344u)))", false, false, true], ["min(other,vec2(value,uintBitsToFloat(2143289344u)))", false, false, true], ["min(other,vec2(value,0.0))", false, false, false]]:
		var source := RDShaderSource.new()
		source.source_compute = "#version 450\nlayout(local_size_x=1) in; layout(set=0,binding=0,std430) buffer Values { float value; vec2 other; vec2 result_value; }; void main() { result_value = %s; }" % entry[0]
		var spirv := device.shader_compile_spirv_from_source(source)
		assert(spirv.compile_error_compute.is_empty(), spirv.compile_error_compute)
		var parsed := Shaders.local_size(spirv.bytecode_compute)
		assert(parsed.pow_domain == entry[1] and parsed.atan2_zero == entry[2] and parsed.minmax_nan == entry[3], str(entry, parsed))
	for entry in [["uvec2", "uvec2(value.x,0u)", true], ["uvec2", "uvec2(value.x,1u)", false], ["vec2", "vec2(value.x,0.0)", true], ["vec2", "vec2(value.x,1.0)", false]]:
		var source := RDShaderSource.new()
		var expression := "mod(value, %s)" % entry[1] if entry[0] == "vec2" else "value / %s" % entry[1]
		source.source_compute = "#version 450\nlayout(local_size_x=1) in; layout(set=0,binding=0,std430) buffer Values { %s value; %s result_value; }; void main() { result_value = %s; }" % [entry[0], entry[0], expression]
		var spirv := device.shader_compile_spirv_from_source(source)
		assert(spirv.compile_error_compute.is_empty(), spirv.compile_error_compute)
		assert(Shaders.local_size(spirv.bytecode_compute).zero_divisor == entry[2], str(entry))
	var gather_source := RDShaderSource.new()
	gather_source.source_compute = "#version 450\nlayout(local_size_x=1) in; layout(set=0,binding=0) uniform sampler2D input_image; layout(set=0,binding=1,std430) buffer Values { vec4 output_value; }; void main() { output_value = textureGather(input_image,vec2(0.0),4); }"
	var gather_spirv := device.shader_compile_spirv_from_source(gather_source)
	assert(not gather_spirv.compile_error_compute.is_empty() and gather_spirv.bytecode_compute.is_empty(), "Invalid gather components are already compiler errors")
	for value in ["1.0", "vec2(1.0)", "vec3(1.0)", "vec4(1.0)"]:
		var source := RDShaderSource.new()
		source.source_compute = "#version 450\nlayout(local_size_x=1) in; layout(set=0,binding=0,rgba32f) uniform image2D img; void main() { imageStore(img, ivec2(0), %s); }" % value
		var spirv := device.shader_compile_spirv_from_source(source)
		assert(spirv.compile_error_compute.is_empty() == (value == "vec4(1.0)"), "Undersized imageStore operands are already compiler findings")
	for indexed in [false, true]:
		var source := RDShaderSource.new()
		var layout := "set=0,binding=0,input_attachment_index=0" if indexed else "set=0,binding=0"
		source.source_fragment = "#version 450\nlayout(%s) uniform subpassInput attachments[2]; layout(location=0) out vec4 color; void main() { color = subpassLoad(attachments[0]); }" % layout
		var spirv := device.shader_compile_spirv_from_source(source)
		assert(spirv.compile_error_fragment.is_empty() == indexed, "Missing input attachment indices are already compiler findings")
	_interface_checks(device)
	_stage_checks(device)
	_header_checks(device)
	_image_format_checks(device)
	_interface_8bit_checks(device)
	_forbidden_capability_checks(device)
	_extension_namespace_checks(device)
	_cooperative_vector_checks(device)
	_intrinsic_training_checks(device)
	device.free()
	_font_cache_check()
	print("PASS actual Godot GLSL compiler and GPU limits: fixed workgroup decoded; specialization skipped; limits=", limits)
	quit()


func _intrinsic_training_checks(device: RenderingDevice) -> void:
	var keys := ["cooperative_outer_interpretation", "cooperative_reduce_type", "cooperative_training_storage", "cooperative_fp8_layout", "graph_capability", "tensor_declaration", "subgroup_repack"]
	for fixture in [
		["cooperative_reduce_int32", ["cooperative_reduce_type"]],
		["cooperative_reduce_float32", []],
		["cooperative_outer_interpretation5", ["cooperative_outer_interpretation"]],
		["cooperative_outer_workgroup", ["cooperative_training_storage"]],
		["cooperative_reduce_private", ["cooperative_training_storage"]],
		["cooperative_matmul_fp8_row", ["cooperative_fp8_layout"]],
		["cooperative_matmul_fp8_training", []],
	]:
		var original := RDShaderSPIRV.new()
		original.bytecode_compute = FileAccess.get_file_as_bytes("res://tests/fixtures/%s.spv" % fixture[0])
		var parsed := Shaders.local_size(original.bytecode_compute)
		var state := _imported_shader_state(original, "res://training_intrinsic_fixture")
		for key: String in keys:
			assert(parsed[key] == (key in fixture[1]))
			assert(state.counts.has("check_shader_" + key) == (key in fixture[1]))
		state = _imported_shader_state(original, "res://training_intrinsic_fixture", true)
		for key: String in keys:
			assert(not state.counts.has("check_shader_" + key))
		original.compile_error_fragment = "intentional other-stage fixture"
		state = _imported_shader_state(original, "res://training_intrinsic_fixture")
		for key: String in keys:
			assert(not state.counts.has("check_shader_" + key))
		original.compile_error_fragment = ""
		original.compile_error_compute = "intentional current-stage fixture"
		state = _imported_shader_state(original, "res://training_intrinsic_fixture")
		for key: String in keys:
			assert(not state.counts.has("check_shader_" + key))
		var source := RDShaderSource.new()
		source.source_compute = FileAccess.get_file_as_string("res://tests/fixtures/%s.source.txt" % fixture[0])
		var compiled := device.shader_compile_spirv_from_source(source)
		if Engine.get_version_info().minor < 7:
			assert(not compiled.compile_error_compute.is_empty() and compiled.bytecode_compute.is_empty())
			state = _imported_shader_state(compiled, "res://training_intrinsic_native_error")
			assert(state.counts.has("check_shader_compile_error"))
			for key: String in keys:
				assert(not state.counts.has("check_shader_" + key))
		else:
			assert(compiled.compile_error_compute.is_empty(), compiled.compile_error_compute)
			parsed = Shaders.local_size(compiled.bytecode_compute)
			for key: String in keys:
				assert(parsed[key] == (key in fixture[1]))
	var add := RDShaderSource.new()
	add.source_compute = "#version 460\n#extension GL_NV_cooperative_vector : require\nlayout(local_size_x=1) in; layout(set=0,binding=0,std430) buffer Output { float data[]; }; void main() { coopvecNV<float,4> a=coopvecNV<float,4>(1.0); coopvecNV<float,4> r; coopVecMatMulAddNV(r,a,1,data,0u,1000491003,data,0u,1,4u,4u,1,false,16u); data[0]=r[0]; }"
	var add_spirv := device.shader_compile_spirv_from_source(add)
	if Engine.get_version_info().minor >= 7:
		assert(add_spirv.compile_error_compute.is_empty(), add_spirv.compile_error_compute)
		assert(Shaders.local_size(add_spirv.bytecode_compute).cooperative_fp8_layout)
	else:
		assert(not add_spirv.compile_error_compute.is_empty() and add_spirv.bytecode_compute.is_empty())
	for capability in [4191, 1]:
		var source := RDShaderSource.new()
		source.source_compute = "#version 450\n#extension GL_EXT_spirv_intrinsics : require\nlayout(local_size_x=1) in; layout(set=0,binding=0,std430) buffer Output { int data[]; }; spirv_instruction(capabilities=[%d],id=128) int add_values(int a,int b); void main(){data[0]=add_values(1,2);}" % capability
		var spirv := device.shader_compile_spirv_from_source(source)
		assert(spirv.compile_error_compute.is_empty(), spirv.compile_error_compute)
		assert(Shaders.local_size(spirv.bytecode_compute).graph_capability == (capability == 4191))
		assert(_imported_shader_state(spirv, "res://graph_intrinsic").counts.has("check_shader_graph_capability") == (capability == 4191))
		assert(not _imported_shader_state(spirv, "res://graph_intrinsic", true).counts.has("check_shader_graph_capability"))
		spirv.compile_error_compute = "intentional current-stage fixture"
		assert(not _imported_shader_state(spirv, "res://graph_intrinsic").counts.has("check_shader_graph_capability"))
	for mode in [true, false]:
		var source := RDShaderSource.new()
		source.source_compute = "#version 450\n#extension GL_EXT_spirv_intrinsics : require\nlayout(local_size_x=1) in; layout(set=0,binding=0,std430) buffer Output { bool data[]; };\n" + ("spirv_execution_mode(extensions=[\"SPV_KHR_subgroup_uniform_control_flow\"],4421);\n" if mode else "") + "spirv_instruction(capabilities=[4479],extensions=[\"SPV_KHR_ray_tracing\"],id=5334) bool report_hit(float t,int kind); void main(){data[0]=report_hit(1.0,0);}"
		var spirv := device.shader_compile_spirv_from_source(source)
		assert(spirv.compile_error_compute.is_empty(), spirv.compile_error_compute)
		assert(Shaders.local_size(spirv.bytecode_compute).subgroup_repack == mode)
		assert(_imported_shader_state(spirv, "res://repack_intrinsic").counts.has("check_shader_subgroup_repack") == mode)
		assert(not _imported_shader_state(spirv, "res://repack_intrinsic", true).counts.has("check_shader_subgroup_repack"))
		spirv.compile_error_fragment = "intentional other-stage fixture"
		assert(not _imported_shader_state(spirv, "res://repack_intrinsic").counts.has("check_shader_subgroup_repack"))
	var tensor_bytes := FileAccess.get_file_as_bytes("res://tests/fixtures/tensor_ranked.spv")
	assert(not Shaders.local_size(tensor_bytes).tensor_declaration)
	for shape in [false, true]:
		var words := tensor_bytes.to_int32_array()
		var cursor := 5
		var changed := false
		while cursor < words.size():
			var count := (words[cursor] >> 16) & 0xffff
			if (words[cursor] & 0xffff) == 4163:
				assert(count == 4)
				if shape:
					words.insert(cursor + 4, words[cursor + 3])
					words[cursor] = (5 << 16) | 4163
				else:
					words.remove_at(cursor + 3)
					words[cursor] = (3 << 16) | 4163
				changed = true
				break
			cursor += count
		assert(changed)
		var spirv := RDShaderSPIRV.new()
		spirv.bytecode_compute = words.to_byte_array()
		assert(Shaders.local_size(spirv.bytecode_compute).tensor_declaration)
		assert(_imported_shader_state(spirv, "res://tensor_intrinsic").counts.has("check_shader_tensor_declaration"))
		assert(not _imported_shader_state(spirv, "res://tensor_intrinsic", true).counts.has("check_shader_tensor_declaration"))
		spirv.compile_error_fragment = "intentional other-stage fixture"
		assert(not _imported_shader_state(spirv, "res://tensor_intrinsic").counts.has("check_shader_tensor_declaration"))
		spirv.compile_error_fragment = ""
		spirv.compile_error_compute = "intentional current-stage fixture"
		assert(not _imported_shader_state(spirv, "res://tensor_intrinsic").counts.has("check_shader_tensor_declaration"))
	print("PASS intrinsic cooperative training, FP8 layouts, GraphARM, tensor declarations and subgroup repack; saved/native/import/error controls; never submitted")


func _cooperative_vector_checks(device: RenderingDevice) -> void:
	for name in ["cooperative_outer_float32_row", "cooperative_outer_float16_training"]:
		var bytes := FileAccess.get_file_as_bytes("res://tests/fixtures/%s.spv" % name)
		assert(not bytes.is_empty())
		var parsed := Shaders.local_size(bytes)
		var bad: bool = name.ends_with("float32_row")
		assert(parsed.cooperative_outer_type == bad and parsed.cooperative_outer_layout == bad)
		var spirv := RDShaderSPIRV.new()
		spirv.bytecode_compute = bytes
		var state := _imported_shader_state(spirv, "res://cooperative_fixture")
		for key in ["type", "layout"]:
			assert(state.counts.has("check_shader_cooperative_outer_" + key) == bad)
		if bad:
			state = _imported_shader_state(spirv, "res://cooperative_fixture", true)
			assert(not state.counts.has("check_shader_cooperative_outer_type") and not state.counts.has("check_shader_cooperative_outer_layout"))
			spirv.compile_error_fragment = "intentional other-stage fixture"
			state = _imported_shader_state(spirv, "res://cooperative_fixture")
			assert(not state.counts.has("check_shader_cooperative_outer_type") and not state.counts.has("check_shader_cooperative_outer_layout"))
			spirv.compile_error_fragment = ""
			spirv.compile_error_compute = "intentional current-stage fixture"
			state = _imported_shader_state(spirv, "res://cooperative_fixture")
			assert(not state.counts.has("check_shader_cooperative_outer_type") and not state.counts.has("check_shader_cooperative_outer_layout"))
	for type in ["float", "float16_t", "int"]:
		for layout in [0, 3]:
			var source := RDShaderSource.new()
			source.source_compute = "#version 460\n#extension GL_NV_cooperative_vector : require\n#extension GL_EXT_shader_explicit_arithmetic_types_float16 : require\n#extension GL_EXT_shader_16bit_storage : require\nlayout(local_size_x=1) in; layout(set=0,binding=0,std430) buffer Output { %s data[]; };\nvoid main() { coopvecNV<%s,4> a = coopvecNV<%s,4>(%s(1)); coopvecNV<%s,4> b = a; coopVecOuterProductAccumulateNV(a,b,data,0u,16u,%d,gl_ComponentTypeFloat16NV); }" % [type,type,type,type,type,layout]
			var spirv := device.shader_compile_spirv_from_source(source)
			if Engine.get_version_info().minor < 7:
				assert(not spirv.compile_error_compute.is_empty() and spirv.bytecode_compute.is_empty())
				var state := _imported_shader_state(spirv, "res://cooperative_compile_error")
				assert(state.counts.has("check_shader_compile_error"))
				assert(not state.counts.has("check_shader_cooperative_outer_type") and not state.counts.has("check_shader_cooperative_outer_layout"))
			else:
				assert(spirv.compile_error_compute.is_empty(), spirv.compile_error_compute)
				var parsed := Shaders.local_size(spirv.bytecode_compute)
				assert(parsed.cooperative_outer_type == (type != "float16_t") and parsed.cooperative_outer_layout == (layout != 3))
	print("PASS compiled cooperative-vector fixtures and import/error gates on both versions; native acceptance in 4.7 versus compiler errors in 4.4; never submitted")


func _extension_namespace_checks(device: RenderingDevice) -> void:
	for extension in ["GL_EXT_shader_8bit_storage", "invalid", "", "SPV_KHR_storage_buffer_storage_class"]:
		var source := RDShaderSource.new()
		source.source_compute = "#version 450\n#extension GL_EXT_spirv_intrinsics : require\nlayout(local_size_x=1) in; layout(set=0,binding=0,std430) buffer Output { int data[]; };\nspirv_instruction(extensions=[\"%s\"],id=128) int add_values(int a, int b);\nvoid main() { data[0]=add_values(1,2); }" % extension
		var spirv := device.shader_compile_spirv_from_source(source)
		assert(spirv.compile_error_compute.is_empty(), spirv.compile_error_compute)
		var expected: bool = not extension.begins_with("SPV_")
		assert(Shaders.local_size(spirv.bytecode_compute).non_spirv_extensions == ([extension] if expected else []))
		var state := _imported_shader_state(spirv, "res://extension_namespace")
		assert(state.counts.has("check_shader_extension_namespace") == expected)
		if extension == "invalid":
			assert(extension in state.offenders.check_shader_extension_namespace[0])
			state = _imported_shader_state(spirv, "res://extension_namespace", true)
			assert(not state.counts.has("check_shader_extension_namespace"))
			spirv.compile_error_fragment = "intentional other-stage fixture"
			state = _imported_shader_state(spirv, "res://extension_namespace")
			assert(not state.counts.has("check_shader_extension_namespace"))
	print("PASS non-SPIR-V extensions accepted by compiler; namespace/import/error gates; never submitted")


func _forbidden_capability_checks(device: RenderingDevice) -> void:
	for capability in [4, 5, 6, 7, 8, 21, 38, 1]:
		var source := RDShaderSource.new()
		source.source_compute = "#version 450\n#extension GL_EXT_spirv_intrinsics : require\nlayout(local_size_x=1) in; layout(set=0,binding=0,std430) buffer Output { int data[]; };\nspirv_instruction(capabilities=[%d],id=128) int add_values(int a, int b);\nvoid main() { data[0]=add_values(1,2); }" % capability
		var spirv := device.shader_compile_spirv_from_source(source)
		assert(spirv.compile_error_compute.is_empty(), spirv.compile_error_compute)
		var forbidden: Array = Shaders.local_size(spirv.bytecode_compute).forbidden_vulkan_capabilities
		assert(forbidden.size() == int(capability != 1))
		var state := _imported_shader_state(spirv, "res://forbidden_capability")
		assert(state.counts.has("check_shader_vulkan_capability") == (capability != 1))
		if capability != 1:
			assert(Shaders.FORBIDDEN_CAPABILITIES[capability] in state.offenders.check_shader_vulkan_capability[0])
		if capability == 6:
			state = _imported_shader_state(spirv, "res://forbidden_capability", true)
			assert(not state.counts.has("check_shader_vulkan_capability"))
			spirv.compile_error_fragment = "intentional other-stage fixture"
			state = _imported_shader_state(spirv, "res://forbidden_capability")
			assert(not state.counts.has("check_shader_vulkan_capability"))
			spirv.compile_error_compute = "intentional same-stage fixture"
			state = _imported_shader_state(spirv, "res://forbidden_capability")
			assert(not state.counts.has("check_shader_vulkan_capability"))
	print("PASS seven forbidden Vulkan capabilities accepted by compiler; static import/error gates; never submitted")


func _image_format_checks(device: RenderingDevice) -> void:
	var current := RenderingServer.get_rendering_device()
	assert(current != null)
	var cache := {}
	var state := {"counts": {}, "offenders": {}}
	Shaders.record_image_formats(Shaders.IMAGE_FORMATS.keys(), state, "native format queries; no images created", cache, "vulkan")
	var unsupported := 0
	for image_format: int in Shaders.IMAGE_FORMATS:
		var data_format: int = Shaders.IMAGE_FORMATS[image_format]
		var optimal := current.texture_is_format_supported_for_usage(data_format, RenderingDevice.TEXTURE_USAGE_STORAGE_BIT)
		var linear := current.texture_is_format_supported_for_usage(data_format, RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CPU_READ_BIT)
		assert(cache[image_format] == (optimal or linear), str(image_format))
		unsupported += int(not optimal and not linear)
	assert(cache.size() == 41 and int(state.counts.get("check_shader_storage_format", 0)) == unsupported)
	for entry in [[1, "rgba32f", "image2D", "vec4(1.0)"], [4, "rgba8", "image2D", "vec4(1.0)"], [24, "r32i", "iimage2D", "ivec4(1)"], [32, "rgba8ui", "uimage2D", "uvec4(1)"], [40, "r64ui", "u64image2D", "u64vec4(1)"], [41, "r64i", "i64image2D", "i64vec4(1)"]]:
		for array in [false, true]:
			var source := RDShaderSource.new()
			var extensions := "#extension GL_EXT_shader_image_int64 : require\n#extension GL_ARB_gpu_shader_int64 : require\n" if entry[0] >= 40 else ""
			source.source_compute = "#version 450\n%slayout(local_size_x=1) in; layout(set=0,binding=0,%s) uniform %s images%s; void main() { imageStore(images%s, ivec2(0), %s); }" % [extensions, entry[1], entry[2], "[2]" if array else "", "[0]" if array else "", entry[3]]
			var compiled := device.shader_compile_spirv_from_source(source)
			assert(compiled.compile_error_compute.is_empty(), compiled.compile_error_compute)
			assert(Shaders.local_size(compiled.bytecode_compute).storage_image_formats == [entry[0]], str(entry))
			for fixture in ["valid", "base_error", "stage_error", "other_stage_error"]:
				var spirv := RDShaderSPIRV.new()
				spirv.bytecode_compute = compiled.bytecode_compute
				if fixture == "stage_error":
					spirv.compile_error_compute = "intentional fixture"
				if fixture == "other_stage_error":
					spirv.compile_error_fragment = "intentional fixture"
				var path: String = "res://storage-format-%d-%s-%s" % [entry[0], array, fixture]
				state = _imported_shader_state(spirv, path, fixture == "base_error")
				assert(state.counts.has("check_shader_storage_format") == (fixture == "valid" and not cache[entry[0]]), str(entry, fixture, state))
				assert(state.shader_scan.storage_image_format_support.size() == int(fixture == "valid"))
				if state.counts.has("check_shader_storage_format"):
					assert(str(state.offenders.check_shader_storage_format[0]).contains("stage=compute"))
	print("PASS native Vulkan support for 41 mapped storage formats; compiler/import/direct/array/error gates; no test images or pipelines created")


func _imported_shader_state(spirv: RDShaderSPIRV, path: String, base_error: bool = false) -> Dictionary:
	var file := RDShaderFile.new()
	file.set_bytecode(spirv)
	if base_error:
		file.base_error = "intentional fixture"
	assert(ResourceSaver.save(file, path + ".res") == OK)
	var config := ConfigFile.new()
	config.set_value("remap", "type", "RDShaderFile")
	config.set_value("remap", "path", path + ".res")
	assert(config.save(path + ".glsl.import") == OK)
	var source_file := FileAccess.open(path + ".glsl", FileAccess.WRITE)
	source_file.store_string("#[compute]\n")
	source_file.close()
	var state := {"counts": {}, "offenders": {}}
	Shaders.scan([path + ".glsl"], state)
	for suffix in [".glsl", ".glsl.import", ".res"]:
		DirAccess.remove_absolute(path + suffix)
	return state


func _interface_8bit_checks(device: RenderingDevice) -> void:
	var prefix := "#version 450\n#extension GL_EXT_shader_8bit_storage : require\n#extension GL_EXT_shader_explicit_arithmetic_types_int8 : require\n"
	var control := RDShaderSource.new()
	control.source_compute = prefix + "layout(local_size_x=1) in; layout(set=0,binding=0,std430) buffer Values { int8_t value; }; void main(){value=int8_t(1);}"
	var valid := device.shader_compile_spirv_from_source(control)
	assert(valid.compile_error_compute.is_empty() and not Shaders.local_size(valid.bytecode_compute).interface_8bit, "8-bit buffer storage is separate from IO")
	for stage in [RenderingDevice.SHADER_STAGE_VERTEX, RenderingDevice.SHADER_STAGE_FRAGMENT]:
		for input in [false, true]:
			for width in [8, 32]:
				var flat := "flat " if (stage == RenderingDevice.SHADER_STAGE_VERTEX and not input) or (stage == RenderingDevice.SHADER_STAGE_FRAGMENT and input) else ""
				var body: String = "value=%s(1);" % ("int8_t" if width == 8 else "int") if not input else ""
				if stage == RenderingDevice.SHADER_STAGE_VERTEX:
					body += "gl_Position=vec4(float(value),0.0,0.0,1.0);"
				elif input:
					body = "result=float(value);"
				var source := RDShaderSource.new()
				source.set_stage_source(stage, prefix + "layout(location=0) %s%s %s value; %s void main(){%s}" % [flat, "in" if input else "out", "int8_t" if width == 8 else "int", "layout(location=0) out float result;" if stage == RenderingDevice.SHADER_STAGE_FRAGMENT and input else "", body])
				var compiled := device.shader_compile_spirv_from_source(source)
				assert(compiled.get_stage_compile_error(stage).is_empty(), compiled.get_stage_compile_error(stage))
				assert(Shaders.local_size(compiled.get_stage_bytecode(stage), Shaders.STAGE_MODELS[stage]).interface_8bit == (width == 8))
				for fixture in ["valid", "base_error", "stage_error", "other_stage_error"]:
					var spirv := RDShaderSPIRV.new()
					spirv.set_stage_bytecode(stage, compiled.get_stage_bytecode(stage))
					if fixture == "stage_error":
						spirv.set_stage_compile_error(stage, "intentional fixture")
					if fixture == "other_stage_error":
						spirv.compile_error_compute = "intentional fixture"
					var state := _imported_shader_state(spirv, "res://interface8-%d-%s-%d-%s" % [stage, input, width, fixture], fixture == "base_error")
					assert(state.counts.has("check_shader_interface_8bit") == (width == 8 and fixture == "valid"), str(stage, input, width, fixture, state))
					if state.counts.has("check_shader_interface_8bit"):
						assert(str(state.offenders.check_shader_interface_8bit[0]).contains("stage=" + Shaders.STAGE_NAMES[stage]))
	print("PASS native compiler accepts eight-bit IO; imported static detection, buffer/32-bit/error exclusions; no pipelines created")


func _header_checks(device: RenderingDevice) -> void:
	var source := RDShaderSource.new()
	source.source_compute = "#version 450\nlayout(local_size_x=1) in; void main() {}"
	var valid := device.shader_compile_spirv_from_source(source)
	assert(valid.compile_error_compute.is_empty())
	for fixture in ["valid", "short", "unaligned", "magic", "oversized", "swapped", "base_error", "stage_error", "other_stage_error", "empty"]:
		var bytes := valid.bytecode_compute.duplicate()
		match fixture:
			"short": bytes.resize(16)
			"unaligned": bytes.append(0)
			"magic", "base_error", "stage_error", "other_stage_error": bytes.encode_u32(0, 0)
			"oversized": bytes.resize(Shaders.MAX_BYTES + 4)
			"swapped": bytes.encode_u32(0, 0x03022307)
			"empty": bytes.clear()
		var spirv := RDShaderSPIRV.new()
		spirv.bytecode_compute = bytes
		if fixture == "stage_error":
			spirv.compile_error_compute = "intentional fixture"
		if fixture == "other_stage_error":
			spirv.compile_error_fragment = "intentional fixture"
		var file := RDShaderFile.new()
		file.set_bytecode(spirv)
		if fixture == "base_error":
			file.base_error = "intentional fixture"
		var path: String = "res://header-" + fixture
		assert(ResourceSaver.save(file, path + ".res") == OK)
		var config := ConfigFile.new()
		config.set_value("remap", "type", "RDShaderFile")
		config.set_value("remap", "path", path + ".res")
		assert(config.save(path + ".glsl.import") == OK)
		var source_file := FileAccess.open(path + ".glsl", FileAccess.WRITE)
		source_file.store_string("#[compute]\n")
		source_file.close()
		var state := {"counts": {}, "offenders": {}}
		Shaders.scan([path + ".glsl"], state)
		assert(state.counts.has("check_shader_invalid_spirv") == (fixture in ["short", "unaligned", "magic"]), str(fixture, state))
		if state.counts.has("check_shader_invalid_spirv"):
			assert(str(state.offenders.check_shader_invalid_spirv[0]).contains("stage=compute"))
		for suffix in [".glsl", ".glsl.import", ".res"]:
			DirAccess.remove_absolute(path + suffix)
	print("PASS imported shader header validation; malformed fixtures were never submitted to the GPU")


func _font_cache_check() -> void:
	var canvas := RenderingServer.canvas_item_create()
	var pixels: Array[int] = []
	for sampling in [1.0, 3.0]:
		var font := ThemeDB.fallback_font.duplicate() as FontFile
		assert(font != null and not font.data.is_empty())
		font.oversampling = sampling
		font.draw_string(canvas, Vector2.ZERO, "Oversampling", HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
		var total := 0
		for size in font.get_size_cache_list(0):
			for index in font.get_texture_count(0, size):
				var texture := font.get_texture_image(0, size, index)
				total += texture.get_width() * texture.get_height()
		pixels.append(total)
	RenderingServer.free_rid(canvas)
	assert(pixels[0] > 0 and pixels[1] > pixels[0], "Native font oversampling must enlarge the tested atlas allocation")
	print("PASS native font oversampling atlas: ", pixels)


func _interface_checks(device: RenderingDevice) -> void:
	var fixtures := [
		["float", "float", "", "v=1.0;", "f", false, 1],
		["float", "uint", "", "v=1.0;", "f", true, 1],
		["ivec4", "uvec4", "", "v=ivec4(1);", "f.x", false, 4],
		["vec2", "vec4", "", "v=vec2(1.0);", "f.x", true, 2],
		["vec4", "vec2", "", "v=vec4(1.0);", "f.x", false, 4],
		["dvec3", "vec3", "", "v=dvec3(1.0);", "f.x", true, 6],
		["vec2", "ivec2", "[2]", "v[0]=vec2(1.0);v[1]=vec2(2.0);", "f[1].x", true, 4],
		["mat2x3", "mat2x3", "", "v=mat2x3(1.0);", "f[1].x", false, 6],
		["mat2x3", "dmat2x3", "", "v=mat2x3(1.0);", "f[1].x", true, 6],
		["dmat2x3", "dmat2x3", "", "v=dmat2x3(1.0);", "f[1].x", false, 12],
		["float", "float16_t", "", "v=1.0;", "f", true, 1],
	]
	for fixture in fixtures:
		var prefix := "#version 450\n#extension GL_ARB_gpu_shader_fp64 : require\n"
		if fixture[1] == "float16_t":
			prefix += "#extension GL_EXT_shader_explicit_arithmetic_types_float16 : require\n#extension GL_EXT_shader_16bit_storage : require\n"
		var source := RDShaderSource.new()
		source.source_vertex = prefix + "layout(location=0) flat out %s v%s;\nvoid main(){gl_Position=vec4(0.0);%s}" % [fixture[0], fixture[2], fixture[3]]
		source.source_fragment = prefix + "layout(location=0) flat in %s f%s;layout(location=0) out vec4 color;\nvoid main(){color=vec4(float(%s));}" % [fixture[1], fixture[2], fixture[4]]
		var spirv := device.shader_compile_spirv_from_source(source)
		assert(spirv.compile_error_vertex.is_empty(), spirv.compile_error_vertex)
		assert(spirv.compile_error_fragment.is_empty(), spirv.compile_error_fragment)
		var vertex := Shaders.local_size(spirv.bytecode_vertex, 0)
		var fragment := Shaders.local_size(spirv.bytecode_fragment, 4)
		assert(vertex.interface_outputs.size() == fixture[6], str(fixture, vertex))
		if fixture[2] == "[2]" or fixture[0] == "mat2x3":
			assert(vertex.interface_outputs.has(Vector2i(1, 0)) and not vertex.interface_outputs.has(Vector2i(0, 3)))
		var state := {"counts": {}, "offenders": {}}
		assert(Shaders.record_interfaces({0: vertex, 1: fragment}, state, "compiled fixture", "vulkan"))
		assert(state.counts.has("check_shader_interface") == fixture[5], str(fixture, state))
		if fixture[1] == "uint":
			var file := RDShaderFile.new()
			file.set_bytecode(spirv)
			assert(ResourceSaver.save(file, "res://interface-fixture.res") == OK)
			var config := ConfigFile.new()
			config.set_value("remap", "type", "RDShaderFile")
			config.set_value("remap", "path", "res://interface-fixture.res")
			assert(config.save("res://interface-fixture.glsl.import") == OK)
			var source_file := FileAccess.open("res://interface-fixture.glsl", FileAccess.WRITE)
			source_file.store_string("#[vertex]\n")
			source_file.close()
			state = {"counts": {}, "offenders": {}}
			Shaders.scan(["res://interface-fixture.glsl"], state)
			assert(state.shader_scan.inspected_interface_pairs == 1 and state.counts.check_shader_interface == 1)
			assert(str(state.offenders.check_shader_interface[0]).contains("vertex->fragment; location=0; component=0"))
			var imported := ResourceLoader.load("res://interface-fixture.glsl") as RDShaderFile
			var stored := imported.get_spirv(imported.get_version_list()[0])
			stored.set_stage_compile_error(2, "fixture: intervening tessellation stage did not compile")
			state = {"counts": {}, "offenders": {}}
			Shaders.scan(["res://interface-fixture.glsl"], state)
			assert(state.shader_scan.inspected_interface_pairs == 0 and not state.counts.has("check_shader_interface"), "A failed intervening stage must not turn into a vertex/fragment pair")
			assert(state.counts.has("check_shader_compile_error"))
			for path in ["res://interface-fixture.res", "res://interface-fixture.glsl.import", "res://interface-fixture.glsl"]:
				DirAccess.remove_absolute(path)
	for block in [true, false]:
		var source := RDShaderSource.new()
		var vertex_decl := "layout(location=2) out Values {flat vec2 value; flat mat2x3 transform;} v;" if block else "layout(location=2,component=1) flat out float v;"
		var fragment_decl := "layout(location=2) in Values {flat ivec2 value; flat mat2x3 transform;} f;" if block else "layout(location=2,component=1) flat in uint f;"
		source.source_vertex = "#version 450\n" + vertex_decl + "void main(){gl_Position=vec4(0.0);" + ("v.value=vec2(1.0);v.transform=mat2x3(1.0);}" if block else "v=1.0;}")
		source.source_fragment = "#version 450\n" + fragment_decl + "layout(location=0) out vec4 color;void main(){color=vec4(float(" + ("f.value.x+f.transform[1].x" if block else "f") + "));}"
		var spirv := device.shader_compile_spirv_from_source(source)
		assert(spirv.compile_error_vertex.is_empty() and spirv.compile_error_fragment.is_empty(), str(spirv.compile_error_vertex, spirv.compile_error_fragment))
		var vertex := Shaders.local_size(spirv.bytecode_vertex, 0)
		var fragment := Shaders.local_size(spirv.bytecode_fragment, 4)
		assert(vertex.interface_outputs.has(Vector2i(2, 0 if block else 1)))
		if block:
			assert(vertex.interface_outputs.size() == 8 and vertex.interface_outputs.has(Vector2i(4, 2)) and not vertex.interface_outputs.has(Vector2i(2, 3)))
		var state := {"counts": {}, "offenders": {}}
		Shaders.record_interfaces({0: vertex, 1: fragment}, state, "compiled block/component fixture", "vulkan")
		assert(state.counts.has("check_shader_interface"))
	for nested in [false, true]:
		var source := RDShaderSource.new()
		if nested:
			source.source_vertex = "#version 450\nstruct Payload {vec2 value; mat2x3 transform;}; layout(location=0) out Values {flat Payload entries[2]; float tail;} v;void main(){gl_Position=vec4(0.0);v.entries[0].value=vec2(1.0);v.entries[0].transform=mat2x3(1.0);v.entries[1].value=vec2(2.0);v.entries[1].transform=mat2x3(2.0);v.tail=3.0;}"
			source.source_fragment = "#version 450\nstruct Payload {ivec2 value; mat2x3 transform;}; layout(location=0) in Values {flat Payload entries[2]; float tail;} f;layout(location=0) out vec4 color;void main(){color=vec4(float(f.entries[1].value.x)+f.tail+f.entries[0].transform[0].x);}"
		else:
			source.source_vertex = "#version 450\nlayout(location=0) out vec2 v;void main(){gl_Position=vec4(0.0);v=vec2(1.0);}"
			source.source_fragment = "#version 450\n#extension GL_EXT_fragment_shader_barycentric : require\nlayout(location=0) pervertexEXT in vec2 f[3];layout(location=0) out vec4 color;void main(){color=vec4(f[2].x);}"
		var spirv := device.shader_compile_spirv_from_source(source)
		assert(spirv.compile_error_vertex.is_empty() and spirv.compile_error_fragment.is_empty(), str(spirv.compile_error_vertex, spirv.compile_error_fragment))
		var vertex := Shaders.local_size(spirv.bytecode_vertex, 0)
		var fragment := Shaders.local_size(spirv.bytecode_fragment, 4)
		if nested:
			assert(vertex.interface_outputs.size() == 17 and vertex.interface_outputs.has(Vector2i(6, 0)), str(vertex))
		else:
			assert(fragment.interface_inputs.size() == 2, "The fragment per-vertex wrapper does not consume interface locations")
		var state := {"counts": {}, "offenders": {}}
		Shaders.record_interfaces({0: vertex, 1: fragment}, state, "nested/per-vertex fixture", "vulkan")
		assert(state.counts.has("check_shader_interface") == nested, str(state))


func _stage_checks(device: RenderingDevice) -> void:
	var combined := RDShaderSPIRV.new()
	for stage in RenderingDevice.SHADER_STAGE_MAX:
		for negative in [false, true]:
			var source := RDShaderSource.new()
			var prefix := "#version 460\n"
			if stage >= 5:
				prefix += "#extension GL_EXT_ray_tracing : require\n"
			if stage == 2:
				prefix += "layout(vertices=3) out;\n"
			elif stage == 3:
				prefix += "layout(triangles,equal_spacing,cw) in;\n"
			elif stage == 4:
				prefix += "layout(local_size_x=1) in;\n"
			source.set_stage_source(stage, prefix + "layout(set=0,binding=0,std430) buffer Values {float values[];};\nvoid main(){values[1]=pow(%s,values[0]);}\n" % ("-1.0" if negative else "1.0"))
			var spirv := device.shader_compile_spirv_from_source(source)
			assert(spirv.get_stage_compile_error(stage).is_empty(), spirv.get_stage_compile_error(stage))
			var bytes := spirv.get_stage_bytecode(stage)
			var parsed := Shaders.local_size(bytes, Shaders.STAGE_MODELS[stage])
			assert(parsed.requires_raytracing_pipeline == (stage >= 5), "Actual ray stages declare RayTracingKHR; other compiled stages do not")
			assert(parsed.pow_domain == negative, str(stage, parsed))
			assert(parsed.has("size") == (stage == RenderingDevice.SHADER_STAGE_COMPUTE))
			assert(parsed.descriptor_counts.storage_buffers == 1)
			if negative:
				combined.set_stage_bytecode(stage, bytes)
	if RenderingDevice.SHADER_STAGE_MAX > 6:
		for instruction in ["ignoreIntersectionEXT", "terminateRayEXT"]:
			var source := RDShaderSource.new()
			source.set_stage_source(6, "#version 460\n#extension GL_EXT_ray_tracing : require\nlayout(set=0,binding=0,std430) buffer Values {float values[];};\nvoid main(){%s; values[1]=pow(-1.0,values[0]);}" % instruction)
			var spirv := device.shader_compile_spirv_from_source(source)
			assert(spirv.get_stage_compile_error(6).is_empty(), spirv.get_stage_compile_error(6))
			assert(not Shaders.local_size(spirv.get_stage_bytecode(6), 5315).pow_domain, "Terminated ray invocations must not diagnose later arithmetic")
	for fixture in [[2,"layout(vertices=3) out; layout(triangles) in;"], [3,"layout(triangles) in; layout(vertices=4) out;"], [2,""], [3,"layout(equal_spacing,cw) in;"]]:
		var source := RDShaderSource.new()
		source.set_stage_source(fixture[0], "#version 450\n" + fixture[1] + "\nvoid main(){}")
		var spirv := device.shader_compile_spirv_from_source(source)
		assert(not spirv.get_stage_compile_error(fixture[0]).is_empty() and spirv.get_stage_bytecode(fixture[0]).is_empty(), "Tessellation layout errors are already compiler findings")
	# This fixture exercises import traversal; it is never used to create a pipeline.
	var file := RDShaderFile.new()
	file.set_bytecode(combined)
	assert(ResourceSaver.save(file, "res://stage-fixture.res") == OK)
	var config := ConfigFile.new()
	config.set_value("remap", "type", "RDShaderFile")
	config.set_value("remap", "path", "res://stage-fixture.res")
	assert(config.save("res://stage-fixture.glsl.import") == OK)
	var source_file := FileAccess.open("res://stage-fixture.glsl", FileAccess.WRITE)
	source_file.store_string("#[compute]\n")
	source_file.close()
	var state := {"counts": {}, "offenders": {}}
	Shaders.scan(["res://stage-fixture.glsl"], state)
	assert(state.shader_scan.inspected_stages == RenderingDevice.SHADER_STAGE_MAX and state.shader_scan.skipped_stages == 0, str(state))
	assert(state.shader_scan.inspected_versions == 1 and state.shader_scan.resource_versions == 1)
	assert(state.counts.check_compute_pow_domain == RenderingDevice.SHADER_STAGE_MAX, str(state))
	assert(state.counts.check_compute_arm_alignment == 1 and state.counts.check_compute_amd_alignment == 1)
	assert(str(state.offenders.check_compute_pow_domain[0]).contains("stage=vertex"))
	for path in ["res://stage-fixture.res", "res://stage-fixture.glsl.import", "res://stage-fixture.glsl"]:
		DirAccess.remove_absolute(path)
