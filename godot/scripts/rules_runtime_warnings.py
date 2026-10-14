"""Rules for stored configurations that make Godot print a runtime warning (docs/GODOT_RUNTIME_WARNINGS.json).

Each rule quotes the engine's own WARN_PRINT text. The build checks that the quote is in the cited source file of every
Godot version the rule covers (skipped when the .tmp/upstream checkouts are absent).
"""
import os

from godot_versions import CHECKOUTS, expand

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UPSTREAM = os.path.join(ROOT, ".tmp", "upstream")
ALL = ["forward_plus", "mobile", "gl_compatibility"]
FP = ["forward_plus"]
FPM = ["forward_plus", "mobile"]
NOT_FP = ["mobile", "gl_compatibility"]
GL = ["gl_compatibility"]
BOTH = ["4.4", "4.7"]
JOLT = {"setting_eq": {"path": "physics/3d/physics_engine", "value": "Jolt Physics"}}


def _by_version(value, version):
    """value is a string, or {first version: string} where each entry holds until the next key."""
    if isinstance(value, str):
        return value
    return value[max(key for key in value if [int(n) for n in key.split(".")] <= [int(n) for n in version.split(".")])]


def _require_message(files, messages, versions):
    if not all(os.path.isdir(os.path.join(UPSTREAM, CHECKOUTS[version])) for version in expand(versions)):
        return
    for version in expand(versions):
        path = os.path.join(UPSTREAM, CHECKOUTS[version], _by_version(files, version))
        with open(path, encoding="utf-8", errors="replace") as handle:
            text = handle.read()
        message = _by_version(messages, version)
        if message not in text:
            raise SystemExit("runtime warning not in %s (%s): %s" % (path, version, message))


def _setting(op, path, value):
    return {"setting_" + op: {"path": path, "value": value}}


def _scene(key):
    return {"scene_gte": {"name": "check_" + key, "value": 1}}


def register(add):
    def warned(rule_id, category, title, condition, files, messages, evidence, suggestion, tradeoff, *, versions=BOTH,
               renderers=ALL, requires=("settings",), kind="correctness", severity="medium", setting="", offender_key="", printed=""):
        _require_message(files, messages, versions)
        latest = expand(versions)[-1]
        # printed: the runtime output when the source builds the message from pieces.
        quote = printed or _by_version(messages, latest)
        add(dict(id=rule_id, category=category, title=title, kind=kind, severity=severity, renderers=renderers,
                 versions=list(versions), requires=list(requires), condition=condition, setting=setting, offender_key=offender_key,
                 evidence='Godot prints "%s" %s' % (quote, evidence), suggestion=suggestion, tradeoff=tradeoff,
                 expected_effect="Godot uses the configuration as written instead of overriding or ignoring it; no performance saving is asserted.",
                 verify_step="audit_project_rendering or scan_scene, then run the game and confirm the warning is gone from the output",
                 source="https://github.com/godotengine/godot/blob/%s/%s" % (CHECKOUTS[latest].removeprefix("godot-"), _by_version(files, latest)),
                 evidence_kind="godot_runtime_warning"))

    viewport = "servers/rendering/renderer_viewport.cpp"
    mode = "rendering/scaling_3d/mode"
    warned("resolution.upscaler_renderer", "resolution", "The 3D scaling mode needs a renderer that is not selected",
           {"any": [_setting("eq", mode, 1), _setting("eq", mode, 2), _setting("eq", mode, 4),
                    {"all": [_setting("eq", "rendering/renderer/rendering_method", "gl_compatibility"), _setting("eq", mode, 3)]}]},
           viewport, {"4.4": "FSR2 is only available when using the Forward+ renderer.", "4.6": "FSR2 3D scaling is only available when using the Forward+ renderer."},
           "when rendering/scaling_3d/mode is FSR 1.0 (1), FSR 2.2 (2) or MetalFX Temporal (4) outside Forward+, or MetalFX Spatial (3) under Compatibility. Godot 4.4, 4.5 and 4.7 reject the mode and 4.6 falls back to bilinear scaling, so the chosen upscaler never runs.",
           "Use bilinear scaling (0) with this renderer, or switch to a renderer that supports the upscaler.",
           "Bilinear scaling is softer than FSR at the same render scale.", renderers=NOT_FP, setting=mode)
    warned("resolution.upscaler_downsampling", "resolution", "An upscaler is selected with a 3D scale above 1",
           {"all": [_setting("gt", "rendering/scaling_3d/scale", 1.0), _setting("neq", mode, 0)]},
           viewport, "not designed for downsampling. Falling back to bilinear 3D resolution scaling.",
           "when rendering/scaling_3d/scale is above 1.0 and the scaling mode is not bilinear. FSR, MetalFX and (4.7) nearest-neighbor scaling are replaced by bilinear supersampling.",
           "Set the scaling mode to bilinear (0) when supersampling, or lower the scale to 1.0 or below to use the upscaler.",
           "None; Godot already renders this configuration with bilinear scaling.", setting=mode, severity="low",
           printed="FSR, MetalFX, and nearest-neighbor 3D resolution scaling are not designed for downsampling. Falling back to bilinear 3D resolution scaling.")
    warned("antialiasing.taa_with_temporal_upscaler", "antialiasing", "TAA is enabled together with a temporal upscaler",
           {"all": [_setting("eq", "rendering/anti_aliasing/quality/use_taa", True), {"any": [_setting("eq", mode, 2), _setting("eq", mode, 4)]}]},
           viewport, "FSR 2 or MetalFX Temporal is not compatible with TAA. Disabling TAA internally.",
           "when use_taa is on and the scaling mode is FSR 2.2 (2) or MetalFX Temporal (4). The upscaler provides its own temporal antialiasing and Godot turns TAA off.",
           "Turn rendering/anti_aliasing/quality/use_taa off; the temporal upscaler already antialiases.",
           "None; TAA is already disabled while the temporal upscaler runs.", renderers=FP, setting="rendering/anti_aliasing/quality/use_taa", severity="low")
    warned("antialiasing.taa_renderer", "antialiasing", "TAA is enabled outside Forward+",
           _setting("eq", "rendering/anti_aliasing/quality/use_taa", True),
           viewport, "TAA is only available when using the Forward+ renderer.",
           "when use_taa is on under the Mobile or Compatibility renderer, which have no TAA pass.",
           "Turn use_taa off for this renderer and choose another antialiasing method (MSAA or FXAA where available).",
           "Without TAA, specular and geometric aliasing remain unless another method is enabled.",
           renderers=NOT_FP, setting="rendering/anti_aliasing/quality/use_taa")
    warned("antialiasing.screen_space_aa_renderer", "antialiasing", "Screen-space antialiasing is set under Compatibility",
           _setting("neq", "rendering/anti_aliasing/quality/screen_space_aa", 0),
           viewport, {"4.5": "Screen space AA is currently unavailable on the Compatibility renderer.", "4.6": "Screen-space AA is only available when using the Forward+ or Mobile renderer."},
           "when screen_space_aa is FXAA or SMAA under the Compatibility renderer, which does not run it.",
           "Set screen_space_aa to Disabled and use MSAA under Compatibility.",
           "MSAA does not smooth shader or transparency aliasing.", versions=["4.5", "4.7"], renderers=GL,
           setting="rendering/anti_aliasing/quality/screen_space_aa")
    warned("antialiasing.msaa_2d_renderer", "antialiasing", "2D MSAA is set under Compatibility",
           _setting("gt", "rendering/anti_aliasing/quality/msaa_2d", 0),
           "drivers/gles3/storage/texture_storage.cpp", "2D MSAA is not yet supported for GLES3.",
           "when msaa_2d is above Disabled under the Compatibility renderer, so 2D content is not multisampled.",
           "Set msaa_2d to Disabled, or antialias 2D lines and polygons with their antialiased properties.",
           "Polygon and line edges stay aliased unless drawn antialiased.", renderers=GL,
           setting="rendering/anti_aliasing/quality/msaa_2d", severity="low")
    warned("gi.probe_always_atlas", "gi", "An Always-updating ReflectionProbe resizes the reflection atlas to 256",
           {"all": [{"scene_gte": {"name": "reflection_probe_always_count", "value": 1}}, _setting("neq", "rendering/reflections/reflection_atlas/reflection_size", 256)]},
           "servers/rendering/renderer_rd/storage_rd/light_storage.cpp", "ReflectionProbes set to UPDATE_ALWAYS must have an atlas size of 256.",
           "when a probe with update_mode Always renders into an atlas whose size is not 256, then resizes the atlas to 256 for every probe. The .mobile override (128 by default) also triggers it on mobile devices.",
           "Set rendering/reflections/reflection_atlas/reflection_size (and its .mobile override) to 256, or use update_mode Once.",
           "A 256 atlas lowers reflection detail for probes that would have used a larger size.", renderers=FPM,
           requires=("scene", "settings"), setting="rendering/reflections/reflection_atlas/reflection_size", offender_key="probes_always", severity="low")
    warned("sky.realtime_radiance_size", "sky", "A real-time sky asks for a radiance size other than 256",
           _scene("sky_realtime_radiance"),
           "servers/rendering/renderer_rd/environment/sky.cpp", "Realtime Skies can only use a radiance size of",
           "when Sky.process_mode is Real-Time and radiance_size is not 256; the radiance map is set to 256 internally.",
           "Set Sky.radiance_size to 256 for real-time skies, or use another process mode if a different size is needed.",
           "None; Godot already renders this sky at 256.", renderers=FPM, requires=("scene",), offender_key="check_sky_realtime_radiance", severity="low",
           printed="Realtime Skies can only use a radiance size of 256. Radiance size will be set to 256 internally.")
    warned("canvas.hdr_output_forces_hdr_2d", "canvas", "HDR output turns on HDR 2D",
           {"all": [_setting("eq", "display/window/hdr/request_hdr_output", True), _setting("eq", "rendering/viewport/hdr_2d", False)]},
           "scene/main/scene_tree.cpp", "HDR 2D was automatically enabled because HDR output was requested in project settings.",
           "when display/window/hdr/request_hdr_output is on and rendering/viewport/hdr_2d is off. The root viewport then renders 2D in HDR anyway, with the memory and bandwidth of an HDR canvas buffer.",
           "Enable rendering/viewport/hdr_2d explicitly so the project settings match what runs, and budget for the HDR canvas buffer.",
           "None; HDR 2D is already active.", versions=["4.7"], setting="display/window/hdr/request_hdr_output", kind="info", severity="low")
    warned("gi.lightmap_missing_nodes", "gi", "Baked lightmap data refers to nodes that no longer exist",
           _scene("lightmap_missing_nodes"),
           "scene/3d/lightmap_gi.cpp", "couldn't find previously baked nodes and needs a rebake",
           "when a LightmapGI's baked data lists a mesh path that does not resolve; that mesh renders without its lightmap.",
           "Rebake the LightmapGI after moving, renaming or deleting baked meshes.",
           "Baking takes time and replaces the lightmap files.", versions=["4.5", "4.7"], requires=("scene",), offender_key="check_lightmap_missing_nodes",
           printed="LightmapGI couldn't find previously baked nodes and needs a rebake (missing nodes: ../Wall).")
    warned("navigation.mesh_cell_size_mismatch", "navigation", "A navigation mesh cell is smaller than its map's",
           _scene("navmesh_cell_size_mismatch"),
           "modules/navigation_3d/nav_region_3d.cpp", "was assigned to a navigation map set to a larger `cell_size` of",
           "when a NavigationRegion's mesh uses a cell_size or cell_height below the map's (the navigation/2d or 3d default_cell_size and default_cell_height settings for default maps). The message says the mismatch can cause rasterization errors with navigation mesh edges on the map.",
           "Bake the navigation mesh with the map's cell size and height, or change the map defaults to match.",
           "Matching a coarser map cell size lowers navigation mesh precision.", versions=["4.5", "4.7"], requires=("scene", "settings"),
           offender_key="check_navmesh_cell_size_mismatch",
           printed="A navigation mesh that uses a `cell_size` of 0.1 was assigned to a navigation map set to a larger `cell_size` of 0.25.")
    warned("navigation.obstacle_vertex_height", "navigation", "Static obstacle vertices have Y values that avoidance ignores",
           _scene("obstacle_vertex_height"),
           {"4.4": "modules/navigation/nav_map.cpp", "4.5": "modules/navigation_3d/nav_map_3d.cpp"},
           "Y coordinates of static obstacle vertices are ignored. Please use obstacle position Y to change elevation of obstacle.",
           "in editor builds when a NavigationObstacle3D's vertices have a nonzero Y; avoidance ignores the Y in every build.",
           "Keep obstacle vertices at Y 0 and move the obstacle node to set its elevation.",
           "None.", requires=("scene",), offender_key="check_obstacle_vertex_height", severity="low")
    warned("physics.jolt_joint_ignored", "physics", "A joint sets parameters that Jolt Physics ignores",
           {"all": [_scene("jolt_joint_ignored"), JOLT]},
           "modules/jolt_physics/joints/jolt_hinge_joint_3d.cpp", "is not supported when using Jolt Physics. Any such value will be ignored.",
           "for each Hinge, Pin, ConeTwist, Slider or Generic6DOF joint parameter (bias, softness, relaxation, damping, restitution, ERP, force limit and slider angular limits) and solver priority that differs from Godot's default while physics/3d/physics_engine is Jolt Physics. PhysicalBone3D joints are not inspected.",
           "Reset the parameters Jolt ignores, or tune the joint with the settings Jolt implements (limits, motors and springs).",
           "Behavior tuned under GodotPhysics may differ under Jolt.", requires=("scene", "settings"), offender_key="check_jolt_joint_ignored",
           printed="Hinge joint softness is not supported when using Jolt Physics. Any such value will be ignored.")
    warned("physics.jolt_area_wind_ignored", "physics", "An Area3D sets wind that Jolt Physics ignores",
           {"all": [_scene("jolt_area_wind_ignored"), JOLT]},
           "modules/jolt_physics/objects/jolt_area_3d.cpp", "Area wind force magnitude is not supported when using Jolt Physics. Any such value will be ignored.",
           "when an Area3D's wind force magnitude, attenuation or source differs from the default while physics/3d/physics_engine is Jolt Physics (Godot 4.4 to 4.6; 4.7 implements area wind).",
           "Apply the force from a script, or remove the wind settings.",
           "A script force needs its own per-body update.", versions=["4.4", "4.6"], requires=("scene", "settings"), offender_key="check_jolt_area_wind_ignored")
    warned("physics.jolt_shape_bias_ignored", "physics", "A collision shape sets a solver bias that Jolt Physics ignores",
           {"all": [_scene("jolt_shape_bias_ignored"), JOLT]},
           "modules/jolt_physics/shapes/jolt_shape_3d.cpp", "Custom solver bias for shapes is not supported when using Jolt Physics. Any such value will be ignored.",
           "when a CollisionShape3D's shape has a nonzero custom_solver_bias while physics/3d/physics_engine is Jolt Physics.",
           "Set custom_solver_bias back to 0.",
           "None.", requires=("scene", "settings"), offender_key="check_jolt_shape_bias_ignored", severity="low")
    mobile_shader = "servers/rendering/renderer_rd/forward_mobile/scene_shader_forward_mobile.cpp"
    warned("materials.subsurf_renderer", "materials", "Subsurface scattering is enabled outside Forward+",
           {"scene_gte": {"name": "subsurf_material_count", "value": 1}},
           mobile_shader, "Subsurface scattering is only available when using the Forward+ renderer.",
           "when a material enables subsurface scattering under the Mobile or Compatibility renderer, which do not draw it.",
           "Turn subsurf_scatter_enabled off for this renderer, or fake the look in the albedo or a custom shader.",
           "Skin and wax lose their soft light bleed.", renderers=NOT_FP, requires=("scene",), offender_key="subsurf_materials")
    warned("materials.transmittance_renderer", "materials", "Subsurface transmittance is enabled outside Forward+",
           _scene("transmittance_material"),
           mobile_shader, "Transmittance is only available when using the Forward+ renderer.",
           "when a material enables subsurface transmittance under the Mobile or Compatibility renderer, which do not draw it.",
           "Turn subsurf_scatter_transmittance_enabled off for this renderer.",
           "Thin objects lose back-lit transmission.", renderers=NOT_FP, requires=("scene",), offender_key="check_transmittance_material", severity="low")
    particles = "drivers/gles3/storage/particles_storage.cpp"
    warned("scene_validation.particle_attractor_renderer", "scene_validation", "A vector-field particle attractor is used under Compatibility",
           _scene("particle_vector_attractor"),
           particles, "Vector field particle attractors are not available in the Compatibility renderer.",
           "when the scene has a GPUParticlesAttractorVectorField3D and the renderer is Compatibility, which skips it.",
           "Use a box or sphere attractor, or switch to Forward+ or Mobile.",
           "Simple attractors cannot reproduce a vector field.", renderers=GL, requires=("scene",), offender_key="check_particle_vector_attractor")
    warned("scene_validation.particle_sdf_renderer", "scene_validation", "An SDF particle collider is used under Compatibility",
           _scene("particle_sdf_collider"),
           particles, "SDF Particle Colliders are not available in the Compatibility renderer.",
           "when the scene has a GPUParticlesCollisionSDF3D and the renderer is Compatibility, which skips it.",
           "Use box, sphere or height-field colliders, or switch to Forward+ or Mobile.",
           "Primitive colliders follow complex geometry less closely.", renderers=GL, requires=("scene",), offender_key="check_particle_sdf_collider")
    warned("post.compositor_pre_opaque_resolved", "post", "A pre-opaque compositor effect asks for resolved buffers",
           _scene("compositor_pre_opaque_resolved"),
           "servers/rendering/renderer_rd/forward_clustered/render_forward_clustered.cpp", "Pre opaque rendering effects can't access resolved color buffers.",
           "when a Pre-Opaque CompositorEffect sets access_resolved_color (or access_resolved_depth without a depth prepass) on a viewport with 3D MSAA; nothing has been rendered to resolve at that point.",
           "Move the effect to a later callback, or clear the access_resolved flags it cannot use.",
           "A later callback runs after opaque geometry.", renderers=FP, requires=("scene",), offender_key="check_compositor_pre_opaque_resolved", versions=BOTH)
    warned("post.compositor_mobile_unsupported", "post", "A compositor effect uses a callback the Mobile renderer does not run",
           _scene("compositor_mobile_unsupported"),
           "servers/rendering/renderer_rd/forward_mobile/render_forward_mobile.cpp", "Post opaque rendering effect callback is not supported in the mobile renderer",
           "for a Post-Opaque CompositorEffect under the Mobile renderer, which renders opaque geometry and sky in subpasses; the renderer also prints that resolved depth access is unsupported when an effect asks for it with 3D MSAA.",
           "Use the Pre-Transparent or Post-Transparent callback on Mobile, or disable 3D MSAA for effects that read resolved depth.",
           "A different callback changes what the effect sees.", renderers=["mobile"], requires=("scene",), offender_key="check_compositor_mobile_unsupported")
    warned("antialiasing.metalfx_temporal_msaa", "antialiasing", "MetalFX Temporal upscaling is combined with 3D MSAA",
           {"all": [_setting("eq", mode, 4), _setting("gt", "rendering/anti_aliasing/quality/msaa_3d", 0)]},
           viewport, "MetalFX temporal upscaling does not support 3D MSAA. Disabling 3D MSAA internally.",
           "on Apple devices that run MetalFX Temporal (scaling mode 4) when msaa_3d is enabled; MSAA is turned off while the upscaler runs.",
           "Set msaa_3d to Disabled when using MetalFX Temporal, or choose another scaling mode.",
           "None on devices that run MetalFX Temporal; other devices fall back to another upscaler and keep MSAA.", renderers=FP, setting=mode, severity="low")
    warned("sky.realtime_roughness_layers", "sky", "A real-time sky runs with roughness layers other than 8",
           {"all": [_scene("sky_realtime"), _setting("neq", "rendering/reflections/sky_reflections/roughness_layers", 8)]},
           "servers/rendering/renderer_rd/environment/sky.cpp", "should be set to 8 in the project settings for best quality reflections.",
           "when Sky.process_mode is Real-Time and rendering/reflections/sky_reflections/roughness_layers is not 8 (Godot 4.4 and 4.5); real-time skies always use 8 layers.",
           "Set roughness_layers to 8, or use a non-real-time sky process mode.",
           "None; real-time skies already use 8 layers.", versions=["4.4", "4.5"], renderers=FPM, requires=("scene", "settings"),
           offender_key="check_sky_realtime", severity="low",
           printed='When using the Real-Time sky update mode (or Automatic with a sky shader using "TIME"), "rendering/reflections/sky_reflections/roughness_layers" should be set to 8 in the project settings for best quality reflections.')
    warned("audio.microphone_input_disabled", "audio", "A microphone stream is used while audio input is off",
           {"all": [_scene("microphone_stream"), _setting("eq", "audio/driver/enable_input", False)]},
           {"4.4": "servers/audio/audio_stream.cpp", "4.6": "servers/audio/audio_server.cpp"},
           "to use audio capture.",
           "when an AudioStreamMicrophone starts while audio/driver/enable_input is off; nothing is captured.",
           "Enable audio/driver/enable_input (export templates may also need microphone permissions on mobile and web).",
           "Enabling input asks the operating system for microphone access.", requires=("scene", "settings"), offender_key="check_microphone_stream",
           printed='You must enable the project setting "audio/driver/enable_input" to use audio capture.')
    warned("physics.convex_polygon_2d_concave", "physics", "A ConvexPolygonShape2D has concave points",
           _scene("convex_polygon_concave"),
           "scene/resources/2d/convex_polygon_shape_2d.cpp", "Concave polygon is assigned to ConvexPolygonShape2D.",
           "in debug builds when a CollisionShape2D's ConvexPolygonShape2D points fail Godot's convexity test; the shape still collides as a convex solver shape, so contacts do not follow the drawn outline.",
           "Use a CollisionPolygon2D with build mode Solids (it decomposes concave outlines), or a ConcavePolygonShape2D for static geometry.",
           "Decomposition creates several shapes.", requires=("scene",), offender_key="check_convex_polygon_concave")
    warned("scene_validation.texture_type_unsampled", "scene_validation", "A decal, projector or 2D light uses a texture type it cannot sample",
           _scene("texture_type_unsampled"),
           "scene/3d/decal.cpp", "cannot be used as a Decal texture",
           "when a Decal texture, a Light3D projector (or 4.7 area-light texture) or a PointLight2D texture is an AnimatedTexture, AtlasTexture, CameraTexture, CanvasTexture, MeshTexture, Texture2DRD or ViewportTexture. Godot's message suggests assigning the image from get_image() instead.",
           "Assign an ImageTexture or imported texture (for example from the texture's get_image()).",
           "A static image does not update with the source texture.", requires=("scene",), offender_key="check_texture_type_unsampled",
           printed="ViewportTexture cannot be used as a Decal texture (Decal path). As a workaround, assign the value returned by ViewportTexture's `get_image()` instead.")
    warned("ui.aspect_ratio_proportional_texture", "ui", "A proportional TextureRect is inside an AspectRatioContainer",
           _scene("aspect_ratio_texture_rect"),
           "scene/gui/aspect_ratio_container.cpp", "Proportional TextureRect is currently not supported inside AspectRatioContainer",
           "when a direct TextureRect child of AspectRatioContainer uses expand mode Fit Width Proportional or Fit Height Proportional; the container ignores that child's proportional sizing.",
           "Use expand mode Ignore Size or Keep Size inside the container and let the container keep the ratio.",
           "None.", requires=("scene",), offender_key="check_aspect_ratio_texture_rect", severity="low")
    warned("xr.composition_layer_sort_zero", "xr", "An OpenXR composition layer has sort order 0",
           _scene("openxr_layer_sort_zero"),
           "modules/openxr/openxr_api.cpp", "Composition layer returned sort order 0, it may be overwritten by projection layer.",
           "when an OpenXRCompositionLayer's sort_order is 0, the order of the main projection layer, so the runtime may draw the scene over it.",
           "Use a positive sort_order to draw the layer in front of the scene, or a negative one to draw it behind.",
           "None.", requires=("scene",), offender_key="check_openxr_layer_sort_zero")
    warned("scene_validation.viewport_sss_transparent", "scene_validation", "Subsurface scattering is drawn in a transparent viewport",
           {"any": [_scene("viewport_sss_transparent"),
                    {"all": [_setting("eq", "rendering/viewport/transparent_background", True), {"scene_gte": {"name": "subsurf_material_count", "value": 1}},
                             _setting("neq", "rendering/environment/subsurface_scattering/subsurface_scattering_quality", 0)]}]},
           "servers/rendering/renderer_rd/forward_clustered/render_forward_clustered.cpp", "Sub-surface scattering is not supported in viewports with a transparent background. Disabling SSS in transparent viewport.",
           "when a SubViewport with transparent_bg draws a material with subsurface scattering, or rendering/viewport/transparent_background is on and the scene uses such a material, while subsurface scattering quality is not Disabled.",
           "Use an opaque background for viewports that need subsurface scattering, or turn subsurface scattering off on those materials.",
           "An opaque background cannot be composited over other content.", versions=["4.5", "4.7"], renderers=FP, requires=("scene", "settings"),
           offender_key="check_viewport_sss_transparent")
    warned("scene_validation.modifier_node_missing", "scene_validation", "A skeleton modifier's center or reference node does not resolve",
           _scene("modifier_node_missing"),
           "scene/3d/bone_constraint_3d.cpp", "' not found.",
           "when a SpringBoneSimulator3D center node or a BoneConstraint3D reference node path does not resolve to a Node3D; the setting then has no valid center or reference.",
           "Point the path at the intended Node3D, or clear it and use a bone reference.",
           "None.", versions=["4.7"], requires=("scene",), offender_key="check_modifier_node_missing",
           printed="Setting: 0: Reference node 'Missing' not found.")
    warned("physics.jolt_singular_basis", "physics", "A physics node has a zero-scale axis under Jolt Physics",
           {"all": [_scene("jolt_singular_basis"), JOLT]},
           "modules/jolt_physics/shapes/jolt_shape_3d.h", "The basis of the transform was singular, which is not supported by Jolt Physics.",
           "when a CollisionObject3D or CollisionShape3D in the tree has a global transform with a zero scale on some axis while physics/3d/physics_engine is Jolt Physics; Jolt replaces the basis.",
           "Give physics nodes a nonzero scale; hide or disable them instead of scaling them to zero.",
           "None.", requires=("scene", "settings"), offender_key="check_jolt_singular_basis", printed="<object>: The basis of the transform was singular, which is not supported by Jolt Physics. This is likely caused by one or more axes having a scale of zero. The basis (and thus its scale) will be treated as identity.")
    warned("xr.frame_synthesis_renderer", "xr", "OpenXR frame synthesis is requested under Forward+",
           {"all": [_setting("eq", "xr/openxr/enabled", True), _setting("eq", "xr/openxr/extensions/frame_synthesis", True)]},
           "modules/openxr/extensions/openxr_frame_synthesis_extension.cpp", "OpenXR: Frame synthesis not supported for this rendering method!",
           "when xr/openxr/extensions/frame_synthesis is on and the project renders with Forward+ on Vulkan; Godot unregisters the extension, so no frames are synthesized. Mobile on Vulkan and Compatibility support it; Direct3D 12 and Metal reject it as a driver instead.",
           "Use the Mobile renderer for XR projects that rely on frame synthesis, or turn the setting off.",
           "The Mobile renderer drops Forward+-only effects.", versions=["4.6", "4.7"], renderers=FP, setting="xr/openxr/extensions/frame_synthesis")
    warned("scene_validation.material_normal_tangents", "scene_validation", "A normal- or height-mapped material is drawn on a mesh without tangents",
           _scene("material_normal_tangents"),
           "servers/rendering/renderer_rd/forward_clustered/render_forward_clustered.cpp", "that requires tangents with a mesh %s that doesn't contain tangents. Ensure that meshes are imported with the 'ensure_tangents' option.",
           "when a per-pixel BaseMaterial3D with normal mapping or height mapping is drawn on an ArrayMesh surface without ARRAY_FORMAT_TANGENT. Normal mapping writes NORMAL_MAP and height mapping reads TANGENT and BINORMAL, so the lighting uses a missing tangent basis. Triplanar materials build their own tangents and are excluded; anisotropy is reported by scene_validation.material_anisotropy_tangents.",
           "Enable ensure_tangents when importing the mesh, add an ARRAY_TANGENT array, or call SurfaceTool.generate_tangents().",
           "Tangents add 4 bytes per vertex (compressed) or more.", requires=("scene",), offender_key="check_material_normal_tangents",
           printed="Attempting to use a shader that requires tangents with a mesh that doesn't contain tangents. Ensure that meshes are imported with the 'ensure_tangents' option. If creating your own meshes, add an `ARRAY_TANGENT` array (when using ArrayMesh) or call `generate_tangents()` (when using SurfaceTool).")
    warned("scene_validation.shader_normal_roughness_renderer", "scene_validation", "A spatial shader reads the normal-roughness buffer under Compatibility",
           _scene("shader_normal_roughness"),
           "drivers/gles3/storage/material_storage.cpp", {"4.4": "Reading from the normal-roughness texture is only available when using the Forward+ or Mobile renderers.", "4.6": "Reading from the normal-roughness texture is only available when using the Forward+ or Mobile renderer."},
           "when a ShaderMaterial's spatial shader declares a hint_normal_roughness_texture uniform (comments ignored) under the Compatibility renderer, which has no normal-roughness buffer.",
           "Remove the normal-roughness read for Compatibility, or use Forward+ or Mobile.",
           "Effects that need screen-space normals lose that input.", renderers=GL, requires=("scene",), offender_key="check_shader_normal_roughness")
    warned("platform.path_case_mismatch", "platform", "A res:// path differs in case from the file on disk",
           _scene("path_case_mismatch"),
           "drivers/windows/file_access_windows.cpp", "This file will not open when exported to other case-sensitive platforms.",
           "in editor builds on Windows (and macOS) when a script, scene, resource or a path-bearing project setting (main scene, icon, boot splash, theme, autoloads, translations and their remaps) refers to a res:// path whose letter case differs from the file or folder on disk. The case-insensitive file system opens it during development; exported packs are case-sensitive. Text-resource references that also carry a uid:// are skipped, since Godot loads those by UID.",
           "Change the reference to the on-disk spelling, or rename the file to match.",
           "Renaming files needs the editor so imports and UIDs follow.", requires=("scene",), offender_key="check_path_case_mismatch",
           printed="Case mismatch opening requested file 'res://Art/hero.png', stored as 'res://art/hero.png' in the filesystem. This file will not open when exported to other case-sensitive platforms.")
    warned("cpu.rendering_server_sync_per_frame", "cpu", "A script calls a waiting RenderingServer getter every frame on a separate render thread",
           {"all": [_scene("frame_rendering_sync"), _setting("eq", "rendering/driver/threads/thread_model", 2)]},
           "servers/rendering/rendering_server_default.h", "causing RenderingServer synchronizations on every frame. This significantly affects performance.",
           "when rendering/driver/threads/thread_model is Separate (2) and a script calls a RenderingServer method that returns a value (one of the FUNCnR/FUNCnRC wrappers, listed in server_sync_calls.gd) unconditionally in _process, _physics_process or _integrate_forces: the main thread waits for the render thread on every frame.",
           "Cache the value, call it less often, or keep the Safe thread model.",
           "Cached values can go stale.", kind="performance", requires=("scene", "settings"), offender_key="check_frame_rendering_sync",
           printed="Call to mesh_get_surface_count causing RenderingServer synchronizations on every frame. This significantly affects performance.")
    warned("cpu.physics_server_sync_per_frame", "cpu", "A script calls a waiting PhysicsServer getter every frame with physics on its own thread",
           {"any": [{"all": [_scene("frame_physics_3d_sync"), _setting("eq", "physics/3d/run_on_separate_thread", True)]},
                    {"all": [_scene("frame_physics_2d_sync"), _setting("eq", "physics/2d/run_on_separate_thread", True)]}]},
           {"4.4": "servers/physics_server_3d_wrap_mt.h", "4.6": "servers/physics_3d/physics_server_3d_wrap_mt.h"},
           "causing PhysicsServer3D synchronizations on every frame. This significantly affects performance.",
           "(or the PhysicsServer2D form) when physics/3d (or 2d) run_on_separate_thread is on and a script calls a PhysicsServer3D (or PhysicsServer2D) method that returns a value unconditionally in a per-frame callback: the main thread waits for the physics thread every frame.",
           "Read state from the body or PhysicsDirectBodyState in _integrate_forces, cache values, or run physics on the main thread.",
           "Cached values can lag one physics step.", kind="performance", requires=("scene", "settings"), offender_key="check_frame_physics_3d_sync",
           printed="Call to body_get_state causing PhysicsServer3D synchronizations on every frame. This significantly affects performance.")
    warned("navigation.runtime_bake_visual_meshes", "navigation", "Navigation is baked at runtime from visual meshes",
           {"all": [_scene("navigation_runtime_bake"), _scene("navmesh_parses_meshes")]},
           "scene/resources/3d/navigation_mesh_source_geometry_data_3d.cpp", "Source geometry parsing for navigation mesh baking had to parse RenderingServer meshes at runtime.",
           "in a running game when a NavigationMesh parses mesh instances (parsed geometry type Mesh Instances, the default, or Both) and a script bakes or parses source geometry (bake_navigation_mesh or parse_source_geometry_data). Godot's message continues that visual meshes store their geometry on the GPU, so reading it back is slow.",
           "Parse static colliders instead (parsed geometry type Static Colliders), or bake in the editor and load the result.",
           "Collision shapes are coarser than visual meshes.", kind="performance", requires=("scene",), offender_key="check_navigation_runtime_bake")
    warned("scene_validation.modifier_axis_colinear", "scene_validation", "A joint rotation axis or pole direction is parallel to the bone",
           _scene("modifier_axis_colinear"),
           {"4.4": "scene/3d/spring_bone_simulator_3d.cpp"}, {"4.4": "Rotation axis and forward vectors are colinear.", "4.6": "Rotation axis and forward vector are colinear."},
           "when a SpringBoneSimulator3D or IterateIK3D joint's rotation axis is parallel to the direction to its child bone in the rest pose, or (4.6+) a TwoBoneIK3D pole direction is parallel to the middle bone's forward vector. Godot's message warns that it may cause unwanted rotation. Joints whose forward comes from an extended end bone are not inspected.",
           "Choose a rotation axis or pole direction perpendicular to the bone.", "None.", requires=("scene",), offender_key="check_modifier_axis_colinear",
           printed="Setting: 0 Joint: 0: Rotation axis and forward vector are colinear. This is not advised as it may cause unwanted rotation.")
    warned("scene_validation.instance_uniform_conflict", "scene_validation", "Materials on one instance declare the same instance uniform differently",
           _scene("instance_uniform_conflict"),
           "servers/rendering/instance_uniforms.cpp", "but they do it with different data types. Only the first one (in order) will display correctly.",
           "(or \"... with different indices ...\") when the material override (or the surface materials) and the overlay of a GeometryInstance3D declare an instance uniform with the same name but a different type or instance index; only the first declaration displays correctly. Shader #include files are not followed.",
           "Give the uniform the same type and instance_index in every shader on the instance, or rename one.",
           "None.", requires=("scene",), offender_key="check_instance_uniform_conflict",
           printed="More than one material in instance export the same instance shader uniform 'tint', but they do it with different data types. Only the first one (in order) will display correctly.")
    warned("ui.flow_fit_texture_rect", "ui", "A fit-mode TextureRect is inside a wrapping FlowContainer",
           _scene("flow_fit_texture_rect"),
           "scene/gui/flow_container.cpp", "TextureRects with Fit Expand Modes are currently not supported inside FlowContainers with multiple lines",
           "when a direct TextureRect child of a FlowContainer that has wrapped to more than one line uses a Fit Width or Fit Height expand mode; Godot stops sizing it to avoid a layout loop. Line count is known only for laid-out containers (running scenes).",
           "Use Ignore Size or Keep Size for TextureRects inside FlowContainers, or wrap them in a fixed-size container.",
           "None.", requires=("scene",), offender_key="check_flow_fit_texture_rect", severity="low")
    warned("xr.object_picking_stereo", "xr", "Physics object picking is expected in a stereo XR viewport",
           {"any": [_scene("xr_viewport_picking"),
                    {"all": [_scene("xr_pickable_listener"), _setting("eq", "xr/openxr/enabled", True), _setting("eq", "physics/common/enable_object_picking", True)]}]},
           "scene/main/viewport.cpp", "Object picking can't be used when stereo rendering, this will be turned off!",
           "once a stereo XR interface renders a viewport that has physics object picking on: a SubViewport with use_xr and physics_object_picking, or an OpenXR project whose root viewport picks (physics/common/enable_object_picking) while scene objects listen for input_event. Godot then turns picking off, so those listeners get no mouse or pointer events.",
           "Use XR pointer raycasts (RayCast3D or a pointer tool) for interaction, and turn object picking off for XR viewports.",
           "Pointer raycasts need their own interaction code.", requires=("scene", "settings"), offender_key="check_xr_pickable_listener")
    warned("xr.canvas_background_multiview", "xr", "An XR project uses a canvas environment background on Mobile",
           {"all": [_scene("env_bg_canvas"), _setting("eq", "xr/openxr/enabled", True)]},
           "servers/rendering/renderer_rd/forward_mobile/render_forward_mobile.cpp", "Canvas background is not supported in multiview!",
           "when an Environment uses background mode Canvas in an OpenXR project under the Mobile renderer; stereo (multiview) rendering cannot show the canvas behind the scene.",
           "Use a sky, color or passthrough background in XR.", "None.", renderers=["mobile"], requires=("scene", "settings"), offender_key="check_env_bg_canvas")
    warned("xr.foveation_subsampled_disabled", "xr", "Subsampled foveation is disabled by post-processing on Mobile",
           {"all": [_setting("eq", "xr/openxr/enabled", True), _setting("eq", "xr/openxr/foveation_with_subsampled_images", True),
                    {"any": [{"scene_gte": {"name": "env_glow", "value": 1}}, {"scene_gte": {"name": "dof_blur_enabled", "value": 1}}, _scene("auto_exposure"),
                             _scene("env_bg_canvas"), _scene("shader_screen_read"), _scene("compositor_transparent_callback"),
                             _setting("neq", "rendering/anti_aliasing/quality/screen_space_aa", 0), _setting("neq", "rendering/scaling_3d/scale", 1.0)]}]},
           "modules/openxr/openxr_api.cpp", "Foveation with subsampled images was enabled, but rendering features are in use that have forced it to be disabled.",
           "on headsets with the FB foveation extension when xr/openxr/foveation_with_subsampled_images is on (the default) and the Mobile renderer cannot finish post-processing in a subpass: glow, depth of field, auto-exposure, a canvas background, screen or depth texture reads (shaders, refraction, proximity fade), transparent-stage compositor effects, screen-space AA or a 3D scale other than 1 (render_forward_mobile.cpp).",
           "Remove those features from the XR view to keep subsampled foveation, or turn the setting off.",
           "Dropping glow or depth of field changes the look.", versions=["4.7"], renderers=["mobile"], requires=("scene", "settings"),
           setting="xr/openxr/foveation_with_subsampled_images")
    warned("scripts.deprecated_engine_call", "scripts", "A script calls a deprecated Godot API that does nothing",
           _scene("script_deprecated_call"),
           "servers/rendering/rendering_device.cpp", "Deprecated. Barriers are automatically inserted by RenderingDevice.",
           "when a script calls RenderingDevice.barrier() or full_barrier(), or draw_command_insert_label(); Godot also warns that RenderingServer.reflection_probe_set_resolution() is not available in Godot 4, that environment_set_ssr_roughness_quality() no longer does anything (4.6+), and that NavigationServer3D.region_bake_navigation_mesh() and NavigationMeshGenerator.bake() are deprecated. Calls in comments and strings are ignored.",
           "Remove the no-op calls; for navigation, parse source geometry and bake with NavigationServer3D.bake_from_source_geometry_data(); set reflection-probe size in the project settings.",
           "None for the no-op calls; the navigation replacement needs code changes.", requires=("scene",), offender_key="check_script_deprecated_call", severity="low")
    warned("scripts.draw_argument_ignored", "scripts", "A draw call passes an argument Godot ignores",
           _scene("script_draw_ignored"),
           "scene/main/canvas_item.cpp", "argument has no effect when",
           "when a script calls draw_rect() or draw_circle() with filled set to true and a literal width other than -1, or draw_polyline()/draw_multiline() with a literal negative width and antialiased set to true (thin line strips cannot be antialiased). Only literal arguments are judged.",
           "Drop the width for filled shapes, or draw an outline separately; use a positive width when antialiasing lines.",
           "A positive width draws triangle strips instead of thin lines.", requires=("scene",), offender_key="check_script_draw_ignored", severity="low",
           printed='The draw_rect() "width" argument has no effect when "filled" is "true".')
    warned("scripts.theme_in_init", "scripts", "A script reads theme items in _init",
           _scene("script_theme_in_init"),
           "scene/gui/control.cpp", "Attempting to access theme items too early in %s; prefer NOTIFICATION_POSTINITIALIZE and NOTIFICATION_THEME_CHANGED",
           "when a script's _init calls get_theme_* or has_theme_*; the Control (or Window) is not initialized yet, so the theme lookup has no owner theme or overrides.",
           "Read theme items in _notification for NOTIFICATION_THEME_CHANGED (or NOTIFICATION_POSTINITIALIZE), or in _ready.",
           "None.", requires=("scene",), offender_key="check_script_theme_in_init",
           printed="Attempting to access theme items too early in Control; prefer NOTIFICATION_POSTINITIALIZE and NOTIFICATION_THEME_CHANGED")
    warned("physics.jolt_server_call_ignored", "physics", "A script sets PhysicsServer3D parameters that Jolt Physics ignores",
           {"all": [_scene("script_jolt_server_call"), JOLT]},
           "modules/jolt_physics/spaces/jolt_space_3d.cpp", "is not supported when using Jolt Physics. Any such value will be ignored.",
           "when physics/3d/physics_engine is Jolt Physics and a script calls PhysicsServer3D.space_set_param() (every space parameter: contact recycle radius, max separation, max penetration, default bias, sleep thresholds, sleep time, solver iterations), body_set_user_flags() or body_set_contacts_reported_depth_threshold() with a non-default value.",
           "Use the physics/jolt_physics_3d project settings for the equivalent tuning, or drop the calls under Jolt.",
           "Jolt's settings are project-wide rather than per space or body.", requires=("scene", "settings"), offender_key="check_script_jolt_server_call",
           printed="Space-specific solver iterations is not supported when using Jolt Physics. Any such value will be ignored.")
    warned("scene_validation.emit_particle_compatibility", "scene_validation", "A script emits particles manually under Compatibility",
           _scene("script_emit_particle"),
           "drivers/gles3/storage/particles_storage.cpp", "The Compatibility renderer does not support manually emitting particles.",
           "when a script calls emit_particle() (GPUParticles2D/3D) and the renderer is Compatibility, which ignores manual emission.",
           "Use CPUParticles for script-driven emission under Compatibility, or a renderer with GPU particle emission.",
           "CPU particles cost CPU time per particle.", renderers=GL, requires=("scene",), offender_key="check_script_emit_particle")
    warned("scene_validation.ext_resource_uid_invalid", "scene_validation", "A text resource references a UID that no longer resolves",
           _scene("ext_resource_uid_invalid"),
           "scene/resources/resource_format_text.cpp", "ext_resource, invalid UID: ",
           "when a .tscn or .tres ext_resource carries a uid:// that is not in the UID cache and does not belong to the file at its path (the editor-build test in resource_format_text.cpp); a UID matching the path's .uid sidecar counts as valid, so C# scripts are not reported by an editor without .NET. Godot falls back to the text path, which breaks when the file is moved again or exported without it.",
           "Open and re-save the scene or resource in the editor so the ext_resource gets the file's current UID.",
           "None.", requires=("scene",), offender_key="check_ext_resource_uid_invalid",
           printed="res://level.tscn:3 - ext_resource, invalid UID: uid://b1example - using text path instead: res://art/hero.png")
    warned("materials.shader_param_old_names", "materials", "A ShaderMaterial is saved with pre-4.0 parameter names",
           _scene("shader_param_old_names"),
           "scene/resources/material.cpp", "uses an old deprecated parameter names. Consider re-saving this resource",
           "when a saved ShaderMaterial (in a .tscn or .tres) stores parameters as shader_param/, param/ or shader_uniform/ instead of shader_parameter/; Godot renames them on every load.",
           "Open and re-save the resource or scene so the parameters are stored as shader_parameter/.",
           "None.", requires=("scene",), offender_key="check_shader_param_old_names", severity="low",
           printed="This material (containing shader with path: 'res://water.gdshader') uses an old deprecated parameter names. Consider re-saving this resource (or scene which contains it) in order for it to continue working in future versions.")
    warned("geometry.mesh_old_surface_format", "geometry", "A saved mesh uses an old surface format that is upgraded on every load",
           _scene("mesh_old_surface_format"),
           {"4.4": "servers/rendering_server.cpp", "4.6": "servers/rendering/rendering_server.cpp"}, "uses an old surface format and needs to be upgraded.",
           "when an ArrayMesh saved in a .tscn or .tres has a surface format without the current format version (bits 35-42, ARRAY_FLAG_FORMAT_VERSION). Godot's message continues that the upgrade happens automatically at load time every time until the mesh is saved again or re-imported. Binary .res/.mesh files are not read.",
           "Re-save the scene or resource (or re-import the source model) in the current Godot version.",
           "Re-saved meshes cannot be opened by Godot versions before 4.2.", kind="performance", requires=("scene",), offender_key="check_mesh_old_surface_format",
           printed="A surface of res://props/crate.tres uses an old surface format and needs to be upgraded.")
    warned("scene_validation.animation_expression_base", "scene_validation", "State-machine transition expressions have no base node",
           _scene("animation_expression_base"),
           "scene/animation/animation_node_state_machine.cpp", "Animation transition has a valid expression, but no expression base node was set on its AnimationTree.",
           "when an AnimationTree's advance_expression_base_node does not resolve and its state machine (or a nested one, four levels deep) has a transition with an advance expression; the expression is never evaluated, so the transition never fires by expression.",
           "Point advance_expression_base_node at the node whose properties the expressions read (the default \".\" is the AnimationTree).",
           "None.", requires=("scene",), offender_key="check_animation_expression_base")
    warned("scene_validation.modifier_bone_missing", "scene_validation", "A skeleton modifier names a bone its skeleton does not have",
           _scene("modifier_bone_missing"),
           {"4.4": "scene/3d/spring_bone_simulator_3d.cpp"}, {"4.4": "Root bone index out of range!", "4.7": "Root bone index '"},
           "(4.4 to 4.6: \"Root bone index out of range!\") when a SkeletonModifier3D setting stores a bone name the parent Skeleton3D lacks, or a bone index past its bone count. Godot re-resolves stored bones whenever the modifier enters the skeleton; the setting then skips that bone. Covers spring bones, IK, bone constraints, twist dispersers, angular-velocity limits, bone targets and look-at origins.",
           "Pick an existing bone in the inspector, or update the bone names after renaming bones or replacing the skeleton.",
           "None.", requires=("scene",), offender_key="check_modifier_bone_missing", printed="Setting: 0: Root bone index '-1' is out of range!")
    warned("scene_validation.animation_track_unresolved", "scene_validation", "An animation track's node path does not resolve",
           _scene("animation_track_unresolved"),
           "scene/animation/animation_mixer.cpp", "couldn't resolve track:",
           "for every enabled track whose node path does not resolve from the AnimationPlayer or AnimationTree root_node, when animation/warnings/check_invalid_track_paths is on (the default). The track animates nothing.",
           "Retarget the track to the renamed or moved node, delete the stale track, or disable it.",
           "None.", requires=("scene",), offender_key="check_animation_track_unresolved",
           printed="AnimationPlayer: 'walk', couldn't resolve track:  'Renamed:visible'. This warning can be disabled in Project Settings.")
