extends RefCounted

const Checks = preload("res://addons/render_lens/scene_checks.gd")
const MAX_BYTES := 1024 * 1024
const MAX_TOTAL_BYTES := 8 * MAX_BYTES
const MAX_FILES := 64
const MAX_INTERFACE_SLOTS := 1024
const STAGE_MODELS := [0, 4, 1, 2, 5, 5313, 5315, 5316, 5317, 5314]
const STAGE_NAMES := ["vertex", "fragment", "tessellation_control", "tessellation_evaluation", "compute", "raygen", "any_hit", "closest_hit", "miss", "intersection"]
## Invocation repack instructions listed by the Vulkan spec (ray-tracing-repack), with their complete word counts.
## Vulkan-ValidationLayers checks only the first four; the spec adds the NV and EXT shader-execution-reorder instructions.
const REPACK_OPCODES := {4445: [12], 4446: [3], 5334: [5], 5339: [13], 5279: [2, 4], 5280: [3], 5314: [3], 5315: [2, 4], 5316: [13], 5310: [3, 5], 5311: [13, 15], 5317: [14], 5312: [14, 16]}
const FORBIDDEN_CAPABILITIES := {4: "Addresses", 5: "Linkage", 6: "Kernel", 7: "Vector16", 8: "Float16Buffer", 21: "AtomicStorage", 38: "GenericPointer"}
const IMAGE_FORMATS := {
	1: RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT,
	2: RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT,
	3: RenderingDevice.DATA_FORMAT_R32_SFLOAT,
	4: RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM,
	5: RenderingDevice.DATA_FORMAT_R8G8B8A8_SNORM,
	6: RenderingDevice.DATA_FORMAT_R32G32_SFLOAT,
	7: RenderingDevice.DATA_FORMAT_R16G16_SFLOAT,
	8: RenderingDevice.DATA_FORMAT_B10G11R11_UFLOAT_PACK32,
	9: RenderingDevice.DATA_FORMAT_R16_SFLOAT,
	10: RenderingDevice.DATA_FORMAT_R16G16B16A16_UNORM,
	11: RenderingDevice.DATA_FORMAT_A2B10G10R10_UNORM_PACK32,
	12: RenderingDevice.DATA_FORMAT_R16G16_UNORM,
	13: RenderingDevice.DATA_FORMAT_R8G8_UNORM,
	14: RenderingDevice.DATA_FORMAT_R16_UNORM,
	15: RenderingDevice.DATA_FORMAT_R8_UNORM,
	16: RenderingDevice.DATA_FORMAT_R16G16B16A16_SNORM,
	17: RenderingDevice.DATA_FORMAT_R16G16_SNORM,
	18: RenderingDevice.DATA_FORMAT_R8G8_SNORM,
	19: RenderingDevice.DATA_FORMAT_R16_SNORM,
	20: RenderingDevice.DATA_FORMAT_R8_SNORM,
	21: RenderingDevice.DATA_FORMAT_R32G32B32A32_SINT,
	22: RenderingDevice.DATA_FORMAT_R16G16B16A16_SINT,
	23: RenderingDevice.DATA_FORMAT_R8G8B8A8_SINT,
	24: RenderingDevice.DATA_FORMAT_R32_SINT,
	25: RenderingDevice.DATA_FORMAT_R32G32_SINT,
	26: RenderingDevice.DATA_FORMAT_R16G16_SINT,
	27: RenderingDevice.DATA_FORMAT_R8G8_SINT,
	28: RenderingDevice.DATA_FORMAT_R16_SINT,
	29: RenderingDevice.DATA_FORMAT_R8_SINT,
	30: RenderingDevice.DATA_FORMAT_R32G32B32A32_UINT,
	31: RenderingDevice.DATA_FORMAT_R16G16B16A16_UINT,
	32: RenderingDevice.DATA_FORMAT_R8G8B8A8_UINT,
	33: RenderingDevice.DATA_FORMAT_R32_UINT,
	34: RenderingDevice.DATA_FORMAT_A2B10G10R10_UINT_PACK32,
	35: RenderingDevice.DATA_FORMAT_R32G32_UINT,
	36: RenderingDevice.DATA_FORMAT_R16G16_UINT,
	37: RenderingDevice.DATA_FORMAT_R8G8_UINT,
	38: RenderingDevice.DATA_FORMAT_R16_UINT,
	39: RenderingDevice.DATA_FORMAT_R8_UINT,
	40: RenderingDevice.DATA_FORMAT_R64_UINT,
	41: RenderingDevice.DATA_FORMAT_R64_SINT,
}


static func scan(files: Array, state: Dictionary) -> void:
	var coverage := {"candidate_files": files.size(), "inspected_versions": 0, "resource_versions": 0, "shared_memory_skipped_versions": 0, "inspected_stages": 0, "skipped_stages": 0, "inspected_interface_pairs": 0, "interface_skipped_declarations": 0, "unavailable_files": 0, "skipped_versions": 0, "skipped_files": 0}
	var driver := RenderingServer.get_current_rendering_driver_name()
	coverage["driver"] = driver
	var limits := device_limits()
	coverage["device_limits"] = limits
	var features := device_features()
	coverage["device_features"] = features
	var image_format_support := {}
	var total_bytes := 0
	var imported_bytes := 0
	for index in files.size():
		if index >= MAX_FILES or total_bytes >= MAX_TOTAL_BYTES or imported_bytes >= MAX_TOTAL_BYTES:
			coverage["skipped_files"] += 1
			continue
		var path := str(files[index])
		var config := ConfigFile.new()
		if config.load(path + ".import") != OK or config.get_value("remap", "type", "") != "RDShaderFile":
			coverage["unavailable_files"] += 1
			continue
		var imported := FileAccess.open(str(config.get_value("remap", "path", "")), FileAccess.READ)
		if imported == null or imported.get_length() > MAX_TOTAL_BYTES:
			coverage["unavailable_files"] += 1
			continue
		if imported_bytes + imported.get_length() > MAX_TOTAL_BYTES:
			coverage["skipped_files"] += 1
			continue
		imported_bytes += imported.get_length()
		var resource := ResourceLoader.load(path, "RDShaderFile") as RDShaderFile
		if resource == null:
			coverage["unavailable_files"] += 1
			continue
		var compile_error := not resource.base_error.is_empty()
		var versions := resource.get_version_list()
		for version_index in versions.size():
			if version_index >= 8 or total_bytes >= MAX_TOTAL_BYTES:
				coverage["skipped_versions"] += 1
				continue
			var spirv: RDShaderSPIRV = resource.get_spirv(versions[version_index])
			if spirv == null:
				coverage["skipped_versions"] += 1
				continue
			var stages := {}
			var present_stages := 0
			var version_error := not resource.base_error.is_empty()
			var invalid_headers: Array[String] = []
			for stage in RenderingDevice.SHADER_STAGE_MAX:
				if not spirv.get_stage_compile_error(stage).is_empty():
					compile_error = true
					version_error = true
				var bytes := spirv.get_stage_bytecode(stage)
				if bytes.is_empty():
					continue
				present_stages += 1
				if stage >= STAGE_MODELS.size() or total_bytes + bytes.size() > MAX_TOTAL_BYTES:
					coverage["skipped_stages"] += 1
					if stage == RenderingDevice.SHADER_STAGE_COMPUTE:
						coverage["skipped_versions"] += 1
					continue
				total_bytes += bytes.size()
				var parsed := local_size(bytes, STAGE_MODELS[stage])
				if not parsed.has("execution_model"):
					if parsed.get("invalid_header", false):
						invalid_headers.append("%s [version=%s; stage=%s; bytes=%d; %s]" % [path, versions[version_index], STAGE_NAMES[stage], bytes.size(), parsed.skip])
					coverage["skipped_stages"] += 1
					if stage == RenderingDevice.SHADER_STAGE_COMPUTE:
						coverage["skipped_versions"] += 1
					continue
				coverage["inspected_stages"] += 1
				stages[stage] = parsed
				coverage["interface_skipped_declarations"] += int(parsed.get("interface_skipped_declarations", 0))
				if stage == RenderingDevice.SHADER_STAGE_COMPUTE:
					if parsed.has("size"):
						coverage["inspected_versions"] += 1
					else:
						coverage["skipped_versions"] += 1
					coverage["resource_versions"] += 1
					if parsed.shared_bytes < 0:
						coverage["shared_memory_skipped_versions"] += 1
				parsed["driver"] = driver
				parsed["features"] = features
				record(parsed.get("size", Vector3i.ZERO), state, "%s [version=%s; stage=%s; local_size=%s; shared_bytes_lower_bound=%s; descriptor_bytes_lower_bound=%s; push_constant_bytes_lower_bound=%s; descriptor_counts_lower_bound=%s; bound_sets_lower_bound=%s; uniform_buffer_size_lower_bound=%s; device_limits=%s]" % [path, versions[version_index], STAGE_NAMES[stage], parsed.get("size", "unknown"), parsed.get("shared_bytes", "unknown"), parsed.get("descriptor_bytes", "unknown"), parsed.get("push_constant_bytes", "unknown"), parsed.get("descriptor_counts", {}), parsed.get("bound_sets", 0), parsed.get("uniform_buffer_size", 0), limits], limits, parsed)
			if driver == "vulkan" and not version_error:
				for invalid_header in invalid_headers:
					Checks.check(state, "shader_invalid_spirv", true, invalid_header)
				for stage: int in stages:
					for key in ["cooperative_outer_type", "cooperative_outer_layout", "cooperative_outer_interpretation", "cooperative_reduce_type", "cooperative_training_storage", "cooperative_fp8_layout", "cooperative_alignment", "cooperative_offset_width", "matrix_muladd", "graph_capability", "tensor_declaration", "subgroup_repack"]:
						Checks.check(state, "shader_" + key, stages[stage].get(key, false), "%s [version=%s; stage=%s; intrinsic restriction=%s]" % [path, versions[version_index], STAGE_NAMES[stage], key])
					Checks.check(state, "shader_extension_namespace", not stages[stage].get("non_spirv_extensions", []).is_empty(), "%s [version=%s; stage=%s; non-SPIR-V OpExtension names=%s]" % [path, versions[version_index], STAGE_NAMES[stage], stages[stage].get("non_spirv_extensions", [])])
					Checks.check(state, "shader_vulkan_capability", not stages[stage].get("forbidden_vulkan_capabilities", []).is_empty(), "%s [version=%s; stage=%s; forbidden capabilities=%s]" % [path, versions[version_index], STAGE_NAMES[stage], stages[stage].get("forbidden_vulkan_capabilities", [])])
					Checks.check(state, "shader_interface_8bit", stages[stage].get("interface_8bit", false), "%s [version=%s; stage=%s; 8-bit numeric Input/Output declaration]" % [path, versions[version_index], STAGE_NAMES[stage]])
					record_image_formats(stages[stage].get("storage_image_formats", []), state, "%s [version=%s; stage=%s]" % [path, versions[version_index], STAGE_NAMES[stage]], image_format_support, driver)
			if not version_error and present_stages == 2 and record_interfaces(stages, state, "%s [version=%s]" % [path, versions[version_index]], driver):
				coverage["inspected_interface_pairs"] += 1
		Checks.check(state, "shader_compile_error", compile_error, path)
	coverage["limits"] = "64 imported GLSL files, 8 versions/file, 1 MiB/module, 8 MiB each for imported resource files and bytecode across all stages. Public vertex, fragment, tessellation and compute stages, plus Godot 4.7 ray-tracing stages, are inspected independently. Offenders identify their stage. Legacy inspected_versions/resource_versions/shared_memory_skipped_versions describe compute only; inspected_stages/skipped_stages cover every stage. Workgroup rules remain compute-only; pipeline layout quantities are per-stage lower bounds, not sums across stages. Specialization-dependent workgroup sizes are skipped independently of resource declarations. Shared memory supports fixed scalar/vector/matrix/array declarations with at most 16 type levels; structs, aliasing, explicit layouts and unknown lengths are skipped. Push constants use explicit member offsets and fixed payload sizes, omitting padding and unknown members. Descriptor counts include plain uniform/storage blocks but omit buffer arrays, buffer/subpass images and unknown lengths. Per-stage descriptor limits supplement pipeline limits. All sizes and counts are conservative lower bounds. Literal operands are checked in the first entry block only: scalar32 ray queries; scalar32 and 2-4 component vector zero divisors and GLSL.std.450 Pow/Atan2/FMin/FMax. Direct scalar-component construction, constant nulls and literal uint32-to-float32 bitcasts are supported. Helpers, later blocks, other widths and unknown dynamic/specialized components are skipped. Compiler-folded instructions may be absent. Sampler/layout and literal-operand checks require Vulkan. Device compatibility requires exposed device limits. Project presence does not prove execution."
	state["shader_scan"] = coverage
	coverage["storage_image_format_support"] = image_format_support
	coverage["cooperative_vector_limits"] = "First-entry-block outer-product, reduce-sum and matrix-multiplication operations, with CooperativeVectorNV or CooperativeVectorTrainingNV declared. Known OpLoad/direct-composite cooperative vector types, core typed-pointer storage from OpVariable/entry-block OpLoad/OpAccessChain/OpInBoundsAccessChain, and signed/unsigned 32-bit literal interpretations/layouts are inspected. Unknown types, encoded wider floats, other pointer flows, future storage classes, helpers/later blocks and specialized/dynamic/other-width literals are omitted independently. Vulkan and error-free imported versions only. Native features/property combinations, dimensions, memory/alignment validity and complete pipeline compatibility remain unknown. No shader or pipeline is created."
	coverage["intrinsic_declarations"] = "Shader-stage modules only. GraphARM capability and the grammar's three/five-word OpTypeTensorARM forms (with TensorsARM) are inspected module-wide; other tensor lengths are omitted. A matching OpExecutionMode SubgroupUniformControlFlowKHR is checked against the 13 complete invocation-repack opcodes the Vulkan spec lists (VVL checks four), module-wide, including helpers/later blocks. OpCooperativeMatrixMulAddKHR operand uses, scopes, M/N/K and signedness flags are compared module-wide for known cooperative-matrix value types (loads, composites, phis, cooperative loads and multiply-adds) and 32-bit constant dimensions. Other mode/opcode forms, data-graph/unknown entry models and modules outside existing budgets are skipped. Only Vulkan imported versions with no stored base/stage errors produce these findings. No feature/property compatibility is inferred."
	coverage["capability_extension_limits"] = "Seven confirmed forbidden SPIR-V 1.0 capabilities only: Addresses, Linkage, Kernel, Vector16, Float16Buffer, AtomicStorage and GenericPointer. Other capabilities are not assumed unsupported. OpExtension namespace checks collect at most 16 distinct non-SPV_ names per module from at most 256-byte, terminated printable ASCII payloads; unknown SPV_ names, long, unterminated and non-ASCII strings are skipped. Both checks require Vulkan and a version without stored base or stage compilation errors; no shader or pipeline is created. Device feature requirements use actual public support getters; Godot 4.4 exposes buffer addresses but no ray-query or ray-tracing pipeline support getter. Missing queries mean unknown, not unsupported."
	coverage["interface_8bit_limits"] = "Typed OpVariable Input/Output declarations in every inspected stage; scalar/vector/matrix/array/struct numeric elements, at most 16 type levels with cached visits. Pointers inside aggregates, untyped variables, unknown types and deeper branches are skipped. This unconditional Vulkan prohibition does not classify 8-bit buffers, push constants, workgroup data or 16-bit interfaces as invalid. Compile-error versions are excluded. No pipeline is created."
	coverage["storage_image_format_limits"] = "Explicit mapped storage-image formats on direct or fixed-array UniformConstant declarations with known set/binding only. Buffer/subpass images, formatless or unmapped formats and unknown array lengths are skipped. Both optimal and linear tiling are queried on the current Vulkan device; either supported path suppresses a finding. At most 82 native format queries per audit, cached per format. Compile-error versions are skipped. No image, shader or pipeline is created; declared format incompatibility does not prove binding or execution."
	coverage["interface_limits"] = "Only successfully compiled vertex/fragment pairs in the same imported version with no additional stages are compared, on Vulkan. Explicit Location/Component declarations and block members support fixed numeric scalar/vector/matrix/array/struct types (16/32/64-bit), at most 16 type levels and 1024 component slots per stage. Signedness is ignored, matching the upstream numeric-type check. PerVertexKHR fragment inputs disregard exactly their outer per-vertex array wrapper. Unknown lengths/types, grouped decorations, overlapping declarations and excess slots are skipped. Array lengths require known unsigned 32-bit constants. Missing-output findings require complete supported vertex reflection; unknown or truncated declarations suppress them. Unused outputs, vector-size rules, built-ins and tessellation interfaces are not inferred. Findings describe incompatible types if the paired stages are linked; import presence does not prove pipeline creation or execution."


static func record_interfaces(stages: Dictionary, state: Dictionary, path: String, driver: String) -> bool:
	if driver != "vulkan" or stages.size() != 2 or not stages.has(RenderingDevice.SHADER_STAGE_VERTEX) or not stages.has(RenderingDevice.SHADER_STAGE_FRAGMENT):
		return false
	var outputs: Dictionary = stages[RenderingDevice.SHADER_STAGE_VERTEX].get("interface_outputs", {})
	var inputs: Dictionary = stages[RenderingDevice.SHADER_STAGE_FRAGMENT].get("interface_inputs", {})
	var missing := Vector2i(-1, -1)
	for slot: Vector2i in inputs:
		var output: Vector2i = outputs.get(slot, Vector2i.ZERO)
		var input: Vector2i = inputs[slot]
		if output != Vector2i.ZERO and input != Vector2i.ZERO and output != input:
			Checks.check(state, "shader_interface", true, "%s [vertex->fragment; location=%d; component=%d; vertex=%s%d; fragment=%s%d]" % [path, slot.x, slot.y, "int" if output.x == 21 else "float", output.y, "int" if input.x == 21 else "float", input.y])
			return true
		if input != Vector2i.ZERO and not outputs.has(slot):
			missing = slot
	if missing.x >= 0 and int(stages[RenderingDevice.SHADER_STAGE_VERTEX].get("interface_skipped_declarations", 1)) == 0:
		Checks.check(state, "shader_interface", true, "%s [vertex->fragment; missing vertex output; location=%d; component=%d]" % [path, missing.x, missing.y])
	return true


static func record_image_formats(formats: Array, state: Dictionary, path: String, support: Dictionary, driver: String) -> void:
	if driver != "vulkan":
		return
	var rd := RenderingServer.get_rendering_device()
	for image_format: int in formats:
		if not IMAGE_FORMATS.has(image_format):
			continue
		var data_format: int = IMAGE_FORMATS[image_format]
		if not support.has(image_format):
			if rd == null:
				continue
			# CPU_READ selects linear tiling in both native Vulkan drivers.
			support[image_format] = rd.texture_is_format_supported_for_usage(data_format, RenderingDevice.TEXTURE_USAGE_STORAGE_BIT) or rd.texture_is_format_supported_for_usage(data_format, RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CPU_READ_BIT)
		Checks.check(state, "shader_storage_format", support[image_format] == false, "%s [SPIR-V ImageFormat=%d; Godot DataFormat=%d; storage unsupported for optimal and linear tiling]" % [path, image_format, data_format])


static func device_limits() -> Dictionary:
	var rd := RenderingServer.get_rendering_device()
	if rd == null:
		return {}
	# Godot 4.4 exposes this enum but its Vulkan getter is unimplemented; 4.5 added it.
	var shared_limit := 0
	if Engine.get_version_info().major == 4 and Engine.get_version_info().minor >= 5 and RenderingServer.get_current_rendering_driver_name() == "vulkan":
		shared_limit = int(rd.limit_get(RenderingDevice.LIMIT_MAX_COMPUTE_SHARED_MEMORY_SIZE))
	# limit_get reads immutable driver limits; it does not submit work or require the render thread.
	var limits := {"x": int(rd.limit_get(RenderingDevice.LIMIT_MAX_COMPUTE_WORKGROUP_SIZE_X)),
		"y": int(rd.limit_get(RenderingDevice.LIMIT_MAX_COMPUTE_WORKGROUP_SIZE_Y)),
		"z": int(rd.limit_get(RenderingDevice.LIMIT_MAX_COMPUTE_WORKGROUP_SIZE_Z)),
		"invocations": int(rd.limit_get(RenderingDevice.LIMIT_MAX_COMPUTE_WORKGROUP_INVOCATIONS)),
		"shared_memory": shared_limit}
	if RenderingServer.get_current_rendering_driver_name() != "vulkan":
		return limits
	limits.merge({"push_constants": int(rd.limit_get(RenderingDevice.LIMIT_MAX_PUSH_CONSTANT_SIZE)),
		"samplers": int(rd.limit_get(RenderingDevice.LIMIT_MAX_SAMPLERS_PER_UNIFORM_SET)),
		"sampled_images": int(rd.limit_get(RenderingDevice.LIMIT_MAX_TEXTURES_PER_UNIFORM_SET)),
		"storage_images": int(rd.limit_get(RenderingDevice.LIMIT_MAX_STORAGE_IMAGES_PER_UNIFORM_SET)),
		"samplers_stage": int(rd.limit_get(RenderingDevice.LIMIT_MAX_SAMPLERS_PER_SHADER_STAGE)),
		"sampled_images_stage": int(rd.limit_get(RenderingDevice.LIMIT_MAX_TEXTURES_PER_SHADER_STAGE)),
		"storage_images_stage": int(rd.limit_get(RenderingDevice.LIMIT_MAX_STORAGE_IMAGES_PER_SHADER_STAGE)),
		"uniform_buffers_stage": int(rd.limit_get(RenderingDevice.LIMIT_MAX_UNIFORM_BUFFERS_PER_SHADER_STAGE)),
		"storage_buffers_stage": int(rd.limit_get(RenderingDevice.LIMIT_MAX_STORAGE_BUFFERS_PER_SHADER_STAGE)),
		"bound_sets": int(rd.limit_get(RenderingDevice.LIMIT_MAX_BOUND_UNIFORM_SETS)),
		"uniform_buffer_size": int(rd.limit_get(RenderingDevice.LIMIT_MAX_UNIFORM_BUFFER_SIZE))})
	return limits


static func device_features() -> Dictionary:
	var rd := RenderingServer.get_rendering_device()
	if rd == null or RenderingServer.get_current_rendering_driver_name() != "vulkan":
		return {}
	var features := {"buffer_device_address": rd.has_feature(RenderingDevice.SUPPORTS_BUFFER_DEVICE_ADDRESS)}
	for feature in ["ray_query", "raytracing_pipeline"]:
		var constant := "SUPPORTS_" + str(feature).to_upper()
		if ClassDB.class_has_integer_constant("RenderingDevice", constant):
			features[feature] = rd.has_feature(ClassDB.class_get_integer_constant("RenderingDevice", constant))
	return features


static func record(size: Vector3i, state: Dictionary, path: String, limits: Dictionary = {}, metadata: Dictionary = {}) -> void:
	var threads: int = size.x * size.y * size.z
	var compute := int(metadata.get("execution_model", 5)) == 5
	var fixed := compute and size.x > 0 and size.y > 0 and size.z > 0
	Checks.check(state, "compute_arm_large", fixed and threads > 64, path)
	Checks.check(state, "compute_arm_alignment", fixed and (threads == 1 or (size.x > 1 and size.x % 4 != 0) or (size.y > 1 and size.y % 4 != 0) or (size.z > 1 and size.z % 4 != 0)), path)
	Checks.check(state, "compute_amd_alignment", fixed and threads % 64 != 0, path)
	Checks.check(state, "compute_invocation_limit", fixed and int(limits.get("invocations", 0)) > 0 and threads > int(limits["invocations"]), path)
	if fixed and int(limits.get("x", 0)) > 0 and int(limits.get("y", 0)) > 0 and int(limits.get("z", 0)) > 0:
		Checks.check(state, "compute_dimension_limit", size.x > int(limits.x) or size.y > int(limits.y) or size.z > int(limits.z), path)
	Checks.check(state, "compute_shared_memory_limit", compute and int(limits.get("shared_memory", 0)) > 0 and int(metadata.get("shared_bytes", -1)) > int(limits.get("shared_memory", 0)), path)
	Checks.check(state, "compute_nvidia_separate_sampler", metadata.get("driver", "") == "vulkan" and metadata.get("separate_sampler", false), path)
	Checks.check(state, "compute_nvidia_descriptor_space", metadata.get("driver", "") == "vulkan" and int(metadata.get("descriptor_bytes", 0)) > 256, path)
	var vulkan: bool = metadata.get("driver", "") == "vulkan"
	for key in ["ray_query_flags", "ray_query_distance", "zero_divisor", "pow_domain", "atan2_zero", "minmax_nan"]:
		Checks.check(state, "compute_" + key, vulkan and metadata.get(key, false), path)
	Checks.check(state, "compute_arm_spatial", vulkan and fixed and int(size.x > 1) + int(size.y > 1) + int(size.z > 1) == 1 and metadata.get("multidimensional_image_access", false), path)
	var push_bytes := int(metadata.get("push_constant_bytes", 0))
	Checks.check(state, "compute_amd_layout", vulkan and push_bytes / 4 + int(metadata.get("bound_sets", 0)) > 13, path)
	Checks.check(state, "compute_push_constant_limit", vulkan and int(limits.get("push_constants", 0)) > 0 and push_bytes > int(limits.get("push_constants", 0)), path)
	for resource in ["samplers", "sampled_images", "storage_images", "uniform_buffers", "storage_buffers"]:
		var maximum := int(limits.get(resource, 0))
		var stage_maximum := int(limits.get(resource + "_stage", 0))
		if stage_maximum > 0:
			maximum = mini(maximum, stage_maximum) if maximum > 0 else stage_maximum
		Checks.check(state, "compute_" + resource + "_limit", vulkan and maximum > 0 and int(metadata.get("descriptor_counts", {}).get(resource, 0)) > maximum, path)
	for resource in ["bound_sets", "uniform_buffer_size"]:
		Checks.check(state, "compute_" + resource + "_limit", vulkan and int(limits.get(resource, 0)) > 0 and int(metadata.get(resource, 0)) > int(limits.get(resource, 0)), path)
	var features: Dictionary = metadata.get("features", {})
	for feature in ["buffer_device_address", "ray_query", "raytracing_pipeline"]:
		Checks.check(state, "compute_" + feature, metadata.get("driver", "") == "vulkan" and metadata.get("requires_" + feature, false) and features.get(feature, null) == false, path)


static func local_size(bytes: PackedByteArray, execution_model: int = 5) -> Dictionary:
	if execution_model not in STAGE_MODELS:
		return {"skip": "unsupported shader execution model"}
	if bytes.size() > MAX_BYTES:
		return {"skip": "SPIR-V module exceeds scan budget"}
	if bytes.size() >= 20 and bytes.size() % 4 == 0 and bytes.decode_u32(0) == 0x03022307:
		return {"skip": "byte-swapped SPIR-V is not reflected"}
	if bytes.size() < 20 or bytes.size() % 4 != 0 or bytes.decode_u32(0) != 0x07230203:
		return {"skip": "SPIR-V requires a five-word header, four-byte alignment and magic 0x07230203", "invalid_header": true}
	var words := bytes.to_int32_array()
	var entry := -1
	var literals := {}
	var ids := {}
	var constants := {}
	var float_constants := {}
	var float_vectors := {}
	var glsl_imports := {}
	var zero_constants := {}
	var composites := {}
	var uint_types := {}
	var types := {}
	var image_formats := {}
	var shared_types: Array[int] = []
	var push_types: Array[int] = []
	var member_offsets := {}
	var blocks := {}
	var uniforms: Array[Vector2i] = []
	var sets := {}
	var bindings := {}
	var interface_ids := {}
	var variable_ids := {}
	var interface_variables: Array[Vector3i] = []
	var io_types: Array[int] = []
	var locations := {}
	var interface_components := {}
	var builtins := {}
	var per_vertex := {}
	var grouped_decorations := false
	var shared_layout_unknown := false
	var capabilities := {}
	var non_spirv_extensions := {}
	var integer_literals := {}
	var cooperative_outer_ops: Array[Vector4i] = []
	var cooperative_reduce_ops: Array[int] = []
	var cooperative_training_pointers: Array[int] = []
	var cooperative_matmul_ops: Array[Vector2i] = []
	var subgroup_uniform_entries := {}
	var invocation_repack := false
	var cooperative_aligned: Array[Vector2i] = []
	var cooperative_strides: Array[Vector2i] = []
	var cooperative_offsets: Array[int] = []
	var int64_values := {}
	var indexing64_entries := {}
	var value_types := {}
	var matrix_muladds: Array = []
	var tensor_declaration := false
	var function := -1
	var entry_block := false
	var ray_query_flags := false
	var ray_query_distance := false
	var zero_divisor := false
	var pow_domain := false
	var atan2_zero := false
	var minmax_nan := false
	var image_values := {}
	var multidimensional_image_access := false
	var builtin := -1
	var cursor := 5
	while cursor < words.size():
		var count: int = (words[cursor] >> 16) & 0xffff
		var opcode: int = words[cursor] & 0xffff
		if count == 0 or cursor + count > words.size():
			return {"skip": "truncated SPIR-V instruction"}
		# Result types of values that can carry cooperative matrices (load, composite, phi, cooperative load and multiply-add).
		if opcode in [44, 61, 80, 245, 4457, 4459] and count >= 3:
			value_types[words[cursor + 2]] = words[cursor + 1]
		if opcode == 4459 and count in [6, 7]: # OpCooperativeMatrixMulAddKHR: result type, A, B, C and the literal operand mask.
			matrix_muladds.append([words[cursor + 1], words[cursor + 3], words[cursor + 4], words[cursor + 5], words[cursor + 6] if count == 7 else 0])
		if opcode == 4456 and count == 7: # OpTypeCooperativeMatrixKHR: component type and scope/rows/columns/use constant ids.
			types[words[cursor + 1]] = [opcode, words[cursor + 2], words[cursor + 3], words[cursor + 4], words[cursor + 5], words[cursor + 6]]
		match opcode:
			4163: # OpTypeTensorARM: shader types require rank and forbid shape.
				tensor_declaration = tensor_declaration or count in [3, 5]
			4445, 4446, 5334, 5339, 5279, 5280, 5310, 5311, 5312, 5314, 5315, 5316, 5317: # Invocation-repack opcodes, module-wide.
				invocation_repack = invocation_repack or count in REPACK_OPCODES[opcode]
			5290: # OpCooperativeVectorOuterProductAccumulateNV, direct entry-block calls.
				if count in [7, 8] and entry_block:
					cooperative_outer_ops.append(Vector4i(words[cursor + 3], words[cursor + 4], words[cursor + 5], words[cursor + 6]))
					cooperative_training_pointers.append(words[cursor + 1])
					cooperative_aligned.append(Vector2i(words[cursor + 2], 64))
					cooperative_offsets.append(words[cursor + 2])
			5291: # OpCooperativeVectorReduceSumAccumulateNV.
				if count == 4 and entry_block:
					cooperative_reduce_ops.append(words[cursor + 3])
					cooperative_training_pointers.append(words[cursor + 1])
					cooperative_aligned.append(Vector2i(words[cursor + 2], 16))
					cooperative_offsets.append(words[cursor + 2])
			5289, 5292: # Cooperative matrix multiplication, with optional stride/operand mask.
				if entry_block and ((opcode == 5289 and count in [12, 13, 14]) or (opcode == 5292 and count in [15, 16, 17])):
					cooperative_matmul_ops.append(Vector2i(words[cursor + 7], words[cursor + (10 if opcode == 5289 else 13)]))
					cooperative_aligned.append(Vector2i(words[cursor + 6], 64))
					if opcode == 5292:
						cooperative_aligned.append(Vector2i(words[cursor + 9], 16))
					if count >= (13 if opcode == 5289 else 16):
						cooperative_strides.append(Vector2i(words[cursor + (12 if opcode == 5289 else 15)], words[cursor + (10 if opcode == 5289 else 13)]))
			5302, 5303: # OpCooperativeVectorLoadNV / StoreNV: byte offsets must be 16-byte aligned.
				if entry_block and count >= (5 if opcode == 5302 else 4):
					var offset: int = words[cursor + (4 if opcode == 5302 else 2)]
					cooperative_aligned.append(Vector2i(offset, 16))
					cooperative_offsets.append(offset)
			65, 66: # Typed access chains; no pointer/value propagation through helpers.
				if count >= 4 and entry_block:
					image_values[words[cursor + 2]] = words[cursor + 1]
			10: # OpExtension, bounded ASCII names with a terminator.
				if count >= 2 and count <= 65 and non_spirv_extensions.size() < 16:
					var payload := bytes.slice((cursor + 1) * 4, (cursor + count) * 4)
					var end := payload.find(0)
					if end >= 0:
						payload = payload.slice(0, end)
						var ascii := true
						for character in payload:
							if character < 32 or character > 126:
								ascii = false
								break
						if ascii:
							var extension := payload.get_string_from_ascii()
							if not extension.begins_with("SPV_"):
								non_spirv_extensions[extension] = true
			11: # OpExtInstImport, exact null-terminated GLSL.std.450 name.
				if count == 6 and words.slice(cursor + 2, cursor + 6) == PackedInt32Array([0x4c534c47, 0x6474732e, 0x3035342e, 0]):
					glsl_imports[words[cursor + 1]] = true
			12: # Binary GLSL extended math, preserving unknown components.
				if count == 7 and entry_block and glsl_imports.has(words[cursor + 3]) and words[cursor + 4] in [25, 26, 37, 40]:
					var result_type: Array = types.get(words[cursor + 1], [])
					var components := 1 if result_type == [22, 32] else 0
					if result_type.size() == 3 and result_type[0] == 23 and result_type[2] >= 2 and result_type[2] <= 4 and types.get(result_type[1], []) == [22, 32]:
						components = result_type[2]
					var left: Array = float_vectors.get(words[cursor + 5], [float_constants.get(words[cursor + 5], null)])
					var right: Array = float_vectors.get(words[cursor + 6], [float_constants.get(words[cursor + 6], null)])
					for component in components:
						var x: Variant = left[component] if component < left.size() else null
						var y: Variant = right[component] if component < right.size() else null
						match words[cursor + 4]:
							26:
								pow_domain = pow_domain or (x != null and (x < 0.0 or (x == 0.0 and y != null and y <= 0.0)))
							25:
								atan2_zero = atan2_zero or (x != null and y != null and x == 0.0 and y == 0.0)
							37, 40:
								minmax_nan = minmax_nan or (x != null and is_nan(x)) or (y != null and is_nan(y))
			124: # Literal uint32-to-float32 bitcast, e.g. uintBitsToFloat.
				if count == 4 and entry_block and types.get(words[cursor + 1], []) == [22, 32] and constants.has(words[cursor + 3]):
					var value := PackedInt32Array([constants[words[cursor + 3]]]).to_byte_array().decode_float(0)
					float_constants[words[cursor + 2]] = value
					if value == 0.0:
						zero_constants[words[cursor + 2]] = true
			54: # OpFunction.
				if count == 5:
					function = words[cursor + 2]
					entry_block = function == entry and entry != -1
			56: # OpFunctionEnd.
				function = -1
				entry_block = false
			249, 250, 251, 252, 253, 254, 255, 4416, 4448, 4449: # Stop at the first control-flow terminator, including KHR ray termination.
				entry_block = false
			134, 135, 137, 138, 139, 140, 141: # Integer div/rem/mod and floating mod/rem, not floating division.
				if count == 5 and entry_block:
					zero_divisor = zero_divisor or zero_constants.has(words[cursor + 4])
			4473: # OpRayQueryInitializeKHR, only direct literal operands in the entry block.
				if count == 9 and entry_block:
					if constants.has(words[cursor + 3]):
						var flags: int = constants[words[cursor + 3]]
						var skip_cull := flags & 0x130
						var opaque := flags & 0xc3
						ray_query_flags = ray_query_flags or (flags & 0x300) == 0x300 or (skip_cull & (skip_cull - 1)) != 0 or (opaque & (opaque - 1)) != 0
					for operand in [6, 8]:
						if float_constants.has(words[cursor + operand]):
							var value: float = float_constants[words[cursor + operand]]
							ray_query_distance = ray_query_distance or is_nan(value) or value < 0.0
					if float_constants.has(words[cursor + 6]) and float_constants.has(words[cursor + 8]):
						ray_query_distance = ray_query_distance or float_constants[words[cursor + 8]] < float_constants[words[cursor + 6]]
			61, 86: # OpLoad / OpSampledImage: record the image value's type.
				if count >= 4 and function == entry and entry != -1:
					image_values[words[cursor + 2]] = words[cursor + 1]
			87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99:
				if function == entry and entry != -1 and count >= (4 if opcode == 99 else 5):
					var value_id: int = words[cursor + (1 if opcode == 99 else 3)]
					var image_type: Array = types.get(image_values.get(value_id, -1), [])
					if image_type.size() == 2 and image_type[0] == 27:
						image_type = types.get(image_type[1], [])
					if image_type.size() == 3 and image_type[0] == 25 and image_type[1] in [1, 2, 3, 4]:
						multidimensional_image_access = true
			17: # OpCapability WorkgroupMemoryExplicitLayoutKHR permits aliasing.
				if count == 2:
					capabilities[words[cursor + 1]] = true
					if words[cursor + 1] == 4428:
						shared_layout_unknown = true
			15: # The entry point must match the imported bytecode's stage.
				if count < 4 or entry != -1 or words[cursor + 1] != execution_model:
					return {"skip": "not a single matching stage entry point"}
				entry = words[cursor + 2]
				var name_end := cursor + 3
				var terminated_name := false
				while name_end < cursor + count:
					var word: int = words[name_end]
					name_end += 1
					if (word & 0xff) == 0 or (word & 0xff00) == 0 or (word & 0xff0000) == 0 or (word & 0xff000000) == 0:
						terminated_name = true
						break
				if not terminated_name:
					return {"skip": "unterminated entry-point name"}
				for index in range(name_end, cursor + count):
					interface_ids[words[index]] = true
			16, 331: # OpExecutionMode / OpExecutionModeId.
				if count < 3:
					return {"skip": "invalid execution mode"}
				var mode: int = words[cursor + 2]
				if opcode == 16 and count == 3 and mode == 4421:
					subgroup_uniform_entries[words[cursor + 1]] = true
				if opcode == 16 and count == 3 and mode == 5427: # Shader64BitIndexingEXT permits 64-bit cooperative-vector offsets.
					indexing64_entries[words[cursor + 1]] = true
				if mode == 17 or mode == 38:
					if count != 6:
						return {"skip": "invalid local size"}
					var value := Vector3i(words[cursor + 3], words[cursor + 4], words[cursor + 5])
					if opcode == 16 and mode == 17:
						literals[words[cursor + 1]] = value
					elif opcode == 331 and mode == 38:
						ids[words[cursor + 1]] = value
			21: # OpTypeInt: only unsigned 32-bit size constants.
				if count == 4:
					types[words[cursor + 1]] = [opcode, words[cursor + 2]]
				if count == 4 and words[cursor + 2] == 32 and words[cursor + 3] == 0:
					uint_types[words[cursor + 1]] = true
			22: # OpTypeFloat.
				if count == 3 or (count == 4 and words[cursor + 2] == 8):
					types[words[cursor + 1]] = [opcode, words[cursor + 2]]
			23, 24, 28, 32, 5288: # Vector, matrix, array, pointer and cooperative/long vector.
				if count == 4:
					types[words[cursor + 1]] = [opcode, words[cursor + 2], words[cursor + 3]]
			26: # OpTypeSampler (not OpTypeSampledImage).
				if count == 2:
					types[words[cursor + 1]] = [opcode]
			25: # OpTypeImage: Dim and Sampled distinguish descriptor classes.
				if count in [9, 10]:
					types[words[cursor + 1]] = [opcode, words[cursor + 3], words[cursor + 7]]
					image_formats[words[cursor + 1]] = words[cursor + 8]
			27: # OpTypeSampledImage.
				if count == 3:
					types[words[cursor + 1]] = [opcode, words[cursor + 2]]
			29: # OpTypeRuntimeArray.
				if count == 3:
					types[words[cursor + 1]] = [opcode, words[cursor + 2]]
			30: # OpTypeStruct.
				if count >= 2:
					var members: Array = [opcode]
					for index in range(cursor + 2, cursor + count):
						members.append(words[index])
					types[words[cursor + 1]] = members
			59: # OpVariable: Workgroup or UniformConstant.
				if count in [4, 5]:
					image_values[words[cursor + 2]] = words[cursor + 1]
					variable_ids[words[cursor + 2]] = true
					if words[cursor + 3] in [1, 3]:
						io_types.append(words[cursor + 1])
					if execution_model in [0, 4] and words[cursor + 3] in [1, 3]:
						interface_variables.append(Vector3i(words[cursor + 1], words[cursor + 2], words[cursor + 3]))
					if words[cursor + 3] == 4:
						shared_types.append(words[cursor + 1])
					elif words[cursor + 3] in [0, 2, 12]:
						uniforms.append(Vector2i(words[cursor + 1], words[cursor + 2]))
					elif words[cursor + 3] == 9:
						push_types.append(words[cursor + 1])
			72: # OpMemberDecorate Offset, Location or Component.
				if count == 5 and words[cursor + 4] >= 0:
					if words[cursor + 3] == 11:
						builtins[Vector2i(words[cursor + 1], words[cursor + 2])] = true
					elif words[cursor + 3] == 30:
						locations[Vector2i(words[cursor + 1], words[cursor + 2])] = words[cursor + 4]
					elif words[cursor + 3] == 31:
						interface_components[Vector2i(words[cursor + 1], words[cursor + 2])] = words[cursor + 4]
				if count == 5 and words[cursor + 3] == 35 and words[cursor + 4] >= 0:
					member_offsets[Vector2i(words[cursor + 1], words[cursor + 2])] = words[cursor + 4]
			43: # OpConstant; specialization constants deliberately remain unresolved.
				if count == 4 and types.get(words[cursor + 1], []) == [21, 32]:
					integer_literals[words[cursor + 2]] = words[cursor + 3]
				if count == 5 and types.get(words[cursor + 1], []) == [21, 64]:
					int64_values[words[cursor + 2]] = true
				if count == 4 and types.get(words[cursor + 1], []) == [21, 32] and words[cursor + 3] == 0:
					zero_constants[words[cursor + 2]] = true
				if count == 4 and uint_types.has(words[cursor + 1]):
					constants[words[cursor + 2]] = words[cursor + 3]
				elif count == 4 and types.get(words[cursor + 1], []) == [22, 32]:
					float_constants[words[cursor + 2]] = bytes.decode_float((cursor + 3) * 4)
					if float_constants[words[cursor + 2]] == 0.0:
						zero_constants[words[cursor + 2]] = true
			46: # OpConstantNull, scalar or 2-4 component vector of 32-bit zeroes.
				if count == 3 and types.get(words[cursor + 1], []) in [[21, 32], [22, 32]]:
					zero_constants[words[cursor + 2]] = true
				if count == 3 and types.get(words[cursor + 1], []) == [22, 32]:
					float_constants[words[cursor + 2]] = 0.0
				var type: Array = types.get(words[cursor + 1], []) if count == 3 else []
				if type.size() == 3 and type[0] == 23 and type[2] >= 2 and type[2] <= 4 and types.get(type[1], []) in [[21, 32], [22, 32]]:
					zero_constants[words[cursor + 2]] = true
					if types.get(type[1], []) == [22, 32]:
						var values: Array = []
						values.resize(type[2])
						values.fill(0.0)
						float_vectors[words[cursor + 2]] = values
			44, 80: # Constant composite / direct scalar-component construction.
				if count >= 4 and (opcode == 44 or entry_block):
					image_values[words[cursor + 2]] = words[cursor + 1]
				if opcode == 44 and count == 6:
					composites[words[cursor + 2]] = Vector3i(words[cursor + 3], words[cursor + 4], words[cursor + 5])
				var type: Array = types.get(words[cursor + 1], []) if count >= 4 else []
				if (opcode == 44 or entry_block) and type.size() == 3 and type[0] == 23 and type[2] >= 2 and type[2] <= 4 and count == 3 + type[2] and types.get(type[1], []) in [[21, 32], [22, 32]]:
					var values: Array = []
					for index in range(cursor + 3, cursor + count):
						values.append(float_constants.get(words[index], null))
						if zero_constants.has(words[index]):
							zero_constants[words[cursor + 2]] = true
					if types.get(type[1], []) == [22, 32]:
						float_vectors[words[cursor + 2]] = values
			71: # OpDecorate, BuiltIn, WorkgroupSize (takes precedence over LocalSize).
				if count == 3 and words[cursor + 2] == 5285:
					per_vertex[words[cursor + 1]] = true
				if count == 4 and words[cursor + 3] >= 0:
					if words[cursor + 2] == 11:
						builtins[words[cursor + 1]] = true
					elif words[cursor + 2] == 30:
						locations[words[cursor + 1]] = words[cursor + 3]
					elif words[cursor + 2] == 31:
						interface_components[words[cursor + 1]] = words[cursor + 3]
				if count == 3 and words[cursor + 2] in [2, 3]:
					blocks[words[cursor + 1]] = words[cursor + 2]
				if count == 4 and words[cursor + 3] >= 0:
					if words[cursor + 2] == 33:
						bindings[words[cursor + 1]] = words[cursor + 3]
					elif words[cursor + 2] == 34:
						sets[words[cursor + 1]] = words[cursor + 3]
				if count == 3 and words[cursor + 2] == 20:
					shared_layout_unknown = true
				if count == 4 and words[cursor + 2] == 11 and words[cursor + 3] == 25:
					if builtin != -1:
						return {"skip": "multiple workgroup builtins"}
					builtin = words[cursor + 1]
			73, 74, 75: # Grouped interface decorations are outside this reader's reflection model.
				grouped_decorations = true
		cursor += count
	if entry == -1:
		return {"skip": "no matching stage entry point"}
	var result := {"shared_bytes": -1 if shared_layout_unknown else 0, "separate_sampler": false, "descriptor_bytes": 0, "push_constant_bytes": 0, "bound_sets": 0, "uniform_buffer_size": 0, "descriptor_counts": {"samplers": 0, "sampled_images": 0, "storage_images": 0, "uniform_buffers": 0, "storage_buffers": 0}}
	result["execution_model"] = execution_model
	result["interface_8bit"] = false
	var width_cache := {}
	for type_id in io_types:
		var pointer: Array = types.get(type_id, [])
		if pointer.size() == 3 and pointer[0] == 32 and pointer[1] in [1, 3] and _has_8bit(pointer[2], types, width_cache):
			result.interface_8bit = true
			break
	result["interface_inputs"] = {}
	result["interface_outputs"] = {}
	result["interface_skipped_declarations"] = 0
	for id: int in interface_ids:
		if execution_model in [0, 4] and not variable_ids.has(id):
			result.interface_skipped_declarations += 1
	var interface_budget := MAX_INTERFACE_SLOTS
	for variable in interface_variables:
		if grouped_decorations:
			result.interface_skipped_declarations += 1
			break
		if not interface_ids.has(variable.y):
			continue
		var pointer: Array = types.get(variable.x, [])
		if pointer.size() != 3 or pointer[0] != 32 or pointer[1] != variable.z:
			result.interface_skipped_declarations += 1
			continue
		var declarations: Array[Vector3i] = []
		var pointee := int(pointer[2])
		if execution_model == 4 and variable.z == 1 and per_vertex.has(variable.y):
			var outer: Array = types.get(pointee, [])
			if outer.size() != 3 or outer[0] != 28:
				result.interface_skipped_declarations += 1
				continue
			pointee = outer[1]
		if locations.has(variable.y):
			declarations.append(Vector3i(pointee, locations[variable.y], interface_components.get(variable.y, 0)))
		else:
			var block: Array = types.get(pointee, [])
			if not block.is_empty() and block[0] == 30:
				for member in range(1, block.size()):
					var key := Vector2i(pointee, member - 1)
					if locations.has(key):
						declarations.append(Vector3i(block[member], locations[key], interface_components.get(key, 0)))
					elif not builtins.has(key):
						result.interface_skipped_declarations += 1
			elif not builtins.has(variable.y):
				result.interface_skipped_declarations += 1
		var slots: Dictionary = result.interface_inputs if variable.z == 1 else result.interface_outputs
		for declaration in declarations:
			if interface_budget <= 0 or declaration.z > 3:
				result.interface_skipped_declarations += 1
				continue
			var payload := _interface_type(declaration.x, types, constants)
			if payload.is_empty() or payload.size() > interface_budget:
				result.interface_skipped_declarations += 1
				interface_budget = 0 if payload.size() > interface_budget else interface_budget
				continue
			interface_budget -= payload.size()
			for offset in payload.size():
				if payload[offset] == Vector2i.ZERO:
					continue
				var slot := Vector2i(declaration.y + (declaration.z + offset) / 4, (declaration.z + offset) % 4)
				slots[slot] = Vector2i.ZERO if slots.has(slot) else payload[offset]
	result["requires_buffer_device_address"] = capabilities.has(5347)
	result["requires_ray_query"] = capabilities.has(4472)
	result["requires_raytracing_pipeline"] = capabilities.has(4479)
	result["forbidden_vulkan_capabilities"] = []
	result["non_spirv_extensions"] = non_spirv_extensions.keys()
	result["cooperative_outer_type"] = false
	result["cooperative_outer_layout"] = false
	result["cooperative_outer_interpretation"] = false
	result["cooperative_reduce_type"] = false
	result["cooperative_training_storage"] = false
	result["cooperative_fp8_layout"] = false
	result["graph_capability"] = capabilities.has(4191)
	result["tensor_declaration"] = tensor_declaration and capabilities.has(4174)
	result["subgroup_repack"] = subgroup_uniform_entries.has(entry) and invocation_repack
	result["cooperative_alignment"] = false
	result["cooperative_offset_width"] = false
	result["matrix_muladd"] = capabilities.has(6022) and _matrix_muladd_invalid(matrix_muladds, types, value_types, integer_literals)
	if capabilities.has(5394) or capabilities.has(5435):
		for operation: Vector4i in cooperative_outer_ops:
			for operand in [operation.x, operation.y]:
				var vector: Array = types.get(image_values.get(operand, -1), [])
				if vector.size() == 3 and vector[0] == 5288:
					var component: Array = types.get(vector[1], [])
					result.cooperative_outer_type = result.cooperative_outer_type or (component in [[21, 8], [21, 16], [21, 32], [21, 64], [22, 8], [22, 32], [22, 64]])
			result.cooperative_outer_layout = result.cooperative_outer_layout or (integer_literals.has(operation.z) and integer_literals[operation.z] != 3)
			result.cooperative_outer_interpretation = result.cooperative_outer_interpretation or (integer_literals.has(operation.w) and integer_literals[operation.w] not in [0, 1])
		for operand: int in cooperative_reduce_ops:
			var vector: Array = types.get(image_values.get(operand, -1), [])
			if vector.size() == 3 and vector[0] == 5288:
				result.cooperative_reduce_type = result.cooperative_reduce_type or (types.get(vector[1], []) in [[21, 8], [21, 16], [21, 32], [21, 64], [22, 8], [22, 64]])
		for operand: int in cooperative_training_pointers:
			var pointer: Array = types.get(image_values.get(operand, -1), [])
			if pointer.size() == 3 and pointer[0] == 32 and pointer[1] in [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]:
				result.cooperative_training_storage = true
		for operation: Vector2i in cooperative_matmul_ops:
			result.cooperative_fp8_layout = result.cooperative_fp8_layout or (integer_literals.get(operation.x, -1) in [1000491002, 1000491003] and integer_literals.has(operation.y) and integer_literals[operation.y] not in [2, 3])
		# Vulkan RuntimeSpirv 10096-10101: constant byte offsets and row/column-major strides must meet the operation's alignment.
		for operand: Vector2i in cooperative_aligned:
			result.cooperative_alignment = result.cooperative_alignment or (integer_literals.has(operand.x) and (int(integer_literals[operand.x]) & (operand.y - 1)) != 0)
		for stride: Vector2i in cooperative_strides:
			result.cooperative_alignment = result.cooperative_alignment or (integer_literals.get(stride.y, -1) in [0, 1] and integer_literals.has(stride.x) and (int(integer_literals[stride.x]) & 15) != 0)
		# RuntimeSpirv 11809: offsets are 32-bit integers unless the entry declares Shader64BitIndexingEXT.
		if not indexing64_entries.has(entry):
			for operand: int in cooperative_offsets:
				result.cooperative_offset_width = result.cooperative_offset_width or int64_values.has(operand) or types.get(image_values.get(operand, -1), []) == [21, 64]
	for capability: int in FORBIDDEN_CAPABILITIES:
		if capabilities.has(capability):
			result.forbidden_vulkan_capabilities.append(FORBIDDEN_CAPABILITIES[capability])
	result["ray_query_flags"] = ray_query_flags
	result["ray_query_distance"] = ray_query_distance
	result["zero_divisor"] = zero_divisor
	result["pow_domain"] = pow_domain
	result["atan2_zero"] = atan2_zero
	result["minmax_nan"] = minmax_nan
	result["multidimensional_image_access"] = multidimensional_image_access
	result["storage_image_formats"] = []
	if not shared_layout_unknown:
		for type_id in shared_types:
			var pointer: Array = types.get(type_id, [])
			var amount := _shared_size(pointer[2], types, constants) if pointer.size() == 3 and pointer[0] == 32 and pointer[1] == 4 else -1
			if amount < 0:
				result.shared_bytes = -1
				break
			result.shared_bytes = mini(result.shared_bytes + amount, 1 << 30)
	for type_id in push_types:
		var pointer: Array = types.get(type_id, [])
		if pointer.size() != 3 or pointer[0] != 32 or pointer[1] != 9:
			continue
		result.push_constant_bytes = maxi(result.push_constant_bytes, _block_size(pointer[2], types, constants, member_offsets))
	var descriptors := {}
	var descriptor_counts := {}
	var buffer_bindings := {}
	for uniform in uniforms:
		if not sets.has(uniform.y) or not bindings.has(uniform.y):
			continue
		var pointer: Array = types.get(uniform.x, [])
		if pointer.size() != 3 or pointer[0] != 32 or not pointer[1] in [0, 2, 12]:
			continue
		var pointee := int(pointer[2])
		var type: Array = types.get(pointee, [])
		var binding := Vector2i(sets[uniform.y], bindings[uniform.y])
		if pointer[1] in [2, 12]:
			var decoration := int(blocks.get(pointer[2], 0))
			if type.is_empty() or type[0] != 30 or not ((pointer[1] == 2 and decoration in [2, 3]) or (pointer[1] == 12 and decoration == 2)):
				continue
			# Godot reflects buffer blocks differently from image arrays; buffer arrays stay unknown.
			var kind := "uniform_buffers" if pointer[1] == 2 and decoration == 2 else "storage_buffers"
			buffer_bindings[binding] = kind
			result.bound_sets = maxi(result.bound_sets, int(binding.x) + 1)
			if kind == "uniform_buffers":
				result.uniform_buffer_size = maxi(result.uniform_buffer_size, _block_size(pointer[2], types, constants, member_offsets))
			continue
		var descriptor_count := 1
		for depth in range(16):
			if type.size() != 3 or type[0] != 28 or int(constants.get(type[2], 0)) <= 0:
				break
			descriptor_count = mini(descriptor_count * int(constants[type[2]]), 1 << 24)
			pointee = int(type[1])
			type = types.get(pointee, [])
		result.separate_sampler = result.separate_sampler or (not type.is_empty() and type[0] == 26)
		if not type.is_empty() and type[0] in [25, 26, 27]:
			result.bound_sets = maxi(result.bound_sets, int(binding.x) + 1)
			descriptors[binding] = maxi(descriptors.get(binding, 0), descriptor_count * 4)
			var counts := Vector3i.ZERO
			if type[0] in [26, 27]:
				counts.x = descriptor_count
			var image_type: Array = types.get(type[1], []) if type[0] == 27 else type
			# Buffer/subpass image types need separate Vulkan descriptor accounting.
			if image_type.size() == 3 and image_type[0] == 25 and image_type[1] in [0, 1, 2, 3, 4]:
				if image_type[2] == 1:
					counts.y = descriptor_count
				elif image_type[2] == 2:
					counts.z = descriptor_count
					var image_format := int(image_formats.get(pointee, 0))
					if type[0] == 25 and image_type[1] != 4 and IMAGE_FORMATS.has(image_format) and not result.storage_image_formats.has(image_format):
						result.storage_image_formats.append(image_format)
			var prior: Vector3i = descriptor_counts.get(binding, Vector3i.ZERO)
			descriptor_counts[binding] = Vector3i(maxi(prior.x, counts.x), maxi(prior.y, counts.y), maxi(prior.z, counts.z))
	for amount in descriptors.values():
		result.descriptor_bytes = mini(result.descriptor_bytes + amount, 1 << 30)
	for counts: Vector3i in descriptor_counts.values():
		result.descriptor_counts.samplers = mini(result.descriptor_counts.samplers + counts.x, 1 << 30)
		result.descriptor_counts.sampled_images = mini(result.descriptor_counts.sampled_images + counts.y, 1 << 30)
		result.descriptor_counts.storage_images = mini(result.descriptor_counts.storage_images + counts.z, 1 << 30)
	for kind: String in buffer_bindings.values():
		result.descriptor_counts[kind] += 1
		result.descriptor_bytes = mini(result.descriptor_bytes + (8 if kind == "uniform_buffers" else 16), 1 << 30)
	if execution_model != 5:
		return result
	var size: Vector3i = literals.get(entry, Vector3i.ZERO)
	if builtin != -1 or ids.has(entry):
		var refs: Vector3i = composites.get(builtin, Vector3i.ZERO) if builtin != -1 else ids[entry]
		size = Vector3i(constants.get(refs.x, 0), constants.get(refs.y, 0), constants.get(refs.z, 0))
	# shortcut: partial metadata reader, not a SPIR-V validator; unknown sizes stay unknown.
	if size.x <= 0 or size.y <= 0 or size.z <= 0 or size.x > 65535 or size.y > 65535 or size.z > 65535:
		result["skip"] = "unresolved, specialized or invalid workgroup size"
	else:
		result["size"] = size
	return result


## SPIRV-Tools ValidateCooperativeMatrixMulAddKHR: A/B/C uses, equal scopes, matching M/N/K and signedness flags only on
## integer components. Only known cooperative-matrix value types and 32-bit constant dimensions are compared.
static func _matrix_muladd_invalid(operations: Array, types: Dictionary, value_types: Dictionary, literals: Dictionary) -> bool:
	for operation: Array in operations:
		var matrices: Array = [types.get(value_types.get(operation[1], -1), []), types.get(value_types.get(operation[2], -1), []),
				types.get(value_types.get(operation[3], -1), []), types.get(operation[0], [])]
		if matrices.any(func(type: Array) -> bool: return type.size() != 6 or type[0] != 4456):
			continue
		for index in 3:
			if literals.has(matrices[index][5]) and int(literals[matrices[index][5]]) != index:
				return true
		var scope: Array = matrices.map(func(type: Array) -> Variant: return literals.get(type[2]))
		var rows: Array = matrices.map(func(type: Array) -> Variant: return literals.get(type[3]))
		var cols: Array = matrices.map(func(type: Array) -> Variant: return literals.get(type[4]))
		if _known_differ(scope) or _known_differ([rows[0], rows[2], rows[3]]) or _known_differ([cols[1], cols[2], cols[3]]) or _known_differ([cols[0], rows[1]]):
			return true
		for bit in 4:
			var component: Array = types.get(matrices[bit][1], [])
			if (int(operation[4]) & (1 << bit)) != 0 and component.size() >= 1 and component[0] != 21:
				return true
	return false


static func _known_differ(values: Array) -> bool:
	var known := values.filter(func(value: Variant) -> bool: return value != null)
	return known.any(func(value: Variant) -> bool: return value != known[0])


static func _interface_type(id: int, types: Dictionary, constants: Dictionary, depth: int = 0) -> Array[Vector2i]:
	var slots: Array[Vector2i] = []
	if depth >= 16:
		return slots
	var type: Array = types.get(id, [])
	if type.size() == 2 and type[0] in [21, 22] and type[1] in [16, 32, 64]:
		for index in (2 if type[1] == 64 else 1):
			slots.append(Vector2i(type[0], type[1]))
	elif type.size() == 3 and type[0] in [23, 24, 28]:
		var child: Array = types.get(type[1], [])
		if child.is_empty() or (type[0] == 23 and child[0] not in [21, 22]) or (type[0] == 24 and child[0] != 23):
			return slots
		var count := int(constants.get(type[2], 0)) if type[0] == 28 else int(type[2])
		if count < 1 or count > MAX_INTERFACE_SLOTS or (type[0] != 28 and (count < 2 or count > 4)):
			return slots
		var payload := _interface_type(type[1], types, constants, depth + 1)
		if payload.is_empty():
			return slots
		if type[0] != 23:
			while payload.size() % 4 != 0:
				payload.append(Vector2i.ZERO)
		if payload.size() * count > MAX_INTERFACE_SLOTS:
			return slots
		for index in count:
			slots.append_array(payload)
	elif not type.is_empty() and type[0] == 30:
		for member in range(1, type.size()):
			var payload := _interface_type(type[member], types, constants, depth + 1)
			if payload.is_empty():
				return []
			while payload.size() % 4 != 0:
				payload.append(Vector2i.ZERO)
			if slots.size() + payload.size() > MAX_INTERFACE_SLOTS:
				return []
			slots.append_array(payload)
	return slots


static func _has_8bit(id: int, types: Dictionary, cache: Dictionary, depth: int = 0) -> bool:
	if depth >= 16:
		return false
	var cached: Vector2i = cache.get(id, Vector2i(0, 16))
	if cached.x == 1 or depth >= cached.y:
		return cached.x == 1
	# Retain search depth so a later shallower declaration can revisit a skipped branch.
	cache[id] = Vector2i(0, depth)
	var found := false
	var type: Array = types.get(id, [])
	if type.size() == 2 and type[0] in [21, 22]:
		found = type[1] == 8
	elif (type.size() == 3 and type[0] in [23, 24, 28]) or (type.size() == 2 and type[0] == 29):
		found = _has_8bit(type[1], types, cache, depth + 1)
	elif not type.is_empty() and type[0] == 30:
		for member in range(1, type.size()):
			if _has_8bit(type[member], types, cache, depth + 1):
				found = true
				break
	cache[id] = Vector2i(1 if found else 0, depth)
	return found


static func _block_size(id: int, types: Dictionary, constants: Dictionary, offsets: Dictionary) -> int:
	var block: Array = types.get(id, [])
	var size := 0
	if block.is_empty() or block[0] != 30:
		return size
	for member in range(1, block.size()):
		var offset := int(offsets.get(Vector2i(id, member - 1), -1))
		var payload := _shared_size(block[member], types, constants)
		if offset >= 0 and payload > 0:
			# Padding only increases this lower bound; unsupported members contribute nothing.
			size = maxi(size, mini(offset + payload, 1 << 30))
	return size


static func _shared_size(id: int, types: Dictionary, constants: Dictionary, depth: int = 0) -> int:
	if depth >= 16:
		return -1
	var type: Array = types.get(id, [])
	if type.size() == 2 and type[0] in [21, 22] and type[1] in [8, 16, 32, 64]:
		return int(type[1]) / 8
	if type.size() != 3 or not type[0] in [23, 24, 28]:
		return -1
	var count: int = constants.get(type[2], 0) if type[0] == 28 else type[2]
	if count <= 0 or count > (1 << 24):
		return -1
	var element := _shared_size(type[1], types, constants, depth + 1)
	# Saturation prevents nested-array overflow; one GiB already exceeds practical shared-memory limits.
	return mini(element * count, 1 << 30) if element >= 0 else -1
