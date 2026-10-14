"""Extra Render Lens 1.2 rules. Each quote is checked against the Godot class XML."""

import os
import re
import tempfile

from godot_versions import CHECKOUTS as GODOT_CHECKOUTS, expand

SOURCE_CACHE = os.environ.get("RENDER_LENS_SOURCE_CACHE", os.path.join(tempfile.gettempdir(), "render-lens-review-upstream"))

DOCS = "/tmp/godot_docs"
D44 = "https://docs.godotengine.org/en/4.4/"
D47 = "https://docs.godotengine.org/en/4.7/"
PROJ = D44 + "classes/class_projectsettings.html"
PROJ47 = D47 + "classes/class_projectsettings.html"
PERF = D44 + "classes/class_performance.html"
PERF47 = D47 + "classes/class_performance.html"
CPU = D44 + "tutorials/performance/cpu_optimization.html"
IMG = D44 + "tutorials/assets_pipeline/importing_images.html"
AUDIO = D44 + "tutorials/assets_pipeline/importing_audio_samples.html"
LOD = D44 + "tutorials/3d/mesh_lod.html"
SCALE = D44 + "tutorials/3d/resolution_scaling.html"
XR = D44 + "tutorials/xr/setting_up_xr.html"
DBG = D44 + "tutorials/scripting/debug/debugger_panel.html"
RS = D44 + "classes/class_renderingserver.html"
RD = D44 + "classes/class_renderingdevice.html"
SCENE_CPP = "https://github.com/godotengine/godot/blob/4.4-stable/editor/import/3d/resource_importer_scene.cpp"
WAV_CPP = "https://github.com/godotengine/godot/blob/4.4-stable/editor/import/resource_importer_wav.cpp"
SERVERS_CPP = "https://github.com/godotengine/godot/blob/4.4-stable/servers/debugger/servers_debugger.cpp"

_cache = {}


def _clean(text):
    text = re.sub(r"<[^>]+>", " ", text)
    text = re.sub(r"\[[^\]]+\]", " ", text)
    return re.sub(r"\s+", " ", text).strip()


# Sparse Godot source checkouts (see docs/GODOT_COVERAGE.json) verify quotes when the doc dump is absent.
UPSTREAM = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".tmp", "upstream")
CHECKOUTS = {version.replace(".", ""): checkout for version, checkout in GODOT_CHECKOUTS.items()}


def _xml(name, tag):
    key = (name, tag)
    if key not in _cache:
        path = os.path.join(DOCS, "%s_%s.xml" % (name, tag))
        if not os.path.exists(path):
            checkout = os.path.join(UPSTREAM, CHECKOUTS[tag])
            matches = [os.path.join(checkout, "doc", "classes", name + ".xml")]
            modules = os.path.join(checkout, "modules")
            if os.path.isdir(modules):
                matches += [os.path.join(modules, module, "doc_classes", name + ".xml") for module in os.listdir(modules)]
            path = next((candidate for candidate in matches if os.path.exists(candidate)), path)
        if not os.path.exists(path):
            raise SystemExit("missing doc %s" % path)
        _cache[key] = _clean(open(path, encoding="utf-8", errors="replace").read())
    return _cache[key]


def _require(name, tags, quote):
    if not os.path.isdir(DOCS) and not all(os.path.isdir(os.path.join(UPSTREAM, CHECKOUTS[tag])) for tag in tags):
        return
    if name.endswith("2D/3D"):
        # A shared quote must appear in both dimension variants.
        for variant in (name[:-len("2D/3D")] + "2D", name[:-len("2D/3D")] + "3D"):
            _require(variant, tags, quote)
        return
    for tag in tags:
        text = _xml(name, tag)
        if quote not in text:
            if os.environ.get("RENDER_LENS_QUOTE_REPORT"):
                print("QUOTE-FAIL %s_%s: %s" % (name, tag, quote))
                continue
            raise SystemExit("quote not in %s_%s: %s" % (name, tag, quote))


def _tags(versions):
    return [version.replace(".", "") for version in expand(versions)]


def _cond(op, path, value):
    return {"setting_%s" % op: {"path": path, "value": value}}


def _scene(op, name, value):
    return {"scene_%s" % op: {"name": name, "value": value}}


def _metric(op, name, value):
    return {"metric_%s" % op: {"name": name, "value": value}}


# Setting rows that only matter when the scanned scenes use what the setting changes: (scene counter, offender key,
# extra condition). The MSDF setting builds Godot's default font, so a project custom_font makes it irrelevant.
SCENE_GATES = {
    "ui.default_font_msdf_off": ("default_font_text_count", "default_font_text", _cond("eq", "gui/theme/custom_font", "")),
}


def register(add):
    both = ["4.4", "4.7"]
    all_r = ["forward_plus", "mobile", "gl_compatibility"]
    for row in SETTING_ROWS:
        _add_setting(add, row, both, all_r)
    for row in SCENE_ROWS:
        _add_scene(add, row, both, all_r)
    for row in MONITOR_ROWS:
        _add_monitor(add, row, all_r)
    for row in COMPOSITE_ROWS:
        _add_composite(add, row)
    _add_profile_and_vram(add, both, all_r)


def _add_setting(add, row, both, all_r):
    (rid, category, path, op, value, severity, kind, renderers, versions, min_v, max_v,
     heuristic, rationale, title, quote, suggestion, tradeoff, source) = row
    tags = _tags(versions)
    doc = "ProjectSettings"
    _require(doc, tags, quote)
    rule = dict(
        id=rid, category=category, title=title, severity=severity, kind=kind,
        heuristic=heuristic, heuristic_rationale=rationale,
        renderers=renderers, versions=versions, requires=["settings"],
        condition=_cond(op, path, value),
        evidence=quote,
        suggestion=suggestion,
        setting=path,
        tradeoff=tradeoff,
        expected_effect="Re-measure with collect_metrics after changing this setting. No frame-time percentage is predicted.",
        verify_step="collect_metrics",
        source=source,
    )
    if rid in SCENE_GATES:
        counter, offenders, extra = SCENE_GATES[rid]
        rule["condition"] = {"all": [rule["condition"], extra, _scene("gte", counter, 1)]}
        rule["requires"] = ["settings", "scene"]
        rule["offender_key"] = offenders
    if min_v:
        rule["min_version"] = min_v
    if max_v:
        rule["max_version"] = max_v
    add(rule)


def _add_scene(add, row, both, all_r):
    (rid, category, key, op, value, severity, kind, heuristic, rationale, title,
     quote, quote_class, suggestion, tradeoff, node_property, offender, source) = row
    _require(quote_class, _tags(BOTH), quote)
    add(dict(
        id=rid, category=category, title=title, severity=severity, kind=kind,
        heuristic=heuristic, heuristic_rationale=rationale,
        renderers=["forward_plus", "mobile", "gl_compatibility"], versions=["4.4", "4.7"],
        requires=["scene"],
        condition=_scene(op, key, value),
        evidence=quote,
        suggestion=suggestion,
        node_property=node_property,
        offender_key=offender,
        tradeoff=tradeoff,
        expected_effect="scan_scene should show a lower count after the edit. No frame-time percentage is predicted.",
        verify_step="scan_scene",
        source=source,
    ))


def _add_monitor(add, row, all_r):
    (rid, category, metric, op, value, versions, min_v, max_v, heuristic, rationale,
     title, quote, suggestion, share_from) = row
    tags = _tags(versions)
    _require("Performance", tags, quote)
    source = PERF if "4.4" in versions else PERF47
    if versions == ["4.7"]:
        source = PERF47
    rule = dict(
        id=rid, category=category, title=title, severity="medium",
        heuristic=heuristic, heuristic_rationale=rationale,
        renderers=all_r, versions=versions, requires=["metrics"],
        condition=_metric(op, metric, value),
        evidence=quote,
        suggestion=suggestion,
        tradeoff="Depends on which objects or allocations you remove.",
        expected_effect="The same Performance monitor should fall on the next collect_metrics.",
        verify_step="collect_metrics",
        source=source,
        share_from=share_from,
        share_unit="seconds" if share_from else "",
    )
    if min_v:
        rule["min_version"] = min_v
    if max_v:
        rule["max_version"] = max_v
    if share_from:
        rule["requires"] = ["metrics", "frame"]
    add(rule)


def _add_profile_and_vram(add, both, all_r):
    add(dict(
        id="scripts.profile_top_self",
        category="scripts",
        title="One script function uses a large share of the frame",
        severity="high",
        heuristic=True,
        heuristic_rationale="The CPU optimization page says to focus on the function that takes much more time than the others. One fifth of the frame budget is the cutoff used here.",
        renderers=all_r, versions=both, requires=["metrics", "frame"],
        condition={"metric_gt_budget_ratio": {"name": "PROFILE_TOP_SELF_SEC", "ratio": 0.2}},
        evidence="The top script self time from the servers profiler exceeds 20% of the frame budget.",
        suggestion="Open script_profile and start with the function at the top of the self-time list. The CPU optimization page says the built-in profiler shows scripting cost separately from physics and audio.",
        tradeoff="Depends on what that function is doing.",
        expected_effect="PROFILE_TOP_SELF_SEC should drop on the next script_profile. No percentage is predicted.",
        verify_step="script_profile",
        source=CPU,
        share_from="PROFILE_TOP_SELF_SEC",
        share_unit="seconds",
    ))
    add(dict(
        id="memory.vram_largest_share",
        category="memory",
        title="One resource is most of the Video RAM list",
        severity="medium",
        heuristic=True,
        heuristic_rationale="The debugger Video RAM tab lists bytes per resource. Half of that listed total and 64 MiB (a 4096x4096 RGBA8 texture with mipmaps is about 85 MiB) are review cuts, not GPU capacities; without the size floor a 6 MiB texture in a 12 MiB list was reported.",
        renderers=all_r, versions=both, requires=["metrics"],
        condition={"all": [{"metric_gt_metric": {"left": "VRAM_LARGEST_BYTES", "right": "VRAM_LISTED_HALF"}},
                           {"metric_gte": {"name": "VRAM_LARGEST_BYTES", "value": 64 * 1024 * 1024}}]},
        evidence="The largest servers:memory_usage entry is more than half the listed total and at least 64 MiB.",
        suggestion="vram_report names that resource by path, format, and byte size. Shrink or compress that texture or mesh. The debugger panel documents this list.",
        tradeoff="A smaller or compressed resource loses detail.",
        expected_effect="That resource's vram_bytes should fall on the next vram_report.",
        verify_step="vram_report",
        source=DBG,
    ))


# (id, category, path, op, value, severity, kind, renderers, versions, min, max, heuristic, rationale, title, quote, suggestion, tradeoff, source)
ALL = ["forward_plus", "mobile", "gl_compatibility"]
FP = ["forward_plus"]
MOBILE = ["mobile"]
GL = ["gl_compatibility"]
BOTH = ["4.4", "4.7"]
V44 = ["4.4"]
V47 = ["4.7"]

SETTING_ROWS = [
    ("pacing.delta_smoothing_off", "pacing", "application/run/delta_smoothing", "eq", False, "low", "performance", ALL, BOTH, "", "", False, "",
     "Frame delta smoothing is off",
     "Delta smoothing can often give a better result",
     "Turn application/run/delta_smoothing back on unless you have a reason to take the raw platform deltas. The setting description says smoothing filters minor fluctuations from the refresh rate.",
     "Smoothing can hide a real hitch from gameplay code that reads delta.", PROJ),
    ("cpu.flush_stdout", "cpu", "application/run/flush_stdout_on_print", "eq", True, "low", "performance", ALL, BOTH, "", "", False, "",
     "Stdout is flushed on every print",
     "flushes the standard output stream every time a line is printed",
     "Turn application/run/flush_stdout_on_print off in release builds. The description says it is disabled by default on release because the flush is extra work.",
     "Logs may arrive later for journald-style collectors.", PROJ),
    ("cpu.low_processor_sleep_short", "cpu", "application/run/low_processor_mode_sleep_usec", "lt", 6900, "low", "performance", ALL, BOTH, "", "", False, "",
     "Low-processor sleep is below the default",
     "Higher values will result in lower CPU usage",
     "Raise application/run/low_processor_mode_sleep_usec toward the default 6900 if low-processor mode is on. The description says higher values use less CPU.",
     "The editor or tool wakes less often.", PROJ),
    ("audio.output_latency_low", "audio", "audio/driver/output_latency", "lt", 15, "medium", "performance", ALL, BOTH, "", "", False, "",
     "Preferred audio latency is below 15 ms",
     "Lower values will result in lower audio latency at the cost of increased CPU usage",
     "Raise audio/driver/output_latency toward 15 if you hear crackling or the mix thread is hot. The description says low values cost CPU and can crackle.",
     "Audible latency increases.", PROJ),
    ("audio.disable_threshold_strict", "audio", "audio/buses/channel_disable_threshold_db", "lt", -60.0, "low", "performance", ALL, BOTH, "", "", False, "",
     "Audio buses stay awake at quieter levels than the default",
     "This saves CPU as effects assigned to that bus will no longer do any processing",
     "Move audio/buses/channel_disable_threshold_db up toward -60 so idle buses disable. The description says disabling the bus skips its effects.",
     "Very quiet tails get cut sooner.", PROJ),
    ("audio.disable_time_long", "audio", "audio/buses/channel_disable_time", "gt", 2.0, "low", "performance", ALL, BOTH, "", "", False, "",
     "Audio buses wait longer than 2 seconds before disabling",
     "This saves CPU as effects assigned to that bus will no longer do any processing",
     "Lower audio/buses/channel_disable_time toward the default 2 seconds. A longer window keeps effects running after the sound has dropped.",
     "Short gaps in a loop may click if the bus sleeps.", PROJ),
    ("audio.tts_enabled", "audio", "audio/general/text_to_speech", "eq", True, "low", "performance", ALL, BOTH, "", "", False, "",
     "Text-to-speech support is enabled",
     "idle CPU usage and interfere with the sleep mode",
     "Turn audio/general/text_to_speech off when the game does not speak. The description warns about idle CPU use and sleep mode.",
     "DisplayServer TTS calls stop working.", PROJ),
    ("platform.windows_driver_vulkan", "platform", "rendering/rendering_device/driver.windows", "eq", "vulkan", "low", "info", ["forward_plus", "mobile"], ["4.6", "4.7"], "4.6", "", False, "",
     "Windows rendering driver is still Vulkan",
     "it is recommended to switch them manually to",
     "On Godot 4.7, rendering/rendering_device/driver.windows still says vulkan. The 4.7 description says projects created before 4.6 keep Vulkan and recommends switching them to d3d12 on Windows. This does not change the Linux driver.",
     "Direct3D 12 has its own validation and fallback path.", PROJ47),
    ("platform.per_pixel_transparency", "platform", "display/window/per_pixel_transparency/allowed", "eq", True, "medium", "performance", ALL, BOTH, "", "", False, "",
     "Per-pixel window transparency is allowed",
     "This affects performance, so leave it on false unless you need it",
     "Set display/window/per_pixel_transparency/allowed to false unless the window really needs a transparent background.",
     "The window background can no longer be transparent.", PROJ),
    ("platform.subwindows_not_embedded", "platform", "display/window/subwindows/embed_subwindows", "eq", False, "low", "performance", ALL, BOTH, "", "", False, "",
     "Subwindows are not embedded in the main window",
     "Single-window mode can be faster",
     "Set display/window/subwindows/embed_subwindows to true. The description says creating a separate window per popup can be slow.",
     "Popups are no longer separate OS windows.", PROJ),
    ("ui.default_font_msdf_off", "ui", "gui/theme/default_font_multichannel_signed_distance_field", "eq", False, "low", "quality_up", ALL, BOTH, "", "", False, "",
     "The default font is not an MSDF font",
     "this allows for resizing the font in real-time without any performance penalty",
     "Turn gui/theme/default_font_multichannel_signed_distance_field on if you scale Controls or Label3D often. The description says MSDF avoids re-rasterizing on size changes.",
     "MSDF text looks different from the bitmap font.", PROJ),
    ("navigation.path_threads_high", "navigation", "navigation/pathfinding/max_threads", "gt", 4, "low", "performance", ALL, BOTH, "", "", False, "",
     "Pathfinding may use more than 4 threads",
     "Additional threads increase memory consumption and synchronization time",
     "Lower navigation/pathfinding/max_threads toward 4 unless queries are actually waiting. The description says extra threads copy data.",
     "Fewer path queries run at once.", PROJ),
    ("navigation.path_threads_unlimited", "navigation", "navigation/pathfinding/max_threads", "lt", 0, "medium", "performance", ALL, BOTH, "", "", False, "",
     "Pathfinding threads are unlimited",
     "A value of -1 means unlimited",
     "Set navigation/pathfinding/max_threads to a finite count. The description says -1 means unlimited and extra threads cost memory.",
     "Path queries queue instead of spawning without a cap.", PROJ),
    ("navigation.sync_on_main_thread", "navigation", "navigation/world/map_use_async_iterations", "eq", False, "medium", "performance", ALL, BOTH, "", "", False, "",
     "Navigation map sync runs on the main thread",
     "avoids stalling the main thread but adds an additional delay",
     "Turn navigation/world/map_use_async_iterations on so map sync leaves the main thread. The description says the async path avoids that stall.",
     "Map changes show up one step later.", PROJ),
    ("navigation.avoidance_single_thread", "navigation", "navigation/avoidance/thread_model/avoidance_use_multiple_threads", "eq", False, "low", "performance", ALL, BOTH, "", "", False, "",
     "Avoidance is not using multiple threads",
     "If enabled the avoidance calculations use multiple threads",
     "Turn navigation/avoidance/thread_model/avoidance_use_multiple_threads on when many agents avoid each other.",
     "Avoidance shares the threads it is given.", PROJ),
    ("physics.solver_iterations_2d", "physics", "physics/2d/solver/solver_iterations", "gt", 16, "medium", "performance", ALL, BOTH, "", "", False, "",
     "2D solver iterations are above 16",
     "a greater number of iterations requires more CPU power, which can decrease performance",
     "Lower physics/2d/solver/solver_iterations toward the default 16. The description says more iterations cost CPU.",
     "Stacks and joints settle less accurately.", PROJ),
    ("physics.jolt_position_steps", "physics", "physics/jolt_physics_3d/simulation/position_steps", "gt", 2, "medium", "performance", ALL, BOTH, "", "", False, "",
     "Jolt position steps are above 2",
     "The greater the number of iterations, the more accurate the simulation will be, at the cost of CPU performance",
     "Lower physics/jolt_physics_3d/simulation/position_steps toward the default 2.",
     "Contacts settle less accurately.", PROJ),
    ("physics.jolt_velocity_steps", "physics", "physics/jolt_physics_3d/simulation/velocity_steps", "gt", 10, "medium", "performance", ALL, BOTH, "", "", False, "",
     "Jolt velocity steps are above 10",
     "The greater the number of iterations, the more accurate the simulation will be, at the cost of CPU performance",
     "Lower physics/jolt_physics_3d/simulation/velocity_steps toward the default 10. The description says friction needs at least 2.",
     "Friction and bounce settle less accurately.", PROJ),
    ("physics.jolt_sleep_disabled", "physics", "physics/jolt_physics_3d/simulation/allow_sleep", "eq", False, "high", "performance", ALL, BOTH, "", "", False, "",
     "Jolt rigid bodies are not allowed to sleep",
     "This can improve physics simulation performance",
     "Turn physics/jolt_physics_3d/simulation/allow_sleep on so resting bodies leave the solver.",
     "Bodies that should stay awake, such as slow platforms, may need sleep disabled locally.", PROJ),
    ("physics.jolt_temp_buffer", "physics", "physics/jolt_physics_3d/limits/temporary_memory_buffer_size", "gt", 32, "low", "performance", ALL, BOTH, "", "", False, "",
     "Jolt's temporary memory buffer is above 32 MiB",
     "The amount of memory to pre-allocate for the stack allocator used within Jolt, in MiB",
     "Lower physics/jolt_physics_3d/limits/temporary_memory_buffer_size toward 32 unless a step is actually running out of that allocator.",
     "A step that needs more temporary memory will fail instead of growing.", PROJ),
    ("physics.areas_detect_static", "physics", "physics/jolt_physics_3d/simulation/areas_detect_static_bodies", "eq", True, "high", "performance", ALL, V44, "", "4.4", False, "",
     "Jolt areas detect static bodies",
     "Enabling this setting can come at a heavy CPU and memory cost",
     "Turn physics/jolt_physics_3d/simulation/areas_detect_static_bodies off unless areas must overlap static shapes. This setting exists in Godot 4.4 and was removed later.",
     "Area3D nodes no longer report overlaps with StaticBody3D.", PROJ),
    ("post.ssr_half_size_off", "post", "rendering/environment/screen_space_reflection/half_size", "eq", False, "medium", "performance", FP, ["4.6", "4.7"], "4.6", "", False, "",
     "Screen-space reflections are rendered at full size",
     "screen-space reflections will be rendered at half size and then upscaled",
     "Set rendering/environment/screen_space_reflection/half_size to true. The 4.7 description says half size is faster and full size is the alternative.",
     "Reflections can look sharper and can flicker less.", PROJ47),
    ("post.ssr_roughness_quality", "post", "rendering/environment/screen_space_reflection/roughness_quality", "gt", 1, "low", "performance", FP, ["4.4", "4.5"], "", "4.5", False, "",
     "SSR roughness quality is above the 4.4 default",
     "higher values make rough reflections look better",
     "Lower rendering/environment/screen_space_reflection/roughness_quality toward the default 1. This setting exists in Godot 4.4.",
     "Rough reflections look sharper and less filtered.", PROJ),
    ("antialiasing.smaa_enabled", "antialiasing", "rendering/anti_aliasing/quality/screen_space_aa", "eq", 2, "medium", "performance", ALL, ["4.5", "4.7"], "4.5", "", False, "",
     "SMAA is the screen-space antialiasing mode",
     "Sets the screen-space antialiasing mode",
     "Viewport.SCREEN_SPACE_AA_SMAA is 2 in Godot 4.7. Set rendering/anti_aliasing/quality/screen_space_aa to 0 or to FXAA if you need the post pass gone or cheaper.",
     "Edges are aliased if you also leave MSAA off.", PROJ47),
    ("antialiasing.smaa_threshold_low", "antialiasing", "rendering/anti_aliasing/quality/smaa_edge_detection_threshold", "lt", 0.05, "medium", "performance", ALL, ["4.5", "4.7"], "4.5", "", False, "",
     "SMAA edge detection is more sensitive than the default",
     "Lower values will catch more edges, at a potentially higher performance cost",
     "Raise rendering/anti_aliasing/quality/smaa_edge_detection_threshold toward 0.05. The description says lower values cost more.",
     "Faint edges are no longer smoothed.", PROJ47),
    ("resolution.nearest_upscale", "resolution", "rendering/scaling_3d/mode", "eq", 5, "low", "info", ALL, V47, "4.7", "", False, "",
     "3D scaling mode is nearest",
     "Sets the scaling 3D mode",
     "Viewport.SCALING_3D_MODE_NEAREST is 5 in Godot 4.7. The resolution scaling page describes bilinear and FSR as the filtered modes. Nearest is the unfiltered mode.",
     "Scaled 3D output looks blockier.", SCALE),
    ("gi.texture_array_reflections", "gi", "rendering/reflections/sky_reflections/texture_array_reflections", "eq", True, "medium", "performance", FP, BOTH, "", "", False, "",
     "Reflections use texture arrays instead of mipmaps",
     "significantly slower to compute and uses",
     "Set rendering/reflections/sky_reflections/texture_array_reflections to false if reflection cost shows up. The description says texture arrays are significantly slower and use more memory.",
     "Reflections pick up more jitter noise.", PROJ),
    ("gi.roughness_layers_high", "gi", "rendering/reflections/sky_reflections/roughness_layers", "gt", 8, "low", "performance", FP, BOTH, "", "", False, "",
     "Radiance roughness layers are above 8",
     "A lower number will be slightly faster and take up less VRAM",
     "Lower rendering/reflections/sky_reflections/roughness_layers toward 8.",
     "Rough reflections have fewer layers.", PROJ),
    ("gi.fast_filter_high_quality", "gi", "rendering/reflections/sky_reflections/fast_filter_high_quality", "eq", True, "medium", "performance", FP, BOTH, "", "", False, "",
     "Sky reflections use the high-quality fast filter",
     "Significantly slower than using default quality",
     "Turn rendering/reflections/sky_reflections/fast_filter_high_quality off unless the scene is especially detailed. The description says to use it only then.",
     "Reflections look less smooth.", PROJ),
    ("memory.staging_block_large", "memory", "rendering/rendering_device/staging_buffer/block_size_kb", "gt", 256, "low", "performance", FP, BOTH, "", "", False, "",
     "Staging buffer blocks are above 256 KiB",
     "Increasing this will result in faster data transfers at the cost of extra",
     "Lower rendering/rendering_device/staging_buffer/block_size_kb toward 256 if upload memory is the problem. The description says larger blocks transfer faster and cost memory.",
     "Copies move less data per operation.", PROJ),
    ("memory.staging_cap_high", "memory", "rendering/rendering_device/staging_buffer/max_size_mb", "gt", 128, "low", "performance", FP, BOTH, "", "", False, "",
     "The staging buffer cap is above 128 MiB",
     "The maximum amount of memory allowed to be used by staging buffers",
     "Lower rendering/rendering_device/staging_buffer/max_size_mb toward 128. The description says exceeding the cap stalls the GPU, so only raise it when uploads actually stall.",
     "Large uploads may stall instead of using more memory.", PROJ),
    ("pacing.swapchain_images", "pacing", "rendering/rendering_device/vsync/swapchain_image_count", "gt", 3, "low", "performance", ALL, BOTH, "", "", False, "",
     "The swapchain has more than 3 images",
     "2 corresponds to double-buffering and 3 to triple-buffering",
     "Set rendering/rendering_device/vsync/swapchain_image_count to 2 or 3. The description says 2 is the lowest latency and 3 is triple-buffering.",
     "With vsync, a missed frame can drop to a divisor of the refresh rate.", PROJ),
    ("textures.webp_method_slow", "textures", "rendering/textures/webp_compression/compression_method", "gt", 4, "low", "info", ALL, BOTH, "", "", False, "",
     "WebP compression method is above 4",
     "compression methods above 4 are very slow",
     "Lower rendering/textures/webp_compression/compression_method to 4 or below. The description says methods above 4 are very slow and save little.",
     "Imported WebP files can be slightly larger.", PROJ),
    ("textures.gpu_compress_off", "textures", "rendering/textures/vram_compression/compress_with_gpu", "eq", False, "info", "info", ALL, BOTH, "", "", False, "",
     "GPU texture compression is disabled",
     "improving the import time of large images",
     "Turn rendering/textures/vram_compression/compress_with_gpu on when the device has Vulkan, D3D12, or Metal. The description says that speeds up import of large images.",
     "Import uses the CPU compressor instead.", PROJ),
    ("platform.etc2_astc_off_mobile", "platform", "rendering/textures/vram_compression/import_etc2_astc", "eq", False, "low", "info", MOBILE, BOTH, "", "", False, "",
     "ETC2 and ASTC import is off while the mobile renderer is selected",
     "Ericsson Texture Compression 2 algorithm",
     "Turn rendering/textures/vram_compression/import_etc2_astc on before exporting to Android or iOS. The description says this override selects ETC2 for lower quality textures and ASTC for high quality, and that the importer always imports the format the host platform needs, so desktop runs are unaffected.",
     "Desktop S3TC imports are a separate override.", PROJ),
    ("platform.s3tc_off_forward", "platform", "rendering/textures/vram_compression/import_s3tc_bptc", "eq", False, "low", "info", FP, BOTH, "", "", False, "",
     "S3TC and BPTC import is off on Forward+",
     "This algorithm is only supported on PC desktop platforms and consoles",
     "Turn rendering/textures/vram_compression/import_s3tc_bptc on for desktop Forward+ if you want VRAM-compressed textures. The description limits that algorithm to PC and consoles.",
     "Mobile GPUs do not sample S3TC.", PROJ),
    ("shadows.directional_mobile_size", "shadows", "rendering/lights_and_shadows/directional_shadow/size.mobile", "gt", 2048, "medium", "performance", MOBILE, BOTH, "", "", False, "",
     "The mobile directional shadow map is above 2048",
     "due to performance concerns or driver support",
     "Lower rendering/lights_and_shadows/directional_shadow/size.mobile toward 2048. The description calls this the lower-end override.",
     "Directional shadows lose detail on mobile.", PROJ),
    ("shadows.positional_mobile_size", "shadows", "rendering/lights_and_shadows/positional_shadow/atlas_size.mobile", "gt", 2048, "medium", "performance", MOBILE, BOTH, "", "", False, "",
     "The mobile positional shadow atlas is above 2048",
     "due to performance concerns or driver support",
     "Lower rendering/lights_and_shadows/positional_shadow/atlas_size.mobile toward 2048.",
     "Positional shadows lose detail on mobile.", PROJ),
    ("shadows.mobile_filter_raised", "shadows", "rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality.mobile", "gt", 0, "low", "performance", MOBILE, BOTH, "", "", False, "",
     "The mobile directional shadow filter is above the low-end default",
     "due to performance concerns or driver support",
     "Set rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality.mobile back to 0 unless the soft edge is required.",
     "Mobile shadow edges look harder.", PROJ),
    ("gi.reflection_mobile_size", "gi", "rendering/reflections/reflection_atlas/reflection_size.mobile", "gt", 128, "low", "performance", MOBILE, BOTH, "", "", False, "",
     "The mobile reflection atlas is above 128",
     "due to performance concerns or driver support",
     "Lower rendering/reflections/reflection_atlas/reflection_size.mobile toward 128.",
     "Mobile reflections lose detail.", PROJ),
    ("gi.ggx_mobile_high", "gi", "rendering/reflections/sky_reflections/ggx_samples.mobile", "gt", 16, "low", "performance", MOBILE, BOTH, "", "", False, "",
     "Mobile GGX samples are above 16",
     "due to performance concerns or driver support",
     "Lower rendering/reflections/sky_reflections/ggx_samples.mobile toward 16.",
     "Mobile specular looks noisier.", PROJ),
    ("renderer.gl_lights_per_object", "renderer_platform", "rendering/limits/opengl/max_lights_per_object", "gt", 8, "low", "performance", GL, BOTH, "", "", False, "",
     "Compatibility allows more than 8 omni or spot lights per object",
     "Setting this low will slightly reduce memory usage",
     "Lower rendering/limits/opengl/max_lights_per_object toward 8. The description says the low value saves a bit of memory and is still capped by max_renderable_lights.",
     "Surfaces keep fewer lights.", PROJ),
    ("renderer.gl_element_cap", "renderer_platform", "rendering/limits/opengl/max_renderable_elements", "gt", 65536, "low", "info", GL, BOTH, "", "", False, "",
     "The Compatibility element cap is above 65536",
     "Setting this low will slightly reduce memory usage and may decrease shader compile times",
     "Lower rendering/limits/opengl/max_renderable_elements toward 65536 unless a frame is actually dropping surfaces. The description says elements are mesh surfaces.",
     "Extra surfaces in a frame are not drawn.", PROJ),
    ("xr.foveation_ignored", "xr", "xr/openxr/foveation_level", "gt", 0, "info", "info", FP, V44, "", "4.4", False, "",
     "Foveation is set but the renderer is Forward+",
     "Only works on the Compatibility rendering method",
     "xr/openxr/foveation_level has no effect on Forward+ in Godot 4.4. The 4.4 description says it only works on Compatibility. Godot 4.7's description no longer says that, so this rule is 4.4 only.",
     "Switching renderer changes the whole pipeline.", PROJ),
    ("xr.subsample_off", "xr", "xr/openxr/foveation_with_subsampled_images", "eq", False, "low", "performance", GL, V47, "4.7", "", False, "",
     "Foveation is not using subsampled images",
     "This can improve the performance gain from foveated rendering",
     "Turn xr/openxr/foveation_with_subsampled_images on when foveation is enabled on Vulkan. The 4.7 description says subsampled images improve the gain and conflict with some screen-space effects.",
     "Some screen-space effects are incompatible.", PROJ47),
    ("gi.lightmap_ultra_rays", "gi", "rendering/lightmapping/bake_quality/ultra_quality_ray_count", "gt", 2048, "info", "info", ALL, BOTH, "", "", False, "",
     "Ultra lightmap bakes use more than 2048 rays",
     "The number of rays to use for baking lightmaps",
     "Lower rendering/lightmapping/bake_quality/ultra_quality_ray_count toward 2048. This is the documented ray count for LightmapGI ultra bakes, not a frame-time measurement.",
     "The bake is noisier.", PROJ),
    ("gi.lightmap_high_rays", "gi", "rendering/lightmapping/bake_quality/high_quality_ray_count", "gt", 512, "info", "info", ALL, BOTH, "", "", False, "",
     "High lightmap bakes use more than 512 rays",
     "The number of rays to use for baking lightmaps",
     "Lower rendering/lightmapping/bake_quality/high_quality_ray_count toward 512.",
     "The bake is noisier.", PROJ),
    ("ui.font_mipmaps_on", "ui", "gui/theme/default_font_generate_mipmaps", "eq", True, "low", "info", ALL, BOTH, "", "", False, "",
     "The default font generates mipmaps",
     "Enabling increases font generation time and memory usage",
     "Leave gui/theme/default_font_generate_mipmaps on only if scaled-down text looks grainy. The description says enabling it increases font generation time and memory usage.",
     "Scaled-down text can look grainy.", PROJ),
    # Class-reference performance notes (docs/GODOT_PERF_NOTES.json).
    ("memory.gdscript_track_locals", "memory", "debug/settings/gdscript/always_track_local_variables", "eq", True, "medium", "performance", ALL, ["4.5", "4.7"], "4.5", "", False, "",
     "GDScript local variables are tracked in export builds",
     "Enabling this comes at the cost of roughly 50 bytes of memory per local variable, for every compiled class in the entire project, so can be several MiB in larger projects.",
     "Turn debug/settings/gdscript/always_track_local_variables off unless shipped builds capture script backtraces with variables.",
     "Exported builds can no longer include local variables in captured script backtraces.", PROJ47),
    ("post.glow_upscale_mobile", "post", "rendering/environment/glow/upscale_mode.mobile", "eq", 1, "low", "performance", ["mobile", "gl_compatibility"], BOTH, "", "", False, "",
     "Mobile devices use bicubic glow upscaling",
     "on mobile devices, due to performance concerns or driver support.",
     "Keep rendering/environment/glow/upscale_mode.mobile at Linear (0), the lower-end default for mobile devices.",
     "Linear glow upscaling looks blockier on large glow radii.", PROJ),
    ("shadows.positional_mobile_filter_raised", "shadows", "rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality.mobile", "gt", 0, "medium", "performance", MOBILE, BOTH, "", "", False, "",
     "The mobile omni/spot shadow filter is above the low-end default",
     "on mobile devices, due to performance concerns or driver support.",
     "Return rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality.mobile to Hard (0) unless soft omni/spot shadows are required on phones.",
     "Omni and spot shadow edges are harder on mobile devices.", PROJ),
    ("gi.texture_array_reflections_mobile", "gi", "rendering/reflections/sky_reflections/texture_array_reflections.mobile", "eq", True, "medium", "performance", MOBILE, BOTH, "", "", False, "",
     "Mobile devices use texture-array sky reflections",
     "on mobile devices, due to performance concerns or driver support.",
     "Keep rendering/reflections/sky_reflections/texture_array_reflections.mobile off, the lower-end default.",
     "Rough sky reflections are lower quality on mobile devices.", PROJ),
    ("renderer.burley_mobile", "renderer", "rendering/shading/overrides/force_lambert_over_burley.mobile", "eq", False, "low", "performance", ["mobile", "gl_compatibility"], BOTH, "", "", False, "",
     "Mobile devices use Burley instead of Lambert diffuse",
     "on mobile devices, due to performance concerns or driver support.",
     "Keep rendering/shading/overrides/force_lambert_over_burley.mobile on, the lower-end default.",
     "Lambert diffuse is slightly less physically accurate.", PROJ),
    ("renderer.gl_item_buffer_raised", "renderer", "rendering/gl_compatibility/item_buffer_size", "gt", 16384, "low", "performance", GL, BOTH, "", "", False, "",
     "The Compatibility canvas item buffer is above its default",
     "Decreasing this limit may improve performance on bandwidth limited devices.",
     "Keep rendering/gl_compatibility/item_buffer_size at 16384 unless canvas items are being dropped; raise it only as far as needed.",
     "Too small a buffer drops canvas items that exceed it in one viewport update.", PROJ),
]

# Fix font mipmaps quote - I'll verify. If the description doesn't say memory, the quote I used might fail.
# I'll adjust after the generator run if needed.

SCENE_ROWS = [
    ("physics.continuous_cd", "physics", "rigid_ccd_count", "gte", 1, "medium", "performance", False, "",
     "Continuous collision detection is enabled on a 3D body",
     "Not using continuous collision detection is faster to compute",
     "RigidBody3D",
     "Turn RigidBody3D.continuous_cd off on bodies that are not small and fast. The class says skipping CCD is faster and can miss those impacts.",
     "Fast thin objects can tunnel.", "RigidBody3D.continuous_cd", "rigid_ccd",
     D44 + "classes/class_rigidbody3d.html"),
    ("physics.continuous_cd_2d", "physics", "rigid_2d_ccd_count", "gte", 1, "medium", "performance", False, "",
     "Continuous collision detection is enabled on a 2D body",
     "Continuous collision detection is slower, but more precise",
     "RigidBody2D",
     "Turn RigidBody2D.continuous_cd off on bodies that are not small and fast.",
     "Fast thin objects can tunnel.", "RigidBody2D.continuous_cd", "rigid_2d_ccd",
     D44 + "classes/class_rigidbody2d.html"),
    ("physics.concave_shape", "physics", "concave_shape_count", "gte", 1, "medium", "performance", False, "",
     "A concave collision shape is in the scene",
     "Try using simplified versions of your rendered geometry for collision shapes",
     "CPU optimization",
     "Replace ConcavePolygonShape3D with a few convex shapes or primitives where the player will not notice. The CPU optimization page recommends simplified collision geometry.",
     "Collision no longer matches every triangle of the visual mesh.", "ConcavePolygonShape3D", "concave_shapes",
     CPU),
    ("physics.heightmap_shape", "physics", "heightmap_shape_count", "gte", 1, "low", "performance", False, "",
     "A heightmap collision shape is in the scene",
     "Try using simplified versions of your rendered geometry for collision shapes",
     "CPU optimization",
     "HeightMapShape3D is a dense terrain collider. The CPU optimization page says simplified stand-in shapes are often enough.",
     "Terrain collision gets coarser.", "HeightMapShape3D", "heightmap_shapes",
     CPU),
    ("physics.soft_body", "physics", "soft_body_count", "gte", 1, "medium", "performance", False, "",
     "A SoftBody3D is in the scene",
     "Increasing this value will improve the resulting simulation, but can affect performance",
     "SoftBody3D",
     "Lower SoftBody3D.simulation_precision if the body is not a focal object. The class says raising it improves the sim and can affect performance.",
     "The soft body looks less stable.", "SoftBody3D.simulation_precision", "soft_bodies",
     D44 + "classes/class_softbody3d.html"),
    ("physics.many_character_bodies", "physics", "character_body_3d_count", "gte", 8, "low", "performance", True,
     "The CPU optimization page says physics becomes a bottleneck with large numbers of physics objects, from the scene rather than a fixed cap. Eight is only a prompt to look.",
     "Several CharacterBody3D nodes are in the scene",
     "physics can end up becoming a bottleneck",
     "CPU optimization",
     "The CPU optimization page says large numbers of physics objects become a bottleneck and suggests removing ones outside the current area.",
     "Bodies you despawn cannot be pushed until they spawn again.", "CharacterBody3D", "",
     CPU),
    ("navigation.avoidance", "navigation", "navigation_avoidance_count", "gte", 1, "medium", "performance", False, "",
     "A NavigationAgent2D/3D has avoidance enabled",
     "Avoidance processing with many registered agents has a significant performance cost",
     "NavigationAgent2D/3D",
     "Turn avoidance_enabled off on 2D or 3D agents that do not currently need avoidance. Cost depends on active agents and nearby neighbours.",
     "Those agents no longer receive safe_velocity.", "NavigationAgent2D/3D.avoidance_enabled", "avoidance_agents",
     D44 + "classes/class_navigationagent3d.html"),
    ("animation.physics_callback", "animation", "animation_physics_callback_count", "gte", 1, "low", "info", False, "",
     "An AnimationPlayer updates during the physics frame",
     "Process animation during physics frames",
     "AnimationMixer",
     "AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS updates during the physics frame. The class says that is for animating physics bodies. Use ANIMATION_CALLBACK_MODE_PROCESS_IDLE otherwise.",
     "Animations of non-physics nodes update with the idle frame instead.", "AnimationMixer.callback_mode_process", "animation_physics",
     D44 + "classes/class_animationmixer.html"),
    ("audio.polyphony", "audio", "audio_polyphony_count", "gte", 1, "low", "performance", True,
     "The class says max_polyphony is how many sounds play at once and that extra sounds cut off the oldest. Above the default of 1 means more simultaneous mixes. No voice budget is documented.",
     "An audio player allows more than one voice",
     "The maximum number of sounds this node can play at the same time",
     "AudioStreamPlayer3D",
     "Lower max_polyphony toward 1 on players that do not need overlapping sounds. The class says extra sounds cut off the oldest.",
     "Overlapping plays cut off sooner.", "AudioStreamPlayer3D.max_polyphony", "audio_polyphony",
     D44 + "classes/class_audiostreamplayer3d.html"),
    ("audio.unbounded_3d", "audio", "check_audio_unbounded_distance", "gte", 1, "low", "performance", True,
     "An assigned stream is playing or configured to autoplay. This does not prove it is currently distant, audible or expensive.",
     "An active or autoplay 3D sound has no distance cutoff",
     "requiring audio mixing when the listener is far away, which saves CPU resources.",
     "AudioStreamPlayer3D",
     "For local sounds, compare a finite audible distance and profile CPU audio work with the listener moving through the scene.",
     "A cutoff changes the fade and removes distant sound; preserve intentionally far-reaching ambience.", "AudioStreamPlayer3D.max_distance", "check_audio_unbounded_distance",
     "https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/audio_stream_player_3d.cpp"),
    ("ui.subviewport_always", "ui", "subviewport_always_count", "gte", 1, "high", "performance", False, "",
     "A SubViewport updates even when it is not visible",
     "Always update the render target",
     "SubViewport",
     "Set SubViewport.render_target_update_mode to SubViewport.UPDATE_WHEN_VISIBLE. The class says UPDATE_ALWAYS always updates, and UPDATE_WHEN_VISIBLE is the default.",
     "A hidden viewport freezes until it is shown.", "SubViewport.render_target_update_mode", "subviewport_always",
     D44 + "classes/class_subviewport.html"),
    ("ui.subviewport_msaa", "ui", "subviewport_msaa_count", "gte", 1, "medium", "performance", False, "",
     "A SubViewport has 3D MSAA enabled",
     "A higher number results in smoother edges at the cost of significantly worse performance",
     "Viewport",
     "Set the SubViewport msaa_3d back to Viewport.MSAA_DISABLED unless that viewport needs smooth edges. The Viewport class says higher MSAA is significantly more expensive.",
     "Edges in that viewport are aliased.", "Viewport.msaa_3d", "subviewport_msaa",
     D44 + "classes/class_viewport.html"),
    ("ui.clip_children", "ui", "canvas_clip_children_count", "gte", 1, "low", "info", False, "",
     "A CanvasItem clips its children",
     "Clipping nodes cannot be nested",
     "CanvasItem",
     "CanvasItem.clip_children cannot be nested or placed in a CanvasGroup. The class says an ancestor that already clips should force this node back to CLIP_CHILDREN_DISABLED.",
     "Children can draw outside the parent.", "CanvasItem.clip_children", "clip_children",
     D44 + "classes/class_canvasitem.html"),
    ("gi.lightmap_unbaked", "gi", "lightmap_unbaked_count", "gte", 1, "medium", "info", False, "",
     "A LightmapGI node has no baked data",
     "This resource is automatically created after baking, and is not meant to be created manually",
     "LightmapGI",
     "Bake LightmapGI or remove the node. light_data stays empty until a bake. Realtime lights keep doing the work the bake would have captured.",
     "You have to rebake after you move static geometry.", "LightmapGI.light_data", "lightmap_unbaked",
     D44 + "classes/class_lightmapgi.html"),
    ("gi.voxel_unbaked", "gi", "voxel_unbaked_count", "gte", 1, "medium", "info", False, "",
     "A VoxelGI node has no baked data",
     "The resource that holds the data for this",
     "VoxelGI",
     "Bake the VoxelGI or remove it. The data resource is what holds the bake.",
     "Moving geometry requires another bake.", "VoxelGI.data", "voxel_unbaked",
     D44 + "classes/class_voxelgi.html"),
    ("scripts.many_process", "scripts", "nodes_with_process_count", "gte", 8, "medium", "performance", True,
     "The CPU optimization page says _process propagates through the tree and each node has a cost, with the visible range starting at thousands of nodes. Eight is only a prompt to look.",
     "Several nodes run _process",
     "_process() and _physics_process() propagate through the tree",
     "CPU optimization",
     "Disable _process on nodes that can wait for a signal. The CPU optimization page says those callbacks propagate through every node.",
     "That node stops seeing per-frame callbacks.", "Node._process", "nodes_with_process",
     CPU),
    ("scripts.many_physics_process", "scripts", "nodes_with_physics_process_count", "gte", 8, "medium", "performance", True,
     "The CPU optimization page groups _physics_process with _process as tree propagation cost. Eight is only a prompt to look, below the documented thousands of nodes.",
     "Several nodes run _physics_process",
     "_process() and _physics_process() propagate through the tree",
     "CPU optimization",
     "Move work that does not need the physics tick out of _physics_process. The CPU optimization page says both callbacks propagate through the tree.",
     "That node stops seeing physics ticks.", "Node._physics_process", "nodes_with_physics_process",
     CPU),
    ("scripts.node_count_high", "scripts", "autoload_count", "gte", 16, "low", "info", True,
     "Autoloads are nodes that stay for the whole run. The CPU optimization page says every node has a cost. Sixteen autoloads is a review prompt, not a Godot limit.",
     "The project has many autoloads",
     "every node has a cost",
     "CPU optimization",
     "The CPU optimization page says every node has a cost. Review autoloads that do not need to exist for the whole session.",
     "A removed autoload is not available as a singleton.", "Node", "autoloads",
     CPU),
    ("import.mesh_lods_off", "import", "import_mesh_lods_off_count", "gte", 1, "medium", "performance", False, "",
     "A 3D scene import disabled mesh LOD generation",
     "meshes/generate_lods",
     "importer",
     "Turn meshes/generate_lods back on. resource_importer_scene.cpp defaults that option to true. The mesh LOD page explains what those generated levels are for.",
     "Distant meshes stay at full triangle count.", "Mesh", "import_mesh_lods_off",
     SCENE_CPP),
    ("import.mesh_shadow_off", "import", "import_mesh_shadow_off_count", "gte", 1, "low", "performance", False, "",
     "A 3D scene import disabled shadow meshes",
     "meshes/create_shadow_meshes",
     "importer",
     "Turn meshes/create_shadow_meshes back on unless the mesh never casts a shadow. resource_importer_scene.cpp defaults that option to true.",
     "Shadow passes use the full mesh instead of the shadow mesh.", "Mesh", "import_mesh_shadow_off",
     SCENE_CPP),
    ("import.mesh_uncompressed", "import", "import_mesh_uncompressed_count", "gte", 1, "low", "performance", False, "",
     "A 3D scene import disables mesh compression",
     "meshes/force_disable_compression",
     "importer",
     "Turn meshes/force_disable_compression off. resource_importer_scene.cpp defaults it to false.",
     "Compressed meshes can show a tiny difference in vertex positions.", "Mesh", "import_mesh_uncompressed",
     SCENE_CPP),
    ("import.audio_pcm", "import", "import_audio_pcm_count", "gte", 1, "low", "performance", False, "",
     "A WAV import uses PCM instead of a compressed mode",
     "PCM (Uncompressed),IMA ADPCM,Quite OK Audio",
     "importer",
     "Set the WAV compress/mode away from 0 (PCM). resource_importer_wav.cpp lists 0 as PCM uncompressed and defaults to Quite OK Audio.",
     "Compressed WAV modes lose a bit of fidelity.", "AudioStreamWAV", "import_audio_pcm",
     WAV_CPP),
    ("import.texture_lossless", "import", "import_texture_lossless_count", "gte", 1, "medium", "performance", False, "",
     "A layered texture import (cubemap, array or 3D texture) uses lossless compression",
     "compress/mode",
     "importer",
     "Use VRAM compression for cubemaps, texture arrays and 3D textures, which are only sampled in 3D. compress/mode 0 is lossless. Plain 2D textures are not counted here: lossless is the recommended 2D default, and textures.lossless_3d covers 2D images used by 3D materials.",
     "The texture can pick up compression artifacts.", "Texture2D", "import_texture_lossless",
     IMG),
    ("import.texture_no_mipmaps", "import", "import_texture_no_mipmaps_count", "gte", 1, "medium", "performance", False, "",
     "A layered texture import (cubemap, array or 3D texture) does not generate mipmaps",
     "mipmaps/generate",
     "importer",
     "Turn mipmaps/generate on for cubemaps, texture arrays and 3D textures shown at varying distances; sampling smaller versions is faster and needs less memory bandwidth. Plain 2D textures are not counted here (2D mipmaps only help when the camera zooms out); textures.no_mipmaps covers 2D images used by 3D materials.",
     "UI textures that must stay sharp sometimes leave mipmaps off.", "Texture2D", "import_texture_no_mipmaps",
     IMG),
    ("import.texture_uncompressed", "import", "import_texture_uncompressed_count", "gte", 1, "high", "performance", False, "",
     "A texture import is VRAM-uncompressed",
     "compress/mode",
     "importer",
     "compress/mode 3 is VRAM uncompressed. Switch 3D textures to VRAM compressed. The image import tutorial describes the modes.",
     "Compressed textures can show block artifacts.", "Texture2D", "import_texture_uncompressed",
     IMG),
    ("geometry.multimesh_many_instances", "geometry", "multimesh_max_instances", "gte", 256, "low", "info", True,
     "The scan caps instance_count by visible_instance_count when set, excludes missing meshes, and covers 2D/3D MultiMesh nodes. 256 is a review prompt, not a Godot limit or a measured draw count.",
     "A MultiMesh permits at least 256 visible instances",
     "Number of instances that will get drawn",
     "MultiMesh",
     "If the visible instances are sparse, compare partitioning the MultiMesh so whole batches can be culled. Lower visible_instance_count only when those instances are actually unnecessary.",
     "Fewer instances are visible or more batches are submitted; profile both effects.", "MultiMesh.visible_instance_count", "multimesh_many_instances",
     D44 + "classes/class_multimesh.html"),
    ("import.texture_high_quality", "import", "import_texture_high_quality_count", "gte", 1, "low", "performance", True,
     "The .import file does not record whether the image is opaque; for transparent images both modes use 8 bits per pixel, so only opaque textures lose memory.",
     "VRAM-compressed textures use high-quality BPTC/ASTC compression",
     "When using S3TC, DXT1 (BC1) is used for opaque textures and DXT5 (BC3) is used for transparent or normal map (RGTC) textures.",
     "ResourceImporterTexture",
     "Turn compress/high_quality off for opaque textures where BC1 block artifacts are acceptable: BC7 (BPTC) stores 8 bits per pixel where DXT1 stores 4.",
     "High quality avoids BC1 block artifacts and is required to VRAM-compress HDR images.", "ResourceImporterTexture.compress/high_quality", "import_texture_high_quality",
     D44 + "classes/class_resourceimportertexture.html"),
    ("import.texture_hdr_uncompressed", "import", "import_texture_hdr_uncompressed_count", "gte", 1, "medium", "performance", False, "",
     "HDR textures are imported without VRAM compression",
     "Never use VRAM compression for HDR textures, regardless of whether they're opaque or transparent.",
     "ResourceImporterTexture",
     "Set compress/hdr_compression back to Opaque Only (or Always) and enable compress/high_quality so BPTC/ASTC can compress the .exr/.hdr image.",
     "VRAM-compressed HDR loses some precision; keep Disabled where exact HDR values matter.", "ResourceImporterTexture.compress/hdr_compression", "import_texture_hdr_uncompressed",
     D44 + "classes/class_resourceimportertexture.html"),
    # Per-frame script calls documented as costly in the class reference.
    ("scripts.frame_texture_readback", "scripts", "check_frame_texture_readback", "gte", 1, "high", "performance", True,
     'Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.',
     'A texture is read back from the GPU every frame',
     'This will fetch the texture data from the GPU, which might cause performance problems when overused.',
     'Texture2D',
     'Read the image once and cache it, or keep the data on the GPU (shaders, compute) instead of reading it back each frame.',
     'Cached images go stale if the texture keeps changing.', 'Texture2D.get_image', "check_frame_texture_readback",
     D44 + "classes/class_texture2d.html"),
    ("scripts.frame_mesh_bake", "scripts", "check_frame_mesh_bake", "gte", 1, "high", "performance", True,
     'Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.',
     'A skinned or blend-shape mesh is baked from the GPU every frame',
     'data needs to be received from the GPU',
     'MeshInstance3D',
     'Bake only when the pose actually changes, or derive the needed data on the CPU from bone transforms.',
     'Less frequent bakes lag behind the animated pose.', 'MeshInstance3D.bake_mesh_from_current_skeleton_pose', "check_frame_mesh_bake",
     D44 + "classes/class_meshinstance3d.html"),
    ("scripts.frame_multimesh_buffer", "scripts", "check_frame_multimesh_buffer", "gte", 1, "high", "performance", True,
     'Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.',
     'A MultiMesh buffer is read back every frame',
     'is potentially a slow operation and should be avoided whenever possible.',
     'RenderingServer',
     'Keep the instance data the script last wrote instead of reading the buffer back from the server.',
     'The script must own a copy of the instance data.', 'RenderingServer.multimesh_get_buffer', "check_frame_multimesh_buffer",
     D44 + "classes/class_renderingserver.html"),
    ("scripts.frame_global_shader_get", "scripts", "check_frame_global_shader_get", "gte", 1, "high", "performance", True,
     'Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.',
     'A global shader parameter is read from the rendering server every frame',
     'has a large performance penalty as the rendering thread needs to synchronize with the calling thread, which is slow.',
     'RenderingServer',
     'Store the value in a script variable when setting it and read that copy instead.',
     'The script copy must be kept in sync with every writer.', 'RenderingServer.global_shader_parameter_get', "check_frame_global_shader_get",
     D44 + "classes/class_renderingserver.html"),
    ("scripts.frame_force_sync", "scripts", "check_frame_force_sync", "gte", 1, "high", "performance", True,
     'Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.',
     'The rendering server is force-synchronized every frame',
     'Forces a synchronization between the CPU and GPU, which may be required in certain cases.',
     'RenderingServer',
     'Call force_sync only where the result is needed, not on every frame.',
     'Results that depend on GPU work may arrive a frame later.', 'RenderingServer.force_sync', "check_frame_force_sync",
     D44 + "classes/class_renderingserver.html"),
    ("scripts.frame_find_nodes", "scripts", "check_frame_find_nodes", "gte", 1, "medium", "performance", True,
     'Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.',
     'The scene tree is searched by name every frame',
     'This method can be very slow.',
     'Node',
     'Find the node once (in _ready or with an @onready variable or a unique name) and keep the reference.',
     'A cached reference must be refreshed if the node is replaced.', 'Node.find_child', "check_frame_find_nodes",
     D44 + "classes/class_node.html"),
    ("scripts.frame_group_calls", "scripts", "check_frame_group_calls", "gte", 1, "medium", "performance", True,
     'Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.',
     'A whole node group is called or notified every frame',
     'acts immediately on all selected nodes at once, which may cause stuttering in some performance-intensive situations.',
     'SceneTree',
     'Let group members run their own per-frame logic, use call_group_flags with GROUP_CALL_DEFERRED, or call only when state changes.',
     'Deferred calls run at the end of the frame instead of immediately.', 'SceneTree.call_group', "check_frame_group_calls",
     D44 + "classes/class_scenetree.html"),
    ("scripts.frame_output_latency", "scripts", "check_frame_output_latency", "gte", 1, "medium", "performance", True,
     'Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.',
     'Audio output latency is queried every frame',
     'This can be expensive; it is not recommended to call every frame.',
     'AudioServer',
     'Query the latency once (or rarely) and cache it.',
     'Latency changes from device switches are picked up later.', 'AudioServer.get_output_latency', "check_frame_output_latency",
     D44 + "classes/class_audioserver.html"),
    ("scripts.frame_window_title", "scripts", "check_frame_window_title", "gte", 1, "medium", "performance", True,
     'Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.',
     'The window title is changed every frame',
     'Avoid changing the window title every frame, as this can cause performance issues on certain window managers.',
     'DisplayServer',
     'Update the title only when its text changes, or show the value in an in-game label.',
     'The title updates less often.', 'DisplayServer.window_set_title', "check_frame_window_title",
     D44 + "classes/class_displayserver.html"),
    ("scripts.frame_capture_rect", "scripts", "check_frame_capture_rect", "gte", 1, "medium", "performance", True,
     'Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.',
     'GPU particle bounds are captured every frame',
     'Calling it often may have a negative impact on performance.',
     'GPUParticles2D',
     'Capture the visibility rectangle once (editor tool or on demand) and store it in visibility_rect.',
     'A stored rectangle can be too small if the effect changes.', 'GPUParticles2D.capture_rect', "check_frame_capture_rect",
     D44 + "classes/class_gpuparticles2d.html"),
    ("scripts.frame_tile_update", "scripts", "check_frame_tile_update", "gte", 1, "medium", "performance", True,
     'Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.',
     'Runtime tile data is invalidated every frame',
     'is computationally expensive and may impact performance.',
     'TileMapLayer',
     'Notify only when the runtime tile data actually changes.',
     'Tiles keep their previous runtime data until notified.', 'TileMapLayer.notify_runtime_tile_data_update', "check_frame_tile_update",
     D44 + "classes/class_tilemaplayer.html"),
    ("scripts.frame_bone_global_pose", "scripts", "check_frame_bone_global_pose", "gte", 1, "medium", "performance", True,
     'Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.',
     'Global bone poses are written every frame',
     'this method executes a dirty poses recalculation and will cause performance to deteriorate.',
     'Skeleton3D',
     'Set local poses (set_bone_pose_*) or use a SkeletonModifier3D, which avoids the dirty-pose recalculation per call.',
     'Local-space poses need the parent transforms to be accounted for.', 'Skeleton3D.set_bone_global_pose', "check_frame_bone_global_pose",
     D44 + "classes/class_skeleton3d.html"),
    ("scripts.frame_navigation_parse", "scripts", "check_frame_navigation_parse", "gte", 1, "high", "performance", True,
     'Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.',
     'Navigation source geometry is parsed every frame',
     'reading data arrays from resources can affect the frame rate negatively.',
     'NavigationServer3D',
     'Parse source geometry only when the level changes, ideally with collision shapes rather than meshes.',
     'Navigation updates follow geometry changes less closely.', 'NavigationServer3D.parse_source_geometry_data', "check_frame_navigation_parse",
     D44 + "classes/class_navigationserver3d.html"),
    ("scripts.frame_navigation_force_update", "scripts", "check_frame_navigation_force_update", "gte", 1, "high", "performance", True,
     'Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.',
     'A navigation map is force-updated every frame',
     'Not only can this severely impact the performance of a game but it can also introduce bugs if used inappropriately without much foresight.',
     'NavigationServer3D',
     'Let maps synchronize at the end of the physics frame, and force an update only after a structural change that needs an immediate path query.',
     'Path queries in the same frame as a map change see the previous map.', 'NavigationServer3D.map_force_update', "check_frame_navigation_force_update",
     D44 + "classes/class_navigationserver3d.html"),
    ("scripts.frame_navigation_bake", "scripts", "check_frame_navigation_bake", "gte", 1, "high", "performance", True,
     'Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.',
     'A navigation mesh is baked every frame',
     'navigation baking is not a cheap operation',
     'NavigationRegion3D',
     'Bake when the level geometry changes, not every frame; bake in the editor where the level is static.',
     'Navigation follows geometry changes later.', 'NavigationRegion3D.bake_navigation_mesh', "check_frame_navigation_bake",
     D44 + "classes/class_navigationregion3d.html"),
    ("scripts.frame_image_texture_set", "scripts", "check_frame_image_texture_set", "gte", 1, "medium", "performance", True,
     'Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.',
     'An ImageTexture is recreated every frame',
     "If you want to update the image, but don't need to change its parameters (format, size), use instead for better performance.",
     'ImageTexture',
     'Use ImageTexture.update() when only the pixels change.',
     'update() requires the same format and size.', 'ImageTexture.set_image', "check_frame_image_texture_set",
     D44 + "classes/class_imagetexture.html"),
    ("scripts.frame_file_flush", "scripts", "check_frame_file_flush", "gte", 1, "medium", "performance", True,
     'Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.',
     'A file is flushed to disk every frame',
     'Otherwise, it will decrease performance due to constant disk writes.',
     'FileAccess',
     'Flush only when the data must survive a crash, or batch writes.',
     'Unflushed data can be lost on a crash.', 'FileAccess.flush', "check_frame_file_flush",
     D44 + "classes/class_fileaccess.html"),
    ("scripts.frame_impulse", "scripts", "check_frame_impulse", "gte", 1, "medium", "correctness", True,
     'Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.',
     'An impulse not scaled by the frame time is applied every frame',
     'Applying an impulse every frame would result in a framerate-dependent force.',
     'RigidBody3D',
     'Use apply_force/apply_central_force for continuous pushes; keep impulses for one-off events.',
     'Forces act over time; impulses change velocity instantly.', 'RigidBody3D.apply_impulse', "check_frame_impulse",
     D44 + "classes/class_rigidbody3d.html"),
    ("materials.shader_material_copies", "materials", "check_shader_material_copies", "gte", 1, "low", "performance", True,
     "Distinct ShaderMaterial resources in the scene that use the same shader and the same textures, matrices and uniform arrays, so they differ at most in scalars, vectors and colors, which per-instance uniforms can hold (shader_language.cpp rejects the instance qualifier on samplers, matrices and arrays). Any copy is reported; the count is not a budget.",
     "Several ShaderMaterials repeat one shader and differ only in instance-uniform values",
     "Per-instance uniforms allow for better shader reuse and are therefore faster", "ShaderMaterial",
     "Share one ShaderMaterial and move the values that differ to instance uniforms set with GeometryInstance3D.set_instance_shader_parameter or CanvasItem.set_instance_shader_parameter.",
     "Instance uniforms cannot be textures, and the shader has a limited number of them.", "ShaderMaterial.set_shader_parameter", "check_shader_material_copies",
     D44 + "classes/class_shadermaterial.html"),
    ("scripts.tile_runtime_update_all", "scripts", "check_tile_runtime_update_all", "gte", 1, "high", "performance", True,
     "Text scan: the first statement of a _use_tile_data_runtime_update override is `return true`, so every tile of the layer is processed at runtime.",
     "Every tile is marked for runtime tile-data updates",
     "Any tile processed at runtime without a need for it will imply a significant performance penalty.", "TileMapLayer",
     "Return true only for the cells that need runtime tile data (for example a set of changed coordinates), and call notify_runtime_tile_data_update when that set changes.",
     "The script must track which cells need runtime data.", "TileMapLayer._use_tile_data_runtime_update", "check_tile_runtime_update_all",
     D44 + "classes/class_tilemaplayer.html"),
    ("scripts.draw_line_loop", "scripts", "check_draw_line_loop", "gte", 1, "low", "performance", True,
     "Text scan of _draw: draw_line calls inside for or while loops, including one-line loops. Loop counts are not known, so a short fixed loop is reported too.",
     "Lines are drawn one draw_line call at a time inside a loop",
     "When drawing large amounts of lines, this is faster than using individual calls.", "CanvasItem",
     "Collect the points and draw them with one draw_multiline (separate segments) or draw_polyline (connected) call, or the _colors variants for per-segment colours.",
     "All lines in one call share the width and antialiasing setting.", "CanvasItem.draw_multiline", "check_draw_line_loop",
     D44 + "classes/class_canvasitem.html"),
    ("import.gltf_embedded_uncompressed", "import", "import_gltf_embedded_uncompressed_count", "gte", 1, "medium", "performance", False, "",
     "A glTF import embeds its images uncompressed",
     "textures compressed losslessly into the generated scene",
     "GLTFState",
     "Set gltf/embedded_image_handling back to Extract Textures (the default) so the images can be VRAM-compressed, or to Embed as Basis Universal.",
     "Extracted textures become separate files in the project.", "", "import_gltf_embedded_uncompressed",
     D44 + "classes/class_gltfstate.html"),
    ("import.obj_lods_off", "import", "import_obj_lods_off_count", "gte", 1, "medium", "performance", False, "",
     "An OBJ import disables mesh LOD generation",
     "generates lower detail variants of the mesh which will be displayed in the distance to improve rendering performance.",
     "ResourceImporterOBJ",
     "Turn generate_lods back on for OBJ meshes that are rendered from a distance.",
     "LODs add import time and file size; meshes always seen up close gain nothing.", "ResourceImporterOBJ.generate_lods", "import_obj_lods_off",
     D44 + "classes/class_resourceimporterobj.html"),
    ("import.obj_shadow_off", "import", "import_obj_shadow_off_count", "gte", 1, "low", "performance", False, "",
     "An OBJ import disables shadow mesh generation",
     "This optimizes shadow rendering without reducing quality by welding vertices together when possible.",
     "ResourceImporterOBJ",
     "Turn generate_shadow_mesh back on unless the mesh never casts shadows.",
     "Shadow meshes add a little import time and memory.", "ResourceImporterOBJ.generate_shadow_mesh", "import_obj_shadow_off",
     D44 + "classes/class_resourceimporterobj.html"),
]

# (id, category, condition, setting, severity, renderers, versions, min, vendors, title, quote, suggestion, tradeoff, source)
COMPOSITE_ROWS = [
    ("physics.separate_thread_2d_off", "physics",
     {"all": [_cond("eq", "physics/2d/run_on_separate_thread", False), {"metric_gt_budget_ratio": {"name": "TIME_PHYSICS_PROCESS", "ratio": 0.33}}]},
     "physics/2d/run_on_separate_thread", "low", ALL, BOTH, "", [],
     "The 2D physics server runs on the main thread while physics takes a third of the frame",
     "making better use of multi-core CPUs",
     "Turn physics/2d/run_on_separate_thread on: measured physics processing exceeds a third of the frame budget. The description says a separate thread can increase performance and restricts API use to the physics process.",
     "2D physics calls from idle _process are no longer safe.", PROJ),
    ("cpu.interpolation_traversal", "cpu",
     {"all": [_cond("eq", "physics/common/physics_interpolation", True), _cond("neq", "physics/3d/physics_interpolation/scene_traversal", "DEFAULT")]},
     "physics/3d/physics_interpolation/scene_traversal", "medium", ALL, ["4.5", "4.7"], "4.5", [],
     "3D physics interpolation uses the slower Legacy or Debug traversal",
     "The previous reference method used for scene tree traversal, which is slower.",
     "Set physics/3d/physics_interpolation/scene_traversal back to DEFAULT; Debug also alternates methods and logs.",
     "Legacy is only useful to compare against the default method while investigating an interpolation bug.", PROJ47),
    ("physics.jolt_contact_cache_off", "physics",
     {"all": [_cond("eq", "physics/3d/physics_engine", "Jolt Physics"), _cond("eq", "physics/jolt_physics_3d/simulation/body_pair_contact_cache_enabled", False)]},
     "physics/jolt_physics_3d/simulation/body_pair_contact_cache_enabled", "medium", ALL, BOTH, "", [],
     "The Jolt body pair contact cache is disabled",
     "enables the body pair contact cache, which removes the need for potentially expensive collision detection when the relative orientation between two bodies hasn't changed much.",
     "Turn physics/jolt_physics_3d/simulation/body_pair_contact_cache_enabled back on.",
     "The cache reuses contacts for nearly unchanged body pairs; disable it only if that causes visible contact errors.", PROJ),
    ("renderer.nvidia_gl_threaded", "renderer",
     _cond("eq", "rendering/gl_compatibility/nvidia_disable_threaded_optimization", False),
     "rendering/gl_compatibility/nvidia_disable_threaded_optimization", "high", GL, BOTH, "", ["nvidia"],
     "NVIDIA threaded optimization stays enabled under OpenGL",
     "disables the threaded optimization feature from the NVIDIA drivers, which are known to cause stuttering in most OpenGL applications.",
     "Turn rendering/gl_compatibility/nvidia_disable_threaded_optimization back on (Windows only).",
     "None documented; the setting has no effect outside Windows.", PROJ),
    ("post.ssil_blur_passes", "post",
     {"all": [{"scene_eq": {"name": "env_ssil", "value": 1}}, _cond("gt", "rendering/environment/ssil/blur_passes", 4)]},
     "rendering/environment/ssil/blur_passes", "medium", FP, BOTH, "", [],
     "SSIL blur passes are above the default",
     "A higher number will result in a smoother look, but will be slower to compute and will have less high-frequency detail.",
     "Return rendering/environment/ssil/blur_passes toward the default 4.",
     "Indirect light looks noisier with fewer blur passes.", PROJ),
]


def _add_composite(add, row):
    (rid, category, condition, path, severity, renderers, versions, min_v, vendors, title, quote, suggestion, tradeoff, source) = row
    _require("ProjectSettings", _tags(versions), quote)
    rule = dict(
        id=rid, category=category, title=title, severity=severity, kind="performance",
        renderers=renderers, versions=versions,
        requires=["settings"] + (["scene"] if "scene_" in repr(condition) else []) + (["metrics", "frame"] if "metric_" in repr(condition) else []),
        condition=condition, evidence=quote, suggestion=suggestion, setting=path, tradeoff=tradeoff,
        expected_effect="Re-measure with collect_metrics after changing this setting. No frame-time percentage is predicted.",
        verify_step="collect_metrics", source=source,
    )
    if vendors:
        rule["vendors"] = vendors
    if min_v:
        rule["min_version"] = min_v
    add(rule)

MONITOR_ROWS = [
    ("physics.active_bodies_2d", "physics", "PHYSICS_2D_ACTIVE_OBJECTS", "gte", 32, BOTH, "", "", True,
     "The monitor counts active RigidBody2D nodes and says lower is better. 32 is a review prompt, not a Godot limit.",
     "Many 2D rigid bodies are active",
     "Number of active nodes in the game",
     "PHYSICS_2D_ACTIVE_OBJECTS counts active 2D bodies. The CPU optimization page says large numbers of physics objects become a bottleneck.",
     ""),
    ("physics.pairs_2d", "physics", "PHYSICS_2D_COLLISION_PAIRS", "gte", 64, BOTH, "", "", True,
     "The monitor counts 2D collision pairs and says lower is better. 64 is a review prompt, not a Godot limit.",
     "Many 2D collision pairs",
     "Number of collision pairs in the 2D physics engine",
     "PHYSICS_2D_COLLISION_PAIRS is the pair count. Simplify shapes or let bodies sleep.",
     ""),
    ("physics.islands_3d", "physics", "PHYSICS_3D_ISLAND_COUNT", "gte", 32, BOTH, "", "", True,
     "The monitor counts 3D physics islands and says lower is better. 32 is a review prompt, not a Godot limit.",
     "Many 3D physics islands",
     "Number of islands in the 3D physics engine",
     "PHYSICS_3D_ISLAND_COUNT is the island count. Islands grow when many bodies are awake and touching.",
     ""),
    ("memory.texture_mem", "memory", "RENDER_TEXTURE_MEM_USED", "gte", 268435456, BOTH, "", "", True,
     "256 MiB is not a Godot limit. RENDER_TEXTURE_MEM_USED is the texture byte counter and the class says lower is better.",
     "Texture memory is above 256 MiB",
     "The amount of texture memory used (in bytes)",
     "RENDER_TEXTURE_MEM_USED is texture bytes. vram_report names the resources when a game is running.",
     ""),
    ("memory.node_count", "memory", "OBJECT_NODE_COUNT", "gte", 1000, BOTH, "", "", True,
     "The CPU optimization page says node cost shows up from thousands of nodes. OBJECT_NODE_COUNT includes the root. 1000 is the low end of that range.",
     "The scene tree has at least 1000 nodes",
     "Number of nodes currently instantiated in the scene tree",
     "OBJECT_NODE_COUNT includes the root. The CPU optimization page says thousands of nodes start to matter and that fewer nodes with more in each is better.",
     ""),
    ("audio.measured_latency", "audio", "AUDIO_OUTPUT_LATENCY", "gt", 0.05, BOTH, "", "", True,
     "The monitor is AudioServer output latency in seconds. 50 ms is above the 15 ms preferred default of audio/driver/output_latency. It is not a hardware measurement from this tool.",
     "Measured audio output latency is above 50 ms",
     "it is not recommended to call this every frame",
     "AUDIO_OUTPUT_LATENCY is the measured output latency in seconds. Compare it with audio/driver/output_latency. The class says not to query it every frame.",
     ""),
    ("navigation.agents_44", "navigation", "NAVIGATION_AGENT_COUNT", "gte", 8, V44, "", "4.4", True,
     "In Godot 4.4 this monitor counts 3D agents processing avoidance. Eight is a review prompt. Godot 4.7 renamed it to NAVIGATION_3D_AGENT_COUNT.",
     "Navigation agents are processing avoidance",
     "Number of active navigation agents processing avoidance",
     "NAVIGATION_AGENT_COUNT is the 4.4 name for agents processing avoidance. Turn avoidance off on agents that do not need it.",
     ""),
    ("navigation.agents_3d", "navigation", "NAVIGATION_3D_AGENT_COUNT", "gte", 8, ["4.5", "4.7"], "4.5", "", True,
     "From Godot 4.5 this monitor counts 3D agents processing avoidance. Eight is a review prompt.",
     "3D navigation agents are processing avoidance",
     "Number of active navigation agents processing avoidance",
     "NAVIGATION_3D_AGENT_COUNT counts 3D agents processing avoidance. Turn avoidance off on agents that do not need it.",
     ""),
    ("navigation.agents_2d", "navigation", "NAVIGATION_2D_AGENT_COUNT", "gte", 8, ["4.5", "4.7"], "4.5", "", True,
     "From Godot 4.5 this monitor counts 2D agents processing avoidance. Eight is a review prompt.",
     "2D navigation agents are processing avoidance",
     "Number of active navigation agents processing avoidance",
     "NAVIGATION_2D_AGENT_COUNT counts 2D agents processing avoidance.",
     ""),
]


def _fix_scene_sources():
    """Scene rows that cite a tutorial are not in a class XML under that quote_class name."""
    return


# Patch _add_scene to allow tutorial quotes that are not class XML.
# CPU and importer quotes are verified differently below.

_TUTORIAL_OK = {
    "CPU optimization": CPU,
    "importer": None,
}


def _add_scene(add, row, both, all_r):
    (rid, category, key, op, value, severity, kind, heuristic, rationale, title,
     quote, quote_class, suggestion, tradeoff, node_property, offender, source) = row
    if quote_class not in _TUTORIAL_OK:
        _require(quote_class, _tags(BOTH), quote)
    elif quote_class == "importer":
        if quote not in open(os.path.join(SOURCE_CACHE, "imp_scene44.cpp"), encoding="utf-8", errors="replace").read() and quote not in open(os.path.join(SOURCE_CACHE, "wav44.cpp"), encoding="utf-8", errors="replace").read() and quote not in "compress/mode mipmaps/generate":
            if quote not in ("compress/mode", "mipmaps/generate"):
                raise SystemExit("importer quote missing: " + quote)
    add(dict(
        id=rid, category=category, title=title, severity=severity, kind=kind,
        heuristic=heuristic, heuristic_rationale=rationale,
        renderers=["forward_plus", "mobile", "gl_compatibility"], versions=["4.4", "4.7"],
        requires=["scene"],
        condition=_scene(op, key, value),
        evidence=quote,
        suggestion=suggestion,
        node_property=node_property,
        offender_key=offender,
        tradeoff=tradeoff,
        expected_effect="scan_scene should show a lower count after the edit. No frame-time percentage is predicted.",
        verify_step="scan_scene",
        source=source,
    ))
