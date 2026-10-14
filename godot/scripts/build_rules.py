#!/usr/bin/env python3
"""Write Render Lens rule JSON and RULES.md from verified Godot 4.4 / 4.7 facts.

Setting paths are checked against /tmp/godot_facts_44.txt and /tmp/godot_facts_47.txt
when those dumps exist.
"""

import json
import os
import re
from collections import OrderedDict

from godot_versions import CHECKOUTS as GODOT_CHECKOUTS, DOCS as GODOT_DOCS, SERIES, expand

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "addons", "render_lens", "rules")
D = "https://docs.godotengine.org/en/4.4/"
AA = D + "tutorials/3d/3d_antialiasing.html"
LIGHTS = D + "tutorials/3d/lights_and_shadows.html"
GPU = D + "tutorials/performance/gpu_optimization.html"
SDFGI = D + "tutorials/3d/global_illumination/using_sdfgi.html"
VFOG = D + "tutorials/3d/volumetric_fog.html"
PIPE = D + "tutorials/performance/pipeline_compilations.html"
OCC = D + "tutorials/3d/occlusion_culling.html"
LOD = D + "tutorials/3d/mesh_lod.html"
VIS = D + "tutorials/3d/visibility_ranges.html"
SCALE = D + "tutorials/3d/resolution_scaling.html"
VRS = D + "tutorials/3d/variable_rate_shading.html"
DECAL = D + "tutorials/3d/using_decals.html"
MM = D + "tutorials/3d/using_multi_mesh_instance.html"
ENV = D + "tutorials/3d/environment_and_post_processing.html"
IMG = D + "tutorials/assets_pipeline/importing_images.html"
D2 = D + "tutorials/2d/2d_lights_and_shadows.html"
OPT3D = D + "tutorials/performance/optimizing_3d_performance.html"
CPU = D + "tutorials/performance/cpu_optimization.html"
THREAD = D + "tutorials/performance/thread_safe_apis.html"
GEN = D + "tutorials/performance/general_optimization.html"
PERF = D + "classes/class_performance.html"
PROJ = D + "classes/class_projectsettings.html"
RS = D + "classes/class_renderingserver.html"
ENVCLS = D + "classes/class_environment.html"
LIGHT3D = D + "classes/class_light3d.html"
DIRL = D + "classes/class_directionallight3d.html"
OMNI = D + "classes/class_omnilight3d.html"
GEO = D + "classes/class_geometryinstance3d.html"
BASE = D + "classes/class_basematerial3d.html"
L2D = D + "classes/class_light2d.html"
GPUP = D + "classes/class_gpuparticles3d.html"
CPUP = D + "classes/class_cpuparticles3d.html"
PROBE = D + "classes/class_reflectionprobe.html"
VOX = D + "classes/class_voxelgi.html"
LMAP = D + "classes/class_lightmapgi.html"
CAM = D + "classes/class_camera3d.html"
SKY = D + "classes/class_sky.html"
REFL = D + "tutorials/3d/global_illumination/reflection_probes.html"
VOXDOC = D + "tutorials/3d/global_illumination/using_voxel_gi.html"
LMAPDOC = D + "tutorials/3d/global_illumination/using_lightmap_gi.html"
PHYS = D + "tutorials/physics/physics_introduction.html"
JOLT = D + "tutorials/physics/using_jolt_physics.html"
PART = D + "tutorials/3d/particles/properties.html"
TRAIL = D + "tutorials/3d/particles/trails.html"
TEXH = "https://github.com/godotengine/godot/blob/4.4-stable/editor/import/resource_importer_texture.h"
FWD = "https://github.com/godotengine/godot/blob/4.4-stable/servers/rendering/renderer_rd/forward_clustered/render_forward_clustered.cpp"

ALL = ["forward_plus", "mobile", "gl_compatibility"]
FP = ["forward_plus"]
FPM = ["forward_plus", "mobile"]
BOTH = ["4.4", "4.7"]
V44 = ["4.4"]
V47 = ["4.7"]

rules = []
DEFAULT_TRADEOFFS = {"post.camera_far_default", "post.glow_bicubic", "gi.texture_array_reflections", "shadows.directional_pssm4", "shadows.omni_cube", "shadows.no_distance_fade"}

# measure_change finding=<id>: the change each rule's suggestion names, tried live in the running game. Changes that touch
# every matching node (all omni lights) measure the upper bound of the suggestion; presets that lower a value carry
# only_above, so objects already cheaper are left alone (PCF13 -> PCF5 never adds filtering to an unfiltered light).
# main() checks each setting against the live tables in runtime/experiment.gd and each class property against the 4.4-4.7
# class references.
def env_off(prop):
    return [{"environment": True, "property": prop, "value": False}]


def live_setting(path, value):
    return [{"setting": path, "value": value}]


EXPERIMENTS = {
    "pass.ssao": env_off("ssao_enabled"), "post.ssao_enabled": env_off("ssao_enabled"),
    "pass.ssil": env_off("ssil_enabled"), "gi.ssil_enabled": env_off("ssil_enabled"),
    "pass.ssr": env_off("ssr_enabled"), "post.ssr_enabled": env_off("ssr_enabled"),
    "post.ssr_steps": [{"environment": True, "property": "ssr_max_steps", "value": 64, "only_above": 64}],
    "pass.vfog": env_off("volumetric_fog_enabled"), "post.volumetric_fog": env_off("volumetric_fog_enabled"),
    "pass.sdfgi": env_off("sdfgi_enabled"), "gi.sdfgi_enabled": env_off("sdfgi_enabled"),
    "pass.glow": env_off("glow_enabled"), "post.glow_enabled": env_off("glow_enabled"),
    "post.glow_bicubic": live_setting("rendering/environment/glow/upscale_mode", 0),
    "pass.taa": live_setting("rendering/anti_aliasing/quality/use_taa", False),
    "antialiasing.taa_enabled": live_setting("rendering/anti_aliasing/quality/use_taa", False),
    "antialiasing.msaa_4x": live_setting("rendering/anti_aliasing/quality/msaa_3d", 1),
    "antialiasing.msaa_8x": live_setting("rendering/anti_aliasing/quality/msaa_3d", 2),
    "antialiasing.smaa_enabled": live_setting("rendering/anti_aliasing/quality/screen_space_aa", 0),
    "resolution.scale_above_one": live_setting("rendering/scaling_3d/scale", 1.0),
    "post.dof_enabled": [{"camera_attributes": True, "property": "dof_blur_far_enabled", "value": False},
                         {"camera_attributes": True, "property": "dof_blur_near_enabled", "value": False}],
    "pass.sss": live_setting("rendering/environment/subsurface_scattering/subsurface_scattering_quality", 0),
    "post.ssao_quality_high": live_setting("rendering/environment/ssao/quality", 2),
    "post.ssil_quality_high": live_setting("rendering/environment/ssil/quality", 2),
    "post.ssao_full_res": live_setting("rendering/environment/ssao/half_size", True),
    "post.ssil_full_res": live_setting("rendering/environment/ssil/half_size", True),
    "shadows.omni_shadow_count": [{"class": "OmniLight3D", "property": "shadow_enabled", "value": False}],
    "shadows.spot_shadow_count": [{"class": "SpotLight3D", "property": "shadow_enabled", "value": False}],
    "shadows.omni_cube": [{"class": "OmniLight3D", "property": "omni_shadow_mode", "value": 0}],
    "shadows.directional_pssm4": [{"class": "DirectionalLight3D", "property": "directional_shadow_mode", "value": 1, "only_above": 1}],
    "shadows.directional_filter_high": live_setting("rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality", 2),
    "shadows.positional_filter_high": live_setting("rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality", 2),
    "shadows.positional_atlas_above_default": live_setting("rendering/lights_and_shadows/positional_shadow/atlas_size", 4096),
    "shadows.directional_size_above_default": live_setting("rendering/lights_and_shadows/directional_shadow/size", 4096),
    "canvas.many_shadow_lights": [{"class": "Light2D", "property": "shadow_enabled", "value": False}],
    "canvas.pcf13": [{"class": "Light2D", "property": "shadow_filter", "value": 1, "only_above": 1}],
}

# Timestamp labels that carry each feature's GPU time (run_regressions.py checks them per version and renderer).
# Markers that bracket CPU work carry no GPU time and are left out (run_regressions.py --graphics checks every name live):
# "Update Volumetric Fog" (the fog work is in the three passes after it) and "Cull CanvasItem Tree".
FEATURE_PASSES = {
    "ssao": ["Process SSAO"],
    "ssil": ["Process SSIL"],
    "ssr": ["Screen-Space Reflections", "Process SSR"],
    "vfog": ["Render Fog", "Integrate Fog", "Filter Fog"],
    "sdfgi": ["Render SDFGI"],
    "dof": ["Depth of Field"],
    "directional_shadows": ["Render Shadows", "Directional/SpotLight Shadows"],
    "positional_shadows": ["Render OmniLight Shadows", "Directional/SpotLight Shadows", "Render Shadows"],
    "shadows": ["Render Shadows", "Render OmniLight Shadows", "Directional/SpotLight Shadows"],
    "canvas_shadows": ["Render PointLight2D Shadow"],
}
# Rules that tune a measured feature take that feature's pass share, so a cheap feature ranks low for every rule about
# it (2026-10-13: post.ssr_steps ranked seventh while SSR measured 0.6% of the frame).
FEATURE_RULES = {
    "ssao": ["post.ssao_quality_high", "post.ssao_full_res", "post.ssao_blur_passes", "post.ssao_large_radius"],
    "ssil": ["post.ssil_quality_high", "post.ssil_full_res", "post.ssil_blur_passes"],
    "ssr": ["post.ssr_steps", "post.ssr_half_size_off", "post.ssr_roughness_quality"],
    "vfog": ["post.volumetric_fog", "post.volumetric_fog_size", "post.fog_density_texture_large", "post.fog_sdfgi_inject",
             "post.fog_ambient_inject", "lights.light_volumetric_fog"],
    "sdfgi": ["gi.sdfgi_cascades", "gi.sdfgi_occlusion", "gi.sdfgi_probe_rays", "gi.sdfgi_frames_to_converge",
              "gi.sdfgi_light_update_slow", "gi.sdfgi_small_cells"],
    "dof": ["post.dof_enabled", "post.dof_circle", "post.dof_quality_high"],
    "directional_shadows": ["shadows.directional_max_distance", "shadows.directional_mobile_size"],
    "positional_shadows": ["shadows.positional_atlas_above_default", "shadows.quadrant_subdiv_high", "shadows.no_distance_fade",
                           "shadows.positional_mobile_size", "shadows.viewport_shadow_atlas", "shadows.light_shadow_fade"],
    "shadows": ["shadows.double_sided_casters", "shadows.small_shadow_casters", "shadows.tighter_culling_off",
                "import.mesh_shadow_off", "import.obj_shadow_off"],
    "canvas_shadows": ["canvas.many_shadow_lights", "shadows.shadow_2d_atlas"],
}
WHY_SAMPLING = "Filtering runs while the opaque pass samples the shadow map, not in the shadow pass."
WHY_MSAA = "MSAA cost is spread over the passes it multisamples; Resolve MSAA times only the resolve."
WHY_PROBES = "Reflection probe faces render as scene passes of their own; no one timestamp carries a probe's cost."
WHY_SKY = "Sky and probe radiance filtering is not timed as one pass."
# Performance rules about a timed feature that keep no pass, with the reason.
NO_FEATURE_PASS = {
    "shadows.directional_filter_high": WHY_SAMPLING, "shadows.positional_filter_high": WHY_SAMPLING,
    "shadows.mobile_filter_raised": WHY_SAMPLING, "shadows.positional_mobile_filter_raised": WHY_SAMPLING,
    "shadows.light_size_soft": WHY_SAMPLING, "shadows.light_shadow_blur": WHY_SAMPLING, "shadows.shadow_blend_splits": WHY_SAMPLING,
    "shadows.directional_32_bit": "Shadow map precision costs both in the shadow pass and when the opaque pass samples it.",
    "shadows.positional_32_bit": "Shadow map precision costs both in the shadow pass and when the opaque pass samples it.",
    "post.glow_bicubic": "The glow upscale runs in the Tonemap pass, which also does other work.",
    "post.glow_upscale_mobile": "The glow upscale runs in the Tonemap pass, which also does other work.",
    "post.fog_enabled": "Depth fog is computed in the scene shaders and has no pass of its own.",
    "post.fog_aerial": "Depth fog is computed in the scene shaders and has no pass of its own.",
    "pacing.shadow_draws_dominate": "A CPU draw-call ratio, not a GPU pass.",
    "gi.half_resolution_off": "The GI label is shared with the parallel shadow timestamp.",
    "gi.probe_always": WHY_PROBES, "gi.probe_shadows": WHY_PROBES, "gi.reflection_atlas_size": WHY_PROBES, "gi.reflection_count": WHY_PROBES,
    "gi.reflection_mobile_size": WHY_PROBES,
    "gi.ggx_samples": WHY_SKY, "gi.texture_array_reflections": WHY_SKY, "gi.roughness_layers_high": WHY_SKY, "gi.fast_filter_high_quality": WHY_SKY,
    "gi.ggx_mobile_high": WHY_SKY, "gi.texture_array_reflections_mobile": WHY_SKY, "sky.quality_mode": WHY_SKY,
    "sky.radiance_size": WHY_SKY,
    "antialiasing.msaa_4x": WHY_MSAA, "antialiasing.msaa_8x": WHY_MSAA, "antialiasing.msaa_on_mobile_renderer": WHY_MSAA,
    "antialiasing.msaa_2d_high": WHY_MSAA, "antialiasing.viewport_msaa_fxaa": WHY_MSAA, "antialiasing.viewport_msaa_2d": WHY_MSAA,
    "gpu_best_practices.arm_msaa8": WHY_MSAA, "gpu_best_practices.imagination_msaa8": WHY_MSAA, "gpu_best_practices.arm_msaa_blending": WHY_MSAA,
    "ui.subviewport_msaa": WHY_MSAA, "post.compositor_msaa_resolve": WHY_MSAA,
}
FEATURE_TOKENS = ("ssao", "ssil", "ssr", "screen_space_reflection", "glow", "fog", "sdfgi", "dof", "shadow", "msaa", "reflection", "sky")



def add(rule):
    rule.setdefault("heuristic", False)
    rule.setdefault("heuristic_rationale", "")
    rule.setdefault("kind", "performance")
    rule.setdefault("severity", "medium")
    rule.setdefault("requires", ["settings"])
    rule.setdefault("when_pass", [])
    rule.setdefault("dedupe_key", "")
    rule.setdefault("pass_only", False)
    rule.setdefault("setting", "")
    rule.setdefault("node_property", "")
    rule.setdefault("offender_key", "")
    rule.setdefault("share_from", "")
    rule.setdefault("share_unit", "")
    rule.setdefault("engine_internal", False)
    rule.setdefault("validation_id", "")
    min_version = rule.pop("min_version", "")
    max_version = rule.pop("max_version", "")
    applies = {
        "renderers": rule.pop("renderers"),
        "versions": expand(rule.pop("versions")),
    }
    if rule.get("vendors"):
        applies["vendors"] = rule.pop("vendors")
    if rule.get("renderers_by_version"):
        applies["renderers_by_version"] = rule.pop("renderers_by_version")
    if min_version:
        applies["min_version"] = min_version
    if max_version:
        applies["max_version"] = max_version
    rule["applies_to"] = applies
    if rule["heuristic"] and not rule["heuristic_rationale"]:
        raise SystemExit("missing rationale: " + rule["id"])
    if not rule.get("source", "").startswith("http"):
        raise SystemExit("bad source: " + rule["id"])
    rules.append(rule)


def sgte(path, value):
    return {"setting_gte": {"path": path, "value": value}}


def sgt(path, value):
    return {"setting_gt": {"path": path, "value": value}}


def slt(path, value):
    return {"setting_lt": {"path": path, "value": value}}


def seq(path, value):
    return {"setting_eq": {"path": path, "value": value}}


def sneq(path, value):
    return {"setting_neq": {"path": path, "value": value}}


def scgte(name, value):
    return {"scene_gte": {"name": name, "value": value}}


def sceq(name, value):
    return {"scene_eq": {"name": name, "value": value}}


def all_(*conds):
    return {"all": list(conds)}


def any_(*conds):
    return {"any": list(conds)}


def mgt(name, value):
    return {"metric_gt": {"name": name, "value": value}}


def mgte(name, value):
    return {"metric_gte": {"name": name, "value": value}}


def ratio(name, value):
    return {"metric_gt_budget_ratio": {"name": name, "ratio": value}}


def present(names):
    if isinstance(names, str):
        names = [names]
    return {"pass_present": {"names": names}}


def pshare(name, share):
    # A list names the pass in each renderer (Forward+ and Mobile label some passes differently).
    return {"pass_share_gte": {"names" if isinstance(name, list) else "name": name, "share": share}}


# --- renderer & platform ----------------------------------------------------

add(dict(
    id="renderer.compatibility_method",
    category="renderer_platform",
    title="Compatibility renderer is selected",
    severity="info",
    kind="info",
    renderers=ALL, versions=BOTH, requires=["settings"],
    condition=seq("rendering/renderer/rendering_method", "gl_compatibility"),
    evidence="rendering/renderer/rendering_method is gl_compatibility.",
    suggestion="Forward+ is required for SDFGI, SSAO, SSIL, SSR, volumetric fog, TAA, and FSR. Mobile keeps VoxelGI, decals, and FXAA but not those Forward+-only effects. Stay on Compatibility only when the target GPU has no RenderingDevice.",
    setting="rendering/renderer/rendering_method",
    tradeoff="Forward+ and Mobile drop older OpenGL-only devices.",
    expected_effect="The feature set changes. Re-measure after switching; this rule does not assign a frame-time delta.",
    verify_step="collect_metrics",
    source=OPT3D,
))

add(dict(
    id="renderer.mobile_method",
    category="renderer_platform",
    title="Mobile renderer is selected",
    severity="info",
    kind="info",
    renderers=ALL, versions=BOTH, requires=["settings"],
    condition=seq("rendering/renderer/rendering_method", "mobile"),
    evidence="rendering/renderer/rendering_method is mobile.",
    suggestion="Mobile is the lower-overhead clustered renderer. SDFGI, SSAO, SSIL, SSR, volumetric fog, TAA, and FSR are Forward+-only in the 4.4 docs. The .mobile shadow-size overrides default to 2048 rather than 4096.",
    setting="rendering/renderer/rendering_method",
    tradeoff="Moving to Forward+ enables those effects and raises the GPU cost.",
    expected_effect="Documents the renderer ceiling. It does not by itself change frame time.",
    verify_step="collect_metrics",
    source=ENV,
))

add(dict(
    id="renderer.thread_model_unsafe",
    category="renderer_platform",
    title="Rendering thread model is Unsafe (deprecated)",
    severity="high",
    renderers=ALL, versions=BOTH, requires=["settings"],
    condition=seq("rendering/driver/threads/thread_model", 0),
    evidence="rendering/driver/threads/thread_model is 0. The ProjectSettings hint is Unsafe (deprecated), Safe, Separate. The default is 1 (Safe).",
    suggestion="Set rendering/driver/threads/thread_model to 1 (Safe). The thread-safety page shows direct scene-tree calls from a worker as unsafe.",
    setting="rendering/driver/threads/thread_model",
    tradeoff="Safe serializes those calls. Separate is a different mode and is not required to leave Unsafe.",
    expected_effect="Removes the deprecated unsafe threading mode.",
    verify_step="collect_metrics",
    source=THREAD,
))

add(dict(
    id="renderer.depth_prepass_disabled",
    category="renderer_platform",
    title="Depth prepass is disabled",
    severity="medium",
    renderers=FPM, versions=BOTH, requires=["settings"],
    condition=seq("rendering/driver/depth_prepass/enable", False),
    evidence="rendering/driver/depth_prepass/enable is false. The default is true.",
    suggestion="Set rendering/driver/depth_prepass/enable back to true unless a specific GPU is on rendering/driver/depth_prepass/disable_for_vendors (default PowerVR,Mali,Adreno,Apple).",
    setting="rendering/driver/depth_prepass/enable",
    tradeoff="The prepass is an extra geometry pass. The GPU optimization page describes early depth rejection as how opaque pixels avoid shading hidden surfaces.",
    expected_effect="Restores the default depth prepass. Compare the Render Depth Pre-Pass timestamp if the game is running.",
    verify_step="gpu_passes frames=60",
    source=GPU,
    when_pass=["Render Depth Pre-Pass"],
    dedupe_key="depth_prepass",
))

add(dict(
    id="renderer.depth_prepass_vendor_list",
    category="renderer_platform",
    title="Adapter vendor is on the depth-prepass disable list",
    severity="info",
    kind="info",
    renderers=FPM, versions=BOTH, requires=["settings", "metrics"],
    condition=all_(
        seq("rendering/driver/depth_prepass/enable", True),
        {"adapter_listed_in_setting": {"path": "rendering/driver/depth_prepass/disable_for_vendors"}},
    ),
    evidence="The video adapter vendor string is listed in rendering/driver/depth_prepass/disable_for_vendors while the prepass project setting is still true.",
    suggestion="Godot keeps a vendor exception list for the depth prepass. Confirm on device whether the prepass is actually running before tuning it.",
    setting="rendering/driver/depth_prepass/disable_for_vendors",
    tradeoff="Forcing the prepass on a listed vendor can be the case the default list is avoiding.",
    expected_effect="Explains a missing depth prepass on that GPU. No frame-time number is assumed.",
    verify_step="collect_metrics",
    source=PROJ,
))

add(dict(
    id="renderer.force_vertex_shading",
    category="renderer_platform",
    title="Vertex shading is forced project-wide",
    severity="low",
    kind="quality_up",
    renderers=FPM, versions=BOTH, requires=["settings"],
    condition=seq("rendering/shading/overrides/force_vertex_shading", True),
    evidence="rendering/shading/overrides/force_vertex_shading is true. The default is false.",
    suggestion="Turn force_vertex_shading off to shade per pixel again. The GPU optimization page points at vertex shading as a way to cut shading cost on particles.",
    setting="rendering/shading/overrides/force_vertex_shading",
    tradeoff="Per-pixel shading costs more GPU time and restores specular and normal-map detail.",
    expected_effect="Higher shading quality. Re-measure the opaque pass before keeping it.",
    verify_step="gpu_passes frames=60",
    source=GPU,
))

add(dict(
    id="renderer.force_lambert",
    category="renderer_platform",
    title="Lambert is forced over Burley",
    severity="low",
    kind="quality_up",
    renderers=ALL, versions=BOTH, requires=["settings"],
    condition=seq("rendering/shading/overrides/force_lambert_over_burley", True),
    evidence="rendering/shading/overrides/force_lambert_over_burley is true. The desktop default is false. The .mobile override defaults to true.",
    suggestion="On desktop Forward+, turn this off to use Burley diffuse. Leave it on for a Mobile-renderer target if you chose that default on purpose.",
    setting="rendering/shading/overrides/force_lambert_over_burley",
    tradeoff="Burley is the higher-quality diffuse model.",
    expected_effect="Changes the diffuse BRDF. Frame-time impact has to be measured.",
    verify_step="collect_metrics",
    source=PROJ,
))

add(dict(
    id="renderer.cluster_elements_scene",
    category="renderer_platform",
    title="Lights, decals, or probes exceed the clustered-element budget",
    severity="high",
    heuristic=True,
    heuristic_rationale="The largest of the scene's omni, spot and area light (hidden lights excluded), decal and reflection-probe counts is compared with rendering/limits/cluster_builder/max_clustered_elements: ClusterBuilderRD caps each type on its own (cluster_builder_rd.h add_light/add_box), although the class reference describes a sum. Scene counts include elements outside the view, so this is not the engine's per-view count. Mobile does not use the cluster builder (RenderForwardMobile::get_max_elements is a fixed 256).",
    renderers=["forward_plus"], versions=BOTH, requires=["settings", "scene"],
    condition={"cluster_budget_exceeded": True},
    evidence="The scene's omni, spot, area, decal or reflection-probe count exceeds rendering/limits/cluster_builder/max_clustered_elements (default 512), which Forward+ applies to each type on its own.",
    suggestion="Raise the limit only if elements are being dropped, or reduce how many lights, decals, and probes overlap the camera. The decal page says extra elements past the limit are not rendered.",
    setting="rendering/limits/cluster_builder/max_clustered_elements",
    tradeoff="A higher limit uses more cluster memory.",
    expected_effect="Stops clustered elements from being dropped. It does not claim a frame-time change.",
    verify_step="scan_scene",
    source=DECAL,
))

add(dict(
    id="renderer.gl_light_limit",
    category="renderer_platform",
    title="Compatibility light count is above max_renderable_lights",
    severity="high",
    heuristic=True,
    heuristic_rationale="The cap applies to the lights visible in a frame; the scan counts the scene's visible omni, spot and area lights, including any outside the camera view.",
    renderers=["gl_compatibility"], versions=BOTH, requires=["settings", "scene"],
    condition={"opengl_light_limit_exceeded": True},
    evidence="The scanned omni, spot or area light count is above rendering/limits/opengl/max_renderable_lights (default 32), which the Compatibility renderer applies to each light type on its own.",
    suggestion="Reduce lights or raise rendering/limits/opengl/max_renderable_lights. That setting is the Compatibility renderer cap, separate from max_lights_per_object (default 8).",
    setting="rendering/limits/opengl/max_renderable_lights",
    tradeoff="A higher cap costs more on the OpenGL path.",
    expected_effect="Lights above the cap become renderable. Measure draw calls afterward.",
    verify_step="scan_scene",
    source=PROJ,
))

add(dict(
    id="renderer.vrs_off_while_gpu_bound",
    category="renderer_platform",
    title="Variable rate shading is off while the frame is over a GPU budget",
    severity="low",
    heuristic=True,
    heuristic_rationale="The rule only suggests VRS when frame_timing says the frame is over budget and GPU-bound. It does not estimate the shading-rate saving.",
    renderers=FPM, versions=BOTH, requires=["settings", "frame"],
    condition=all_(
        seq("rendering/vrs/mode", 0),
        {"frame_over_budget": True},
        {"frame_bound": "gpu"},
    ),
    evidence="rendering/vrs/mode is 0 (Disabled) and frame_timing reports a GPU-bound frame over the target budget.",
    suggestion="Try rendering/vrs/mode Texture or XR on hardware that supports variable rate shading. The VRS page describes it as shading some pixels at a lower rate.",
    setting="rendering/vrs/mode",
    tradeoff="Lower shading rates soften shading, not geometric edges. A density texture has to be authored for Texture mode.",
    expected_effect="Can cut shading work on supported GPUs. Re-measure; do not assume a percentage.",
    verify_step="frame_timing",
    source=VRS,
))

# --- resolution -------------------------------------------------------------

add(dict(
    id="resolution.scale_above_one",
    category="resolution",
    title="3D render scale is above 1 (supersampling)",
    severity="high",
    renderers=ALL, versions=BOTH, requires=["settings"],
    condition=sgt("rendering/scaling_3d/scale", 1.0),
    evidence="rendering/scaling_3d/scale is above 1.0. The resolution scaling page says scales above 1.0 are supersample antialiasing and are not recommended for most games. Scale is per axis, so 2.0 shades four times the pixels.",
    suggestion="Set rendering/scaling_3d/scale to 1.0 and use MSAA or TAA instead of supersampling.",
    setting="rendering/scaling_3d/scale",
    tradeoff="Edges and specular aliasing lose the supersample filter.",
    expected_effect="Fewer shaded pixels. The page's tables show the megapixel change for common factors; this rule does not invent a frame-time percentage.",
    verify_step="frame_timing",
    source=SCALE,
    when_pass=["Render Opaque"],
    dedupe_key="render_scale",
))

add(dict(
    id="resolution.full_scale_gpu_over_budget",
    category="resolution",
    title="Full 3D resolution while the GPU frame is over budget",
    severity="high",
    heuristic=True,
    heuristic_rationale="Suggests leaving scale 1.0 only after frame_timing reports a GPU-bound over-budget frame. The resolution scaling page says lowering scale helps GPU-bound scenes. No target scale is prescribed.",
    renderers=ALL, versions=BOTH, requires=["settings", "frame"],
    condition=all_(
        seq("rendering/scaling_3d/scale", 1.0),
        {"frame_over_budget": True},
        {"frame_bound": "gpu"},
    ),
    evidence="rendering/scaling_3d/scale is 1.0 and frame_timing is GPU-bound over the target budget.",
    suggestion="Lower rendering/scaling_3d/scale below 1.0. The page lists 0.85, 0.75, 0.67, and 0.50 as example factors and notes that halving the factor cuts shaded pixels by four because the scale is per axis.",
    setting="rendering/scaling_3d/scale",
    tradeoff="The image is blurrier and aliases more unless FSR 1.0 or FSR 2.2 reconstructs it.",
    expected_effect="Less fragment work in GPU-bound scenes. Measure the new median before keeping a factor.",
    verify_step="frame_timing",
    source=SCALE,
    dedupe_key="render_scale",
))

add(dict(
    id="resolution.fsr2_native_over_budget",
    category="resolution",
    title="FSR 2.2 is on at native resolution while over budget",
    severity="high",
    renderers=FP, versions=BOTH, requires=["settings", "frame"],
    condition=all_(
        seq("rendering/scaling_3d/mode", 2),
        seq("rendering/scaling_3d/scale", 1.0),
        {"frame_over_budget": True},
    ),
    evidence="rendering/scaling_3d/mode is 2 (FSR 2.2) and scale is 1.0. The antialiasing page says FSR 2.2 at native resolution costs more than TAA.",
    suggestion="If the goal was antialiasing, use rendering/anti_aliasing/quality/use_taa instead. If the goal was performance, lower rendering/scaling_3d/scale or switch mode to 0 (bilinear) or 1 (FSR 1.0). Mode integers are Bilinear 0, FSR 1.0 1, FSR 2.2 2 on both 4.4 and 4.7 (4.7 also has Nearest 5).",
    setting="rendering/scaling_3d/mode",
    tradeoff="TAA ghosts more than FSR 2.2. Bilinear at a lower scale is blurrier.",
    expected_effect="Removes the native-resolution FSR 2.2 cost described in the antialiasing page.",
    verify_step="gpu_passes frames=60",
    source=AA,
    when_pass=["FSR2"],
    dedupe_key="fsr2",
))

add(dict(
    id="resolution.fsr2_enabled",
    category="resolution",
    title="FSR 2.2 upscaling is selected",
    severity="medium",
    renderers=FP, versions=BOTH, requires=["settings"],
    condition=all_(seq("rendering/scaling_3d/mode", 2), slt("rendering/scaling_3d/scale", 1.0)),
    evidence="rendering/scaling_3d/mode is 2 (FSR 2.2) and scale is below 1. The ProjectSettings hint marks FSR 2.2 as Slow, and the resolution scaling page says it is the slowest upscaler and provides its own temporal antialiasing.",
    suggestion="On a GPU that cannot afford FSR 2.2, set mode to 1 (FSR 1.0) or 0 (bilinear). The page says matching FSR 2.2 speed with FSR 1.0 needs a lower scale factor. use_taa is ignored while FSR 2.2 is the scaling mode.",
    setting="rendering/scaling_3d/mode",
    tradeoff="FSR 1.0 and bilinear reconstruct less detail and do not replace TAA.",
    expected_effect="A cheaper upscale pass. Compare the FSR2 timestamp.",
    verify_step="gpu_passes frames=60",
    source=SCALE,
    when_pass=["FSR2"],
    dedupe_key="fsr2",
))

add(dict(
    id="resolution.bilinear_while_upscaling",
    category="resolution",
    title="Upscaling with bilinear filtering",
    severity="low",
    kind="quality_up",
    renderers=FP, versions=BOTH, requires=["settings"],
    condition=all_(seq("rendering/scaling_3d/mode", 0), slt("rendering/scaling_3d/scale", 1.0)),
    evidence="Scale is below 1 and mode is 0 (bilinear). The page calls bilinear the fastest fallback and FSR slower but sharper. FSR is Forward+ only.",
    suggestion="If there is GPU headroom, try mode 1 (FSR 1.0) or 2 (FSR 2.2). Pair FSR 1.0 with TAA or MSAA; FSR 2.2 already antialiases.",
    setting="rendering/scaling_3d/mode",
    tradeoff="FSR costs more GPU time than bilinear.",
    expected_effect="Sharper upscale when the GPU can pay for it.",
    verify_step="frame_timing",
    source=SCALE,
))

add(dict(
    id="resolution.fsr_sharpness_extreme",
    category="resolution",
    title="FSR sharpness is at a documented extreme",
    severity="low",
    kind="quality_up",
    renderers=FP, versions=BOTH, requires=["settings"],
    condition=all_(
        any_(seq("rendering/scaling_3d/mode", 1), seq("rendering/scaling_3d/mode", 2)),
        any_(seq("rendering/scaling_3d/fsr_sharpness", 0.0), sgte("rendering/scaling_3d/fsr_sharpness", 2.0)),
    ),
    evidence="FSR is selected and fsr_sharpness is 0 or at least 2. The page says 0 is sharpest, 2 is least sharp, and the default 0.2 balances sharpness against extra aliasing. Lower values are sharper.",
    suggestion="Return rendering/scaling_3d/fsr_sharpness to 0.2 unless you measured aliasing or blur at that default.",
    setting="rendering/scaling_3d/fsr_sharpness",
    tradeoff="0.0 aliases more. 2.0 softens the image.",
    expected_effect="Restores the documented default sharpness. No frame-time claim.",
    verify_step="collect_metrics",
    source=SCALE,
))

add(dict(
    id="resolution.negative_mip_bias",
    category="resolution",
    title="Texture mipmap bias is negative",
    severity="medium",
    renderers=FPM, versions=BOTH, requires=["settings"],
    condition=slt("rendering/textures/default_filters/texture_mipmap_bias", 0.0),
    evidence="rendering/textures/default_filters/texture_mipmap_bias is below 0. The resolution scaling page says a negative bias samples higher mips farther away, which can cost performance, and recommends a manual offset between -0.5 and 0.",
    suggestion="Set texture_mipmap_bias back to 0 and let Godot apply its automatic bias when 3D scale is below 1 or when FXAA or TAA is on.",
    setting="rendering/textures/default_filters/texture_mipmap_bias",
    tradeoff="A less negative bias looks slightly blurrier on detailed textures.",
    expected_effect="Fewer high-resolution mip samples. Measure texture-heavy views.",
    verify_step="collect_metrics",
    source=SCALE,
))

# --- antialiasing -----------------------------------------------------------

add(dict(
    id="antialiasing.msaa_4x",
    category="antialiasing",
    title="MSAA 3D is 4×",
    severity="medium",
    renderers=ALL, versions=BOTH, requires=["settings"],
    condition=seq("rendering/anti_aliasing/quality/msaa_3d", 2),
    evidence="msaa_3d is 2. The hint is Disabled, 2×, 4×, 8×, so 2 is 4×. The antialiasing page says higher levels are significantly more demanding.",
    suggestion="Try 2× (value 1) or TAA (Forward+ only) if 4× shows up in the frame time.",
    setting="rendering/anti_aliasing/quality/msaa_3d",
    tradeoff="2× leaves more edge aliasing than 4×. TAA adds blur and ghosting.",
    expected_effect="Fewer coverage samples. Compare frame_timing.",
    verify_step="frame_timing",
    source=AA,
))

add(dict(
    id="antialiasing.msaa_8x",
    category="antialiasing",
    title="MSAA 3D is 8×",
    severity="high",
    renderers=ALL, versions=BOTH, requires=["settings"],
    condition=seq("rendering/anti_aliasing/quality/msaa_3d", 3),
    evidence="msaa_3d is 3 (8×). The antialiasing page says 8× MSAA is usually too demanding and recommends staying at 2× or 4× for modern visuals.",
    suggestion="Set rendering/anti_aliasing/quality/msaa_3d to 2 (4×) or 1 (2×).",
    setting="rendering/anti_aliasing/quality/msaa_3d",
    tradeoff="Edges alias more than at 8×.",
    expected_effect="A large drop in MSAA sample cost, as characterized on the antialiasing page, still to be measured in this project.",
    verify_step="frame_timing",
    source=AA,
))

add(dict(
    id="antialiasing.msaa_on_mobile_renderer",
    category="antialiasing",
    title="MSAA 3D is on with the Mobile renderer",
    severity="high",
    renderers=["mobile"], versions=BOTH, requires=["settings"],
    condition=all_(
        seq("rendering/renderer/rendering_method", "mobile"),
        sgt("rendering/anti_aliasing/quality/msaa_3d", 0),
    ),
    evidence="Mobile renderer with msaa_3d above 0. The antialiasing page says that on mobile, FXAA is usually the viable option and higher MSAA levels are unlikely to run smoothly.",
    suggestion="Set msaa_3d to 0 and set screen_space_aa to 1 (FXAA), which the page says is available on Mobile.",
    setting="rendering/anti_aliasing/quality/msaa_3d",
    tradeoff="FXAA is blurrier than MSAA and does little for specular aliasing.",
    expected_effect="Replaces MSAA with the low-cost post pass the page recommends for low-end GPUs.",
    verify_step="frame_timing",
    source=AA,
))

add(dict(
    id="antialiasing.msaa_and_taa",
    category="antialiasing",
    title="MSAA and TAA are both enabled",
    severity="medium",
    heuristic=True,
    heuristic_rationale="The antialiasing page says stacking techniques is usually unnecessary. It does not forbid the combination.",
    renderers=FP, versions=BOTH, requires=["settings"],
    condition=all_(
        sgt("rendering/anti_aliasing/quality/msaa_3d", 0),
        seq("rendering/anti_aliasing/quality/use_taa", True),
    ),
    evidence="msaa_3d is above 0 and use_taa is true. TAA is Forward+ only.",
    suggestion="Keep one of them. The page says TAA is the usual choice against specular aliasing, and MSAA can be added only when there is spare GPU time.",
    setting="rendering/anti_aliasing/quality/use_taa",
    tradeoff="Dropping MSAA leaves more geometric aliasing. Dropping TAA leaves more specular shimmer and adds no blur.",
    expected_effect="One less full antialiasing technique. Measure both ways.",
    verify_step="frame_timing",
    source=AA,
    when_pass=["TAA"],
    dedupe_key="taa",
))

add(dict(
    id="antialiasing.taa_enabled",
    category="antialiasing",
    title="TAA is enabled",
    severity="low",
    renderers=FP, versions=BOTH, requires=["settings"],
    condition=all_(
        seq("rendering/anti_aliasing/quality/use_taa", True),
        sneq("rendering/scaling_3d/mode", 2),
    ),
    evidence="use_taa is true and FSR 2.2 is not the scaling mode. The page says TAA has a medium cost, blurs in motion, and ghosts.",
    suggestion="Turn use_taa off and compare. If FSR 2.2 is enabled later, this setting is ignored because FSR 2.2 supplies temporal antialiasing.",
    setting="rendering/anti_aliasing/quality/use_taa",
    tradeoff="Specular and edge shimmer return.",
    expected_effect="Removes the TAA pass. Read the TAA timestamp when it is present.",
    verify_step="gpu_passes frames=60",
    source=AA,
    when_pass=["TAA"],
    dedupe_key="taa",
))

add(dict(
    id="antialiasing.fxaa_enabled",
    category="antialiasing",
    title="FXAA is the screen-space antialiasing mode",
    severity="low",
    renderers=FPM, versions=BOTH, requires=["settings"],
    condition=seq("rendering/anti_aliasing/quality/screen_space_aa", 1),
    evidence="screen_space_aa is 1. On 4.4 the hint is Disabled, FXAA. On 4.7 it is Disabled, FXAA, SMAA, so 1 is still FXAA. The page calls FXAA the fastest antialiasing method and a moderate blur.",
    suggestion="Leave FXAA if the GPU is tight. On Forward+ with headroom, TAA covers specular aliasing better.",
    setting="rendering/anti_aliasing/quality/screen_space_aa",
    tradeoff="TAA costs more and ghosts. Disabling FXAA exposes edges.",
    expected_effect="FXAA is a cheap fullscreen pass. Confirm with frame_timing rather than a fixed millisecond cost.",
    verify_step="frame_timing",
    source=AA,
))

add(dict(
    id="antialiasing.no_aa",
    category="antialiasing",
    title="No 3D antialiasing is enabled",
    severity="low",
    kind="quality_up",
    renderers=ALL, versions=BOTH, requires=["settings", "scene"],
    condition=all_(
        {"scene_gte": {"name": "geometry_3d_count", "value": 1}},
        seq("rendering/anti_aliasing/quality/msaa_3d", 0),
        seq("rendering/anti_aliasing/quality/use_taa", False),
        seq("rendering/anti_aliasing/quality/screen_space_aa", 0),
        {"setting_lte": {"path": "rendering/scaling_3d/scale", "value": 1.0}},
        sneq("rendering/scaling_3d/mode", 2),
    ),
    evidence="msaa_3d, use_taa, and screen_space_aa are off, scale is not above 1, and mode is not FSR 2.2. The antialiasing page treats that combination as no edge antialiasing.",
    suggestion="With GPU headroom: Forward+ can enable use_taa. Mobile can set screen_space_aa to 1 (FXAA). Compatibility can use msaa_3d 1 (2×). This is optional.",
    setting="rendering/anti_aliasing/quality/use_taa",
    tradeoff="Every method on the page costs GPU time or adds blur.",
    expected_effect="Smoother edges. Measure before shipping it.",
    verify_step="frame_timing",
    source=AA,
))

add(dict(
    id="antialiasing.roughness_limiter_off",
    category="antialiasing",
    title="Screen-space roughness limiter is off",
    severity="low",
    kind="quality_up",
    renderers=FPM, versions=BOTH, requires=["settings"],
    condition=seq("rendering/anti_aliasing/screen_space_roughness_limiter/enabled", False),
    evidence="The limiter is disabled. The antialiasing page says it is on by default, has a small performance impact, and reduces specular aliasing.",
    suggestion="Set rendering/anti_aliasing/screen_space_roughness_limiter/enabled to true. Defaults are amount 0.25 and limit 0.18.",
    setting="rendering/anti_aliasing/screen_space_roughness_limiter/enabled",
    tradeoff="A small extra cost, which the page says to skip only when specular aliasing is not a problem.",
    expected_effect="Less specular shimmer on detailed geometry. Not an edge antialiasing method.",
    verify_step="collect_metrics",
    source=AA,
))

add(dict(
    id="antialiasing.debanding_on",
    category="antialiasing",
    title="Debanding is enabled",
    severity="low",
    renderers=ALL, versions=BOTH, requires=["settings"],
    condition=seq("rendering/anti_aliasing/quality/use_debanding", True),
    evidence="rendering/anti_aliasing/quality/use_debanding is true. The default is false.",
    suggestion="Turn use_debanding off and check gradients. It is an extra fullscreen operation on top of the default off state.",
    setting="rendering/anti_aliasing/quality/use_debanding",
    tradeoff="Color banding can show in gradients and fog.",
    expected_effect="One less fullscreen step. Measure; the class reference does not publish a millisecond cost.",
    verify_step="frame_timing",
    source=PROJ,
))

add(dict(
    id="antialiasing.msaa_2d_high",
    category="antialiasing",
    title="2D MSAA is 4× or 8×",
    severity="medium",
    renderers=ALL, versions=BOTH, requires=["settings"],
    condition=sgte("rendering/anti_aliasing/quality/msaa_2d", 2),
    evidence="msaa_2d is 2 or 3 (4× or 8×). The hint matches 3D: Disabled, 2×, 4×, 8×. The default is 0.",
    suggestion="Set rendering/anti_aliasing/quality/msaa_2d to 0 or 1 unless 2D edges need the higher sample count.",
    setting="rendering/anti_aliasing/quality/msaa_2d",
    tradeoff="2D edges alias more.",
    expected_effect="Fewer 2D coverage samples. This setting is independent of msaa_3d.",
    verify_step="frame_timing",
    source=AA,
))

# --- shadows ----------------------------------------------------------------

add(dict(
    id="shadows.directional_size_above_default",
    category="shadows",
    title="Directional shadow map is larger than the default",
    severity="high",
    heuristic=True,
    heuristic_rationale="The default directional shadow size is 4096 (2048 on the .mobile override). Larger than 4096 is above that default, which stores more shadow texels.",
    renderers=ALL, versions=BOTH, requires=["settings"],
    condition=sgt("rendering/lights_and_shadows/directional_shadow/size", 4096),
    evidence="rendering/lights_and_shadows/directional_shadow/size is above 4096. The setting range is 256–16384 and the default is 4096.",
    suggestion="Set the size back to 4096, or 2048 on a mobile target. The lights page says the directional shadow atlas is shared by every DirectionalLight3D.",
    setting="rendering/lights_and_shadows/directional_shadow/size",
    tradeoff="Shadow edges on the directional light look blockier.",
    expected_effect="Fewer directional shadow texels. Read the shadow timestamps.",
    verify_step="gpu_passes frames=60",
    source=LIGHTS,
    when_pass=["Render Shadows", "Directional/SpotLight Shadows"],
    dedupe_key="dir_shadow_size",
))

add(dict(
    id="shadows.positional_atlas_above_default",
    category="shadows",
    title="Positional shadow atlas is larger than the default",
    severity="high",
    heuristic=True,
    heuristic_rationale="The positional atlas default is 4096. Values above that increase the atlas beyond the documented default.",
    renderers=ALL, versions=BOTH, requires=["settings"],
    condition=sgt("rendering/lights_and_shadows/positional_shadow/atlas_size", 4096),
    evidence="positional shadow atlas_size is above 4096 (default 4096, range 256–16384).",
    suggestion="Set rendering/lights_and_shadows/positional_shadow/atlas_size to 4096 or 2048.",
    setting="rendering/lights_and_shadows/positional_shadow/atlas_size",
    tradeoff="Omni and spot shadows lose resolution.",
    expected_effect="A smaller shadow atlas. Measure the shadow passes.",
    verify_step="gpu_passes frames=60",
    source=LIGHTS,
))

add(dict(
    id="shadows.directional_filter_high",
    category="shadows",
    title="Directional soft shadow filter is High or Ultra",
    severity="high",
    renderers=ALL, versions=BOTH, requires=["settings"],
    condition=sgte("rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality", 4),
    evidence="directional soft_shadow_filter_quality is 4 or 5. The hint is Hard, Soft Very Low, Soft Low, Soft Medium, Soft High (Slow), Soft Ultra (Slowest). The default is 2 (Soft Low).",
    suggestion="Set the filter to 2 (Soft Low) or 0 (Hard).",
    setting="rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality",
    tradeoff="Shadow penumbras look harder.",
    expected_effect="Fewer directional shadow filter taps, matching the Slow and Slowest labels.",
    verify_step="gpu_passes frames=60",
    source=LIGHTS,
))

add(dict(
    id="shadows.positional_filter_high",
    category="shadows",
    title="Positional soft shadow filter is High or Ultra",
    severity="high",
    renderers=ALL, versions=BOTH, requires=["settings"],
    condition=sgte("rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality", 4),
    evidence="positional soft_shadow_filter_quality is 4 or 5 (Soft High / Soft Ultra). The default is 2 (Soft Low). The .mobile override defaults to 0 (Hard).",
    suggestion="Set positional soft_shadow_filter_quality to 2 or 0.",
    setting="rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality",
    tradeoff="Omni and spot shadow edges look harder.",
    expected_effect="Cheaper positional shadow filtering.",
    verify_step="gpu_passes frames=60",
    source=LIGHTS,
))

add(dict(
    id="shadows.directional_32_bit",
    category="shadows",
    title="Directional shadows are not 16-bit",
    severity="medium",
    renderers=FPM, versions=BOTH, requires=["settings"],
    condition=seq("rendering/lights_and_shadows/directional_shadow/16_bits", False),
    evidence="directional_shadow/16_bits is false. The default is true.",
    suggestion="Set rendering/lights_and_shadows/directional_shadow/16_bits to true.",
    setting="rendering/lights_and_shadows/directional_shadow/16_bits",
    tradeoff="16-bit shadow maps have less depth precision, which can need a slightly higher bias.",
    expected_effect="Half the directional shadow depth bandwidth versus a 32-bit map. Measure shadows if acne appears.",
    verify_step="gpu_passes frames=60",
    source=PROJ,
))

add(dict(
    id="shadows.positional_32_bit",
    category="shadows",
    title="Positional shadow atlas is not 16-bit",
    severity="medium",
    renderers=FPM, versions=BOTH, requires=["settings"],
    condition=seq("rendering/lights_and_shadows/positional_shadow/atlas_16_bits", False),
    evidence="positional atlas_16_bits is false. The default is true.",
    suggestion="Set atlas_16_bits to true.",
    setting="rendering/lights_and_shadows/positional_shadow/atlas_16_bits",
    tradeoff="Same precision tradeoff as directional 16-bit maps.",
    expected_effect="Smaller positional shadow atlas bandwidth.",
    verify_step="collect_metrics",
    source=PROJ,
))

add(dict(
    id="shadows.quadrant_subdiv_high",
    category="shadows",
    title="A positional shadow quadrant allows 256 or more shadows",
    severity="medium",
    renderers=ALL, versions=BOTH, requires=["settings"],
    condition=any_(
        sgte("rendering/lights_and_shadows/positional_shadow/atlas_quadrant_0_subdiv", 5),
        sgte("rendering/lights_and_shadows/positional_shadow/atlas_quadrant_1_subdiv", 5),
        sgte("rendering/lights_and_shadows/positional_shadow/atlas_quadrant_2_subdiv", 5),
        sgte("rendering/lights_and_shadows/positional_shadow/atlas_quadrant_3_subdiv", 5),
    ),
    evidence="A quadrant subdiv index is 5 or 6. The hint is Disabled, 1, 4, 16, 64, 256, 1024 shadows. Defaults are 2, 2, 3, 4 (4, 4, 16, and 64 shadows).",
    suggestion="Lower that quadrant toward the defaults. Index 4 is 64 shadows, which is already the default for quadrant 3.",
    setting="rendering/lights_and_shadows/positional_shadow/atlas_quadrant_3_subdiv",
    tradeoff="Fewer shadows can be stored in that quadrant, so distant lights lose shadows sooner.",
    expected_effect="Less atlas subdivision work. The lights page describes lights popping when the shadow budget is exceeded.",
    verify_step="collect_metrics",
    source=LIGHTS,
))

add(dict(
    id="shadows.tighter_culling_off",
    category="shadows",
    title="Tighter shadow caster culling is off",
    severity="low",
    renderers=FPM, versions=BOTH, requires=["settings"],
    condition=seq("rendering/lights_and_shadows/tighter_shadow_caster_culling", False),
    evidence="tighter_shadow_caster_culling is false. The default is true.",
    suggestion="Set rendering/lights_and_shadows/tighter_shadow_caster_culling to true.",
    setting="rendering/lights_and_shadows/tighter_shadow_caster_culling",
    tradeoff="The default tighter test can cull casters the looser test would keep. Watch for missing shadow casters at the edges.",
    expected_effect="Fewer shadow casters submitted. Compare shadow draw calls in collect_metrics.",
    verify_step="collect_metrics",
    source=PROJ,
))

add(dict(
    id="shadows.directional_pssm4",
    category="shadows",
    title="A DirectionalLight3D uses 4 PSSM splits",
    severity="medium",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=all_(scgte("directional_shadow_count", 1), scgte("directional_pssm4_count", 1)),
    evidence="A shadow-casting DirectionalLight3D has directional_shadow_mode 2. The inspector hint is Orthogonal (Fast), PSSM 2 Splits (Average), PSSM 4 Splits (Slow). The node default printed from Godot 4.4 is 2.",
    suggestion="Set DirectionalLight3D.directional_shadow_mode to 1 (2 splits) or 0 (orthogonal). Also lower directional_shadow_max_distance if it is above the node default of 100.",
    node_property="DirectionalLight3D.directional_shadow_mode",
    offender_key="directional_pssm4",
    tradeoff="2 splits and orthogonal cover the same distance with less shadow resolution up close. The lights page describes PSSM as the fix for blocky distant shadows.",
    expected_effect="Fewer directional shadow cascades to render.",
    verify_step="scan_scene",
    source=LIGHTS,
    when_pass=["Render Shadows", "Directional/SpotLight Shadows"],
    dedupe_key="pssm4",
))

add(dict(
    id="shadows.directional_max_distance",
    category="shadows",
    title="Directional shadow max distance is above the node default",
    severity="medium",
    heuristic=True,
    heuristic_rationale="DirectionalLight3D.directional_shadow_max_distance defaults to 100 in Godot 4.4. Above that spreads the same shadow map over more world space.",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=scgte("directional_max_distance_above_default_count", 1),
    evidence="At least one DirectionalLight3D has directional_shadow_max_distance above 100.",
    suggestion="Lower directional_shadow_max_distance toward the distance that actually needs shadows.",
    node_property="DirectionalLight3D.directional_shadow_max_distance",
    offender_key="directional_max_distance",
    tradeoff="Beyond the new distance, directional shadows disappear.",
    expected_effect="Shadow texels cover a shorter range. The lights page says the shared atlas resolution drops when more of the frustum is shadowed.",
    verify_step="scan_scene",
    source=LIGHTS,
))

add(dict(
    id="shadows.omni_cube",
    category="shadows",
    title="Omni shadows use cube maps",
    severity="medium",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=scgte("omni_shadow_cube_count", 1),
    evidence="shadow_enabled OmniLight3D nodes use omni_shadow_mode 1 (Cube). Godot 4.4's default is Cube. The lights page says dual paraboloid renders quickly and cube is more correct but slower.",
    suggestion="Set OmniLight3D.omni_shadow_mode to 0 (Dual Paraboloid) on lights where the deformation is acceptable.",
    node_property="OmniLight3D.omni_shadow_mode",
    offender_key="omni_shadow_cube",
    tradeoff="Dual paraboloid deforms the shadow.",
    expected_effect="A cheaper omni shadow algorithm, as described on the lights page.",
    verify_step="scan_scene",
    source=LIGHTS,
    when_pass=["Render OmniLight Shadows", "mobile:Render Shadows"],
    dedupe_key="omni_cube",
))

add(dict(
    id="shadows.omni_shadow_count",
    category="shadows",
    title="More than one omni light casts shadows",
    severity="high",
    heuristic=True,
    heuristic_rationale="Two or more shadow-casting omni lights is the cut. Each one renders its own shadow map. The number is not a Godot budget.",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=scgte("omni_shadow_count", 2),
    evidence="The scan found at least two OmniLight3D nodes with shadow_enabled.",
    suggestion="Disable shadow_enabled on omni lights that do not need grounded contact, or turn on Light3D.distance_fade_enabled so distant ones drop their shadows.",
    node_property="Light3D.shadow_enabled",
    offender_key="omni_shadows",
    tradeoff="Those lights no longer cast real-time shadows.",
    expected_effect="Fewer omni shadow maps. The optimizing-3D page calls multiple real-time shadow lights especially expensive.",
    verify_step="scan_scene",
    source=OPT3D,
    when_pass=["Render OmniLight Shadows", "mobile:Render Shadows"],
    dedupe_key="omni_count",
))

add(dict(
    id="shadows.spot_shadow_count",
    category="shadows",
    title="More than one spot light casts shadows",
    severity="medium",
    heuristic=True,
    heuristic_rationale="Two or more shadow-casting spot lights is a review cut, not an engine limit.",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=scgte("spot_shadow_count", 2),
    evidence="At least two SpotLight3D nodes have shadow_enabled.",
    suggestion="Disable shadows on the spots that only need a projected cookie, and enable Light3D.distance_fade_enabled on the rest.",
    node_property="Light3D.shadow_enabled",
    offender_key="spot_shadows",
    tradeoff="Those spots stop casting shadows.",
    expected_effect="Fewer spot shadow passes.",
    verify_step="scan_scene",
    source=OPT3D,
    when_pass=["Render Shadows", "Directional/SpotLight Shadows"],
))

add(dict(
    id="shadows.no_distance_fade",
    category="shadows",
    title="Shadow-casting positional lights have no distance fade",
    severity="medium",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=scgte("positional_shadow_without_distance_fade_count", 1),
    evidence="Omni or spot lights cast shadows with distance_fade_enabled left off. The lights page says distance fade reduces popping and improves performance when many lights compete for the atlas.",
    suggestion="Enable Light3D.distance_fade_enabled and set distance_fade_shadow inside the light's useful range.",
    node_property="Light3D.distance_fade_enabled",
    offender_key="positional_shadow_no_fade",
    tradeoff="Shadows fade out before the light itself does, over distance_fade_length.",
    expected_effect="Distant lights drop out of the shadow atlas.",
    verify_step="scan_scene",
    source=LIGHTS,
))

add(dict(
    id="shadows.light_size_soft",
    category="shadows",
    title="Shadow lights use size or angular distance",
    severity="medium",
    renderers=FPM, versions=BOTH, requires=["scene"],
    condition=scgte("light_size_shadow_count", 1),
    evidence="A shadow-casting light has light_size or light_angular_distance above 0. The lights page says blur then softens contact-hardening shadows from Size or Angular Distance, which is a different path from a hard shadow map.",
    suggestion="Set light_size and light_angular_distance to 0 on lights that do not need contact-hardening shadows, and lower shadow_blur.",
    node_property="Light3D.light_size",
    offender_key="light_size_shadows",
    tradeoff="Penumbra width from the light's physical size goes away.",
    expected_effect="Harder, cheaper shadows for those lights.",
    verify_step="scan_scene",
    source=LIGHTS,
))

add(dict(
    id="shadows.shadow_2d_atlas",
    category="shadows",
    title="2D shadow atlas is larger than the default",
    severity="medium",
    heuristic=True,
    heuristic_rationale="rendering/2d/shadow_atlas/size defaults to 2048. Above that is more 2D shadow texels than the default.",
    renderers=ALL, versions=BOTH, requires=["settings"],
    condition=sgt("rendering/2d/shadow_atlas/size", 2048),
    evidence="rendering/2d/shadow_atlas/size is above 2048 (range 128–16384, default 2048).",
    suggestion="Set the 2D shadow atlas back to 2048 or lower.",
    setting="rendering/2d/shadow_atlas/size",
    tradeoff="2D shadows look softer or blockier at a smaller atlas.",
    expected_effect="Less 2D shadow-map memory and fill.",
    verify_step="collect_metrics",
    source=D2,
))

add(dict(
    id="shadows.double_sided_casters",
    category="shadows",
    title="Meshes cast double-sided shadows",
    severity="low",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=scgte("mesh_double_sided_shadow_count", 1),
    evidence="GeometryInstance3D.cast_shadow is Double-Sided (enum Off, On, Double-Sided, Shadows Only).",
    suggestion="Use cast_shadow On unless the mesh is a single-sided card that must shadow from both sides.",
    node_property="GeometryInstance3D.cast_shadow",
    offender_key="double_sided_shadows",
    tradeoff="Back faces stop casting shadows.",
    expected_effect="Fewer shadow triangles for those meshes.",
    verify_step="scan_scene",
    source=GEO,
))

# --- lights -----------------------------------------------------------------

add(dict(
    id="lights.many_realtime",
    category="lights",
    title="The scene has many real-time lights",
    severity="medium",
    heuristic=True,
    heuristic_rationale="Eight or more Light3D nodes is a review cut. The optimizing-3D page says real-time lights are costly and does not publish this count.",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=scgte("light_count", 8),
    evidence="The scan counted at least eight DirectionalLight3D, OmniLight3D, or SpotLight3D nodes.",
    suggestion="Bake static lights with LightmapGI, or disable light_bake_mode's dynamic contribution by leaving lights Static and using a lightmap. Narrow omni_range and spot_range so fewer lights overlap.",
    node_property="Light3D.light_bake_mode",
    offender_key="lights",
    tradeoff="Baked lights do not move every frame. Dynamic lights (bake mode Dynamic) stay expensive.",
    expected_effect="Fewer real-time light evaluations. The optimizing-3D page recommends baked lighting especially on mobile.",
    verify_step="scan_scene",
    source=OPT3D,
))

add(dict(
    id="lights.omni_range",
    category="lights",
    title="Omni range is far above the node default",
    severity="low",
    heuristic=True,
    heuristic_rationale="OmniLight3D.omni_range defaults to 5. A range of 20 or more is four times that default and increases overlap; it is not an engine error.",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=scgte("omni_range_large_count", 1),
    evidence="At least one OmniLight3D has omni_range >= 20.",
    suggestion="Shrink omni_range to the distance the light actually covers.",
    node_property="OmniLight3D.omni_range",
    offender_key="omni_range_large",
    tradeoff="Objects outside the new range are no longer lit by that omni.",
    expected_effect="Less light overlap. The lights page says overlapping lights cost more and can exceed the shadow atlas.",
    verify_step="scan_scene",
    source=LIGHTS,
))

add(dict(
    id="lights.wide_spot",
    category="lights",
    title="Spot angle is very wide",
    severity="low",
    heuristic=True,
    heuristic_rationale="spot_angle of 120 degrees or more is far above the SpotLight3D default of 45. A wide cone behaves more like an omni for culling.",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=scgte("spot_angle_wide_count", 1),
    evidence="A SpotLight3D has spot_angle >= 120. The property range is 0–180 and the default is 45.",
    suggestion="Narrow spot_angle, or replace the light with an OmniLight3D if the cone is intentional.",
    node_property="SpotLight3D.spot_angle",
    offender_key="spot_wide",
    tradeoff="A narrower cone leaves more of the scene unlit by that spot.",
    expected_effect="Tighter light culling.",
    verify_step="scan_scene",
    source=LIGHT3D,
))

add(dict(
    id="lights.physical_units",
    category="lights",
    title="Physical light units are enabled",
    severity="info",
    kind="info",
    renderers=ALL, versions=BOTH, requires=["settings"],
    condition=seq("rendering/lights_and_shadows/use_physical_light_units", True),
    evidence="use_physical_light_units is true. The default is false. Intensities are then lux or lumens on Light3D.",
    suggestion="No change is required. Artists must set light_intensity_lux or light_intensity_lumens, or lights look black. This is a workflow note, not a cost estimate.",
    setting="rendering/lights_and_shadows/use_physical_light_units",
    tradeoff="Turning it off returns to the energy multiplier.",
    expected_effect="None claimed.",
    verify_step="collect_metrics",
    source=LIGHTS,
))

add(dict(
    id="lights.projector_filter_aniso",
    category="lights",
    title="Light projector filter uses anisotropic samples",
    severity="low",
    renderers=FPM, versions=BOTH, requires=["settings"],
    condition=sgte("rendering/textures/light_projectors/filter", 4),
    evidence="light projector filter index is 4 or higher. The hint starts Nearest, Linear, Nearest Mipmap, Linear Mipmap, then anisotropic modes marked Average. The default index is 3 (Linear Mipmap).",
    suggestion="Set rendering/textures/light_projectors/filter to 3.",
    setting="rendering/textures/light_projectors/filter",
    tradeoff="Projected cookies shimmer more at grazing angles.",
    expected_effect="Cheaper projector sampling.",
    verify_step="collect_metrics",
    source=PROJ,
))

add(dict(
    id="lights.negative",
    category="lights",
    title="Negative lights are in the scene",
    severity="info",
    kind="info",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=scgte("negative_light_count", 1),
    evidence="At least one Light3D has light_negative enabled.",
    suggestion="Negative lights still run the real-time light path. Remove them if they were only for a prototype.",
    node_property="Light3D.light_negative",
    offender_key="negative_lights",
    tradeoff="Those subtractive lights disappear.",
    expected_effect="Fewer lights. No separate negative-light budget is documented.",
    verify_step="scan_scene",
    source=LIGHT3D,
))

add(dict(
    id="lights.no_lightmap_with_many_lights",
    category="lights",
    title="Many real-time lights and no LightmapGI",
    severity="medium",
    heuristic=True,
    heuristic_rationale="Fires when the light count is at least 8 and the scan finds no LightmapGI. The optimizing-3D page recommends baked lighting; it does not define this count.",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=all_(scgte("light_count", 8), sceq("lightmap_gi_count", 0)),
    evidence="At least eight Light3D nodes and no LightmapGI node.",
    suggestion="Add a LightmapGI and set static lights' light_bake_mode to Static. The lightmap page covers bake quality versus bake time.",
    node_property="LightmapGI",
    tradeoff="Bake time, and indirect light will not follow moving geometry unless you also use SDFGI or VoxelGI.",
    expected_effect="Static lights can stop being evaluated in real time after a bake.",
    verify_step="scan_scene",
    source=LMAPDOC,
))

add(dict(
    id="lights.editor_only_ignored",
    category="lights",
    title="Realtime lights are marked editor-only",
    severity="info",
    kind="info",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=scgte("editor_only_light_count", 1),
    evidence="Light3D.editor_only is true on at least one light, so the running game does not render it.",
    suggestion="Turn editor_only off if the light was meant to ship.",
    node_property="Light3D.editor_only",
    offender_key="editor_only_lights",
    tradeoff="The light starts costing real-time lighting in game.",
    expected_effect="Corrects a hidden light. Not a performance cut.",
    verify_step="scan_scene",
    source=LIGHT3D,
))

# --- GI ---------------------------------------------------------------------

add(dict(
    id="gi.sdfgi_enabled",
    category="gi",
    title="SDFGI is enabled",
    severity="high",
    renderers=FP, versions=BOTH, requires=["scene"],
    condition=sceq("env_sdfgi", 1),
    evidence="Environment.sdfgi_enabled is true. The SDFGI page says the effect is Forward+ only.",
    suggestion="Turn sdfgi_enabled off and compare, or lower cascades and probe rays. Use a LightmapGI for static scenes.",
    node_property="Environment.sdfgi_enabled",
    offender_key="environments",
    tradeoff="Dynamic indirect light from SDFGI disappears.",
    expected_effect="Removes the SDFGI passes. Read Render SDFGI when the game is running.",
    verify_step="gpu_passes frames=60",
    source=SDFGI,
    when_pass=["Render SDFGI"],
    dedupe_key="sdfgi",
))

add(dict(
    id="gi.sdfgi_cascades",
    category="gi",
    title="SDFGI cascade count is above the Environment default",
    severity="high",
    renderers=FP, versions=BOTH, requires=["scene"],
    condition=all_(sceq("env_sdfgi", 1), scgte("env_sdfgi_cascades", 5)),
    evidence="sdfgi_cascades is above 4. The Environment default printed from Godot 4.4 is 4, and the property range is 1–8. The SDFGI page says more cascades are significantly more expensive on the CPU and GPU.",
    suggestion="Set Environment.sdfgi_cascades to 4 or fewer.",
    node_property="Environment.sdfgi_cascades",
    tradeoff="GI distance or detail drops.",
    expected_effect="Fewer SDFGI cascades, which the page calls out as expensive.",
    verify_step="scan_scene",
    source=SDFGI,
    dedupe_key="sdfgi",
))

add(dict(
    id="gi.sdfgi_occlusion",
    category="gi",
    title="SDFGI use-occlusion is on",
    severity="medium",
    renderers=FP, versions=BOTH, requires=["scene"],
    condition=all_(sceq("env_sdfgi", 1), sceq("env_sdfgi_use_occlusion", 1)),
    evidence="sdfgi_use_occlusion is true. The SDFGI page says this throws extra rays to hide leaks and has a performance cost, so it should be enabled only when leaks are visible.",
    suggestion="Set Environment.sdfgi_use_occlusion to false unless light leaks are visible.",
    node_property="Environment.sdfgi_use_occlusion",
    tradeoff="Light leaks through thin walls can return.",
    expected_effect="Fewer SDFGI occlusion rays.",
    verify_step="scan_scene",
    source=SDFGI,
))

add(dict(
    id="gi.sdfgi_probe_rays",
    category="gi",
    title="SDFGI probe ray count is at the slow end",
    severity="high",
    renderers=FP, versions=BOTH, requires=["settings", "scene"],
    condition=all_(sceq("env_sdfgi", 1), sgte("rendering/global_illumination/sdfgi/probe_ray_count", 4)),
    evidence="probe_ray_count index is 4 or 5. The hint is 8, 16, 32, 64, 96, 128 (Slowest). The default index is 1 (16 rays).",
    suggestion="Set rendering/global_illumination/sdfgi/probe_ray_count to 1 (16) or 2 (32).",
    setting="rendering/global_illumination/sdfgi/probe_ray_count",
    tradeoff="Indirect light is noisier and converges with less detail.",
    expected_effect="Fewer rays per probe. The SDFGI page ties ray count to quality and cost.",
    verify_step="collect_metrics",
    source=SDFGI,
))

add(dict(
    id="gi.sdfgi_frames_to_converge",
    category="gi",
    title="SDFGI frames-to-converge is the high-latency end",
    severity="medium",
    renderers=FP, versions=BOTH, requires=["settings", "scene"],
    condition=all_(sceq("env_sdfgi", 1), sgte("rendering/global_illumination/sdfgi/frames_to_converge", 5)),
    evidence="frames_to_converge index is 5. The hint lists 5, 10, 15, 20, 25, 30 frames, and the stored default is 5, which is the last entry (30, more latency, higher quality). The SDFGI page says higher values take longer to converge.",
    suggestion="Lower the index (for example to 2 or 3) so GI converges in fewer frames after a light change.",
    setting="rendering/global_illumination/sdfgi/frames_to_converge",
    tradeoff="The converged result is lower quality, which the hint states.",
    expected_effect="Less latency before GI settles. Not a single-frame GPU cut.",
    verify_step="collect_metrics",
    source=SDFGI,
))

add(dict(
    id="gi.sdfgi_light_update_slow",
    category="gi",
    title="SDFGI updates dynamic lights every frame",
    severity="medium",
    renderers=FP, versions=BOTH, requires=["settings", "scene"],
    condition=all_(sceq("env_sdfgi", 1), seq("rendering/global_illumination/sdfgi/frames_to_update_lights", 0)),
    evidence="frames_to_update_lights is 0. The hint is 1 (Slower), 2, 4, 8, 16 (Faster). The default index is 2, which is 4 frames. The SDFGI page says fast-moving lights can use 16 to improve performance.",
    suggestion="Raise the index toward 2 (4) or 4 (16).",
    setting="rendering/global_illumination/sdfgi/frames_to_update_lights",
    tradeoff="Dynamic lights show up in GI a few frames later.",
    expected_effect="SDFGI light updates happen less often.",
    verify_step="collect_metrics",
    source=SDFGI,
))

add(dict(
    id="gi.half_resolution_off",
    category="gi",
    title="GI half-resolution buffer is off while GI is enabled",
    severity="medium",
    renderers=FP, versions=BOTH, requires=["settings", "scene"],
    condition=all_(
        seq("rendering/global_illumination/gi/use_half_resolution", False),
        any_(sceq("env_sdfgi", 1), scgte("voxel_gi_count", 1)),
    ),
    evidence="gi/use_half_resolution is false (the default) and SDFGI or VoxelGI is in use. The SDFGI and VoxelGI pages say enabling it renders the GI buffer at half resolution.",
    suggestion="Set rendering/global_illumination/gi/use_half_resolution to true.",
    setting="rendering/global_illumination/gi/use_half_resolution",
    tradeoff="Indirect light is blurrier. The pages give 3840×2160 rendering a 1920×1080 GI buffer as the example.",
    expected_effect="A smaller GI buffer. Measure Render SDFGI or the voxel GI cost after the change.",
    verify_step="gpu_passes frames=60",
    source=SDFGI,
))

add(dict(
    id="gi.voxel_quality_high",
    category="gi",
    title="VoxelGI cone tracing is set to High",
    severity="medium",
    renderers=FPM, versions=BOTH, requires=["settings", "scene"],
    condition=all_(scgte("voxel_gi_count", 1), seq("rendering/global_illumination/voxel_gi/quality", 1)),
    evidence="A VoxelGI node is present and voxel_gi/quality is 1. The hint is Low (4 cones) and High (6 cones). The default is 0. The VoxelGI page says High uses 6 taps instead of 4.",
    suggestion="Set rendering/global_illumination/voxel_gi/quality to 0.",
    setting="rendering/global_illumination/voxel_gi/quality",
    tradeoff="Ambient occlusion from voxel cones is less pronounced.",
    expected_effect="Four cone taps instead of six.",
    verify_step="collect_metrics",
    source=VOXDOC,
))

add(dict(
    id="gi.voxel_subdiv",
    category="gi",
    title="VoxelGI subdivision is above the default 128",
    severity="high",
    renderers=FPM, versions=BOTH, requires=["scene"],
    condition=scgte("voxel_gi_subdiv_above_default_count", 1),
    evidence="VoxelGI.subdiv index is 2 or 3 (256 or 512). The enum is 64, 128, 256, 512 and the Godot 4.4 default is 1 (128). The VoxelGI page says bake time depends on the subdivision.",
    suggestion="Set VoxelGI.subdiv to 1 (128) or 0 (64) and bake again.",
    node_property="VoxelGI.subdiv",
    offender_key="voxel_subdiv",
    tradeoff="Coarser voxels and a longer visual leak through thin walls.",
    expected_effect="Less voxel memory and a shorter bake. The page tells you not to make the VoxelGI extents larger than necessary.",
    verify_step="scan_scene",
    source=VOXDOC,
))

add(dict(
    id="gi.voxel_count",
    category="gi",
    title="More than one VoxelGI is in the scene",
    severity="medium",
    heuristic=True,
    heuristic_rationale="Two VoxelGI nodes means two baked volumes. The page does not forbid more than one; overlapping volumes still both store data.",
    renderers=FPM, versions=BOTH, requires=["scene"],
    condition=scgte("voxel_gi_count", 2),
    evidence="The scan found at least two VoxelGI nodes.",
    suggestion="Cover the play space with one VoxelGI where you can. Keep each volume's size tight.",
    node_property="VoxelGI",
    offender_key="voxel_gi",
    tradeoff="A single volume cannot follow the camera. Large extents lower quality, which the page warns about.",
    expected_effect="Fewer voxel volumes to sample.",
    verify_step="scan_scene",
    source=VOXDOC,
))

add(dict(
    id="gi.probe_always",
    category="gi",
    title="A ReflectionProbe updates every frame",
    severity="high",
    renderers=FPM, versions=BOTH, requires=["scene"],
    condition=scgte("reflection_probe_always_count", 1),
    evidence="ReflectionProbe.update_mode is Always (1). The reflection probe page says Once renders when the probe moves and is much faster, and Always re-renders every frame. The default is Once (0).",
    suggestion="Set update_mode to Once unless the reflected scene moves every frame.",
    node_property="ReflectionProbe.update_mode",
    offender_key="probes_always",
    tradeoff="Reflections stay frozen until the probe moves.",
    expected_effect="The probe stops re-rendering the scene every frame.",
    verify_step="scan_scene",
    source=REFL,
))

add(dict(
    id="gi.probe_shadows",
    category="gi",
    title="A ReflectionProbe renders real-time shadows",
    severity="medium",
    renderers=FPM, versions=BOTH, requires=["scene"],
    condition=scgte("reflection_probe_shadow_count", 1),
    evidence="ReflectionProbe.enable_shadows is true. The page says this improves quality at a performance cost and should stay off for the Once update mode in most cases. The default is false.",
    suggestion="Set ReflectionProbe.enable_shadows to false.",
    node_property="ReflectionProbe.enable_shadows",
    offender_key="probes_shadows",
    tradeoff="Reflections lose real-time shadow detail.",
    expected_effect="The probe render skips real-time shadow maps.",
    verify_step="scan_scene",
    source=REFL,
))

add(dict(
    id="gi.reflection_atlas_size",
    category="gi",
    title="Reflection atlas size is above the default",
    severity="medium",
    heuristic=True,
    heuristic_rationale="reflection_size defaults to 256. Above that stores a larger reflection atlas than the default.",
    renderers=FPM, versions=BOTH, requires=["settings"],
    condition=sgt("rendering/reflections/reflection_atlas/reflection_size", 256),
    evidence="reflection_size is above 256. On 4.4 the range starts at 0; on 4.7 it starts at 4. The default is 256 on both.",
    suggestion="Set rendering/reflections/reflection_atlas/reflection_size to 256.",
    setting="rendering/reflections/reflection_atlas/reflection_size",
    tradeoff="Reflection probes look softer.",
    expected_effect="Less reflection-atlas memory.",
    verify_step="collect_metrics",
    source=REFL,
))

add(dict(
    id="gi.reflection_count",
    category="gi",
    title="Reflection atlas count is above the default",
    severity="low",
    heuristic=True,
    heuristic_rationale="reflection_count defaults to 64. A higher count reserves more atlas slots than the default.",
    renderers=FPM, versions=BOTH, requires=["settings"],
    condition=sgt("rendering/reflections/reflection_atlas/reflection_count", 64),
    evidence="reflection_count is above 64.",
    suggestion="Lower reflection_count toward 64 unless probes are being dropped.",
    setting="rendering/reflections/reflection_atlas/reflection_count",
    tradeoff="Fewer probes can be resident.",
    expected_effect="A smaller reflection atlas allocation.",
    verify_step="collect_metrics",
    source=PROJ,
))

add(dict(
    id="gi.ggx_samples",
    category="gi",
    title="Sky GGX sample count is above the default",
    severity="medium",
    renderers=FPM, versions=BOTH, requires=["settings"],
    condition=sgt("rendering/reflections/sky_reflections/ggx_samples", 32),
    evidence="ggx_samples is above 32. The default is 32 (16 on the .mobile override). The Sky class points at this setting when reflections sparkle.",
    suggestion="Set ggx_samples back to 32 unless specular fireflies are visible.",
    setting="rendering/reflections/sky_reflections/ggx_samples",
    tradeoff="Rough sky reflections sparkle more.",
    expected_effect="Fewer GGX samples in the sky radiance filter.",
    verify_step="collect_metrics",
    source=SKY,
))

add(dict(
    id="gi.ssil_enabled",
    category="gi",
    title="Screen-space indirect lighting is enabled",
    severity="high",
    renderers=FP, versions=BOTH, requires=["scene"],
    condition=sceq("env_ssil", 1),
    evidence="Environment.ssil_enabled is true. The environment page says SSIL is Forward+ only.",
    suggestion="Turn ssil_enabled off, or lower rendering/environment/ssil/quality (default index 2, Medium) and keep half_size true.",
    node_property="Environment.ssil_enabled",
    tradeoff="Small-scale bounced light from SSIL disappears.",
    expected_effect="Removes the SSIL pass. Read Process SSIL.",
    verify_step="gpu_passes frames=60",
    source=ENV,
    when_pass=["Process SSIL"],
    dedupe_key="ssil",
))

add(dict(
    id="gi.lightmap_bicubic_off",
    category="gi",
    title="Lightmap bicubic filter is off",
    severity="low",
    kind="quality_up",
    renderers=ALL, versions=BOTH, requires=["settings", "scene"],
    condition=all_(scgte("lightmap_gi_count", 1), seq("rendering/lightmapping/lightmap_gi/use_bicubic_filter", False)),
    evidence="A LightmapGI is present and use_bicubic_filter is false. The default is true.",
    suggestion="Turn rendering/lightmapping/lightmap_gi/use_bicubic_filter back on if lightmaps look blocky and there is GPU headroom.",
    setting="rendering/lightmapping/lightmap_gi/use_bicubic_filter",
    tradeoff="Bicubic filtering costs more taps at sample time.",
    expected_effect="Smoother lightmaps. Measure if the scene is already over budget.",
    verify_step="collect_metrics",
    source=LMAPDOC,
))

# --- post -------------------------------------------------------------------

add(dict(
    id="post.ssao_enabled",
    category="post",
    title="SSAO is enabled",
    severity="high",
    renderers=FP, versions=BOTH, requires=["scene"],
    condition=sceq("env_ssao", 1),
    evidence="Environment.ssao_enabled is true. The environment page says SSAO is Forward+ only and only affects ambient light.",
    suggestion="Turn ssao_enabled off and compare contact darkening. If you keep it, leave rendering/environment/ssao/half_size true (the default) and avoid quality indexes 3 and 4 (High, Ultra).",
    node_property="Environment.ssao_enabled",
    tradeoff="Corners and creases lose the screen-space ambient darkening.",
    expected_effect="Removes Process SSAO. No millisecond cost is assumed.",
    verify_step="gpu_passes frames=60",
    source=ENV,
    when_pass=["Process SSAO"],
    dedupe_key="ssao",
))

add(dict(
    id="post.ssao_quality_high",
    category="post",
    title="SSAO quality is High or Ultra",
    severity="high",
    renderers=FP, versions=BOTH, requires=["settings", "scene"],
    condition=all_(sceq("env_ssao", 1), sgte("rendering/environment/ssao/quality", 3)),
    evidence="ssao/quality is 3 or 4. The hint is Very Low, Low, Medium, High (Slow), Ultra (Custom). The default is 2 (Medium).",
    suggestion="Set rendering/environment/ssao/quality to 2 or lower.",
    setting="rendering/environment/ssao/quality",
    tradeoff="SSAO banding and noise increase.",
    expected_effect="A cheaper SSAO quality level than the ones labeled Slow and Ultra.",
    verify_step="gpu_passes frames=60",
    source=PROJ,
    dedupe_key="ssao",
))

add(dict(
    id="post.ssao_full_res",
    category="post",
    title="SSAO half-size is off",
    severity="medium",
    renderers=FP, versions=BOTH, requires=["settings", "scene"],
    condition=all_(sceq("env_ssao", 1), seq("rendering/environment/ssao/half_size", False)),
    evidence="ssao/half_size is false. The default is true.",
    suggestion="Set rendering/environment/ssao/half_size to true.",
    setting="rendering/environment/ssao/half_size",
    tradeoff="SSAO is blurrier, which is the default look.",
    expected_effect="SSAO runs at half resolution.",
    verify_step="gpu_passes frames=60",
    source=PROJ,
))

add(dict(
    id="post.ssao_blur_passes",
    category="post",
    title="SSAO blur passes are above the default",
    severity="low",
    heuristic=True,
    heuristic_rationale="ssao/blur_passes defaults to 2 (range 0–6). More passes than the default is extra blur work.",
    renderers=FP, versions=BOTH, requires=["settings", "scene"],
    condition=all_(sceq("env_ssao", 1), sgt("rendering/environment/ssao/blur_passes", 2)),
    evidence="ssao/blur_passes is above 2.",
    suggestion="Set blur_passes back to 2.",
    setting="rendering/environment/ssao/blur_passes",
    tradeoff="SSAO noise is less smoothed.",
    expected_effect="Fewer SSAO blur iterations.",
    verify_step="collect_metrics",
    source=PROJ,
))

add(dict(
    id="post.ssil_quality_high",
    category="post",
    title="SSIL quality is High or Ultra",
    severity="high",
    renderers=FP, versions=BOTH, requires=["settings", "scene"],
    condition=all_(sceq("env_ssil", 1), sgte("rendering/environment/ssil/quality", 3)),
    evidence="ssil/quality is 3 or 4 (High / Ultra). The default is 2 (Medium). blur_passes defaults to 4 and half_size defaults to true.",
    suggestion="Set ssil/quality to 2 or lower.",
    setting="rendering/environment/ssil/quality",
    tradeoff="Indirect detail gets noisier.",
    expected_effect="A cheaper SSIL quality level.",
    verify_step="gpu_passes frames=60",
    source=PROJ,
    dedupe_key="ssil",
))

add(dict(
    id="post.ssil_full_res",
    category="post",
    title="SSIL half-size is off",
    severity="medium",
    renderers=FP, versions=BOTH, requires=["settings", "scene"],
    condition=all_(sceq("env_ssil", 1), seq("rendering/environment/ssil/half_size", False)),
    evidence="ssil/half_size is false. The default is true.",
    suggestion="Set rendering/environment/ssil/half_size to true.",
    setting="rendering/environment/ssil/half_size",
    tradeoff="SSIL softens, which matches the default.",
    expected_effect="SSIL runs at half resolution.",
    verify_step="collect_metrics",
    source=PROJ,
))

add(dict(
    id="post.ssr_enabled",
    category="post",
    title="Screen-space reflections are enabled",
    severity="high",
    renderers=FP, versions=BOTH, requires=["scene"],
    condition=sceq("env_ssr", 1),
    evidence="Environment.ssr_enabled is true. The environment page says SSR is Forward+ only.",
    suggestion="Turn ssr_enabled off or lower ssr_max_steps (Environment default 64, range 1–512).",
    node_property="Environment.ssr_enabled",
    tradeoff="Reflections fall back to reflection probes and the sky.",
    expected_effect="Removes the screen-space reflection pass.",
    verify_step="gpu_passes frames=60",
    source=ENV,
    when_pass=["Screen-Space Reflections", "Process SSR"],
    dedupe_key="ssr",
))

add(dict(
    id="post.ssr_steps",
    category="post",
    title="SSR max steps is above the Environment default",
    severity="medium",
    heuristic=True,
    heuristic_rationale="Environment.ssr_max_steps defaults to 64 in Godot 4.4. Above 64 traces more steps than that default.",
    renderers=FP, versions=BOTH, requires=["scene"],
    condition=all_(sceq("env_ssr", 1), scgte("env_ssr_max_steps", 65)),
    evidence="ssr_max_steps is above 64.",
    suggestion="Set Environment.ssr_max_steps to 64 or below.",
    node_property="Environment.ssr_max_steps",
    tradeoff="Reflections cut off sooner on grazing surfaces.",
    expected_effect="Shorter SSR traces.",
    verify_step="scan_scene",
    source=ENVCLS,
    dedupe_key="ssr_steps",
))

add(dict(
    id="post.glow_enabled",
    category="post",
    title="Glow is enabled",
    severity="medium",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=sceq("env_glow", 1),
    evidence="Environment.glow_enabled is true.",
    suggestion="Turn glow off to see the bloom cost, or reduce how many glow_levels are above 0. The timestamp label for the pass is Glow.",
    node_property="Environment.glow_enabled",
    tradeoff="Bloom and glow on bright pixels disappear.",
    expected_effect="Removes the glow pass. Measure it; do not assume a percentage of the frame.",
    verify_step="gpu_passes frames=60",
    source=ENV,
    when_pass=["Glow"],
    dedupe_key="glow",
))

add(dict(
    id="post.glow_bicubic",
    category="post",
    title="Glow upscale is bicubic while glow is on",
    severity="low",
    renderers=ALL, versions=BOTH, requires=["settings", "scene"],
    condition=all_(sceq("env_glow", 1), seq("rendering/environment/glow/upscale_mode", 1)),
    evidence="glow/upscale_mode is 1. The hint is Linear (Fast), Bicubic (Slow). The desktop default is 1 and the .mobile override default is 0.",
    suggestion="Set rendering/environment/glow/upscale_mode to 0 (Linear) if glow is a measured cost.",
    setting="rendering/environment/glow/upscale_mode",
    tradeoff="Glow upscale looks softer or more aliased than bicubic.",
    expected_effect="The faster glow upscale labeled in ProjectSettings.",
    verify_step="gpu_passes frames=60",
    source=PROJ,
    dedupe_key="glow",
))

add(dict(
    id="post.volumetric_fog",
    category="post",
    title="Volumetric fog is enabled",
    severity="high",
    renderers=FP, versions=BOTH, requires=["scene"],
    condition=sceq("env_volumetric_fog", 1),
    evidence="Environment.volumetric_fog_enabled is true. The volumetric fog page says it is Forward+ only.",
    suggestion="Turn volumetric fog off, or lower volume_size and volume_depth (both default to 64, range 16–512). The page says a smaller volume size is the performance side of that tradeoff.",
    node_property="Environment.volumetric_fog_enabled",
    tradeoff="Height fog and light shafts from the froxel volume disappear. Quad-based fog still works on Mobile and Compatibility.",
    expected_effect="Removes the volumetric fog passes (Render Fog, Filter Fog, Integrate Fog).",
    verify_step="gpu_passes frames=60",
    source=VFOG,
    dedupe_key="vfog",
))

add(dict(
    id="post.volumetric_fog_size",
    category="post",
    title="Volumetric fog volume size or depth is above the default",
    severity="high",
    renderers=FP, versions=BOTH, requires=["settings", "scene"],
    condition=all_(
        sceq("env_volumetric_fog", 1),
        any_(
            sgt("rendering/environment/volumetric_fog/volume_size", 64),
            sgt("rendering/environment/volumetric_fog/volume_depth", 64),
        ),
    ),
    evidence="volume_size or volume_depth is above 64. Both default to 64. The volumetric fog page says to raise them for detail and lower them for performance.",
    suggestion="Set volume_size and volume_depth back to 64 or below.",
    setting="rendering/environment/volumetric_fog/volume_size",
    tradeoff="Froxel detail drops. Shorten Environment.volumetric_fog_length if the fog range is the actual problem; the page says that part has no performance cost.",
    expected_effect="A smaller froxel buffer.",
    verify_step="gpu_passes frames=60",
    source=VFOG,
    dedupe_key="vfog",
))

add(dict(
    id="post.fog_enabled",
    category="post",
    title="Distance or height fog is enabled",
    severity="low",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=all_(sceq("env_fog", 1), sceq("env_volumetric_fog", 0)),
    evidence="Environment.fog_enabled is true and volumetric fog is off. This is the exponential or depth fog mode, not the froxel volume.",
    suggestion="Turn fog_enabled off only if the art direction allows it. Prefer this over volumetric fog when the scene does not need light shafts.",
    node_property="Environment.fog_enabled",
    tradeoff="Aerial perspective goes away.",
    expected_effect="Drops the standard fog evaluation. Volumetric fog is the separate, heavier feature.",
    verify_step="scan_scene",
    source=ENV,
))

add(dict(
    id="post.adjustments",
    category="post",
    title="Color adjustments are enabled",
    severity="low",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=sceq("env_adjustment", 1),
    evidence="Environment.adjustment_enabled is true (brightness, contrast, saturation, or a color correction texture).",
    suggestion="Bake the grade into the tonemap and textures if this is a constant grade, and turn adjustment_enabled off.",
    node_property="Environment.adjustment_enabled",
    tradeoff="You lose a live grade slider.",
    expected_effect="One less fullscreen color pass.",
    verify_step="scan_scene",
    source=ENV,
))

add(dict(
    id="post.dof_enabled",
    category="post",
    title="Depth-of-field blur is enabled",
    severity="medium",
    renderers=FPM, versions=BOTH, requires=["scene"],
    condition=sceq("dof_blur_enabled", 1),
    evidence="CameraAttributesPractical has far or near DOF blur enabled on the camera or WorldEnvironment.",
    suggestion="Turn dof_blur_far_enabled and dof_blur_near_enabled off, or lower the bokeh quality project setting (default index 1, Low).",
    node_property="CameraAttributesPractical.dof_blur_far_enabled",
    offender_key="dof",
    tradeoff="Focus falloff disappears.",
    expected_effect="Removes the DOF blur. The bokeh shape hint marks Circle as Slowest.",
    verify_step="scan_scene",
    source=PROJ,
))

add(dict(
    id="post.dof_circle",
    category="post",
    title="DOF bokeh shape is Circle",
    severity="medium",
    renderers=FPM, versions=BOTH, requires=["settings", "scene"],
    condition=all_(sceq("dof_blur_enabled", 1), seq("rendering/camera/depth_of_field/depth_of_field_bokeh_shape", 2)),
    evidence="bokeh shape is 2. The hint is Box (Fast), Hexagon (Average), Circle (Slowest). The default is 1 (Hexagon).",
    suggestion="Set depth_of_field_bokeh_shape to 1 or 0.",
    setting="rendering/camera/depth_of_field/depth_of_field_bokeh_shape",
    tradeoff="Bokeh highlights become hexagonal or square.",
    expected_effect="The faster bokeh kernel labeled in ProjectSettings.",
    verify_step="collect_metrics",
    source=PROJ,
))

add(dict(
    id="post.dof_quality_high",
    category="post",
    title="DOF bokeh quality is High",
    severity="medium",
    renderers=FPM, versions=BOTH, requires=["settings", "scene"],
    condition=all_(sceq("dof_blur_enabled", 1), sgte("rendering/camera/depth_of_field/depth_of_field_bokeh_quality", 3)),
    evidence="bokeh quality index is 3 or more. The hint is Very Low, Low, Medium, High (Slow). The default is 1 (Low).",
    suggestion="Set depth_of_field_bokeh_quality to 1.",
    setting="rendering/camera/depth_of_field/depth_of_field_bokeh_quality",
    tradeoff="DOF looks noisier.",
    expected_effect="A cheaper bokeh quality than High (Slow).",
    verify_step="collect_metrics",
    source=PROJ,
))

add(dict(
    id="post.sss_quality",
    category="post",
    title="Subsurface scattering quality is Medium or High while materials use it",
    severity="medium",
    renderers=FPM, versions=BOTH, requires=["settings", "scene"],
    condition=all_(scgte("subsurf_material_count", 1), sgte("rendering/environment/subsurface_scattering/subsurface_scattering_quality", 2)),
    evidence="A material enables subsurf_scatter and the quality index is 2 or 3. The hint is Disabled, Low, Medium (Average), High (Slow). The default is 1 (Low).",
    suggestion="Set subsurface_scattering_quality to 1, or turn subsurf_scatter_enabled off on materials that do not need it.",
    setting="rendering/environment/subsurface_scattering/subsurface_scattering_quality",
    offender_key="subsurf_materials",
    tradeoff="Skin and wax scattering looks harder.",
    expected_effect="A cheaper subsurface mode than the ones labeled Average and Slow.",
    verify_step="gpu_passes frames=60",
    source=PROJ,
    when_pass=["Sub-Surface Scattering"],
    dedupe_key="sss",
))

add(dict(
    id="post.camera_far_default",
    category="post",
    title="Camera far plane is still the default 4000",
    severity="low",
    heuristic=True,
    heuristic_rationale="Camera3D.far defaults to 4000, which is also the inspector maximum. Keeping the far plane that high retains more of the world in the frustum than a typical scene needs.",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=scgte("camera_far_at_default_count", 1),
    evidence="A Camera3D has far >= 4000.",
    suggestion="Lower Camera3D.far to just beyond the play space. Shadow max distance and fog depth should stay inside that range.",
    node_property="Camera3D.far",
    offender_key="camera_far",
    tradeoff="Geometry beyond the new far plane pops out.",
    expected_effect="A shorter frustum for culling. The mesh LOD page notes that what is on screen drives LOD; the far plane decides what can be on screen.",
    verify_step="scan_scene",
    source=CAM,
))

# --- materials --------------------------------------------------------------

add(dict(
    id="materials.alpha_blend",
    category="materials",
    title="Materials use alpha blend transparency",
    severity="high",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=scgte("transparent_alpha_blend_count", 1),
    evidence="An effective BaseMaterial3D uses Alpha transparency, or writes ALPHA with transparency Disabled because pixel-alpha distance fade, proximity fade or shadow-to-opacity is enabled. These implicit cases are excluded for alpha-scissor/hash and explicit depth-prepass modes. Blended surfaces can incur overdraw and reduced depth rejection; their configured state does not measure the cost.",
    suggestion="For opaque-looking surfaces, remove unnecessary fade/shadow-to-opacity features as well as selecting Disabled transparency. Compare dithered distance fading or masked foliage modes when their visual tradeoffs are acceptable; preserve intentionally translucent surfaces.",
    node_property="BaseMaterial3D.transparency",
    offender_key="alpha_blend",
    tradeoff="Alpha scissor and hash are 1-bit and need alpha antialiasing if the edge shimmers. MSAA does not fix alpha-scissor edges by itself.",
    expected_effect="Those surfaces leave the transparent pass and can be rejected by the depth buffer.",
    verify_step="scan_scene",
    source="https://github.com/godotengine/godot/blob/4.4-stable/scene/resources/material.cpp",
    when_pass=["Render 3D Transparent Pass", "Render Transparent"],
    dedupe_key="transparency",
))

add(dict(
    id="materials.alpha_blend_depth_always",
    category="materials",
    title="Alpha-blend materials write depth every fragment",
    severity="medium",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=scgte("alpha_blend_depth_always_count", 1),
    evidence="An alpha-blend material has depth_draw_mode Always (index 1 of Opaque Only, Always, Never).",
    suggestion="Use Opaque Only unless a later effect samples that depth. Never skips the depth write entirely and can break sorting.",
    node_property="BaseMaterial3D.depth_draw_mode",
    offender_key="depth_always",
    tradeoff="Effects that need the transparent surface in the depth buffer stop seeing it.",
    expected_effect="Less depth-write traffic on blended surfaces.",
    verify_step="scan_scene",
    source=BASE,
))

add(dict(
    id="materials.depth_prepass_transparency",
    category="materials",
    title="Materials use the depth-prepass transparency mode",
    severity="low",
    renderers=FPM, versions=BOTH, requires=["scene"],
    condition=scgte("transparent_depth_prepass_count", 1),
    evidence="transparency is Depth Pre-Pass (index 4).",
    suggestion="Prefer Alpha Scissor or Alpha Hash when a hard edge is acceptable. Depth pre-pass transparency draws the surface twice.",
    node_property="BaseMaterial3D.transparency",
    offender_key="depth_prepass_transparency",
    tradeoff="Scissor and hash cannot represent partial coverage as smoothly.",
    expected_effect="One less prepass draw for those materials.",
    verify_step="scan_scene",
    source=BASE,
))

add(dict(
    id="materials.double_sided",
    category="materials",
    title="Materials disable backface culling",
    severity="medium",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=scgte("double_sided_material_count", 1),
    evidence="cull_mode is Disabled (index 2 of Back, Front, Disabled).",
    suggestion="Set cull_mode back to Back unless the surface is a leaf card or cloth that must be seen from both sides.",
    node_property="BaseMaterial3D.cull_mode",
    offender_key="double_sided_materials",
    tradeoff="The back face becomes invisible.",
    expected_effect="Half the rasterization for those surfaces.",
    verify_step="scan_scene",
    source=BASE,
))

add(dict(
    id="materials.per_pixel_particles",
    category="materials",
    title="Particle materials are per-pixel shaded",
    severity="low",
    heuristic=True,
    heuristic_rationale="Counts BaseMaterial3D shading_mode Per-Pixel (index 1) used by GPUParticles3D or CPUParticles3D. The GPU optimization page says non-unshaded particles can force vertex shading to cut cost.",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=scgte("particle_per_pixel_material_count", 1),
    evidence="A particle node uses a per-pixel BaseMaterial3D. shading_mode values are Unshaded, Per-Pixel, Per-Vertex.",
    suggestion="Set shading_mode to Per-Vertex (2) or Unshaded (0) on particle materials.",
    node_property="BaseMaterial3D.shading_mode",
    offender_key="particle_per_pixel",
    tradeoff="Normal maps and specular on particles get coarser or disappear.",
    expected_effect="Less fragment shading on particles.",
    verify_step="scan_scene",
    source=GPU,
))

add(dict(
    id="materials.shader_materials",
    category="materials",
    title="ShaderMaterials are in the scene",
    severity="low",
    heuristic=True,
    heuristic_rationale="Any ShaderMaterial is reported because the pipeline-compilations page says material changes create pipelines that are not covered until that variant is seen. The count is not a budget.",
    renderers=FPM, versions=BOTH, requires=["scene"],
    condition=scgte("shader_material_count", 1),
    evidence="The scan found ShaderMaterial resources.",
    suggestion="Prefer BaseMaterial3D when the built-in slots are enough. Load custom shaders during a loading screen so PIPELINE_COMPILATIONS_DRAW does not spike in gameplay. The pipeline page says draw-step compilations mean an ubershader was not ready.",
    node_property="ShaderMaterial",
    offender_key="shader_materials",
    tradeoff="Built-in materials cannot express every custom shader.",
    expected_effect="Fewer unseen shader variants at runtime. Watch the pipeline monitors.",
    verify_step="collect_metrics",
    source=PIPE,
))

add(dict(
    id="materials.subsurf",
    category="materials",
    title="Materials enable subsurface scattering",
    severity="medium",
    renderers=FPM, versions=BOTH, requires=["scene"],
    condition=scgte("subsurf_material_count", 1),
    evidence="BaseMaterial3D.subsurf_scatter_enabled is true.",
    suggestion="Disable subsurface on materials that are not skin, wax, or foliage, and keep subsurface_scattering_quality at Low (1).",
    node_property="BaseMaterial3D.subsurf_scatter_enabled",
    offender_key="subsurf_materials",
    tradeoff="Those surfaces lose translucency.",
    expected_effect="They drop out of the subsurface pass.",
    verify_step="scan_scene",
    source=BASE,
    when_pass=["Sub-Surface Scattering"],
    dedupe_key="sss",
))

add(dict(
    id="materials.refraction",
    category="materials",
    title="Materials enable refraction",
    severity="medium",
    renderers=FPM, versions=BOTH, requires=["scene"],
    condition=scgte("refraction_material_count", 1),
    evidence="BaseMaterial3D.refraction_enabled is true. Refraction samples the screen texture, which is the same class of fullscreen copy the transparent path needs.",
    suggestion="Disable refraction on materials that only need transparency.",
    node_property="BaseMaterial3D.refraction_enabled",
    offender_key="refraction_materials",
    tradeoff="The surface no longer distorts the background.",
    expected_effect="Drops the refraction sample. The Copy Screen Texture timestamp is the related pass.",
    verify_step="gpu_passes frames=60",
    source=BASE,
    when_pass=["Copy Screen Texture"],
))

add(dict(
    id="materials.heightmap",
    dedupe_key="heightmap",
    category="materials",
    title="Materials enable height mapping",
    severity="medium",
    renderers=FPM, versions=BOTH, requires=["scene"],
    condition=all_(scgte("heightmap_material_count", 1), {"not": scgte("check_material_deep_parallax", 1)}),
    evidence="heightmap_enabled is true with UV1 triplanar disabled. When a configured deep-parallax texture is present, the more specific deep-parallax rule supplies this advice instead.",
    suggestion="Turn heightmap_enabled off where a normal map is enough. If deep parallax is on, lower heightmap_max_layers.",
    node_property="BaseMaterial3D.heightmap_enabled",
    offender_key="heightmap_materials",
    tradeoff="Silhouette relief from the height map disappears.",
    expected_effect="Fewer relief parallax iterations in the fragment shader.",
    verify_step="scan_scene",
    source=BASE,
))

add(dict(
    id="materials.proximity_fade",
    category="materials",
    title="Materials enable proximity fade",
    severity="low",
    renderers=FPM, versions=BOTH, requires=["scene"],
    condition=scgte("proximity_fade_count", 1),
    evidence="proximity_fade_enabled is true. The material fades against nearby surfaces, which needs a depth read.",
    suggestion="Disable proximity_fade_enabled on surfaces that do not intersect the camera.",
    node_property="BaseMaterial3D.proximity_fade_enabled",
    offender_key="proximity_fade",
    tradeoff="Meshes no longer fade where they intersect the camera.",
    expected_effect="Drops that depth-based fade.",
    verify_step="scan_scene",
    source=BASE,
))

# --- geometry ---------------------------------------------------------------

add(dict(
    id="geometry.multimesh_candidate",
    category="geometry",
    title="Many MeshInstance3D nodes share one mesh",
    severity="medium",
    heuristic=True,
    heuristic_rationale="Four or more MeshInstance3D nodes sharing one mesh resource is the cut. The MultiMesh page is the tool for repeated instances. The optimizing-3D page also notes automatic instancing for identical opaque mesh-and-material pairs, which does not replace MultiMesh for large counts.",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=scgte("largest_identical_mesh_count", 4),
    evidence="One mesh resource is used by at least four MeshInstance3D nodes.",
    suggestion="Replace that group with a MultiMeshInstance3D. Keep distant islands in separate MultiMeshes so frustum and occlusion culling can drop a whole node; the mesh LOD page says individual MultiMesh instances are not culled.",
    node_property="MultiMeshInstance3D",
    offender_key="identical_meshes",
    tradeoff="Per-instance script transforms become multimesh buffer updates.",
    expected_effect="Fewer draw submissions for that mesh.",
    verify_step="scan_scene",
    source=MM,
))

add(dict(
    id="geometry.high_surface_count",
    category="geometry",
    title="A mesh has several surfaces",
    severity="medium",
    heuristic=True,
    heuristic_rationale="Three or more surfaces on one mesh is the cut. Each surface is a separate draw with its own material. The optimizing-3D page says to split only the part that must be transparent.",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=scgte("mesh_high_surface_count", 1),
    evidence="At least one mesh reports get_surface_count() >= 3.",
    suggestion="Merge surfaces that share a material. Keep a separate surface only for a genuinely transparent region.",
    node_property="Mesh.get_surface_count",
    offender_key="high_surface_meshes",
    tradeoff="Merging materials can waste texture space.",
    expected_effect="Fewer draws per mesh.",
    verify_step="scan_scene",
    source=OPT3D,
))

add(dict(
    id="geometry.no_visibility_range",
    category="geometry",
    title="Many meshes have no visibility range",
    severity="low",
    heuristic=True,
    heuristic_rationale="Fires when at least 30 MeshInstance3D nodes leave visibility_range_begin and visibility_range_end at 0. The visibility-range page is aimed at large scenes; 30 is a review cut, not a Godot limit.",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=scgte("mesh_without_visibility_range_count", 30),
    evidence="At least 30 MeshInstance3D nodes have no visibility range.",
    suggestion="Set visibility_range_end on distant props, with visibility_range_fade_mode Self or Dependencies. The page describes this as the manual HLOD-style tool next to automatic mesh LOD.",
    node_property="GeometryInstance3D.visibility_range_end",
    tradeoff="Objects pop or fade at that distance.",
    expected_effect="Distant nodes are not drawn. Combine with mesh LOD rather than replacing it.",
    verify_step="scan_scene",
    source=VIS,
))

add(dict(
    id="geometry.lod_threshold_below_default",
    category="geometry",
    title="Mesh LOD threshold is below the default 1 pixel",
    severity="medium",
    renderers=ALL, versions=BOTH, requires=["settings"],
    condition=slt("rendering/mesh_lod/lod_change/threshold_pixels", 1.0),
    evidence="threshold_pixels is below 1. The mesh LOD page says the default of 1 pixel is tuned to look lossless, and higher values switch LOD sooner (more performance, less quality).",
    suggestion="Raise rendering/mesh_lod/lod_change/threshold_pixels to 1 or above. Per-object tweaks belong on GeometryInstance3D.lod_bias, where values below 1 switch sooner.",
    setting="rendering/mesh_lod/lod_change/threshold_pixels",
    tradeoff="A higher threshold drops geometric detail earlier.",
    expected_effect="LOD switches sooner, which the page says increases performance.",
    verify_step="collect_metrics",
    source=LOD,
))

add(dict(
    id="geometry.lod_bias_high",
    category="geometry",
    title="Mesh LOD bias is above 1",
    severity="low",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=scgte("mesh_lod_bias_above_one_count", 1),
    evidence="GeometryInstance3D.lod_bias is above 1. The mesh LOD page says values above 1 switch later (higher quality, lower performance).",
    suggestion="Set lod_bias to 1, or below 1 on hero-distance props you can simplify.",
    node_property="GeometryInstance3D.lod_bias",
    offender_key="lod_bias_high",
    tradeoff="Detail drops earlier on those nodes.",
    expected_effect="Earlier LOD selection on the flagged nodes.",
    verify_step="scan_scene",
    source=LOD,
))

add(dict(
    id="geometry.occlusion_without_occluders",
    category="geometry",
    title="Occlusion culling is on without occluder nodes",
    severity="medium",
    renderers=ALL, versions=BOTH, requires=["settings", "scene"],
    condition=all_(
        seq("rendering/occlusion_culling/use_occlusion_culling", True),
        sceq("occluder_count", 0),
    ),
    evidence="use_occlusion_culling is true and the scan found no OccluderInstance3D. The occlusion page says occluder geometry is what gets rasterized into the occlusion buffer.",
    suggestion="Add OccluderInstance3D nodes (or bake occluders) for large solid walls, or turn the setting off if you have not authored occluders. The page says the feature may not be worth its CPU cost without useful occluders.",
    setting="rendering/occlusion_culling/use_occlusion_culling",
    tradeoff="Turning it off spends the draw calls the occluders would have removed.",
    expected_effect="Either the CPU occlusion pass starts hiding objects, or its CPU cost goes away.",
    verify_step="scan_scene",
    source=OCC,
))

add(dict(
    id="geometry.occlusion_bvh_high",
    category="geometry",
    title="Occlusion BVH build quality is High",
    severity="low",
    renderers=ALL, versions=BOTH, requires=["settings"],
    condition=all_(
        seq("rendering/occlusion_culling/use_occlusion_culling", True),
        sgte("rendering/occlusion_culling/bvh_build_quality", 2),
    ),
    evidence="bvh_build_quality is 2. The hint is Low, Medium, High and the default is High. The occlusion page says to lower BVH build quality or occlusion_rays_per_thread (default 512) when the CPU update shows up.",
    suggestion="Set bvh_build_quality to 1 (Medium) or 0 (Low) if moving occluders rebuild the BVH often.",
    setting="rendering/occlusion_culling/bvh_build_quality",
    tradeoff="The occlusion test is coarser.",
    expected_effect="Cheaper BVH builds. The page warns that moving occluders every frame forces rebuilds.",
    verify_step="collect_metrics",
    source=OCC,
))

add(dict(
    id="geometry.occlusion_rays",
    category="geometry",
    title="Occlusion rays per thread are above the default",
    severity="low",
    heuristic=True,
    heuristic_rationale="occlusion_rays_per_thread defaults to 512. Above that is more rays than the default the occlusion page says you can lower.",
    renderers=ALL, versions=BOTH, requires=["settings"],
    condition=all_(
        seq("rendering/occlusion_culling/use_occlusion_culling", True),
        sgt("rendering/occlusion_culling/occlusion_rays_per_thread", 512),
    ),
    evidence="occlusion_rays_per_thread is above 512.",
    suggestion="Set it back to 512 or below.",
    setting="rendering/occlusion_culling/occlusion_rays_per_thread",
    tradeoff="Occlusion results get noisier.",
    expected_effect="Less CPU work per occlusion update.",
    verify_step="collect_metrics",
    source=OCC,
))

add(dict(
    id="geometry.ignore_occlusion",
    category="geometry",
    title="Meshes opt out of occlusion culling",
    severity="low",
    renderers=ALL, versions=BOTH, requires=["settings", "scene"],
    condition=all_(
        seq("rendering/occlusion_culling/use_occlusion_culling", True),
        scgte("mesh_ignore_occlusion_count", 1),
    ),
    evidence="GeometryInstance3D.ignore_occlusion_culling is true on at least one mesh while occlusion culling is enabled.",
    suggestion="Clear ignore_occlusion_culling except on meshes that flicker when culled.",
    node_property="GeometryInstance3D.ignore_occlusion_culling",
    offender_key="ignore_occlusion",
    tradeoff="Those meshes can disappear if their occluder test is wrong.",
    expected_effect="Occlusion culling applies to them again.",
    verify_step="scan_scene",
    source=OCC,
))

add(dict(
    id="geometry.opaque_pass_share",
    category="geometry",
    title="The opaque pass is a large share of measured GPU time",
    severity="high",
    heuristic=True,
    heuristic_rationale="25% of the median timestamp-span frame is a review cut so the opaque pass is only flagged when it is a large measured slice. The percentage is not a Godot budget.",
    renderers=FPM, versions=BOTH, requires=["passes"],
    condition=pshare("Render Opaque", 25),
    evidence="The opaque pass (Render Opaque Pass on Forward+, Render Opaque on Mobile) exclusive time is at least 25% of the median timestamp-span frame GPU time.",
    suggestion="Use the mesh LOD threshold, visibility ranges, fewer surfaces, and opaque materials. The optimizing-3D page treats draw calls and overdraw as the opaque-pass levers. Automatic instancing already covers identical opaque MeshInstance3D pairs.",
    tradeoff="LOD and visibility ranges change how much detail is visible at a distance.",
    expected_effect="The opaque pass should shrink after those cuts. Re-run gpu_passes; this rule does not predict the new share.",
    verify_step="gpu_passes frames=60",
    source=OPT3D,
    when_pass=["Render Opaque"],
    dedupe_key="opaque",
))

add(dict(
    id="geometry.transparent_pass_share",
    category="geometry",
    title="The transparent pass is a large share of measured GPU time",
    severity="high",
    heuristic=True,
    heuristic_rationale="15% of measured frame GPU time is a review cut for the transparent pass. It is not a documented budget.",
    renderers=FPM, versions=BOTH, requires=["passes"],
    condition=pshare(["Render 3D Transparent Pass", "Render Transparent"], 15),
    evidence="The transparent pass (Render 3D Transparent Pass on Forward+, Render Transparent on Mobile) is at least 15% of the median timestamp-span frame GPU time.",
    suggestion="Replace alpha blend with alpha scissor or hash, and reduce overlapping transparent layers. The GPU optimization page explains why transparency causes overdraw.",
    tradeoff="Masked transparency cannot do smooth partial coverage.",
    expected_effect="Less transparent overdraw. Measure the pass again.",
    verify_step="gpu_passes frames=60",
    source=GPU,
    when_pass=["Render 3D Transparent Pass", "Render Transparent"],
    dedupe_key="transparency",
))

# --- textures ---------------------------------------------------------------

add(dict(
    id="textures.anisotropy_16x",
    category="textures",
    title="Anisotropic filtering is 16×",
    severity="medium",
    renderers=FPM, versions=BOTH, requires=["settings"],
    condition=sgte("rendering/textures/default_filters/anisotropic_filtering_level", 4),
    evidence="anisotropic_filtering_level is 4. The hint is Disabled, 2×, 4×, 8×, 16× (Slow). The default is 2 (4×).",
    suggestion="Set anisotropic_filtering_level to 2 (4×) or 3 (8×).",
    setting="rendering/textures/default_filters/anisotropic_filtering_level",
    tradeoff="Grazing surfaces look blurrier.",
    expected_effect="Fewer anisotropic samples than the level labeled Slow.",
    verify_step="collect_metrics",
    source=PROJ,
))

add(dict(
    id="textures.anisotropy_off",
    category="textures",
    title="Anisotropic filtering is disabled",
    severity="low",
    kind="quality_up",
    renderers=FPM, versions=BOTH, requires=["settings"],
    condition=seq("rendering/textures/default_filters/anisotropic_filtering_level", 0),
    evidence="anisotropic_filtering_level is 0 (Disabled). The default is 2 (4×).",
    suggestion="Set it to 2 if grazing-angle textures shimmer and there is GPU headroom.",
    setting="rendering/textures/default_filters/anisotropic_filtering_level",
    tradeoff="4× anisotropy costs more samples than disabled.",
    expected_effect="Sharper textures at an angle. The importing-images page is the companion for mipmaps, which anisotropy needs.",
    verify_step="collect_metrics",
    source=IMG,
))

add(dict(
    id="textures.nearest_mip_filter",
    category="textures",
    title="Nearest mipmap filter is forced",
    severity="info",
    kind="info",
    renderers=ALL, versions=BOTH, requires=["settings"],
    condition=seq("rendering/textures/default_filters/use_nearest_mipmap_filter", True),
    evidence="use_nearest_mipmap_filter is true. The default is false.",
    suggestion="Leave this on only for a pixel-art mip look. The default linear mip filter is the smoother 3D path.",
    setting="rendering/textures/default_filters/use_nearest_mipmap_filter",
    tradeoff="Linear mip filtering is slightly more expensive and blurs mip transitions.",
    expected_effect="Visual only, unless you were bandwidth-bound on the extra tap.",
    verify_step="collect_metrics",
    source=PROJ,
))

add(dict(
    id="textures.vram_uncompressed",
    category="textures",
    title="Imported textures use VRAM uncompressed",
    severity="high",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=scgte("texture_vram_uncompressed_count", 1),
    evidence="A texture .import file has compress/mode 3. resource_importer_texture.h at tag 4.4-stable orders the enum Lossless, Lossy, VRAM Compressed, VRAM Uncompressed, Basis Universal.",
    suggestion="Set the Import dock compress mode to VRAM Compressed for 3D textures. The importing-images page says 3D detection switches compression to VRAM Compressed.",
    node_property="compress/mode",
    offender_key="textures_uncompressed",
    tradeoff="Block compression is lossy.",
    expected_effect="Less texture VRAM. Read RENDER_TEXTURE_MEM_USED after reimport.",
    verify_step="collect_metrics",
    source=TEXH,
))

add(dict(
    id="textures.lossless_3d",
    category="textures",
    title="Textures used in 3D are imported lossless",
    severity="medium",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=scgte("texture_lossless_count", 1),
    evidence="compress/mode is 0 (Lossless) on a texture referenced by a 3D material or decal.",
    suggestion="Reimport as VRAM Compressed unless the texture is a UI asset or a normal map that cannot tolerate the block format.",
    node_property="compress/mode",
    offender_key="textures_lossless",
    tradeoff="VRAM compression is lossy. The importing-images page notes quality issues can be fixed per texture.",
    expected_effect="Smaller GPU textures.",
    verify_step="collect_metrics",
    source=IMG,
))

add(dict(
    id="textures.no_mipmaps",
    category="textures",
    title="3D textures have mipmaps disabled",
    severity="medium",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=scgte("texture_no_mipmaps_count", 1),
    evidence="mipmaps/generate is false on a texture used in 3D. The importing-images page says mipmaps are enabled when a texture is detected as 3D.",
    suggestion="Enable mipmaps in the Import dock and reimport.",
    node_property="mipmaps/generate",
    offender_key="textures_no_mipmaps",
    tradeoff="Mipmaps use about a third more memory and storage.",
    expected_effect="Farther surfaces sample smaller mips instead of the full image. The resolution scaling page notes the mipmap bias only affects textures that have mipmaps.",
    verify_step="scan_scene",
    source=IMG,
))

add(dict(
    id="textures.large_dimension",
    category="textures",
    title="A texture is larger than 2048 on a side",
    severity="medium",
    heuristic=True,
    heuristic_rationale="2048 is not a Godot maximum. Textures wider or taller than 2048 are called out because they dominate VRAM relative to the 256 default reflection size and the 4096 shadow maps.",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=scgte("texture_large_count", 1),
    evidence="A Texture2D used by the scene reports a width or height above 2048.",
    suggestion="Downscale in the Import dock with process/size_limit, or author a smaller source. Keep unique hero textures only where the texel is visible.",
    node_property="Texture2D.get_width",
    offender_key="textures_large",
    tradeoff="Less texel detail up close.",
    expected_effect="Less RENDER_TEXTURE_MEM_USED after reimport.",
    verify_step="collect_metrics",
    source=IMG,
))

add(dict(
    id="textures.decal_filter_aniso",
    category="textures",
    title="Decal filter uses anisotropic samples",
    severity="low",
    renderers=FPM, versions=BOTH, requires=["settings"],
    condition=sgte("rendering/textures/decals/filter", 4),
    evidence="decals/filter index is 4 or higher (anisotropic modes in the hint). The default index is 3 (Linear Mipmap).",
    suggestion="Set rendering/textures/decals/filter to 3.",
    setting="rendering/textures/decals/filter",
    tradeoff="Decals shimmer more at grazing angles.",
    expected_effect="Cheaper decal sampling.",
    verify_step="collect_metrics",
    source=DECAL,
))

# --- particles --------------------------------------------------------------

add(dict(
    id="particles.gpu_amount",
    category="particles",
    title="A GPU particle amount is far above the default",
    severity="medium",
    heuristic=True,
    heuristic_rationale="GPUParticles2D and GPUParticles3D amount default to 8. 64 is eight times that default. The particles properties page says raising Amount spawns more particles at a performance cost and does not define this cut.",
    renderers=FPM, versions=BOTH, requires=["scene"],
    condition=scgte("gpu_particle_high_amount_count", 1),
    evidence="A GPUParticles2D or GPUParticles3D has amount >= 64.",
    suggestion="Compare a lower amount. Godot documents that reducing amount_ratio alone does not reduce allocated particle resources or improve performance.",
    node_property="GPUParticles2D/3D.amount",
    offender_key="gpu_particles_amount",
    tradeoff="The effect is thinner.",
    expected_effect="Fewer simulated particles.",
    verify_step="scan_scene",
    source="https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/GPUParticles3D.xml",
))

add(dict(
    id="particles.cpu_nodes",
    category="particles",
    title="CPU particle nodes are in the scene",
    severity="medium",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=scgte("cpu_particle_count", 1),
    evidence="The scan found CPUParticles2D or CPUParticles3D nodes, which simulate on the CPU. Their presence alone does not establish a bottleneck.",
    suggestion="Benchmark large effects with the matching GPUParticles2D or GPUParticles3D node when the target renderer supports the required features. CPU particles may be preferable for small effects or constrained platforms.",
    node_property="CPUParticles2D/3D",
    offender_key="cpu_particles",
    tradeoff="GPU particles need a process material and suitable visibility bounds; 3D uses an AABB and 2D uses a rectangle. Behavior and renderer support can differ.",
    expected_effect="Particle simulation leaves the CPU. Compare TIME_PROCESS.",
    verify_step="collect_metrics",
    source=CPUP,
))

add(dict(
    id="particles.trails",
    category="particles",
    title="GPU particle trails are enabled",
    severity="medium",
    renderers=FPM, versions=BOTH, requires=["scene"],
    condition=scgte("gpu_particle_trail_count", 1),
    evidence="GPUParticles2D or GPUParticles3D trail_enabled is true. Trails add particle history and geometry; the default is false.",
    suggestion="Disable trail_enabled where a billboard is enough, and keep trail_lifetime short (the property range is 0.01–10 seconds).",
    node_property="GPUParticles2D/3D.trail_enabled",
    offender_key="particle_trails",
    tradeoff="The ribbon disappears.",
    expected_effect="Less trail geometry per particle.",
    verify_step="scan_scene",
    source=TRAIL,
))

add(dict(
    id="particles.collision",
    category="particles",
    title="Particle process materials enable collision",
    severity="medium",
    renderers=FPM, versions=BOTH, requires=["scene"],
    condition=scgte("gpu_particle_collision_count", 1),
    evidence="ParticleProcessMaterial.collision_mode is not Disabled (0). The particles properties page says Fixed FPS also limits collision processing and that this helps most when collision is in heavy use.",
    suggestion="Compare disabled collision where unnecessary, or lower the GPUParticles2D/3D fixed_fps. The documented default is 30.",
    node_property="ParticleProcessMaterial.collision_mode",
    offender_key="particle_collision",
    tradeoff="Particles stop colliding.",
    expected_effect="Less collision work inside the particle update.",
    verify_step="scan_scene",
    source=PART,
))

add(dict(
    id="particles.fixed_fps_high",
    category="particles",
    title="Particle Fixed FPS is at or above 60",
    severity="low",
    heuristic=True,
    heuristic_rationale="60 matches a common display rate, not a particle constant. fixed_fps defaults to 30. The properties page says Fixed FPS limits how often the system is processed.",
    renderers=FPM, versions=BOTH, requires=["scene"],
    condition=scgte("gpu_particle_fixed_fps_high_count", 1),
    evidence="GPUParticles2D or GPUParticles3D fixed_fps is >= 60.",
    suggestion="Lower fixed_fps toward 30 and leave interpolate true so the motion stays smooth. The class reference says a value of 2 renders the visual at 2 frames per second and does not slow the simulation speed.",
    node_property="GPUParticles2D/3D.fixed_fps",
    offender_key="particle_fixed_fps",
    tradeoff="Collision and attractors update less often and can look choppy if interpolate is off.",
    expected_effect="Fewer particle process steps per second.",
    verify_step="scan_scene",
    source=PART,
))

add(dict(
    id="particles.draw_passes",
    category="particles",
    title="GPU particles use more than one draw pass",
    severity="low",
    renderers=FPM, versions=BOTH, requires=["scene"],
    condition=scgte("gpu_particle_multi_pass_count", 1),
    evidence="GPUParticles3D.draw_passes is above 1. The default is 1 and the range is 0–4.",
    suggestion="Drop extra draw passes that are not a second mesh.",
    node_property="GPUParticles3D.draw_passes",
    offender_key="particle_draw_passes",
    tradeoff="The extra mesh in that pass disappears.",
    expected_effect="One less particle draw per system.",
    verify_step="scan_scene",
    source=GPUP,
))

add(dict(
    id="particles.heightfield_resolution",
    category="particles",
    title="Particle heightfield collision resolution is Slow or worse",
    severity="medium",
    renderers=FPM, versions=BOTH, requires=["scene"],
    condition=scgte("heightfield_high_res_count", 1),
    evidence="GPUParticlesCollisionHeightField3D.resolution index is 3 or higher. The hint is 256 (Fastest), 512 (Fast), 1024 (Average), 2048 (Slow), 4096 (Slower), 8192 (Slowest).",
    suggestion="Lower resolution to 2 (1024) or below. update_mode Always is the slow update; When Moved is the fast one.",
    node_property="GPUParticlesCollisionHeightField3D.resolution",
    offender_key="heightfields",
    tradeoff="Collision against the heightfield gets coarser.",
    expected_effect="A smaller heightfield texture. The related timestamp is Render Collider Heightfield.",
    verify_step="gpu_passes frames=60",
    source=GPUP,
    # Mobile's setup marker carries no GPU time (4.7.2 live capture); its heightfield draw is under Render Collider Heightfield.
    when_pass=["Render Collider Heightfield", "forward_plus:Setup GPUParticlesCollisionHeightField3D"],
))

add(dict(
    id="particles.many_systems",
    category="particles",
    title="Many particle nodes are in the scene",
    severity="low",
    heuristic=True,
    heuristic_rationale="Eight particle nodes is a review cut so a scene full of systems is surfaced. It is not an engine limit.",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=scgte("particle_node_count", 8),
    evidence="The combined GPUParticles2D/3D and CPUParticles2D/3D count is at least 8. Emission state and actual workload still need measurement.",
    suggestion="Stop emission on systems that are off camera, or merge similar effects. amount still caps each system.",
    offender_key="particle_nodes",
    tradeoff="Fewer simultaneous effects.",
    expected_effect="Fewer particle updates. Measure TIME_PROCESS and the GPU frame.",
    verify_step="scan_scene",
    source=PART,
))

# --- decals -----------------------------------------------------------------

add(dict(
    id="decals.count",
    category="decals",
    title="Many decals are in the scene",
    severity="medium",
    heuristic=True,
    heuristic_rationale="Sixteen decals is a review cut. The decal page says Forward+ clusters as many as performance allows, with a default limit of 512 clustered elements in view.",
    renderers=FPM, versions=BOTH, requires=["scene"],
    condition=scgte("decal_count", 16),
    evidence="The scan found at least 16 Decal nodes. Decals are Forward+ and Mobile only.",
    suggestion="Enable Decal.distance_fade_enabled so distant decals drop out, and stay under rendering/limits/cluster_builder/max_clustered_elements together with lights and probes.",
    node_property="Decal.distance_fade_enabled",
    offender_key="decals",
    tradeoff="Decals fade out over distance_fade_length.",
    expected_effect="Fewer clustered decals in view.",
    verify_step="scan_scene",
    source=DECAL,
))

add(dict(
    id="decals.no_distance_fade",
    category="decals",
    title="Decals have no distance fade",
    severity="low",
    renderers=FPM, versions=BOTH, requires=["scene"],
    condition=scgte("decal_without_distance_fade_count", 4),
    evidence="At least four Decal nodes leave distance_fade_enabled off. The optimizing-3D page says decals can use their distance fade for level of detail.",
    suggestion="Enable distance_fade_enabled on decals that are not always next to the camera.",
    node_property="Decal.distance_fade_enabled",
    offender_key="decals_no_fade",
    tradeoff="Decals fade before they reach the far plane.",
    expected_effect="Distant decals leave the cluster.",
    verify_step="scan_scene",
    source=OPT3D,
))

add(dict(
    id="decals.compatibility_renderer",
    category="decals",
    title="Decals are present under the Compatibility renderer",
    severity="high",
    renderers=["gl_compatibility"], versions=BOTH, requires=["scene"],
    condition=scgte("decal_count", 1),
    evidence="Decal nodes exist while the renderer is gl_compatibility. The decal page says decals are not supported on Compatibility and points at Sprite3D as a stand-in.",
    suggestion="Switch to Forward+ or Mobile, or replace Decal nodes with Sprite3D.",
    node_property="Decal",
    tradeoff="Sprite3D does not project onto arbitrary geometry the same way.",
    expected_effect="The decals become visible. They currently are not part of the Compatibility renderer.",
    verify_step="scan_scene",
    source=DECAL,
))

add(dict(
    id="decals.large_size",
    category="decals",
    title="A decal is very large",
    severity="low",
    heuristic=True,
    heuristic_rationale="A decal size axis of 50 meters or more covers a large cluster region. The property range goes to 1024. 50 is a review cut.",
    renderers=FPM, versions=BOTH, requires=["scene"],
    condition=scgte("decal_large_count", 1),
    evidence="A Decal has a size component >= 50.",
    suggestion="Shrink the decal to the stain it represents so it overlaps fewer clusters.",
    node_property="Decal.size",
    offender_key="decals_large",
    tradeoff="The projection covers less surface.",
    expected_effect="Less cluster overlap.",
    verify_step="scan_scene",
    source=DECAL,
))

# --- sky --------------------------------------------------------------------

add(dict(
    id="sky.quality_mode",
    category="sky",
    title="Sky process mode is Quality",
    severity="medium",
    renderers=FPM, versions=BOTH, requires=["scene"],
    condition=scgte("sky_quality_count", 1),
    evidence="Sky.process_mode is 1 (Quality). The Sky class says Quality uses importance sampling, looks better than Real-Time (3), takes much longer to generate, and should not be used if the sky changes at runtime. Automatic is 0.",
    suggestion="Use PROCESS_MODE_AUTOMATIC, or REALTIME (3) if the sky changes every frame. Real-Time is the fast filter, not the expensive one.",
    node_property="Sky.process_mode",
    offender_key="sky_quality",
    tradeoff="Real-Time radiance is lower quality. The class says to raise ggx_samples if Quality reflections sparkle.",
    expected_effect="The radiance map generates faster when the sky changes.",
    verify_step="scan_scene",
    source=SKY,
))

add(dict(
    id="sky.radiance_size",
    category="sky",
    title="Sky radiance size is 1024 or 2048",
    severity="medium",
    renderers=FPM, versions=BOTH, requires=["scene"],
    condition=scgte("sky_radiance_large_count", 1),
    evidence="Sky.radiance_size index is 5 or 6 (1024 or 2048). The enum runs 32, 64, 128, 256, 512, 1024, 2048. The class reference default is 3 (256).",
    suggestion="Set radiance_size to 3 (256) or 4 (512).",
    node_property="Sky.radiance_size",
    offender_key="sky_radiance",
    tradeoff="Rough reflections of the sky lose detail.",
    expected_effect="A smaller radiance cubemap.",
    verify_step="scan_scene",
    source=SKY,
))

add(dict(
    id="sky.background_keep",
    category="sky",
    title="Environment background mode is Keep",
    severity="info",
    kind="info",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=sceq("env_background_keep", 1),
    evidence="background_mode is Keep (index 4 of Clear Color, Custom Color, Sky, Canvas, Keep, Camera Feed). The environment page says Keep skips drawing the sky and is faster for indoor scenes, but mirrors if the sky is ever visible.",
    suggestion="Keep this mode for interiors. Switch to Sky or Custom Color if the background is visible.",
    node_property="Environment.background_mode",
    tradeoff="A real sky costs the sky pass.",
    expected_effect="The page already calls Keep the faster indoor background. No further cut is implied.",
    verify_step="scan_scene",
    source=ENV,
))

add(dict(
    id="sky.custom_fov",
    category="sky",
    title="Sky custom FOV is set",
    severity="info",
    kind="info",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=scgte("sky_custom_fov_count", 1),
    evidence="Environment.sky_custom_fov is above 0 (the property range is 0–180).",
    suggestion="Set sky_custom_fov to 0 to follow the camera. A custom FOV does not remove the sky pass.",
    node_property="Environment.sky_custom_fov",
    tradeoff="The sky's perspective matches the camera again.",
    expected_effect="No frame-time claim. This is a visual mismatch check.",
    verify_step="scan_scene",
    source=ENVCLS,
))

# --- canvas -----------------------------------------------------------------

add(dict(
    id="canvas.pcf13",
    category="canvas",
    title="A 2D light uses PCF13 shadows",
    severity="high",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=scgte("canvas_pcf13_count", 1),
    evidence="Light2D.shadow_filter is 2 (PCF13). The 2D lights page says PCF13 is the softest and the most expensive, and should be used on only a few lights. PCF5 is 1 and None is 0.",
    suggestion="Set shadow_filter to 1 (PCF5) or 0 (None).",
    node_property="Light2D.shadow_filter",
    offender_key="canvas_pcf13",
    tradeoff="2D shadows look harder.",
    expected_effect="A cheaper 2D shadow filter than the one the page calls the most demanding.",
    verify_step="scan_scene",
    source=D2,
    when_pass=["Render PointLight2D Shadow", "Render DirectionalLight2D Shadows"],
))

add(dict(
    id="canvas.many_shadow_lights",
    category="canvas",
    title="Several 2D lights cast shadows",
    severity="medium",
    heuristic=True,
    heuristic_rationale="Four shadow-casting Light2D nodes is a review cut. The 2D lights page says even PCF13 should be limited to a few lights.",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=scgte("canvas_shadow_light_count", 4),
    evidence="At least four Light2D nodes have shadow_enabled.",
    suggestion="Disable shadow_enabled on fill lights. Leave shadows on the one or two lights that define the silhouette.",
    node_property="Light2D.shadow_enabled",
    offender_key="canvas_shadow_lights",
    tradeoff="Those 2D lights stop casting shadows.",
    expected_effect="Fewer 2D shadow renders.",
    verify_step="scan_scene",
    source=D2,
))

add(dict(
    id="canvas.hdr_2d",
    category="canvas",
    title="2D HDR is enabled",
    severity="low",
    renderers=FPM, versions=BOTH, requires=["settings"],
    condition=seq("rendering/viewport/hdr_2d", True),
    evidence="rendering/viewport/hdr_2d is true. The default is false.",
    suggestion="Turn hdr_2d off unless 2D glow or HDR canvases need values above 1.",
    setting="rendering/viewport/hdr_2d",
    tradeoff="2D buffers go back to the low-dynamic-range format. Bright 2D glow can clip.",
    expected_effect="A narrower 2D framebuffer. Measure canvas time if 2D is the scene.",
    verify_step="collect_metrics",
    source=PROJ,
))

add(dict(
    id="canvas.sdf_oversize",
    category="canvas",
    title="2D SDF oversize is above the default",
    severity="low",
    renderers=ALL, versions=BOTH, requires=["settings", "scene"],
    condition=all_(scgte("canvas_light_count", 1), sgte("rendering/2d/sdf/oversize", 2)),
    evidence="sdf/oversize index is 2 or 3. The hint is 100%, 120%, 150%, 200%. The default index is 1 (120%). A 2D light is in the scene.",
    suggestion="Set rendering/2d/sdf/oversize to 1.",
    setting="rendering/2d/sdf/oversize",
    tradeoff="The signed-distance field covers less margin around the viewport.",
    expected_effect="A smaller 2D SDF texture.",
    verify_step="collect_metrics",
    source=PROJ,
))

add(dict(
    id="canvas.sdf_scale",
    category="canvas",
    title="2D SDF scale is at full resolution",
    severity="low",
    kind="quality_up",
    renderers=ALL, versions=BOTH, requires=["settings", "scene"],
    condition=all_(scgte("canvas_shadow_light_count", 1), seq("rendering/2d/sdf/scale", 0)),
    evidence="sdf/scale index is 0. The hint is 100%, 50%, 25%. The default index is 1 (50%). Shadow-casting 2D lights are present.",
    suggestion="The default 50% scale is the cheaper SDF. Index 0 is the sharper, heavier field. Set it back to 1 if you did not choose 100% on purpose.",
    setting="rendering/2d/sdf/scale",
    tradeoff="50% SDF is blurrier around 2D shadows.",
    expected_effect="A quarter of the SDF pixels versus 100%, because the scale is per axis.",
    verify_step="collect_metrics",
    source=PROJ,
))

add(dict(
    id="canvas.item_buffer",
    category="canvas",
    title="2D item buffer is above the default while canvas draws are high",
    severity="low",
    heuristic=True,
    heuristic_rationale="item_buffer_size defaults to 16384. The rule flags it only when it is larger than that and canvas draw calls exceed 1000. 1000 is a review cut, not a batching budget.",
    renderers=ALL, versions=BOTH, requires=["settings", "metrics"],
    condition=all_(
        sgt("rendering/2d/batching/item_buffer_size", 16384),
        mgt("VIEWPORT_CANVAS_DRAW_CALLS", 1000),
    ),
    evidence="item_buffer_size is above 16384 and the canvas viewport draw-call counter is above 1000.",
    suggestion="Lower item_buffer_size toward 16384 after confirming the 2D scene still batches. uniform_set_cache_size defaults to 4096.",
    setting="rendering/2d/batching/item_buffer_size",
    tradeoff="A buffer that is too small splits batches.",
    expected_effect="Less reserved 2D batch memory if the extra size is unused.",
    verify_step="collect_metrics",
    source=PROJ,
))

add(dict(
    id="canvas.draw_calls",
    category="canvas",
    title="Canvas draw calls are high",
    severity="medium",
    heuristic=True,
    heuristic_rationale="2000 canvas draw calls is a review cut so a 2D frame with a large VIEWPORT_CANVAS_DRAW_CALLS count is surfaced. Godot does not publish that number as a limit.",
    renderers=ALL, versions=BOTH, requires=["metrics"],
    condition=mgt("VIEWPORT_CANVAS_DRAW_CALLS", 2000),
    evidence="Viewport canvas draw calls are above 2000.",
    suggestion="Reuse textures and materials so CanvasItem batching can merge items. The GPU optimization page explains draw calls as the CPU-side submission cost.",
    tradeoff="Merging atlases changes how art is packed.",
    expected_effect="Fewer canvas draws. Read the counter again with collect_metrics.",
    verify_step="collect_metrics",
    source=GPU,
    when_pass=["Render CanvasItems"],
))

# --- CPU --------------------------------------------------------------------

add(dict(
    id="cpu.process_time",
    category="cpu",
    title="Process time beyond the GPU time exceeds half the frame budget",
    severity="high",
    heuristic=True,
    heuristic_rationale="Half the budget is a review threshold. Godot's per-frame process time (the span Performance.TIME_PROCESS reports, passed to profilers in main.cpp) also covers RenderingServer sync and draw, so it includes the wait for the GPU: the median GPU time is subtracted, and the rule is skipped when frame timing finds the run GPU-bound. The median of frame_timing's samples is used instead of the once-per-second TIME_PROCESS peak, which also caught Render Lens's own work in the game; a few spike frames, which stutter_report covers, can also move a 95th percentile of 40 samples. It cannot name a script.",
    renderers=ALL, versions=BOTH, requires=["metrics", "frame"],
    condition={"all": [{"metric_gt_budget_ratio": {"name": "PROCESS_MEDIAN_SEC", "ratio": 0.5, "minus_gpu": True}}, {"not": {"frame_bound": "gpu"}}]},
    evidence="The median process time of the frame_timing samples, less the median GPU time, exceeds half of the target frame budget.",
    suggestion="Profile _process and _physics_process. The CPU optimization page shows those built-in costs in the profiler. This rule does not name a script.",
    tradeoff="Depends on which script work you remove.",
    expected_effect="Compare actual frame_timing samples and script_profile before attributing work. A lower process median alone does not establish which work was saved.",
    verify_step="frame_timing",
    source=CPU,
))

add(dict(
    id="cpu.physics_time",
    category="cpu",
    title="Physics time is a large share of the frame budget",
    severity="high",
    heuristic=True,
    heuristic_rationale="TIME_PHYSICS_PROCESS above a third of the frame budget is a review cut. The monitor is seconds, per the Performance class.",
    renderers=ALL, versions=BOTH, requires=["metrics", "frame"],
    condition=ratio("TIME_PHYSICS_PROCESS", 0.33),
    evidence="Performance.TIME_PHYSICS_PROCESS exceeds a third of the target frame budget.",
    suggestion="Lower physics/common/physics_ticks_per_second toward 60 if it is higher, reduce collision shapes, and read PHYSICS_3D_ACTIVE_OBJECTS and PHYSICS_3D_COLLISION_PAIRS.",
    tradeoff="Fewer ticks change physics feel. Simpler shapes change gameplay collision.",
    expected_effect="Less time in the physics step.",
    verify_step="collect_metrics",
    source=CPU,
))

add(dict(
    id="cpu.navigation_time",
    category="cpu",
    title="Navigation time is a large share of the frame budget",
    severity="medium",
    heuristic=True,
    heuristic_rationale="TIME_NAVIGATION_PROCESS above a quarter of the frame budget is a review cut. The monitor is seconds.",
    renderers=ALL, versions=BOTH, requires=["metrics", "frame"],
    condition=ratio("TIME_NAVIGATION_PROCESS", 0.25),
    evidence="Performance.TIME_NAVIGATION_PROCESS exceeds a quarter of the target frame budget.",
    suggestion="Reduce navigation regions that rebuild, and check NAVIGATION_AGENT_COUNT and NAVIGATION_OBSTACLE_COUNT in the same snapshot.",
    tradeoff="Fewer agents or a coarser navmesh changes pathing.",
    expected_effect="Less navigation-server time.",
    verify_step="collect_metrics",
    source=PERF,
))

add(dict(
    id="cpu.physics_ticks",
    category="cpu",
    title="Physics ticks per second are above 60",
    severity="medium",
    renderers=ALL, versions=BOTH, requires=["settings"],
    condition=sgt("physics/common/physics_ticks_per_second", 60),
    evidence="physics_ticks_per_second is above 60. The default is 60 and the range is 1–1000.",
    suggestion="Set physics/common/physics_ticks_per_second to 60 unless the game needs a higher simulation rate.",
    setting="physics/common/physics_ticks_per_second",
    tradeoff="Physics and _physics_process run less often. Fast objects may need a different collision setup.",
    expected_effect="Fewer physics steps per second. The physics introduction is the overview of that step.",
    verify_step="collect_metrics",
    source=PHYS,
))

add(dict(
    id="cpu.max_physics_steps",
    category="cpu",
    title="Max physics steps per frame is above the default",
    severity="low",
    heuristic=True,
    heuristic_rationale="max_physics_steps_per_frame defaults to 8. A higher value lets a slow frame run more catch-up physics steps.",
    renderers=ALL, versions=BOTH, requires=["settings"],
    condition=sgt("physics/common/max_physics_steps_per_frame", 8),
    evidence="max_physics_steps_per_frame is above 8.",
    suggestion="Set it back to 8. If frames are dropping physics steps, the frame itself is over budget; raising this cap spends more CPU on catch-up.",
    setting="physics/common/max_physics_steps_per_frame",
    tradeoff="A stalled frame discards extra ticks sooner, so the simulation can hitch instead of spiraling.",
    expected_effect="A lower CPU ceiling on catch-up ticks.",
    verify_step="collect_metrics",
    source=PROJ,
))

add(dict(
    id="cpu.solver_iterations",
    category="cpu",
    title="GodotPhysics solver iterations are above the default",
    severity="medium",
    renderers=ALL, versions=BOTH, requires=["settings"],
    condition=all_(
        seq("physics/3d/physics_engine", "GodotPhysics3D"),
        sgt("physics/3d/solver/solver_iterations", 16),
    ),
    evidence="physics_engine is GodotPhysics3D and solver_iterations is above 16. The default is 16 and the range is 1–32. This setting is the GodotPhysics solver, not Jolt's velocity_steps.",
    suggestion="Set solver_iterations back to 16.",
    setting="physics/3d/solver/solver_iterations",
    tradeoff="Stacks and constraints settle less accurately.",
    expected_effect="Less work per GodotPhysics step.",
    verify_step="collect_metrics",
    source=PROJ,
))

add(dict(
    id="cpu.jolt_kinematic_contacts",
    category="cpu",
    title="Jolt generates all kinematic contacts",
    severity="high",
    renderers=ALL, versions=BOTH, requires=["settings"],
    condition=all_(
        seq("physics/3d/physics_engine", "Jolt Physics"),
        seq("physics/jolt_physics_3d/simulation/generate_all_kinematic_contacts", True),
    ),
    evidence="generate_all_kinematic_contacts is true. The Jolt page says kinematic bodies skip static contacts by default because reporting them all can waste CPU and memory, and the setting is opt-in.",
    suggestion="Set generate_all_kinematic_contacts to false unless those contacts are required.",
    setting="physics/jolt_physics_3d/simulation/generate_all_kinematic_contacts",
    tradeoff="Kinematic bodies stop reporting contacts against static geometry.",
    expected_effect="Less Jolt contact work, which the page describes as the reason the default is off.",
    verify_step="collect_metrics",
    source=JOLT,
))

add(dict(
    id="cpu.jolt_face_index",
    category="cpu",
    title="Jolt ray-cast face index is enabled",
    severity="low",
    renderers=ALL, versions=BOTH, requires=["settings"],
    condition=all_(
        seq("physics/3d/physics_engine", "Jolt Physics"),
        seq("physics/jolt_physics_3d/queries/enable_ray_cast_face_index", True),
    ),
    evidence="enable_ray_cast_face_index is true. The Jolt page says face_index stays -1 by default and enabling it raises ConcavePolygonShape3D memory by about 25%.",
    suggestion="Turn enable_ray_cast_face_index off if queries do not read face_index.",
    setting="physics/jolt_physics_3d/queries/enable_ray_cast_face_index",
    tradeoff="intersect_ray face_index returns -1.",
    expected_effect="The memory increase the page describes goes away.",
    verify_step="collect_metrics",
    source=JOLT,
))

add(dict(
    id="cpu.orphan_nodes",
    category="cpu",
    title="Orphan nodes exist",
    severity="high",
    renderers=ALL, versions=BOTH, requires=["metrics"],
    condition=mgt("OBJECT_ORPHAN_NODE_COUNT", 0),
    evidence="Performance.OBJECT_ORPHAN_NODE_COUNT is above 0. The class reference defines these as nodes not parented to the scene tree and says lower is better.",
    suggestion="Free nodes that were removed from the tree without queue_free. This is a leak signal, not a tuning knob.",
    tradeoff="None, if the orphans are truly unused.",
    expected_effect="OBJECT_ORPHAN_NODE_COUNT returns to 0 after the leaked nodes are freed.",
    verify_step="collect_metrics",
    source=PERF,
))

add(dict(
    id="cpu.collision_pairs",
    category="cpu",
    title="3D collision pair count is high",
    severity="medium",
    heuristic=True,
    heuristic_rationale="500 is not a Godot physics limit (Jolt's max_body_pairs default is 65536). It flags PHYSICS_3D_COLLISION_PAIRS so a broadphase that is doing a lot of work is visible.",
    renderers=ALL, versions=BOTH, requires=["metrics"],
    condition=mgt("PHYSICS_3D_COLLISION_PAIRS", 500),
    evidence="PHYSICS_3D_COLLISION_PAIRS is above 500.",
    suggestion="Shrink collision shapes, freeze sleeping bodies, and avoid large Area3D overlaps. Read PHYSICS_3D_ACTIVE_OBJECTS in the same snapshot.",
    tradeoff="Smaller shapes miss some contacts.",
    expected_effect="Fewer pairs. Measure TIME_PHYSICS_PROCESS.",
    verify_step="collect_metrics",
    source=PERF,
))

add(dict(
    id="cpu.active_bodies",
    category="cpu",
    title="Many 3D physics objects are active",
    severity="medium",
    heuristic=True,
    heuristic_rationale="100 active 3D objects is a review cut. Jolt's max_bodies default is 10240, so this is not that cap.",
    renderers=ALL, versions=BOTH, requires=["metrics"],
    condition=mgt("PHYSICS_3D_ACTIVE_OBJECTS", 100),
    evidence="PHYSICS_3D_ACTIVE_OBJECTS is above 100.",
    suggestion="Let rigid bodies sleep. The Jolt page documents allow_sleep (default true) and the cost of contacts that never sleep.",
    tradeoff="Sleeping bodies do not react until woken.",
    expected_effect="Fewer active bodies on later snapshots.",
    verify_step="collect_metrics",
    source=PERF,
))

add(dict(
    id="cpu.separate_thread_off",
    category="cpu",
    title="Physics is on the main thread while physics time is high",
    severity="low",
    heuristic=True,
    heuristic_rationale="Suggests the separate-thread setting only when TIME_PHYSICS_PROCESS already exceeds a third of the budget. The 4.4 Jolt page calls that threading support experimental.",
    renderers=ALL, versions=BOTH, requires=["settings", "metrics", "frame"],
    condition=all_(
        seq("physics/3d/run_on_separate_thread", False),
        ratio("TIME_PHYSICS_PROCESS", 0.33),
    ),
    evidence="physics/3d/run_on_separate_thread is false and physics time is a large share of the budget. The default is false.",
    suggestion="Try enabling run_on_separate_thread and re-measure. The Jolt page says the module's thread safety, including this setting, is experimental.",
    setting="physics/3d/run_on_separate_thread",
    tradeoff="Threaded physics has the experimental status the Jolt page describes, and gameplay code must not assume physics state mid-frame.",
    expected_effect="Physics work can overlap the frame. Confirm TIME_PHYSICS_PROCESS and frame time; do not assume a speedup.",
    verify_step="frame_timing",
    source=JOLT,
))

add(dict(
    id="cpu.scene_bodies",
    category="cpu",
    title="The edited scene contains many physics bodies",
    severity="low",
    heuristic=True,
    heuristic_rationale="80 physics bodies in the scanned scene is a review cut so a crowded collision scene is visible before play mode. It is not PHYSICS_3D_ACTIVE_OBJECTS.",
    renderers=ALL, versions=BOTH, requires=["scene"],
    condition=scgte("physics_body_3d_count", 80),
    evidence="The scan found at least 80 PhysicsBody3D nodes.",
    suggestion="Merge static geometry into fewer shapes and remove bodies that never collide.",
    offender_key="physics_bodies",
    tradeoff="Merged colliders are coarser.",
    expected_effect="Fewer bodies for the broadphase once the scene runs.",
    verify_step="scan_scene",
    source=PHYS,
))

# --- memory -----------------------------------------------------------------

add(dict(
    id="memory.video_mem",
    category="memory",
    title="Video memory in use is above 512 MiB",
    severity="medium",
    heuristic=True,
    heuristic_rationale="512 MiB is not a Godot limit and not the GPU's capacity. RENDER_VIDEO_MEM_USED is the engine's byte counter, and the class reference says it includes texture, buffer, and miscellaneous allocations.",
    renderers=ALL, versions=BOTH, requires=["metrics"],
    condition=mgte("RENDER_VIDEO_MEM_USED", 512 * 1024 * 1024),
    evidence="RENDER_VIDEO_MEM_USED is at least 512 MiB.",
    suggestion="Compare RENDER_TEXTURE_MEM_USED and RENDER_BUFFER_MEM_USED in the same snapshot. Shrink shadow atlases, reflection size, and uncompressed textures. Godot does not report total VRAM capacity through this monitor.",
    tradeoff="Smaller textures and shadow maps lose detail.",
    expected_effect="The byte counters drop after those assets shrink. No capacity percentage is available from the monitor.",
    verify_step="collect_metrics",
    source=PERF,
))

add(dict(
    id="memory.message_queue",
    category="memory",
    title="Message-queue peak is near its cap",
    severity="high",
    heuristic=True,
    heuristic_rationale="0.9 is not an engine watermark. MEMORY_MESSAGE_BUFFER_MAX is the peak bytes, compared with memory/limits/message_queue/max_size_mb (default 32).",
    renderers=ALL, versions=BOTH, requires=["metrics", "settings"],
    condition={"message_queue_ratio_gte": {"ratio": 0.9}},
    evidence="The message-buffer peak is at least 90% of max_size_mb.",
    suggestion="Find the deferred calls or resource loads that fill the queue before raising max_size_mb. Raising the cap hides the spike and uses more RAM.",
    setting="memory/limits/message_queue/max_size_mb",
    tradeoff="A higher cap uses more memory. A full queue drops or stalls deferred work.",
    expected_effect="The peak stays under the cap after the spike is removed.",
    verify_step="collect_metrics",
    source=PERF,
))

add(dict(
    id="memory.static_high",
    category="memory",
    title="Static memory is above 512 MiB",
    severity="low",
    heuristic=True,
    heuristic_rationale="512 MiB of MEMORY_STATIC is a review cut. The monitor is bytes of statically allocated memory, not a leak by itself. Compare it with MEMORY_STATIC_MAX.",
    renderers=ALL, versions=BOTH, requires=["metrics"],
    condition=mgte("MEMORY_STATIC", 512 * 1024 * 1024),
    evidence="MEMORY_STATIC is at least 512 MiB.",
    suggestion="Look at loaded resources (OBJECT_RESOURCE_COUNT) and textures. Static memory does not mean a leak unless it grows across snapshots.",
    tradeoff="Unloading resources changes what is available without a load hit.",
    expected_effect="A later snapshot should show a lower MEMORY_STATIC if unused resources were released.",
    verify_step="collect_metrics",
    source=PERF,
))

add(dict(
    id="memory.object_count",
    category="memory",
    title="Object count is very high",
    severity="medium",
    heuristic=True,
    heuristic_rationale="20000 Object instances is a review cut. OBJECT_COUNT is the Performance monitor for live Objects. Godot does not define this threshold.",
    renderers=ALL, versions=BOTH, requires=["metrics"],
    condition=mgt("OBJECT_COUNT", 20000),
    evidence="OBJECT_COUNT is above 20000.",
    suggestion="Compare OBJECT_NODE_COUNT and OBJECT_RESOURCE_COUNT. Free unused resources and orphan nodes.",
    tradeoff="Unloaded resources hitch when requested again.",
    expected_effect="OBJECT_COUNT falls after unused objects are freed.",
    verify_step="collect_metrics",
    source=PERF,
))

add(dict(
    id="memory.resource_count",
    category="memory",
    title="Resource count is very high",
    severity="low",
    heuristic=True,
    heuristic_rationale="5000 resources is a review cut on OBJECT_RESOURCE_COUNT so a project that has loaded a large library is visible.",
    renderers=ALL, versions=BOTH, requires=["metrics"],
    condition=mgt("OBJECT_RESOURCE_COUNT", 5000),
    evidence="OBJECT_RESOURCE_COUNT is above 5000.",
    suggestion="Load scenes on demand instead of keeping every packed resource in memory.",
    tradeoff="The next use pays a load.",
    expected_effect="Fewer resident resources.",
    verify_step="collect_metrics",
    source=PERF,
))

add(dict(
    id="memory.buffer_mem",
    category="memory",
    title="Buffer memory is above 256 MiB",
    severity="low",
    heuristic=True,
    heuristic_rationale="256 MiB of RENDER_BUFFER_MEM_USED is a review cut. The class reference says this is buffer memory in bytes, separate from texture memory.",
    renderers=ALL, versions=BOTH, requires=["metrics"],
    condition=mgte("RENDER_BUFFER_MEM_USED", 256 * 1024 * 1024),
    evidence="RENDER_BUFFER_MEM_USED is at least 256 MiB.",
    suggestion="Look at mesh vertex buffers and GPU particle buffers. Vertex memory is part of the video total the class reference describes.",
    tradeoff="Simpler meshes lose silhouette detail. Mesh LOD is the documented way to cut that.",
    expected_effect="Buffer bytes drop if large meshes are simplified.",
    verify_step="collect_metrics",
    source=PERF,
))

# --- stutter ----------------------------------------------------------------

add(dict(
    id="stutter.shader_cache_off",
    category="stutter",
    title="Shader cache is disabled",
    severity="high",
    renderers=FPM, versions=BOTH, requires=["settings"],
    condition=seq("rendering/shader_compiler/shader_cache/enabled", False),
    evidence="shader_cache/enabled is false. The default is true. compress and use_zstd_compression also default to true.",
    suggestion="Set rendering/shader_compiler/shader_cache/enabled to true so compiled shaders are reused across runs.",
    setting="rendering/shader_compiler/shader_cache/enabled",
    tradeoff="The cache uses disk. strip_debug defaults to false in the editor and true on release.",
    expected_effect="Later runs skip shader compiles that the cache can serve. The pipeline page separates shader compilation from pipeline compilation.",
    verify_step="collect_metrics",
    source=PIPE,
))

add(dict(
    id="stutter.pipeline_cache_off",
    category="stutter",
    title="Pipeline cache is disabled",
    severity="high",
    renderers=FPM, versions=BOTH, requires=["settings"],
    condition=seq("rendering/rendering_device/pipeline_cache/enable", False),
    evidence="pipeline_cache/enable is false. The default is true.",
    suggestion="Set rendering/rendering_device/pipeline_cache/enable to true.",
    setting="rendering/rendering_device/pipeline_cache/enable",
    tradeoff="The pipeline cache file grows on disk (save_chunk_size_mb defaults to 3).",
    expected_effect="Driver pipelines can be reused. The pipeline page describes compilation stutter when they are created during play.",
    verify_step="collect_metrics",
    source="https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/best_practices/bp_pipeline.cpp",
    upstream_check="BestPractices-vkCreateGraphicsPipelines-multiple-pipelines-no-cache",
    evidence_kind="godot_adaptation",
    heuristic=True,
    heuristic_rationale="Godot exposes the cache setting, not individual Vulkan pipeline creations or cache handles. Compare repeat runs; this is not proof that the upstream API condition fired.",
))

add(dict(
    id="stutter.compilations_canvas",
    category="stutter",
    title="Canvas pipeline compilations have occurred",
    severity="medium",
    renderers=FPM, versions=BOTH, requires=["metrics"],
    condition=mgt("PIPELINE_COMPILATIONS_CANVAS", 0),
    evidence="PIPELINE_COMPILATIONS_CANVAS is above 0. The pipeline page says 2D has no precompilation, so the first draw of a CanvasItem can hitch.",
    suggestion="Show every 2D material once during a loading screen. The page says canvas compilations are the 2D case.",
    tradeoff="The loading screen has to instance those canvases.",
    expected_effect="The hitch moves to load time. A later snapshot should not climb on the same items.",
    verify_step="collect_metrics",
    source=PIPE,
))

add(dict(
    id="stutter.compilations_mesh",
    category="stutter",
    title="Mesh pipeline compilations have occurred",
    severity="medium",
    renderers=FPM, versions=BOTH, requires=["metrics"],
    condition=mgt("PIPELINE_COMPILATIONS_MESH", 0),
    evidence="PIPELINE_COMPILATIONS_MESH is above 0. The page says mesh compilations happen while loading a mesh and show up as longer loads, and a background load avoids a gameplay hitch.",
    suggestion="Load meshes on a background thread before they are needed in gameplay.",
    tradeoff="Background loads still take time and memory.",
    expected_effect="The mesh-step count should not spike during gameplay after the preload.",
    verify_step="collect_metrics",
    source=PIPE,
))

add(dict(
    id="stutter.compilations_surface",
    category="stutter",
    title="Surface pipeline compilations have occurred",
    severity="medium",
    renderers=FPM, versions=BOTH, requires=["metrics"],
    condition=mgt("PIPELINE_COMPILATIONS_SURFACE", 0),
    evidence="PIPELINE_COMPILATIONS_SURFACE is above 0. The page says a sudden surface-step increase usually means a rendering feature was enabled after load, and that changing features during play hitches.",
    suggestion="Enable MSAA, glow, SSR, and similar features before gameplay, on a loading screen. The page lists features the precompilation system has to see first.",
    tradeoff="The loading screen does the compile.",
    expected_effect="Surface compilations stop appearing mid-game for features that were already enabled.",
    verify_step="collect_metrics",
    source=PIPE,
))

add(dict(
    id="stutter.compilations_draw",
    category="stutter",
    title="Draw-step pipeline compilations have occurred",
    severity="high",
    renderers=FPM, versions=BOTH, requires=["metrics"],
    condition=mgt("PIPELINE_COMPILATIONS_DRAW", 0),
    evidence="PIPELINE_COMPILATIONS_DRAW is above 0. The pipeline page says draw-step compilations mean an ubershader was not precompiled and the hitch matches pre-4.4 shader stutter. There is no project setting that disables ubershaders.",
    suggestion="Treat a rising draw counter as a bug to reproduce for the engine if your materials are ordinary, which is what the page asks. Also make sure shader_cache and pipeline_cache are enabled.",
    tradeoff="None for leaving caches on.",
    expected_effect="Draw-step compilations should stay at zero in normal play. The page says this case should not happen when the ubershader path works.",
    verify_step="collect_metrics",
    source=PIPE,
))

add(dict(
    id="stutter.compilations_specialization",
    category="stutter",
    title="Specialization pipeline compilations are climbing",
    severity="low",
    renderers=FPM, versions=BOTH, requires=["metrics"],
    condition=mgt("PIPELINE_COMPILATIONS_SPECIALIZATION", 0),
    evidence="PIPELINE_COMPILATIONS_SPECIALIZATION is above 0. The page says specializations compile in the background to optimize the frame rate and are the expected ubershader follow-up, unlike draw-step hitches.",
    suggestion="Do not treat this counter like DRAW. A large spike in one frame can still hitch; check it next to frame time.",
    tradeoff="Specializations are what make the later frames cheaper.",
    expected_effect="Background specializations, not a settings change.",
    verify_step="collect_metrics",
    source=PIPE,
))

add(dict(
    id="stutter.draw_calls_high",
    category="stutter",
    title="Frame draw-call count is high",
    severity="medium",
    heuristic=True,
    heuristic_rationale="300 is not a Godot draw-call budget. RENDER_TOTAL_DRAW_CALLS_IN_FRAME above that is a review cut so a CPU-bound scene with several hundred draws is listed. 1500 is not a Godot budget either. The GPU optimization page describes draw calls as CPU submission cost.",
    renderers=ALL, versions=BOTH, requires=["metrics"],
    condition=mgt("RENDER_TOTAL_DRAW_CALLS_IN_FRAME", 300),
    evidence="RENDER_TOTAL_DRAW_CALLS_IN_FRAME is above 300.",
    suggestion="Compare VIEWPORT_VISIBLE_DRAW_CALLS and VIEWPORT_SHADOW_DRAW_CALLS. Merge materials, use MultiMesh, and reduce shadow casters.",
    tradeoff="Batching constraints change how materials are authored.",
    expected_effect="A lower draw-call counter. The page says frame time is the measurement that matters, not the counter alone.",
    verify_step="collect_metrics",
    source=GPU,
))

# --- pacing -----------------------------------------------------------------

add(dict(
    id="pacing.vsync_off_uncapped",
    category="pacing",
    title="VSync is off and the frame rate is uncapped",
    severity="medium",
    renderers=ALL, versions=BOTH, requires=["settings"],
    condition=all_(
        seq("display/window/vsync/vsync_mode", 0),
        seq("application/run/max_fps", 0),
    ),
    evidence="vsync_mode is 0 (Disabled) and max_fps is 0 (uncapped). The vsync hint is Disabled, Enabled, Adaptive, Mailbox. The default vsync mode is 1 (Enabled) and the default max_fps is 0.",
    suggestion="Enable vsync (1) or set application/run/max_fps to the target rate so the frame does not run ahead of the display.",
    setting="display/window/vsync/vsync_mode",
    tradeoff="VSync adds latency. A cap without vsync can still tear.",
    expected_effect="Frame pacing follows the display or the cap. TIME_FPS should sit near that rate.",
    verify_step="frame_timing",
    source=PROJ,
))

add(dict(
    id="pacing.vsync_off_with_cap",
    category="pacing",
    title="VSync is off with a max_fps cap",
    severity="low",
    renderers=ALL, versions=BOTH, requires=["settings"],
    condition=all_(
        seq("display/window/vsync/vsync_mode", 0),
        sgt("application/run/max_fps", 0),
    ),
    evidence="vsync_mode is Disabled and max_fps is above 0.",
    suggestion="Expect tearing. Turn vsync on if the cap was only meant to limit CPU use.",
    setting="display/window/vsync/vsync_mode",
    tradeoff="VSync latency versus tearing.",
    expected_effect="The image stops tearing if the display supports the selected mode. Adaptive is 2 and Mailbox is 3.",
    verify_step="frame_timing",
    source=PROJ,
))

add(dict(
    id="pacing.max_fps_below_target",
    category="pacing",
    title="max_fps is below the advise target",
    severity="medium",
    renderers=ALL, versions=BOTH, requires=["settings", "frame"],
    condition={"max_fps_below_target": True},
    evidence="application/run/max_fps is greater than 0 and lower than the target_fps passed to advise or frame_timing.",
    suggestion="Raise max_fps to the target, or to 0 if vsync should govern the rate.",
    setting="application/run/max_fps",
    tradeoff="A higher cap lets the frame run hotter if vsync is off.",
    expected_effect="The cap stops being the reason TIME_FPS cannot reach the target.",
    verify_step="frame_timing",
    source=PROJ,
))

add(dict(
    id="pacing.low_processor",
    category="pacing",
    title="Low-processor mode is on",
    severity="info",
    kind="info",
    renderers=ALL, versions=BOTH, requires=["settings"],
    condition=seq("application/run/low_processor_mode", True),
    evidence="application/run/low_processor_mode is true. The default is false. low_processor_mode_sleep_usec defaults to 6900.",
    suggestion="Turn low_processor_mode off while measuring a game. It sleeps the main loop and will not represent gameplay frame time. frame_timing already disables it for the sample window.",
    setting="application/run/low_processor_mode",
    tradeoff="The editor or tool uses more CPU when this is off.",
    expected_effect="The measured frame is no longer sleeping on purpose.",
    verify_step="collect_metrics",
    source=PROJ,
))

add(dict(
    id="pacing.frame_queue",
    category="pacing",
    title="Rendering-device frame queue size is 3",
    severity="info",
    kind="info",
    renderers=FPM, versions=BOTH, requires=["settings"],
    condition=sgte("rendering/rendering_device/vsync/frame_queue_size", 3),
    evidence="frame_queue_size is 3. The range is 2–3 and the default is 2. swapchain_image_count defaults to 3 (range 2–4).",
    suggestion="Leave the queue at 2 if you are chasing latency. A deeper queue can smooth pacing and adds frames of latency.",
    setting="rendering/rendering_device/vsync/frame_queue_size",
    tradeoff="A shorter queue can stutter if the GPU falls a frame behind.",
    expected_effect="Lower presentation latency. Confirm with frame_timing rather than a formula.",
    verify_step="frame_timing",
    source=PROJ,
))

add(dict(
    id="pacing.mailbox_vsync",
    category="pacing",
    title="VSync mode is Mailbox",
    severity="info",
    kind="info",
    renderers=ALL, versions=BOTH, requires=["settings"],
    condition=seq("display/window/vsync/vsync_mode", 3),
    evidence="vsync_mode is 3 (Mailbox).",
    suggestion="Mailbox is a valid low-latency present mode when the driver supports it. If the display stutters, compare with Enabled (1).",
    setting="display/window/vsync/vsync_mode",
    tradeoff="Enabled can add latency. Mailbox can still tear on drivers that do not support it cleanly.",
    expected_effect="No change is required. Re-measure if you switch modes.",
    verify_step="frame_timing",
    source=PROJ,
))

add(dict(
    id="pacing.fps_below_target",
    category="pacing",
    title="Measured FPS is below the target",
    severity="high",
    renderers=ALL, versions=BOTH, requires=["metrics", "frame"],
    condition={"fps_below_target": True},
    evidence="TIME_FPS is above 1 and below the target rate from the frame budget. TIME_FPS is frames per second, per the Performance class.",
    suggestion="Use the bound from frame_timing. GPU-bound frames should follow the measured pass list. Use script_profile to investigate CPU work; periodic Performance peaks do not identify a bottleneck.",
    tradeoff="Depends on which later suggestion you apply.",
    expected_effect="TIME_FPS should move toward the target after a real cut. This rule only reports the gap.",
    verify_step="frame_timing",
    source=PERF,
))

add(dict(
    id="pacing.shadow_draws_dominate",
    category="pacing",
    title="Shadow draw calls exceed visible draw calls",
    severity="high",
    renderers=ALL, versions=BOTH, requires=["metrics"],
    condition={"metric_gt_metric": {"left": "VIEWPORT_SHADOW_DRAW_CALLS", "right": "VIEWPORT_VISIBLE_DRAW_CALLS"}},
    evidence="VIEWPORT_SHADOW_DRAW_CALLS is greater than VIEWPORT_VISIBLE_DRAW_CALLS. Both come from viewport_get_render_info for the shadow and visible viewports.",
    suggestion="Disable shadows on lights that do not need them, switch omni shadows to dual paraboloid, and shorten directional shadow distance. The visible scene is no longer the larger draw submission.",
    tradeoff="Fewer real-time shadows.",
    expected_effect="The shadow counter should fall below the visible counter after the cut. No percentage is assumed.",
    verify_step="collect_metrics",
    source=RS,
))

# --- pass-only companions (game running, scene scan missed the feature) ----

PASS_RULES = [
    ("pass.shadows", "shadows", "A shadow timestamp is in the capture", ["Render Shadows", "Render OmniLight Shadows", "Directional/SpotLight Shadows"], "shadows",
     "Shadow timestamp names were recorded. The lights and optimizing-3D pages treat real-time shadows as one of the expensive features.",
     "Reduce shadow-casting lights, atlas size, and filter quality, then run gpu_passes again.", LIGHTS),
    ("pass.ssao", "post", "Process SSAO is in the capture", ["Process SSAO"], "ssao",
     "The Process SSAO timestamp is present. SSAO is Forward+ only.",
     "Turn Environment.ssao_enabled off or lower ssao/quality, then re-measure.", ENV),
    ("pass.ssil", "gi", "Process SSIL is in the capture", ["Process SSIL"], "ssil",
     "The Process SSIL timestamp is present. SSIL is Forward+ only.",
     "Turn Environment.ssil_enabled off or lower ssil/quality.", ENV),
    ("pass.ssr", "post", "Screen-space reflections are in the capture", ["Screen-Space Reflections", "Process SSR"], "ssr",
     "An SSR timestamp is present. SSR is Forward+ only.",
     "Turn Environment.ssr_enabled off or lower ssr_max_steps.", ENV),
    ("pass.glow", "post", "Glow is in the capture", ["Glow"], "glow",
     "The Glow timestamp is present.",
     "Turn Environment.glow_enabled off or set glow upscale to Linear (0).", ENV),
    ("pass.vfog", "post", "Volumetric fog is in the capture", FEATURE_PASSES["vfog"], "vfog",
     "Volumetric fog timestamps (Render Fog, Filter Fog, Integrate Fog) are present. Volumetric fog is Forward+ only.",
     "Turn volumetric_fog_enabled off or lower volume_size and volume_depth toward 64.", VFOG),
    ("pass.sdfgi", "gi", "SDFGI is in the capture", ["Render SDFGI"], "sdfgi",
     "Render SDFGI is present. SDFGI is Forward+ only.",
     "Turn sdfgi_enabled off or lower cascades and probe_ray_count.", SDFGI),
    ("pass.taa", "antialiasing", "TAA is in the capture", ["TAA"], "taa",
     "The TAA timestamp is present. TAA is Forward+ only and has a medium cost on the antialiasing page.",
     "Turn use_taa off if another antialiasing method is enough.", AA),
    ("pass.fsr2", "resolution", "FSR 2.2 is in the capture", ["FSR2"], "fsr2",
     "The FSR2 timestamp is present. FSR 2.2 is the slowest scaler on the resolution scaling page.",
     "Lower the scale only if you need the speed, or switch mode to bilinear or FSR 1.0.", SCALE),
    ("pass.sss", "post", "Subsurface scattering is in the capture", ["Sub-Surface Scattering"], "sss",
     "A subsurface timestamp is present.",
     "Disable subsurf_scatter on materials that do not need it, and keep the quality setting at Low.", PROJ),
]


for pid, cat, title, names, dedupe, evidence, suggestion, source in PASS_RULES:
    add(dict(
        id=pid,
        category=cat,
        title=title,
        severity="medium",
        heuristic=True,
        heuristic_rationale="The trigger is a RenderingDevice timestamp label substring from Godot's clustered renderer. Labels are not a stable public API. The rule fires only when that pass has exclusive time above 0.",
        renderers=FPM, versions=BOTH, requires=["passes"],
        condition=present(names),
        evidence=evidence,
        suggestion=suggestion,
        tradeoff="Turning the feature off changes the look described on the cited page.",
        expected_effect="That pass should shrink or disappear on the next gpu_passes capture. No percentage is predicted.",
        verify_step="gpu_passes frames=60",
        source=source,
        when_pass=names,
        dedupe_key=dedupe,
        pass_only=True,
    ))


def checkout_settings(checkout):
    """Documented ProjectSettings members from a sparse Godot checkout under .tmp/upstream."""
    path = os.path.join(ROOT, ".tmp", "upstream", checkout, "doc", "classes", "ProjectSettings.xml")
    if not os.path.exists(path):
        return set()
    import xml.etree.ElementTree as ET
    return {member.get("name") for member in ET.parse(path).getroot().iter("member")}


def checkout_members(checkout):
    """Class -> (parent, documented members and methods) from a sparse Godot checkout."""
    import glob
    import xml.etree.ElementTree as ET
    base = os.path.join(ROOT, ".tmp", "upstream", checkout)
    classes = {}
    for path in glob.glob(os.path.join(base, "doc", "classes", "*.xml")) + glob.glob(os.path.join(base, "modules", "*", "doc_classes", "*.xml")):
        root = ET.parse(path).getroot()
        classes[root.get("name")] = (root.get("inherits"), {item.get("name") for tag in ("member", "method") for item in root.iter(tag)})
    return classes


def node_property_members(spec):
    """(class, member) pairs of a rule's node_property: "Light3D.shadow_enabled", or "GPUParticles2D/3D.amount" for both."""
    match = re.fullmatch(r"([A-Z]\w*?)((?:\d?D)?(?:/\d?D)*)\.([a-z_0-9/]+)", spec or "")
    if not match:
        return []
    base, suffixes, member = match.groups()
    variants = [part for part in suffixes.split("/") if part] or [""]
    return [(base + variant, member) for variant in variants]


def has_member(classes, name, member):
    while name in classes:
        parent, members = classes[name]
        if member in members:
            return True
        name = parent
    return False


def walk_paths(node, found):
    if isinstance(node, dict):
        for k, v in node.items():
            if k == "path" and isinstance(v, str):
                found.add(v)
            else:
                walk_paths(v, found)
    elif isinstance(node, list):
        for item in node:
            walk_paths(item, found)


def main():
    import importlib.util
    extra_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "rules_12.py")
    spec = importlib.util.spec_from_file_location("rules_12", extra_path)
    extra = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(extra)
    extra.register(add)
    api_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "rules_api.py")
    api_spec = importlib.util.spec_from_file_location("rules_api", api_path)
    api_mod = importlib.util.module_from_spec(api_spec)
    api_spec.loader.exec_module(api_mod)
    api_mod.register(add)
    from rules_scene_checks import register as register_scene_checks
    register_scene_checks(add)
    from rules_runtime_warnings import register as register_runtime_warnings
    register_runtime_warnings(add)

    # These fire on Godot's own defaults, so they report only when the measured frame is over budget
    # (godot-demo-projects audit 2026-10-11: each fired in 12-50 of 139 untouched demos; post.glow_bicubic in 10 on
    # 2026-10-13, once the dedupe no longer hid it behind post.glow_enabled).
    for rule in rules:
        if rule["id"] in DEFAULT_TRADEOFFS:
            # The frame median, not TIME_FPS: one hitch drops the per-second count below target within budget.
            rule["condition"] = {"all": [rule["condition"], {"frame_over_budget": True}]}
            rule["requires"] = sorted(set(rule["requires"]) | {"frame"})
            rule["evidence"] += " This is Godot's default, so it is reported only when the measured frame is over budget."

    by_id = {r["id"]: r for r in rules}
    live_source = open(os.path.join(ROOT, "addons", "render_lens", "runtime", "experiment.gd"), encoding="utf-8").read()
    live = set(re.findall(r'^\t"([a-z0-9_/.]+)"', live_source, re.M))
    allowed_block = live_source[live_source.index("const ALLOWED_PROPERTIES"):]
    allowed_properties = {name: set(re.findall(r'"([a-z_0-9]+)"', props)) for name, props in
                          re.findall(r'"([A-Z]\w+)": \[([^\]]*)\]', allowed_block[:allowed_block.index("\n}")])}
    for rule_id, changes in EXPERIMENTS.items():
        if rule_id not in by_id:
            raise SystemExit("EXPERIMENTS names unknown rule " + rule_id)
        for change in changes:
            if "setting" in change and change["setting"] not in live:
                raise SystemExit("%s experiment setting %s has no live setter in runtime/experiment.gd" % (rule_id, change["setting"]))
        by_id[rule_id]["experiment"] = changes
    # Findings Godot itself already shows: a configuration warning in the editor's scene dock, or a warning it prints while
    # the game runs. package() lists them after the rest of their area, so top leads with what only Render Lens reports.
    for doc, status, shown in (("GODOT_COVERAGE.json", "implemented", "editor"), ("GODOT_RUNTIME_WARNINGS.json", "covered", "runtime")):
        for item in json.load(open(os.path.join(ROOT, "docs", doc), encoding="utf-8"))["warnings"]:
            if item["status"] == status:
                by_id[item["rule"]].setdefault("godot_warns", shown)
    for feature, rule_ids in FEATURE_RULES.items():
        for rule_id in rule_ids:
            by_id[rule_id]["when_pass"] = FEATURE_PASSES[feature]
    # A new performance rule about a timed feature must name its pass or say why it has none.
    unclassified = [r["id"] for r in rules if r["kind"] == "performance" and not r["when_pass"] and not r["share_from"]
                    and r["id"] not in NO_FEATURE_PASS and any(t in (r["id"] + json.dumps(r["condition"])).lower() for t in FEATURE_TOKENS)]
    if unclassified:
        raise SystemExit("performance rules about a timed feature, not in FEATURE_RULES or NO_FEATURE_PASS: %s" % unclassified)
    stale = [i for i in list(NO_FEATURE_PASS) + sum(FEATURE_RULES.values(), []) if i not in by_id]
    if stale:
        raise SystemExit("unknown rule ids in FEATURE_RULES/NO_FEATURE_PASS: %s" % stale)

    ids = [r["id"] for r in rules]
    if len(ids) != len(set(ids)):
        dup = [i for i in ids if ids.count(i) > 1]
        raise SystemExit("duplicate ids: %s" % sorted(set(dup)))
    if len(rules) < 120:
        raise SystemExit("only %d rules" % len(rules))

    # Every setting a rule reads must be documented in each version the rule lists as verified.
    dumps = {version: checkout_settings(GODOT_CHECKOUTS[version]) for version in SERIES}
    if all(dumps.values()):
        for rule in rules:
            paths = set()
            if rule["setting"]:
                paths.add(rule["setting"])
            walk_paths(rule["condition"], paths)
            for version in rule["applies_to"]["versions"]:
                for path in paths:
                    if path not in dumps[version]:
                        raise SystemExit("setting %s from %s missing in %s" % (path, rule["id"], version))

    class_pages = {}
    for tag, checkout in GODOT_CHECKOUTS.items():
        classes = checkout_members(checkout)
        if not classes:
            continue
        class_pages[tag] = {name.lower() for name in classes}
        for rule in rules:
            for owner, member in node_property_members(rule.get("node_property")):
                if tag in rule["applies_to"]["versions"] and not has_member(classes, owner, member):
                    raise SystemExit("node_property %s from %s missing in %s" % (rule["node_property"], rule["id"], tag))
        for rule_id, changes in EXPERIMENTS.items():
            for change in changes:
                owner = change.get("class") or ("Environment" if "environment" in change else "CameraAttributesPractical" if "camera_attributes" in change else None)
                if owner and tag in by_id[rule_id]["applies_to"]["versions"] and not has_member(classes, owner, change["property"].split(":")[0]):
                    raise SystemExit("%s experiment property %s.%s missing in %s" % (rule_id, owner, change["property"], tag))
                # runtime/experiment.gd changes only ALLOWED_PROPERTIES (on the class or a subclass); a preset outside them
                # would always fail.
                ancestor = owner
                while ancestor and change["property"] not in allowed_properties.get(ancestor, ()):
                    ancestor = classes.get(ancestor, (None, None))[0]
                if owner and not ancestor:
                    raise SystemExit("%s experiment changes %s.%s, which runtime/experiment.gd does not allow" % (rule_id, owner, change["property"]))

    # Every cited docs page must exist in that version's class reference or godot-docs branch (sparse checkouts).
    docs_dirs = {tag: os.path.join(ROOT, ".tmp", "upstream", GODOT_DOCS[tag]) for tag in SERIES}
    if len(class_pages) == len(SERIES) and all(os.path.isdir(path) for path in docs_dirs.values()):
        for rule in rules:
            for tag, page in re.findall(r"https://docs\.godotengine\.org/en/([^/]+)/([^\s\"'#)]+?)\.html", json.dumps(rule)):
                if tag not in docs_dirs:
                    raise SystemExit("%s cites unverifiable docs version %s" % (rule["id"], tag))
                if page.startswith("classes/class_"):
                    found = page[len("classes/class_"):] in class_pages[tag]
                else:
                    found = os.path.isfile(os.path.join(docs_dirs[tag], page + ".rst"))
                if not found:
                    raise SystemExit("%s cites missing docs page %s/%s" % (rule["id"], tag, page))

    os.makedirs(OUT, exist_ok=True)
    by_cat = OrderedDict()
    for rule in rules:
        by_cat.setdefault(rule["category"], []).append(rule)
    for retired in ("api_vulkan.json", "api_d3d12.json"):
        path = os.path.join(OUT, retired)
        if os.path.isfile(path):
            os.remove(path)
    for cat, group in by_cat.items():
        path = os.path.join(OUT, cat + ".json")
        with open(path, "w", encoding="utf-8") as handle:
            json.dump(group, handle, indent=2)
            handle.write("\n")

    lines = []
    lines.append("# Render Lens rules")
    lines.append("")
    lines.append("Version 2.0.0. Generated from `addons/render_lens/rules/*.json`.")
    lines.append("Each rule is data. The evaluator in `rule_engine.gd` does not apply changes.")
    lines.append("")
    lines.append("A heuristic threshold is labeled in the rule. Costs in suggestions are qualitative unless a measured pass share, frame-time share, or memory share is attached.")
    lines.append("A rule's versions are the Godot versions it is verified on (4.4, 4.5.2, 4.6.3, 4.7.2): its quotes, ProjectSettings paths and class members exist in each, and the test suites run on each. It is evaluated from its first to its last verified version; a rule verified on 4.7 also applies to later 4.x releases with an `engine_version_note`. `min_version` and `max_version` narrow that range.")
    lines.append("")
    lines.append("## Counts")
    lines.append("")
    lines.append("| Category | Rules |")
    lines.append("| --- | --- |")
    for cat, group in by_cat.items():
        lines.append("| %s | %d |" % (cat, len(group)))
    lines.append("| **total** | **%d** |" % len(rules))
    lines.append("")
    for cat, group in by_cat.items():
        lines.append("## %s" % cat)
        lines.append("")
        for rule in group:
            heur = "yes" if rule["heuristic"] else "no"
            lines.append("### `%s`" % rule["id"])
            lines.append("")
            lines.append("- **Title:** %s" % rule["title"])
            lines.append("- **Severity:** %s" % rule["severity"])
            lines.append("- **Kind:** %s" % rule["kind"])
            lines.append("- **Heuristic:** %s" % heur)
            if rule["heuristic"]:
                lines.append("- **Heuristic rationale:** %s" % rule["heuristic_rationale"])
            lines.append("- **Renderers:** %s" % ", ".join(rule["applies_to"]["renderers"]))
            lines.append("- **Godot versions:** %s" % ", ".join(rule["applies_to"]["versions"]))
            if rule["applies_to"].get("renderers_by_version"):
                lines.append("- **Renderer scope by version:** `%s`" % json.dumps(rule["applies_to"]["renderers_by_version"], sort_keys=True))
            if rule["applies_to"].get("min_version"):
                lines.append("- **min_version:** %s" % rule["applies_to"]["min_version"])
            if rule["applies_to"].get("max_version"):
                lines.append("- **max_version:** %s" % rule["applies_to"]["max_version"])
            if rule.get("upstream_check"):
                lines.append("- **Upstream idea:** `%s` (Godot adaptation, no layer required)" % rule["upstream_check"])
                lines.append("- **Observed condition:** `%s`" % json.dumps(rule["condition"], sort_keys=True))
                if rule["heuristic_rationale"]:
                    lines.append("- **Mapping limits:** %s" % rule["heuristic_rationale"])
            if rule["applies_to"].get("vendors"):
                lines.append("- **GPU families:** %s" % ", ".join(rule["applies_to"]["vendors"]))
            if rule.get("validation_id"):
                lines.append("- **Validator id:** `%s`" % rule["validation_id"])
            if rule.get("engine_internal"):
                lines.append("- **engine_internal:** yes")
            if rule["setting"]:
                lines.append("- **Setting:** `%s`" % rule["setting"])
            if rule["node_property"]:
                lines.append("- **Node:** `%s`" % rule["node_property"])
            if rule.get("godot_warns"):
                lines.append("- **Godot also warns:** %s" % ("in the editor (configuration warning)" if rule["godot_warns"] == "editor" else "at run time (printed warning)"))
            if rule.get("experiment"):
                lines.append("- **Try live:** `measure_change finding=%s` applies `%s`" % (rule["id"], json.dumps(rule["experiment"])))
            if rule.get("evidence_kind") in ("godot_configuration", "godot_runtime_warning", "godot_feature", "device_limit", "device_format_support", "spirv_operands", "spirv_interface", "spirv_header"):
                if not rule.get("upstream_check"):
                    lines.append("- **Observed condition:** `%s`" % json.dumps(rule["condition"], sort_keys=True))
                lines.append("- **Evidence and limits:** %s" % rule["evidence"])
                lines.append("- **Suggested action:** %s" % rule["suggestion"])
            lines.append("- **Source:** %s" % rule["source"])
            lines.append("")
    out_md = os.path.join(ROOT, "RULES.md")
    with open(out_md, "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines))
    print("rules", len(rules))
    for cat, group in by_cat.items():
        print("  %s %d" % (cat, len(group)))


if __name__ == "__main__":
    main()
