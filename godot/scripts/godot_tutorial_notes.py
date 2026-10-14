"""Classify every godot-docs tutorial paragraph that mentions a performance cost.

Usage: python scripts/godot_tutorial_notes.py <godot-docs 4.4> <4.5> <4.6> <4.7 checkout>
Writes docs/GODOT_TUTORIAL_NOTES.json and fails on any unclassified or stale entry.
"""

import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from godot_perf_notes import KEYWORDS  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
BRANCHES = ("4.4", "4.5", "4.6", "4.7")
SCOPES = ("tutorials",)
PROSE_DIRECTIVES = {"note", "tip", "warning", "important", "seealso", "caution", "danger", "attention", "hint"}
UNDERLINE = re.compile(r"^([=\-~^\"'`#*+])\1{2,}\s*$")


def _inline(text):
    text = re.sub(r":[a-z]+:`([^`<]*?)\s*<[^`>]*>`", r"\1", text)
    text = re.sub(r":[a-z]+:`~?([^`]*)`", r"\1", text)
    text = re.sub(r"`([^`<]*?)\s*<[^`>]*>`__?", r"\1", text)
    text = re.sub(r"``([^`]*)``", r"\1", text)
    text = re.sub(r"\*\*([^*]+)\*\*|\*([^*]+)\*", lambda m: m.group(1) or m.group(2), text)
    text = re.sub(r"`([^`]*)`_?", r"\1", text)
    return " ".join(text.split())


def paragraphs(path):
    """(section title, prose paragraph) pairs; code, images, tables, options and headings are dropped."""
    lines = path.read_text(encoding="utf-8").splitlines()
    out, current, section, skip_indent = [], [], "", None
    def flush():
        if current:
            out.append((section, _inline(" ".join(current))))
            current.clear()
    for index, line in enumerate(lines):
        stripped = line.strip()
        indent = len(line) - len(line.lstrip())
        if skip_indent is not None:
            if not stripped or indent > skip_indent:
                continue
            skip_indent = None
        if not stripped:
            flush()
            continue
        if UNDERLINE.match(stripped):
            if current and index > 0 and lines[index - 1].strip() == current[-1].strip():
                section = _inline(current.pop())
            flush()
            continue
        directive = re.match(r"\.\.\s+([\w-]+)::", stripped)
        if directive or stripped.startswith(".. "):
            flush()
            if not (directive and directive.group(1) in PROSE_DIRECTIVES):
                skip_indent = indent
            elif stripped[directive.end():].strip():
                current.append(stripped[directive.end():].strip())
            continue
        if re.match(r"^:[\w -]+:(\s|$)", stripped) or stripped.startswith(("|", "+--", "+==")):
            continue
        current.append(stripped[:-1] if stripped.endswith("::") and not stripped.endswith(" ::") else stripped.rstrip(":") if stripped.endswith(" ::") else stripped)
        if stripped.endswith("::"):
            flush()
            skip_indent = indent
    flush()
    return out


def extract(checkout):
    found = {}
    base = Path(checkout)
    for scope in SCOPES:
        for path in sorted((base / scope).rglob("*.rst")):
            page = path.relative_to(base).with_suffix("").as_posix()
            for section, text in paragraphs(path):
                if KEYWORDS.search(text):
                    key = "%s: %s" % (page, " ".join(text.split()[:8]))
                    found.setdefault(key, (section, text))
    return found


METHOD = "notcost:Profiling, measurement or optimization-process guidance; Render Lens's measurement tools (frame timing, GPU passes, script profiles) implement it rather than a configuration rule."
CONCEPT = "notcost:Explains a concept, renderer behaviour or trade-off; it names no configuration to check."
SCRIPT = "exclude:Advice about script algorithms, data layout, threading or language choice; its cost cannot be told from source text, and measured script time is reported by cpu.process_time and scripts.profile_top_self."
PER_INSTANCE = "exclude:Per-frame MultiMesh instance updates from scripts run in loops, which the per-frame text scan deliberately skips; their cost depends on instance counts that cannot be told from source text."
ENV_OS = "exclude:Operating-system, compositor or window-manager behaviour outside the project; Render Lens reports the resulting frame pacing, not its cause."
ENV_DRIVER = "exclude:A graphics-driver control-panel setting outside the project."
ENV_VRR = "exclude:Advice for variable-refresh-rate monitors; whether the player's display supports VRR is a property of their hardware, outside the project."
BASE_SIZE = "exclude:Asset resolution and base window size are art-direction choices; the stated memory and file-size cost follows from the assets, which texture-memory measurements report."
DEFAULT_T = "exclude:Describes the cost of a default or of a quality trade-off; flagging it would add noise without a measured symptom."
BAKE_T = "exclude:Bake, import or editor time and file size only; it does not affect the running game's frames or memory."
NO_COST_T = "notcost:The paragraph states the option has no or minimal performance cost."
FILL_LIGHT = "exclude:Which lights are secondary fill lights cannot be told from scene data; shadow-casting light counts are covered by shadows.omni_shadow_count and shadows.spot_shadow_count."
CAMERA_SPEED = "exclude:Camera speed is runtime behaviour that cannot be told from scene data; measured GI pass costs are reported by the GPU-pass rules."
RUNTIME_TEXTURE = "exclude:Changing a light's texture at runtime is script behaviour whose frequency cannot be told from source text."
SIMPLER_MATERIALS = "exclude:Choosing simpler materials for distant LOD meshes is an art decision; which materials could be simplified cannot be told from scene data."
MOTION_T = "notcost:The keyword describes motion, animation speed or smoothness, not a performance cost."
MOVIE = "exclude:Movie Maker recording is an offline workflow outside the project's running game; its encoding settings do not affect gameplay frames."
WEB = "exclude:Web-only audio playback-mode behaviour (Sample is Godot's default there); the platform choice is outside the project's scene data."
GLYPHS = "exclude:Which glyphs a game shows, and so which to prerender, cannot be told from scene data; first-use rasterization stutter appears in frame-spike measurements."
NAV_LAYERS = "exclude:Toggling navigation layers on regions at runtime is script behaviour whose frequency cannot be told from source text."
PATH_COST_T = "notcost:\"Cost\" is a navigation path weight, not a performance cost."
SHADER_AUTHORING = "exclude:Shader-authoring micro-optimization (branches, constants, precision); its effect depends on the GPU and cannot be told from source text without compiling for the target."
EDITOR_T = "exclude:Editor, project-manager, plugin or editor-platform behaviour outside the project's running game."
DELTA_T = "notcost:Explains delta time and frame-rate independence; no cost is stated."
EXPORT_T ="exclude:An export or build-template option; export presets and custom templates are outside the scan, and Render Lens measures the running game."
MATERIAL_REUSE = "rule:materials.shader_material_copies,stutter.draw_calls_high"
TRANSPARENCY = "rule:materials.alpha_blend,geometry.transparent_pass_share"
# Page default, then (paragraph prefix, classification) overrides; a prefix must match the start of the paragraph text.
PAGES = {
    "tutorials/performance/cpu_optimization": (METHOD, [
        ("- Try using simplified versions", "rule:physics.concave_shape,cpu.active_bodies"),
        ("Although Nodes are an incredibly", "rule:memory.node_count,scripts.node_count_high,scripts.many_process"),
        ("Built-in engine functions run", SCRIPT),
        ("Each node is handled individually", "rule:geometry.multimesh_candidate,memory.node_count"),
        ("GDScript is designed", SCRIPT),
        ("Godot supports a number of different languages", SCRIPT),
        ("In some situations, physics can end up", "rule:cpu.physics_time,cpu.active_bodies,physics.active_bodies_2d"),
        ("One quirk of the SceneTree", "exclude:Whether detaching nodes beats hiding them depends on how often they return, which cannot be told from scene data; processing node counts are reported by scripts.many_process."),
        ("The solution to jitter", "rule:cpu.physics_ticks"),
    ]),
    "tutorials/performance/general_optimization": (METHOD, [
        ("As with design, you should concentrate", SCRIPT),
        ("Once algorithms and data are good", SCRIPT),
    ]),
    "tutorials/performance/gpu_optimization": (CONCEPT, [
        ("- Reusing Materials", MATERIAL_REUSE),
        ("Additionally, tile-based rendering struggles", "rule:gpu_best_practices.tile_small_meshes,geometry.primitive_density"),
        ("By default, Godot compresses textures", "rule:textures.vram_uncompressed,import.texture_uncompressed,textures.lossless_3d"),
        ("Even in 3D, \"pixel art\" textures", "notcost:A quality recommendation (no VRAM compression for low-resolution pixel art); it says compression would not improve performance."),
        ("Godot sends instructions to the GPU", "rule:stutter.draw_calls_high,canvas.draw_calls"),
        ("If a scene has, for example, 20,000 objects", MATERIAL_REUSE),
        ("In 2D, the costs of treating each item", "rule:canvas.draw_calls,canvas.item_buffer,renderer.gl_item_buffer_raised"),
        ("In 3D, we still aim to minimize draw calls", "rule:stutter.draw_calls_high,geometry.multimesh_candidate"),
        ("In contrast to vertex processing", "rule:resolution.full_scale_gpu_over_budget,resolution.scale_above_one"),
        ("Nearly every API command in OpenGL", "rule:stutter.draw_calls_high,canvas.draw_calls"),
        ("On supported hardware", "rule:renderer.vrs_off_while_gpu_bound"),
        ("Post-processing effects and shadows", "rule:post.ssao_enabled,post.ssr_enabled,post.glow_enabled,post.volumetric_fog,pass.shadows"),
        ("Reducing the size of shadowmaps", "rule:shadows.directional_size_above_default,shadows.positional_atlas_above_default,shadows.omni_shadow_count,shadows.spot_shadow_count"),
        ("The other factor in fragment shaders", "rule:textures.anisotropy_16x,gpu_best_practices.arm_anisotropic_materials"),
        ("There are some downsides though", "rule:gpu_best_practices.tile_keep_viewport,canvas.backbuffer_full"),
        ("To be more efficient, mobile GPUs", "rule:renderer.depth_prepass_disabled,materials.alpha_blend"),
        ("Transparency is particularly expensive", TRANSPARENCY),
        ("Transparent objects are also particularly bad", TRANSPARENCY),
        ("Understanding and investigating GPU bottlenecks", METHOD),
        ("Using more power is not an option on mobile", "rule:gpu_best_practices.tile_small_meshes"),
        ("You can increase performance in a fill rate-limited", "rule:materials.per_pixel_particles,resolution.full_scale_gpu_over_budget"),
        ("You can test whether a project is fill", METHOD),
    ]),
    "tutorials/performance/index": (CONCEPT, []),
    "tutorials/performance/optimizing_3d_performance": (CONCEPT, [
        ("Animation and vertex animation", "rule:geometry.skin_eight_weights,cpu.skin_dynamic_bounds"),
        ("Godot sorts objects by Material", TRANSPARENCY),
        ("If several identical objects", "rule:geometry.multimesh_candidate"),
        ("If you have many identical objects", "notcost:Describes automatic instancing, which needs no setup."),
        ("In some cases, you may have to adapt", "exclude:Level-design advice (more walls for occlusion); whether a level could hide more cannot be told from scene data."),
        ("Lighting objects is one of the most costly", "rule:lights.many_realtime,pass.shadows,gi.sdfgi_enabled"),
        ("See doc_using_lightmap_gi", "rule:lights.positional_light_dynamic_bake"),
        ("The downside of lights with the Static", "rule:lights.positional_light_dynamic_bake"),
        ("The simplest version of using transparency", "rule:geometry.transparent_pass_share"),
        ("Things aren't quite as bad", "rule:renderer.depth_prepass_disabled,geometry.occlusion_without_occluders"),
    ]),
    "tutorials/performance/pipeline_compilations": (CONCEPT, [
        ("- Canvas: Compiled", "rule:stutter.compilations_canvas,stutter.compilations_mesh,stutter.compilations_surface,stutter.compilations_draw,stutter.compilations_specialization"),
        ("Pipeline compilation, also commonly known", "rule:stutter.compilations_draw,stutter.pipeline_cache_off,stutter.shader_cache_off"),
        ("Since Godot 4.5, you can choose to bake", "exclude:An export option for first-launch loading time (shader baker); export presets are outside the scan, and Render Lens measures frames in the running game."),
        ("The Godot debugger offers monitors", "rule:stutter.compilations_draw,stutter.compilations_surface"),
    ]),
    "tutorials/performance/thread_safe_apis": (None, [
        ("You should avoid calling functions", "exclude:Which thread a script call runs on cannot be told from source text."),
    ]),
    "tutorials/performance/using_multiple_threads": (SCRIPT, []),
    "tutorials/performance/using_servers": (CONCEPT, [
        ("Try to never request any information", "rule:scripts.frame_global_shader_get,scripts.frame_multimesh_buffer,scripts.frame_force_sync"),
    ]),
    "tutorials/performance/vertex_animation/animating_thousands_of_fish": (None, [
        ("For both color_format and custom_data_format", "exclude:Describes Godot 3 MultiMesh properties (color_format, custom_data_format); the 4.4 and 4.7 MultiMesh only has the use_colors and use_custom_data booleans, so there is no format to check."),
        ("If performance is an issue for you", CONCEPT),
        ("Now the fish all have unique positions", "notcost:\"Faster\" refers to swimming speed."),
        ("One problem that you will run into", PER_INSTANCE),
    ]),
    "tutorials/performance/vertex_animation/controlling_thousands_of_fish": (None, [
        ("The problem with MeshInstance3D", PER_INSTANCE),
    ]),
    "tutorials/3d/3d_antialiasing": (CONCEPT, [
        ("Combine it with TAA, or even FSR2", "rule:antialiasing.smaa_enabled,antialiasing.taa_enabled"),
        ("Fast approximate antialiasing is a post-processing", "rule:antialiasing.fxaa_enabled"),
        ("However, unlike FSR1, FSR2 also provides", "rule:resolution.fsr2_native_over_budget"),
        ("If you are using a high window size", "rule:resolution.scale_above_one"),
        ("MSAA is available in 3 levels", "rule:antialiasing.msaa_4x,antialiasing.msaa_8x"),
        ("Since Godot 4.2, there is built-in support for", "rule:resolution.fsr2_enabled"),
        ("Since this processing occurs purely on import", NO_COST_T),
        ("Sub-pixel Morphological Antialiasing is a post-processing", "rule:antialiasing.smaa_enabled"),
        ("Supersampling provides the highest quality", "rule:resolution.scale_above_one,resolution.viewport_supersampling"),
        ("The downside of SSAA is its extremely high", "rule:resolution.scale_above_one,resolution.viewport_supersampling"),
        ("The screen-space roughness limiter is enabled by default", DEFAULT_T),
        ("To mitigate aliasing on alpha scissor materials", "rule:materials.material_alpha_to_coverage"),
        ("Using FSR2 at native resolution is more demanding", "rule:resolution.fsr2_native_over_budget"),
    ]),
    "tutorials/3d/3d_rendering_limitations": (CONCEPT, [
        ("- If you need to render semi-transparent areas", "rule:materials.depth_prepass_transparency"),
        ("- If your texture mostly has fully opaque", "rule:materials.alpha_blend"),
        ("- Only make materials transparent if you actually", "rule:materials.alpha_blend"),
    ]),
    "tutorials/3d/3d_text": (CONCEPT, [
        ("- Label3D is faster to generate than TextMesh", "rule:geometry.textmesh_detail"),
        ("This can be mitigated by setting the Label3D's", "rule:canvas.sprite_opaque_prepass"),
    ]),
    "tutorials/3d/csg_tools": (CONCEPT, [
        ("- Bake lightmaps, since UV2 can be generated", "rule:cpu.csg_composition"),
        ("Godot's doc_standard_material_3d supports triplanar mapping", "rule:materials.material_triplanar_uv1"),
        ("In the interest of performance, make sure CSG", "rule:cpu.csg_composition"),
        ("The default lighting of the environment", "notcost:Mentions the editor's overdraw display mode."),
    ]),
    "tutorials/3d/environment_and_post_processing": (CONCEPT, [
        ("- AGX Contrast", NO_COST_T),
        ("- Background: Reflect from the background", DEFAULT_T),
        ("- Clear Color uses the default clear color", "rule:sky.background_keep"),
        ("- If you want to maximize performance, you", "rule:canvas.hdr_2d"),
        ("- Linear: Does not modify color data", DEFAULT_T),
        ("- Max Steps: Determines the", "rule:post.ssr_steps"),
        ("- Quality: Sets the quality of the screen-space", "rule:post.ssao_quality_high,post.ssao_full_res"),
        ("- Radius: The distance at which objects can", "rule:post.ssao_large_radius"),
        ("- Since Godot 4.2, you can enable HDR", "rule:canvas.hdr_2d"),
        ("A 3D look-up-texture (LUT) can also be used", "rule:post.color_correction_lut_large"),
        ("Additionally, you can adjust the quality of SSR", "rule:post.ssr_half_size_off"),
        ("Auto exposure needs to evaluate", "rule:post.auto_exposure"),
        ("By default, glow uses a bicubic scaling filter", "rule:post.glow_bicubic,post.glow_upscale_mobile"),
        ("In general, you should only rely on ambient", DEFAULT_T),
        ("This feature only provides indirect lighting", "rule:gi.ssil_enabled"),
        ("Tonemap selects the tonemapping algorithm", DEFAULT_T),
    ]),
    "tutorials/3d/global_illumination/faking_global_illumination": (CONCEPT, [
        ("- Increase the light's Range by 25-50%", FILL_LIGHT),
        ("- Rotate the light by 180 degrees", FILL_LIGHT),
    ]),
    "tutorials/3d/global_illumination/introduction_to_global_illumination": (CONCEPT, [
        ("- By default, reflections update when the probe", "rule:gi.probe_always"),
        ("- For desktop games, it's a good idea", "rule:gi.sdfgi_enabled"),
        ("- For static level lighting, use the Static", "exclude:Which lights are short-lived effects (weapon flashes) cannot be told from scene data; dynamic GI costs are covered by gi.gi_dynamic."),
        ("- Lights can be baked with indirect lighting", "rule:lights.positional_light_dynamic_bake,gi.lightmap_directional"),
        ("- Performance. Real-time GI techniques", "rule:gi.sdfgi_enabled,gi.voxel_count"),
        ("- ReflectionProbes with their update mode", "rule:gi.probe_always"),
        ("- The SSIL quality and number of blur", "rule:post.ssil_quality_high,post.ssil_full_res,post.ssil_blur_passes"),
        ("- The bake's number of subdivisions", "rule:gi.voxel_subdiv,gi.half_resolution_off"),
        ("- The number of cascades can be adjusted", "rule:gi.sdfgi_cascades,gi.sdfgi_probe_rays,gi.half_resolution_off"),
        ("Leaks can be reduced significantly by enabling", "rule:gi.sdfgi_occlusion"),
        ("To provide more accurate ambient occlusion", "rule:post.ssao_enabled"),
        ("To provide more accurate reflections", "rule:post.ssr_enabled"),
    ]),
    "tutorials/3d/global_illumination/reflection_probes": (CONCEPT, [
        ("- Update Mode: Controls when the reflection probe", "rule:gi.probe_always"),
        ("To make several ReflectionProbes blend", "exclude:The overlap needed for blending is scene-specific (\"a few units\"); no threshold separates intended blending from waste, so overlap is not flagged."),
        ("When using the Forward+ renderer, Godot uses a", "rule:renderer.cluster_elements_scene"),
    ]),
    "tutorials/3d/global_illumination/using_lightmap_gi": (BAKE_T, [
        ("- None (default): Don't bake a shadowmask", CONCEPT),
        ("Baked lightmaps are a workflow", "rule:lights.no_lightmap_with_many_lights"),
        ("Both indirect and direct lighting will be baked", "rule:lights.positional_light_dynamic_bake"),
        ("Despite their lack of flexibility", "rule:lights.no_lightmap_with_many_lights"),
        ("Fully baked lights can also make use of", "rule:shadows.light_size_soft"),
        ("Since bake modes can be adjusted on a", "rule:lights.positional_light_dynamic_bake"),
        ("The Data > Light Data property", "rule:gi.lightmap_data_embedded"),
        ("This is the default mode, and is a", "rule:lights.positional_light_dynamic_bake"),
    ]),
    "tutorials/3d/global_illumination/using_sdfgi": (CONCEPT, [
        ("- Ensuring the camera doesn't move too fast", CAMERA_SPEED),
        ("- Sdfgi > Probe Ray Count", "rule:gi.sdfgi_probe_rays,gi.sdfgi_frames_to_converge"),
        ("- Use Occlusion: If enabled, SDFGI", "rule:gi.sdfgi_occlusion"),
        ("Additionally, performance will suffer if the camera", CAMERA_SPEED),
        ("From a performance standpoint, SDFGI is one of", "rule:gi.sdfgi_enabled"),
        ("SDFGI rendering performance also depends on", "rule:gi.sdfgi_cascades,gi.sdfgi_small_cells"),
        ("Since SDFGI is relatively demanding", "rule:gi.sdfgi_enabled"),
    ]),
    "tutorials/3d/global_illumination/using_voxel_gi": (CONCEPT, [
        ("- Disabled: The mesh won't be taken into", "rule:gi.gi_dynamic"),
        ("- Dynamic Range: The maximum brightness", "notcost:A precision trade-off; no performance cost is stated."),
        ("- Subdiv: Higher values result in more precise", "rule:gi.voxel_subdiv"),
        ("- Voxel Gi > Quality", "rule:gi.voxel_quality_high,gi.half_resolution_off"),
        ("Additionally, for performance reasons, Godot can only blend", "rule:gi.voxel_count"),
        ("For meshes with the Static bake mode", "rule:gi.gi_dynamic"),
        ("Since VoxelGI is relatively demanding", "rule:gi.voxel_count"),
        ("VoxelGI is a form of fully real-time", "rule:gi.voxel_count"),
    ]),
    "tutorials/2d/2d_antialiasing": (CONCEPT, [
        ("The downside of these antialiasing methods", "exclude:Antialiased geometry regenerated every frame is script behaviour whose frequency cannot be told from source text."),
        ("These methods do not require MSAA", NO_COST_T),
        ("This is the recommended method", "rule:antialiasing.msaa_2d_high"),
    ]),
    "tutorials/2d/2d_lights_and_shadows": (CONCEPT, [
        ("- Color: The color of shaded areas", "rule:canvas.pcf13"),
        ("- SDF Collision: If enabled", NO_COST_T),
        ("Additive sprites are much faster to render", "rule:canvas.many_shadow_lights"),
        ("If you run into performance issues when using", "rule:canvas.many_shadow_lights"),
    ]),
    "tutorials/2d/2d_meshes": ("rule:materials.parallax_layers", []),
    "tutorials/2d/2d_parallax": (MOTION_T, []),
    "tutorials/2d/2d_sprite_animation": (MOTION_T, []),
    "tutorials/2d/canvas_layers": (CONCEPT, []),
    "tutorials/2d/custom_drawing_in_2d": (CONCEPT, [
        ("Feel free to play with the parameters", "exclude:The segment count passed to draw_arc is script data whose cost cannot be told from source text."),
        ("For custom drawing methods that don't provide", "rule:antialiasing.msaa_2d_high"),
        ("Note that if multiple unconnected lines", "rule:scripts.draw_line_loop"),
    ]),
    "tutorials/2d/particle_process_material_2d": (MOTION_T, []),
    "tutorials/2d/particle_systems_2d": (MOTION_T, [
        ("Godot provides two different nodes for 2D", "rule:particles.cpu_nodes"),
        ("This setting can be used to set the", "rule:particles.fixed_fps_high"),
    ]),
    "tutorials/2d/using_tilemaps": (CONCEPT, [
        ("TileMap built-in navigation has many", "rule:navigation.tilemap_navigation_regions"),
    ]),
    "tutorials/2d/using_tilesets": (CONCEPT, [
        ("Scene tiles come with a greater performance", "rule:canvas.tilemap_scene_tiles"),
        ("There are two ways to assign properties", "notcost:Editor workflow speed, not a runtime cost."),
    ]),
    "tutorials/animation/2d_skeletons": (CONCEPT, []),
    "tutorials/animation/creating_movies": (MOVIE, [
        ("For 3D rendering, Godot provides a Rendering >", "rule:resolution.scale_above_one"),
    ]),
    "tutorials/animation/cutout_animation": ("notcost:Editor workflow speed, not a runtime cost.", []),
    "tutorials/animation/introduction": (MOTION_T, []),
    "tutorials/animation/playing_videos": (CONCEPT, []),
    "tutorials/audio/audio_buses": (CONCEPT, [
        ("This feature is not supported on the web", WEB),
    ]),
    "tutorials/audio/audio_effects": (CONCEPT, []),
    "tutorials/audio/audio_streams": (WEB, []),
    "tutorials/ui/bbcode_in_richtextlabel": ("rule:ui.richtext_sync", [
        ("If you don't want to use BBCode for", SCRIPT),
        ("freq controls the frequency", MOTION_T),
    ]),
    "tutorials/ui/creating_applications": (CONCEPT, [
        ("- The maximum framerate at which the application", "rule:pacing.low_processor,cpu.low_processor_sleep_short"),
        ("- Use the Compatibility renderer if you don't", "rule:renderer.compatibility_method"),
    ]),
    "tutorials/ui/gui_using_fonts": (CONCEPT, [
        ("- Higher baseline cost for font rendering", "rule:ui.default_font_msdf_off,ui.font_msdf_size"),
        ("- The font will always look crisp", CONCEPT),
        ("By default, fonts do not have mipmaps", "rule:ui.font_mipmaps_on,ui.font_local_mipmaps"),
        ("Subpixel positioning can be adjusted", "rule:ui.font_subpixel_large"),
        ("The second method requires less configuration", GLYPHS),
        ("To avoid stuttering issues related to font", GLYPHS),
        ("When using MSDF fonts, they only need to", "rule:ui.font_msdf_size"),
        ("When using traditional rasterized fonts", GLYPHS),
        ("You can force the subpixel positioning mode", "rule:ui.font_subpixel_large"),
    ]),
    "tutorials/navigation/navigation_debug_tools": ("rule:cpu.navigation_time", [
        ("Navigation Process does NOT include pathfinding", CONCEPT),
        ("Navigation statistics help with identifying", "rule:navigation.navigation_polygons"),
        ("Navigation statistics shown here can not be judged", CONCEPT),
    ]),
    "tutorials/navigation/navigation_different_actor_area_access": (NAV_LAYERS, []),
    "tutorials/navigation/navigation_introduction_2d": (PATH_COST_T, []),
    "tutorials/navigation/navigation_introduction_3d": (PATH_COST_T, []),
    "tutorials/navigation/navigation_optimizing_performance": ("rule:navigation.navigation_polygons", [
        ("- Performance problems with parsing scene tree", CONCEPT),
        ("Baking navigation meshes at runtime should always", "exclude:Runtime navigation-mesh baking is started by scripts; whether it runs on a background thread cannot be told from scene data."),
        ("Change the SamplePartitionType from watershed", BAKE_T),
        ("Common Navigation related performance problems", CONCEPT),
        ("Complexity of source geometry data parsed", BAKE_T),
        ("Do not check beforehand if a target position", "rule:scripts.frame_navigation_reachable"),
        ("Logical errors and wasteful operations", SCRIPT),
        ("Prefer using simple physics collision shapes", BAKE_T),
        ("When changes are made to e.g. navigation meshes", "rule:navigation.navigation_polygons,navigation.sync_on_main_thread"),
    ]),
    "tutorials/navigation/navigation_using_navigationagents": (CONCEPT, []),
    "tutorials/navigation/navigation_using_navigationlayers": (NAV_LAYERS, []),
    "tutorials/navigation/navigation_using_navigationmeshes": (CONCEPT, [
        ("- parse_source_geometry_data() can be used", "rule:scripts.frame_navigation_parse"),
        ("The common source for performance issues at runtime", "rule:scripts.frame_navigation_parse,navigation.tilemap_navigation_regions"),
        ("To improve performance, use more optimized shapes", BAKE_T),
    ]),
    "tutorials/navigation/navigation_using_navigationobstacles": (CONCEPT, [
        ("- Dynamic obstacles act as a soft", NO_COST_T),
        ("Avoidance is enabled by default", "rule:navigation.avoidance"),
        ("While both static and dynamic properties", "rule:navigation.obstacle_static_and_dynamic"),
    ]),
    "tutorials/navigation/navigation_using_navigationpathqueryobjects": (SCRIPT, []),
    "tutorials/navigation/navigation_using_navigationservers": (CONCEPT, []),
    "tutorials/physics/collision_shapes_2d": (CONCEPT, [
        ("- Simplification: Higher values will result", BAKE_T),
        ("Depending on the object's complexity, you may get", "rule:physics.concave_shape,physics.body_many_shapes"),
        ("If you have an image with many small", BAKE_T),
        ("We recommend favoring primitive shapes", "rule:physics.concave_shape"),
        ("When using a single non-transformed collision shape", "rule:physics.body_many_shapes"),
        ("You aren't limited to a single collision shape", "rule:physics.body_many_shapes"),
    ]),
    "tutorials/physics/collision_shapes_3d": (CONCEPT, [
        ("- Create Multiple Convex Collision Siblings", "rule:physics.body_many_shapes"),
        ("- Create Single Convex Collision Sibling", "rule:physics.body_many_shapes"),
        ("Depending on the object's complexity, you may get", "rule:physics.concave_shape,physics.body_many_shapes"),
        ("We recommend favoring primitive shapes", "rule:physics.concave_shape"),
        ("When not using GridMaps for level design", "rule:physics.concave_shape"),
        ("When using a single non-transformed collision shape", "rule:physics.body_many_shapes"),
        ("You aren't limited to a single collision shape", "rule:physics.body_many_shapes"),
    ]),
    "tutorials/physics/interpolation/advanced_physics_interpolation": (None, [
        ("get_global_transform_interpolated() should only", "exclude:Calling it every frame from a camera is the intended use, and the page gives no count; how many call sites are too many cannot be told from source text."),
    ]),
    "tutorials/physics/interpolation/physics_interpolation_introduction": (CONCEPT, []),
    "tutorials/physics/interpolation/using_physics_interpolation": (CONCEPT, []),
    "tutorials/physics/kinematic_character_2d": (CONCEPT, []),
    "tutorials/physics/large_world_coordinates": ("exclude:Large world coordinates are an engine build option (precision=double), outside the project's settings and scenes.", [
        ("- 2D games, as precision issues", CONCEPT),
        ("To avoid model snapping issues when far away", CONCEPT),
    ]),
    "tutorials/physics/physics_introduction": (CONCEPT, [
        ("When a rigid body goes to sleep", "rule:physics.rigid_sleep_disabled"),
    ]),
    "tutorials/physics/ragdoll_system": ("exclude:Which physical bones are too small or are utility bones cannot be told reliably from scene data.", [
        ("- Hide PhysicalBone3D nodes you aren't", "notcost:Editor workflow, not a runtime cost."),
    ]),
    "tutorials/physics/soft_body": ("rule:physics.soft_body,physics.softbody_precision", [
        ("Additionally, physics interpolation currently does not", "rule:cpu.physics_ticks"),
        ("To assign the properties faster", "notcost:Editor workflow, not a runtime cost."),
    ]),
    "tutorials/physics/troubleshooting_physics_issues": (CONCEPT, [
        ("In 3D, switching the physics engine from the default", "rule:cpu.physics_time"),
        ("In Godot 4.5 and later, creating a composite", "rule:physics.tilemap_physics_chunking"),
        ("In some cases, replacing a convex collider", "rule:physics.body_many_shapes"),
        ("This is likely due to one of the", "rule:physics.body_many_shapes"),
        ("This issue can also occur with StaticBodies", "rule:physics.concave_shape"),
        ("This occurs because the physics engine can't keep", "rule:cpu.max_physics_steps"),
        ("Using a composite collider can also improve", "rule:physics.tilemap_physics_chunking"),
    ]),
    "tutorials/physics/using_jolt_physics": (CONCEPT, [
        ("When using Jolt, a class_RigidBody3D frozen", "rule:cpu.jolt_kinematic_contacts"),
        ("When using Jolt, class_Area3D will not detect", "rule:physics.areas_detect_static"),
    ]),
    "tutorials/platform/consoles": ("notcost:Publishing process, not a runtime cost.", []),
    "tutorials/shaders/compute_shaders": (CONCEPT, []),
    "tutorials/shaders/custom_postprocessing": (CONCEPT, []),
    "tutorials/shaders/shader_reference/shader_functions": (CONCEPT, []),
    "tutorials/shaders/shader_reference/shader_preprocessor": (SHADER_AUTHORING, []),
    "tutorials/shaders/shader_reference/shading_language": (SHADER_AUTHORING, [
        ("Adding or removing global uniforms at runtime", "exclude:Adding or removing global uniforms at runtime is script behaviour whose frequency cannot be told from source text."),
        ("Assigning global uniform values can be done", NO_COST_T),
        ("Beware that discard has a performance cost", "rule:materials.shader_discard"),
        ("Sometimes, you want to modify a parameter", "rule:materials.shader_material_copies"),
        ("While you can query the value of a global", "rule:scripts.frame_global_shader_get"),
    ]),
    "tutorials/shaders/shader_reference/sky_shader": ("rule:sky.quality_mode,sky.radiance_size", []),
    "tutorials/shaders/your_first_shader/your_second_3d_shader": (CONCEPT, []),
    "tutorials/xr/a_better_xr_start_script": ("exclude:The page's start script sets Engine.physics_ticks_per_second from the headset refresh rate at runtime, so the project setting does not show the effective rate and cannot be told from scene data.", []),
    "tutorials/xr/mobilevr_intro": (CONCEPT, []),
    "tutorials/xr/openxr_settings": ("rule:xr.foveation_ignored", []),
    "tutorials/xr/setting_up_xr": (CONCEPT, []),
    "tutorials/xr/xr_full_screen_effects": ("rule:xr.screen_texture", []),
    "tutorials/assets_pipeline/importing_3d_scenes/advanced_import_settings": (BAKE_T, [
        ("- Physics > Body Type", "rule:physics.concave_shape"),
    ]),
    "tutorials/assets_pipeline/importing_3d_scenes/available_formats": ("notcost:Editor iteration speed, not a runtime cost.", [
        ("By default, Blender has backface culling", "rule:materials.double_sided"),
    ]),
    "tutorials/assets_pipeline/importing_3d_scenes/import_configuration": (BAKE_T, [
        ("- Embedded Texture Handling", "rule:import.gltf_embedded_uncompressed"),
        ("- Physics > Body Type", "rule:physics.concave_shape"),
        ("- Save to File", CONCEPT),
    ]),
    "tutorials/assets_pipeline/importing_3d_scenes/node_type_customization": ("rule:physics.concave_shape", [
        ("When possible, try to use a few primitive", "rule:physics.concave_shape,physics.body_many_shapes"),
    ]),
    "tutorials/assets_pipeline/importing_audio_samples": ("rule:import.audio_pcm", [
        ("Ogg Vorbis and MP3 don't decrease quality", DEFAULT_T),
    ]),
    "tutorials/assets_pipeline/importing_images": (CONCEPT, [
        ("- Lossless: This is the default", "rule:import.texture_lossless,textures.lossless_3d"),
        ("- Textures will not become grainy", "rule:import.texture_no_mipmaps,textures.no_mipmaps"),
        ("- The size of a texture should be", "rule:textures.large_dimension"),
        ("After doing this, you may notice that textures", DEFAULT_T),
        ("BPTC and ASTC support VRAM compression for HDR", "rule:import.texture_hdr_uncompressed"),
        ("Enabling mipmaps can also make textures appear", DEFAULT_T),
        ("Even in 3D, \"pixel art\" textures", "notcost:A quality recommendation (no VRAM compression for low-resolution pixel art); it says compression would not improve performance."),
        ("High-quality VRAM texture compression is only", "rule:import.texture_high_quality"),
        ("If disabled (default), uses the faster", "rule:import.texture_high_quality"),
        ("If set to Always, will force VRAM compression", "rule:import.texture_hdr_uncompressed"),
        ("If set to Disabled, never uses VRAM compression", "rule:import.texture_hdr_uncompressed"),
        ("If set to Opaque Only (default)", "rule:import.texture_hdr_uncompressed"),
        ("If set to a value greater than -1", DEFAULT_T),
        ("It's recommended to enable mipmaps in 3D", "rule:import.texture_no_mipmaps,textures.no_mipmaps"),
        ("Notice how at larger resolutions", "rule:textures.vram_uncompressed,import.texture_uncompressed"),
        ("The default import options (no mipmaps and Lossless", "rule:import.texture_uncompressed,import.texture_no_mipmaps"),
        ("The downside of mipmaps is that they increase", DEFAULT_T),
        ("This can be used to reduce memory usage", "rule:textures.large_dimension"),
        ("VRAM compression also reduces the memory bandwidth", "rule:textures.vram_uncompressed,import.texture_uncompressed"),
    ]),
    "tutorials/export/exporting_for_linux": (CONCEPT, []),
    "tutorials/export/exporting_for_web": (EXPORT_T, [
        ("Remember that CPU and GPU performance is at", CONCEPT),
    ]),
    "tutorials/export/exporting_for_windows": (CONCEPT, []),
    "tutorials/export/exporting_projects": (EXPORT_T, [
        ("When more developers (and even non-programmers)", "notcost:History of the export system, not a cost."),
    ]),
    "tutorials/scripting/c_sharp/c_sharp_basics": (SCRIPT, [
        ("The following tools may be used for performance", METHOD),
    ]),
    "tutorials/scripting/c_sharp/c_sharp_collections": (SCRIPT, []),
    "tutorials/scripting/change_scenes_manually": (SCRIPT, []),
    "tutorials/scripting/cpp/about_godot_cpp": (SCRIPT, []),
    "tutorials/scripting/cpp/gdextension_cpp_example": (MOTION_T, []),
    "tutorials/scripting/debug/custom_performance_monitors": (METHOD, []),
    "tutorials/scripting/debug/debugger_panel": (METHOD, []),
    "tutorials/scripting/debug/objectdb_profiler": (METHOD, []),
    "tutorials/scripting/debug/the_profiler": (METHOD, []),
    "tutorials/scripting/gdextension/gdextension_cpp_example": (MOTION_T, []),
    "tutorials/scripting/gdextension/what_is_gdextension": (SCRIPT, []),
    "tutorials/scripting/gdscript/gdscript_advanced": (SCRIPT, []),
    "tutorials/scripting/gdscript/gdscript_basics": (SCRIPT, []),
    "tutorials/scripting/gdscript/gdscript_exports": ("notcost:Editor slider behaviour, not a runtime cost.", []),
    "tutorials/scripting/gdscript/static_typing": (SCRIPT, []),
    "tutorials/scripting/idle_and_physics_processing": ("notcost:Explains delta time and frame-rate independence; no cost is stated.", []),
    "tutorials/scripting/logging": (CONCEPT, [
        ("In projects exported in release mode, backtraces", "rule:memory.gdscript_track_call_stacks"),
        ("Log files for print() statements are updated", "rule:cpu.flush_stdout"),
    ]),
    "tutorials/scripting/scene_unique_nodes": ("rule:scripts.frame_find_nodes", []),
    "tutorials/scripting/singletons_autoload": (CONCEPT, []),
    "tutorials/best_practices/data_preferences": (SCRIPT, [
        ("Also note that AnimatedTexture is a Resource", CONCEPT),
    ]),
    "tutorials/best_practices/godot_notifications": (DELTA_T, [
        ("While it is possible, to achieve the best", "exclude:Polling continuous input (movement axes) every frame is the normal pattern; which checks belong in _input callbacks cannot be told from source text."),
    ]),
    "tutorials/best_practices/logic_preferences": (SCRIPT, [
        ("The naive answer is to use a static", CONCEPT),
        ("Well, the simple answer is, \"when the performance", CONCEPT),
    ]),
    "tutorials/best_practices/node_alternatives": (CONCEPT, [
        ("Nodes are cheap to produce", "rule:memory.node_count,scripts.node_count_high"),
    ]),
    "tutorials/best_practices/scenes_versus_scripts": (SCRIPT, []),
    "tutorials/editor/game_embedding": (EDITOR_T, []),
    "tutorials/editor/project_manager": (EDITOR_T, []),
    "tutorials/editor/using_the_android_editor": (EDITOR_T, []),
    "tutorials/editor/using_the_web_editor": (EDITOR_T, []),
    "tutorials/editor/using_the_xr_editor": (EDITOR_T, []),
    "tutorials/i18n/localization_using_gettext": ("exclude:Loading time and file size of very large translation sets only; it does not affect frames after loading.", []),
    "tutorials/io/runtime_file_loading_and_saving": (SCRIPT, []),
    "tutorials/math/interpolation": (DELTA_T, []),
    "tutorials/math/random_number_generation": (SCRIPT, [
        ("In global scope, you can find a randomize()", "exclude:Godot already seeds the generator at startup and the 4.7 docs dropped this note; a repeated randomize() call is script behaviour whose frequency cannot be told from source text."),
    ]),
    "tutorials/migrating/upgrading_to_godot_4": (CONCEPT, []),
    "tutorials/migrating/upgrading_to_godot_4.2": ("notcost:Describes the mesh-format migration dialog, not a runtime cost.", [
        ("The class_Mesh resource format has changed in 4.2", "rule:import.mesh_uncompressed"),
    ]),
    "tutorials/migrating/upgrading_to_godot_4.5": ("rule:navigation.region_sync_on_main_thread", []),
    "tutorials/migrating/upgrading_to_godot_4.6": (CONCEPT, []),
    "tutorials/networking/high_level_multiplayer": ("exclude:Network transfer-mode and protocol choices are made by scripts per RPC or channel; there is no project-level setting to compare.", []),
    "tutorials/plugins/editor/import_plugins": (EDITOR_T, []),
    "tutorials/plugins/editor/making_plugins": (EDITOR_T, []),
    "tutorials/troubleshooting": (EDITOR_T, []),
    "tutorials/3d/lights_and_shadows": (CONCEPT, [
        ("- Enabled: Controls whether distance fade", "rule:shadows.no_distance_fade"),
        ("A Size parameter is also available in OmniLight3D", "rule:shadows.light_size_soft"),
        ("Always make sure to set a shadow Max", "rule:shadows.directional_max_distance"),
        ("Any sort of bias issues can be fixed", "rule:shadows.directional_size_above_default,shadows.positional_atlas_above_default"),
        ("Area lights can also cast shadows", "rule:lights.area_light_cost"),
        ("Changing the area light's texture at runtime", RUNTIME_TEXTURE),
        ("For reference, the angular distance of the Sun", "rule:shadows.light_size_soft"),
        ("High shadow resolutions result in sharper shadows", "rule:shadows.directional_size_above_default,shadows.positional_atlas_above_default,shadows.directional_mobile_size,shadows.positional_mobile_size"),
        ("If 16 Bits is disabled", "rule:shadows.directional_32_bit,shadows.positional_32_bit"),
        ("If the objects being rendered are mostly irregular", "rule:shadows.omni_cube"),
        ("If the rendering limit is exceeded", "rule:shadows.no_distance_fade,lights.many_realtime"),
        ("If you need to render more lights than", "rule:lights.no_lightmap_with_many_lights,lights.positional_light_dynamic_bake"),
        ("In Forward+, as soon as one area light", "rule:lights.area_light_cost"),
        ("In Mobile and Compatibility, only objects", "rule:lights.area_light_cost"),
        ("Lights can optionally cast shadows", "rule:shadows.omni_shadow_count,shadows.spot_shadow_count,pass.shadows"),
        ("Omni Shadows can be rendered as either", "rule:shadows.omni_cube"),
        ("OmniLight3D and SpotLight3D offer several properties", "rule:shadows.no_distance_fade"),
        ("OmniLight3D, SpotLight3D, and AreaLight3D offer", "rule:shadows.no_distance_fade"),
        ("Percentage-closer soft shadows (PCSS)", "rule:shadows.light_size_soft"),
        ("Several shadow map quality settings", "rule:shadows.directional_filter_high,shadows.positional_filter_high"),
        ("Shadow rendering is a critical topic", "rule:pass.shadows"),
        ("Sometimes, the transition between a split", "rule:shadows.shadow_blend_splits"),
        ("Spots feature the same parameters as omni", "rule:shadows.omni_shadow_count"),
        ("The way projectors are rendered", "rule:lights.projector_filter_aniso"),
        ("This type of light is the most expensive", "rule:lights.area_light_cost"),
        ("To fix this, a technique named Parallel Split", "rule:shadows.directional_pssm4"),
        ("To reduce the performance impact of switching textures", RUNTIME_TEXTURE),
        ("Using a higher number of shadows per quadrant", "rule:shadows.quadrant_subdiv_high"),
        ("When using the Compatibility renderer, up to 8", "rule:renderer.gl_lights_per_object,renderer.gl_element_cap"),
        ("When using the Forward+ renderer, Godot uses a", "rule:renderer.cluster_elements_scene"),
    ]),
    "tutorials/3d/mesh_lod": (CONCEPT, [
        ("Additionally, ReflectionProbe nodes have their own", "rule:gi.probe_lod_disabled"),
        ("If you have instances in a MultiMesh that", "exclude:Whether MultiMesh instances are \"far away from each other\" depends on the camera's view distance; no size threshold separates one cullable group from several."),
        ("If you need to perform per-object adjustments", "rule:geometry.lod_bias_high"),
        ("Level of detail (LOD) is one of the", "rule:geometry.viewport_lod_disabled"),
        ("The default mesh LOD threshold of 1 pixel", "rule:geometry.lod_threshold_below_default"),
    ]),
    "tutorials/3d/occlusion_culling": (CONCEPT, [
        ("After enabling the project setting, you still need", "rule:geometry.occlusion_without_occluders"),
        ("As a last resort, you can enable the", "rule:geometry.ignore_occlusion"),
        ("If you notice low performance or stuttering", "rule:geometry.occluder_dense"),
        ("If you toggle occlusion culling in the project", METHOD),
        ("In the same menu, you can also enable", METHOD),
        ("Toggling occlusion culling at runtime is useful", METHOD),
    ]),
    "tutorials/3d/particles/collision": (CONCEPT, [
        ("- Make the colliders thicker", "rule:particles.fixed_fps_high"),
        ("Height field particle collision is very useful", "rule:particles.heightfield_resolution"),
        ("SDF collision nodes create a signed distance field", "rule:particles.particle_sdf_large"),
        ("The Follow Camera Enabled property", "rule:particles.heightfield_camera"),
        ("The Resolution property controls how detailed the distance", "rule:particles.particle_sdf_large"),
        ("The Resolution property controls how detailed the height", "rule:particles.heightfield_resolution"),
        ("The Update Mode property controls when the height", "rule:particles.particle_heightfield_always"),
    ]),
    "tutorials/3d/particles/creating_a_3d_particle_system": (CONCEPT, []),
    "tutorials/3d/particles/process_material_properties": ("notcost:Describes particle motion or flipbook smoothness, not a performance cost.", []),
    "tutorials/3d/particles/properties": (CONCEPT, [
        ("The Amount property controls the maximum", "rule:particles.gpu_amount"),
        ("The Fixed FPS property limits how often", "rule:particles.fixed_fps_high"),
        ("The Visibility AABB property defines a box", "exclude:The page gives no size threshold; the right visibility box depends on how far the effect's particles travel, which a scan cannot know."),
        ("When using particle collision, tunneling", "rule:particles.fixed_fps_high"),
        ("You can slow down or speed up the", "notcost:Speed Scale changes simulation speed, not cost."),
    ]),
    "tutorials/3d/particles/turbulence": ("notcost:Describes turbulence motion, not a performance cost.", [
        ("Turbulence makes use of 3D noise", "rule:particles.particle_turbulence"),
    ]),
    "tutorials/3d/physical_light_and_camera_units": (CONCEPT, [
        ("Since physical light and camera units only require", "rule:post.dof_enabled"),
    ]),
    "tutorials/3d/procedural_geometry/index": (CONCEPT, [
        ("ImmediateMesh is useful for prototyping", "exclude:Runtime mesh generation from scripts; how often a script rebuilds a mesh cannot be told reliably from source text."),
        ("ImmediateMesh is more limited than both", "exclude:Runtime mesh generation from scripts; how often a script rebuilds a mesh cannot be told reliably from source text."),
        ("Using an ArrayMesh is slightly faster", SCRIPT),
    ]),
    "tutorials/3d/resolution_scaling": (CONCEPT, [
        ("- Bilinear: Standard bilinear filtering", DEFAULT_T),
        ("If performance doesn't increase much when decreasing", METHOD),
        ("Negative mipmap LOD bias can also decrease", "rule:resolution.negative_mip_bias"),
        ("Positive mipmap LOD bias will make", DEFAULT_T),
        ("Resolution scales above 1.0 can be used", "rule:resolution.scale_above_one"),
        ("Resolution scaling is one of the most direct", "rule:resolution.full_scale_gpu_over_budget"),
        ("The Rendering > Scaling 3D > Scale setting", "rule:resolution.full_scale_gpu_over_budget"),
        ("The resolution scale is defined on a per-axis", "rule:resolution.scale_above_one"),
    ]),
    "tutorials/3d/standard_material_3d": (CONCEPT, [
        ("- Alpha Scissor: Material is transparent", "rule:materials.alpha_blend"),
        ("- Alpha-blended materials are significantly slower", TRANSPARENCY),
        ("- Alpha: Material is transparent", TRANSPARENCY),
        ("By default, Blender has backface culling", "rule:materials.double_sided"),
        ("On low-end or mobile devices, using per-vertex", "rule:materials.per_pixel_particles,renderer.force_vertex_shading"),
        ("Rendering unshaded is useful", "rule:materials.per_pixel_particles"),
        ("The Per-Pixel shading mode calculates", "rule:materials.per_pixel_particles"),
        ("To hide a character when they get too", "rule:materials.alpha_blend"),
        ("While alpha scissor and alpha hash materials", "rule:materials.alpha_blend"),
    ]),
    "tutorials/3d/variable_rate_shading": ("rule:renderer.vrs_off_while_gpu_bound", [
        ("You can create your own VRS density map", "exclude:Generating a VRS image at runtime is script behaviour whose cost cannot be told from source text."),
    ]),
    "tutorials/3d/visibility_ranges": ("rule:geometry.no_visibility_range", [
        ("- Disabled: Uses hysteresis", "rule:geometry.geometry_fade_cost"),
        ("- Higher performance, as dithering transparency", "rule:geometry.geometry_fade_cost"),
        ("- What visibility ranges can do", CONCEPT),
        ("For example, on the materials used by distant", SIMPLER_MATERIALS),
        ("One way to further improve performance is to", SIMPLER_MATERIALS),
        ("Performance gains when doing so should be", SIMPLER_MATERIALS),
    ]),
    "tutorials/3d/volumetric_fog": (CONCEPT, [
        ("- Rendering > Environment > Volumetric Fog >", "rule:post.volumetric_fog_size"),
        ("- Temporal Reprojection > Enabled", NO_COST_T),
        ("If fog light interaction is not desired", "rule:lights.light_volumetric_fog"),
        ("There are a few project settings available", "rule:post.volumetric_fog_size"),
        ("Thin fog volumes may appear to flicker", "rule:post.volumetric_fog_size"),
        ("To improve performance, it's recommended to use low", "rule:post.fog_density_texture_large"),
    ]),
    "tutorials/3d/introduction_to_3d": (CONCEPT, [
        ("In any case, this method is meant for", "exclude:Runtime mesh generation from scripts; how often a script rebuilds a mesh cannot be told reliably from source text."),
    ]),
    "tutorials/3d/using_decals": (CONCEPT, [
        ("- Enabled: Controls whether distance fade", "rule:decals.no_distance_fade"),
        ("- Extents: The size of the decal", "rule:decals.large_size"),
        ("Decal rendering performance is mostly determined", "rule:decals.large_size,decals.count"),
        ("The way decals are rendered also has an", "rule:textures.decal_filter_aniso"),
        ("To improve rendering performance, you can enable the", "rule:decals.no_distance_fade"),
        ("When using the Forward+ renderer, Godot uses a", "rule:renderer.cluster_elements_scene"),
    ]),
    "tutorials/rendering/compositor": (None, [
        ("There is no performance benefit to use multiview", "notcost:The paragraph states there is no performance benefit."),
    ]),
    "tutorials/rendering/jitter_stutter": (CONCEPT, [
        ("Additionally, stutter may be induced", ENV_OS),
        ("Another common reason for stuttering is shader compilation", "rule:stutter.compilations_draw,stutter.shader_cache_off"),
        ("Feral GameMode", ENV_OS),
        ("For fullscreen, Windows gives special priority", ENV_OS),
        ("Forcing your graphics card", ENV_DRIVER),
        ("Generally, Android is stutter", ENV_OS),
        ("Generally, macOS is stutter-free", ENV_OS),
        ("However, when using the Compatibility renderer", "exclude:A level-loading technique for the Compatibility renderer (draw every mesh and effect once behind a loading screen); whether a level does this cannot be told from scene data."),
        ("If your monitor supports it, consider enabling variable", ENV_VRR),
        ("On some platforms, you can also opt into", ENV_DRIVER),
        ("Since Godot 4.4, when using the Forward+", "rule:stutter.compilations_surface,stutter.compilations_draw"),
        ("Stutter may be visible on desktop Linux", ENV_OS),
        ("Stutter may happen due to several different reasons", "rule:pacing.fps_below_target"),
        ("Stutter may happen due to two different reasons", "rule:pacing.fps_below_target"),
        ("The downside of increasing physics FPS", "rule:cpu.physics_ticks"),
        ("The formula used to determine the framerate cap", ENV_VRR),
        ("The second is more complicated", ENV_OS),
        ("There is no workaround for driver or compositor", ENV_OS),
        ("This framerate cap can be set", ENV_VRR),
        ("This may be counterintuitive at first", ENV_VRR),
        ("When using the Forward+ or Mobile rendering methods, another way", "rule:gpu_best_practices.double_buffer_vsync,pacing.swapchain_images"),
        ("Windows is known to cause stutter", ENV_OS),
        ("iOS devices are generally stutter-free", ENV_OS),
    ]),
    "tutorials/rendering/multiple_resolutions": (CONCEPT, [
        ("- Set the base window width to 1280", BASE_SIZE),
        ("- Set the base window width to 1920", BASE_SIZE),
        ("- Set the base window width to 720", BASE_SIZE),
        ("- Set the stretch mode to canvas_items", "rule:resolution.full_scale_gpu_over_budget"),
        ("For 3D games, there is not much", "rule:resolution.full_scale_gpu_over_budget"),
        ("If Stretch Mode is set to viewport", "rule:resolution.full_scale_gpu_over_budget"),
        ("On top of that, changing the monitor's resolution", "notcost:Describes slower alt-tabbing when the monitor changes resolution; not a rendering cost."),
        ("Oversampling can also be applied", "exclude:CanvasItem.oversampling_with_scale (4.5+) costs CPU only when the node's scale changes often at runtime, which cannot be told from scene data."),
        ("To render 3D at a different resolution", "rule:resolution.full_scale_gpu_over_budget"),
        ("To render 3D at a lower resolution", "rule:resolution.full_scale_gpu_over_budget"),
        ("To resolve this, you can enable mipmaps", "exclude:A quality trade-off (2D mipmaps reduce aliasing when downsampling but use more memory); flagging either choice would be noise without a measured symptom."),
        ("Using multiple Viewport nodes", "rule:resolution.full_scale_gpu_over_budget"),
    ]),
    "tutorials/rendering/renderers": (CONCEPT, [
        ("- Forward+. The most advanced renderer", "rule:renderer.mobile_method,renderer.compatibility_method"),
        ("- You are developing for older mobile devices", "rule:renderer.mobile_method,renderer.compatibility_method"),
    ]),
    "tutorials/rendering/viewports": (CONCEPT, [
        ("- Debug Draw = Overdraw", "notcost:A debug view; capture_viewport uses it to show overdraw."),
        ("By default, re-rendering of the SubViewport", "rule:ui.subviewport_always"),
        ("Godot also provides a way of customizing", "notcost:Describes debug draw modes."),
        ("If you know that the Viewport is only", "rule:ui.subviewport_3d_unused"),
    ]),
}
COVERAGE_NOTES = {
    "- Reusing Materials": "Partial: duplicated ShaderMaterials and draw-call counts are checked; duplicated StandardMaterial3D resources are not compared.",
    "If a scene has, for example, 20,000 objects": "Partial: duplicated ShaderMaterials and draw-call counts are checked; duplicated StandardMaterial3D resources are not compared.",
    "The other factor in fragment shaders": "Partial: texture filtering is checked; the number of textures a shader reads is not.",
    "Animation and vertex animation": "Partial: skin weights and dynamic skin bounds are checked; animation rates of distant meshes are not.",
    "Try to never request any information": "Partial: the documented hot getters are matched; other server getters called every frame are not.",
    "The solution to jitter": "The rule flags tick rates above 60; physics interpolation is the cheaper alternative the page recommends.",
}


def classify(page, text, used):
    default, overrides = PAGES.get(page, (None, []))
    for prefix, value in overrides:
        if text.startswith(prefix):
            used.add((page, prefix))
            return value, prefix
    return default, None


def main():
    rules = {rule["id"] for path in (ROOT / "addons/render_lens/rules").glob("*.json") for rule in json.loads(path.read_text(encoding="utf-8"))}
    entries, used, missing = {}, set(), []
    for branch, checkout in zip(BRANCHES, sys.argv[1:5]):
        for key, (section, text) in extract(checkout).items():
            entry = entries.setdefault(key, {"paragraph": key, "section": section, "text": text, "branches": []})
            entry["branches"].append(branch)
    for key, entry in entries.items():
        page = key.split(": ", 1)[0]
        value, prefix = classify(page, entry["text"], used)
        if value is None:
            missing.append(key)
            continue
        status, _, detail = value.partition(":")
        entry["status"] = {"rule": "covered", "notcost": "not_a_cost", "exclude": "excluded"}[status]
        if status == "rule":
            entry["rules"] = detail.split(",")
            for rule_id in entry["rules"]:
                assert rule_id in rules, f"{key}: rule {rule_id} is missing"
        else:
            entry["reason"] = detail
        if prefix in COVERAGE_NOTES:
            entry["note_on_coverage"] = COVERAGE_NOTES[prefix]
    assert not missing, "Unclassified paragraphs:\n" + "\n".join(sorted(missing))
    stale = sorted("%s: %s" % item for item in {(page, prefix) for page, (_, overrides) in PAGES.items() for prefix, _ in overrides} - used)
    assert not stale, "Classified prefixes without a matching paragraph:\n" + "\n".join(stale)
    items = [entries[key] for key in sorted(entries)]
    summary = {"paragraphs": len(items), "pages": len({item["paragraph"].split(": ", 1)[0] for item in items})}
    for status in ("covered", "excluded", "not_a_cost"):
        summary[status] = sum(1 for item in items if item["status"] == status)
    document = {
        "scope": "Every prose paragraph (notes and tips included; code, tables and images excluded) under %s in the godot-docs 4.4, 4.5, 4.6 and 4.7 branches whose text matches a performance keyword." % ", ".join(SCOPES),
        "branches": {branch: "https://github.com/godotengine/godot-docs/tree/%s" % branch for branch in BRANCHES},
        "keywords": KEYWORDS.pattern,
        "method": "Keyword matches are candidates, keyed by page and the paragraph's first eight words. Each is classified by hand: covered by named rules, not a cost (methodology, concepts, motion), or excluded with a reason. Rules that quote a tutorial are verified verbatim against both branches at build time.",
        "summary": summary,
        "notes": items,
    }
    (ROOT / "docs/GODOT_TUTORIAL_NOTES.json").write_text(json.dumps(document, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    print(summary)


if __name__ == "__main__" and len(sys.argv) == 5:
    main()


if __name__ == "__main__" and len(sys.argv) == 6 and sys.argv[5] == "--dump":
    entries = {}
    for branch, checkout in zip(BRANCHES, sys.argv[1:5]):
        for key, (section, text) in extract(checkout).items():
            entries.setdefault(key, (section, text, []))[2].append(branch)
    for key in sorted(entries):
        section, text, branches = entries[key]
        print("%s [%s] {%s}\n    %s\n" % (key, ",".join(branches), section, text[:700]))
