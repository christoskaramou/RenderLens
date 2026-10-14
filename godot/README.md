# Render Lens 2.0.0

Godot editor plugin with an embedded MCP server for game rendering measurements and sourced advice. Test targets: Godot 4.4, 4.5.2, 4.6.3 and 4.7.2. Rules verified on 4.7.2 also apply to later 4.x releases; their findings carry an `engine_version_note` there until that version is verified.

Copy `addons/render_lens` into your project, then enable **Render Lens** in Project Settings → Plugins. Connect your assistant to `http://127.0.0.1:43788`:

```json
{"mcpServers":{"render-lens":{"url":"http://127.0.0.1:43788"}}}
```

## Free and open source

Render Lens is free and open source under the [MIT license](LICENSE), with every tool included. If it saves you time, you can support it on [Ko-fi](https://ko-fi.com/christoskaramoustos): the **♥ Support Render Lens** link at the top of the Render Lens dock in the editor opens the page, no account is needed to tip, and a message with what you would like improved is very welcome.

## Why Render Lens

Godot already shows configuration warnings and has a profiler. Render Lens covers what those leave out, and every claim below is checked by the build or the test suites of the Render Lens source repository (they are not part of this package). [COMPARISON.md](docs/COMPARISON.md) sets it beside Godot's own profilers, the Debug Menu addon and other Godot MCP servers, with sources.

- **It measures what a change saves.** `measure_change` applies a suggestion in the running game only, measures the frame before, with the change and after restoring it, and reports the frame and GPU saving against the drift between the two "before" captures, with the GPU passes that moved. Nothing in the project changes. 36 findings carry a ready-made `experiment` (`measure_change finding=<id>`); other values of the rendering properties advice suggests (light shadows, environment effects, depth of field, geometry LOD and shadows, materials, viewport anti-aliasing and scaling) or of live project settings can be tried directly. Godot's profiler shows what a frame costs, not what a change would save.
- **Measured, not guessed.** In the running game it reads frame percentiles, GPU pass times (Forward+ and Mobile), script profiles, stutter and pipeline-compilation monitors. Frame and pass timings are taken with V-Sync and `max_fps` off, so they show what the frame costs rather than the display's refresh interval; the game's own settings come back afterwards. Findings come in four areas, always in this order: performance (measured costs, one entry per measured GPU pass), visual upgrades, missing parts (absent or misconfigured nodes and resources), and a collapsed "to check" list of candidates that no measurement in the run ties to a cost. An assistant can ask for one area with `focus`. Godot's default trade-offs are raised only when the frame is over budget. [MEASURED_EFFECTS.md](docs/MEASURED_EFFECTS.md) times each suggestion on the heavy sample scene (RTX 4080 SUPER, 1920x1080, Godot 4.7.2): omni-light shadows cost 2.8 of 6.0 ms GPU, SSR step count is within noise, and for the eight largest savings `gpu_passes` names the pass that shrank (the five smallest were not captured per pass).
- **Built for assistants.** The MCP server returns structured findings with the evidence, the suggestion and the trade-off for each, so an AI agent can act on them.
- **Every scene, and the running game.** Godot shows configuration warnings only for the scene open in the editor. Render Lens evaluates all 189 native warnings of Godot 4.4 to 4.7 (181 as rules; 8 excluded with reasons) for every scanned scene and inside the running game. Checks that resolve node paths or need processing state run only where the nodes are in a scene tree: the scene open in the editor and the running game, not scenes scanned by file path. Findings Godot already shows (its editor configuration warnings and the warnings it prints at run time) come after the others in their area and carry `godot_warns`, so the top of each list is what only Render Lens reports.
- **Godot's own runtime warnings, before the game runs.** Godot's engine code holds 643 distinct runtime warnings across 4.4 to 4.7, and many fire when Godot cannot honour a configuration: an upscaler the renderer lacks, TAA under a temporal upscaler, joint settings Jolt Physics ignores, a probe that forces the reflection atlas to 256, lightmaps pointing at deleted meshes, normal maps on meshes without tangents, skeleton modifiers naming missing bones, animation tracks pointing at renamed nodes, `res://` paths whose letter case differs from the file (they load on Windows and fail after export). Render Lens reports the stored configurations, saved files and script calls behind 222 of them, and lists the other 421 with the reason in the [runtime-warning inventory](docs/GODOT_RUNTIME_WARNINGS.json): hardware, drivers, platforms, editor tools, script calls that depend on runtime values, asset files Godot repairs itself, and engine internals. Every warning that stored state can predict has a rule.
- **Nothing silently left out.** Every cost statement in the class reference (812 notes) and the tutorials (771 paragraphs) is classified. 603 cost statements are checked by rules. The other 548 are listed with their reason in [DECLINED_RULES.md](docs/DECLINED_RULES.md): 107 concern the editor, baking, export or the operating system rather than the running game, 78 repeat a setting that is already checked or that Godot already warns about, 69 describe Godot's own default trade-offs, 293 depend on how scripts behave at runtime, which Render Lens measures (frame timing, script profiles) rather than predicts, and 1 describes a Godot 3 property that no longer exists.
- **Each rule cites Godot.** Every rule is tied to a class-reference entry, a godot-docs tutorial or engine source. Quoted sentences are checked word for word against Godot 4.4, 4.5.2, 4.6.3 and 4.7.2 when the catalog is built, every cited docs page must exist, and every scene predicate has a positive and a negative test fixture on each version where it applies.
- **Quiet on healthy projects.** A default project produces no performance or correctness findings (a regression test). Audited against all 139 official godot-demo-projects (391 scenes): no scan errors, no errors from Render Lens code, a median of 52 to 68 ms per scene across runs. On those untouched demos the median project gets one performance or correctness finding, and 42 get none; what remains comes mostly from settings the demos change on purpose (MSAA 4x, higher physics tick rates, 16x anisotropy, V-Sync off).
- **Tested on four Godot versions and 139 real projects.** Full suites, including the real editor-to-game bridge, a GPU screenshot, a heavy scene and the Separate render thread model, pass on Godot 4.4, 4.5.2, 4.6.3 and 4.7.2. Every tool has also been run against each of the 139 godot-demo-projects in a live game: no crashes, and every refusal explained (Compatibility renderer, a demo that quits or pauses itself).

## Measurements

Start the game with `run_game`. Frame timing, rendering statistics, screenshots, stutter reports and session summaries execute in the game process through the debugger bridge. `source=editor` explicitly requests an editor-only measurement; an unavailable game is never silently replaced by editor timing. Output context identifies the source, scene and process.

Frame percentiles use actual elapsed frame intervals. Per-frame process/physics times come from `EngineProfiler._tick` when available; `Performance.TIME_PROCESS` remains available as a periodic peak monitor, but is never used as a frame median. Process time includes rendering synchronization. An unexplained frame/GPU gap is labeled `unknown`, not automatically blamed on CPU work. GPU counters can lag by a frame.

The advisor scans the running scene, verifies scene identity against its measurements, and ranks measured evidence/pass correlations before unmeasured suggestions. A pass under 1% of the frame goes to the end of the performance area. Rules that measured the same pass are listed under one entry, so a timestamp that covers several passes (Godot's "Render GI + Render Directional/SpotLight Shadows (Parallel)") is counted once. Performance rules leave out nodes Godot never draws (a MeshInstance3D without a mesh, a PointLight2D without a texture, a VoxelGI without data); the missing-part finding reports them instead. A decal without textures is still clustered, so it still counts. A costly pass does not prove the individual cost of every node associated with it. There are no invented CPU millisecond ceilings. Profiling captures occur sequentially; compare a stable workload and repeat after each change.

## Tools

Eighteen tools. [WHY_MEASURE.md](docs/WHY_MEASURE.md) explains what the measurement tools add over the static audit, with the evidence for each claim.

| Tool | Output |
| --- | --- |
| `ping_render_lens` | Connection and version |
| `run_game`, `stop_game` | Editor play-session control |
| `render_stats` | Game draw calls, primitives, memory and viewport counters |
| `frame_timing` | Frame percentiles and cautious bottleneck hints |
| `capture_viewport` | Game viewport PNG, normal or overdraw |
| `collect_metrics` | Performance monitors, rendering counters and settings, with explicit source |
| `audit_project_rendering` | Static settings, scene and import findings |
| `gpu_passes` | Exclusive/inclusive GPU pass times, Forward+ or Mobile |
| `measure_change` | A change tried in the running game only: frame and GPU saving against measured noise, and the passes that moved |
| `stutter_report` | Wall-clock-bounded frame capture and hitch candidates |
| `advise` | Live scene, frame timing, GPU passes, profiler and resource evidence |
| `scan_scene` | Running scene counts and node paths; explicit scene paths request a static scan |
| `script_profile` | In-game frame/process/physics samples, script function rows when Godot delivers them |
| `vram_report` | Resource estimates or debugger Video RAM data, with source noted |
| `capture_compare` | Saved-capture comparison |
| `session_summary` | Time-bounded session rows |
| `debug_status` | Debugger connection diagnostics |

Measurements write artifacts under `.render_lens/captures`; advisory tools do not apply project or scene edits.

## Rules without validation layers

There are **703 rules in 30 areas**. **Every native node configuration warning in Godot 4.4, 4.5.2, 4.6.3 and 4.7.2 (189 messages) is mapped**: 181 are implemented as tested rules and 8 are excluded with stated reasons (editor/platform notices and two that stored state cannot reach); see the [Godot coverage inventory](docs/GODOT_COVERAGE.json). Every class-reference property, setting, enum-constant and method note that mentions a cost (812 notes) is classified in the [performance-notes inventory](docs/GODOT_PERF_NOTES.json), as is every godot-docs tutorial paragraph that mentions a cost (771 paragraphs, [tutorial inventory](docs/GODOT_TUTORIAL_NOTES.json)), as is every runtime `WARN_PRINT` message in Godot's `servers/`, `drivers/`, `scene/` and `modules/` (643 messages, [runtime-warning inventory](docs/GODOT_RUNTIME_WARNINGS.json)), and every declined candidate is listed with its reason in [DECLINED_RULES.md](docs/DECLINED_RULES.md). Quoted documentation, setting paths and property names are verified against the class XML of every Godot version a rule covers (4.4, 4.5.2, 4.6.3, 4.7.2) and the godot-docs 4.4 to 4.7 branches when the catalog is generated, and every cited docs page must exist. Godot shows these warnings only for scenes open in the editor; Render Lens reports them for the running game and for every scanned scene (checks that need a scene tree skip scenes scanned by file path). The catalog also includes **16 Khronos best-practice adaptations, 15 device-compatibility checks, 12 static shader-operand checks, 2 shader-interface checks, 5 shader capability, extension, declaration and execution-mode checks and 1 shader-header check adapted from Vulkan-ValidationLayers**. [RULES.md](RULES.md) records their sources, conditions and limits. [Upstream mapping](docs/UPSTREAM_RULES.md) explains what was read, what can be inspected in Godot and what was excluded. The [Vulkan coverage inventory](docs/VULKAN_COVERAGE.json) explicitly distinguishes implemented checks from remaining research.

The configuration checks also cover visibility ranges, 2D lights, particle colliders, paths, viewports and material conflicts. Performance candidates include extra material passes, triplanar and detail sampling, deep parallax, lighting features and particle warmup. Material scans follow up to eight passes per chain and report truncated chains. `advise` separates these from measured performance findings. Imported RenderingDevice shader stages are checked from compiled SPIR-V: vertex, fragment, tessellation and compute, plus ray-tracing stages in Godot 4.7. Scan coverage reports inspected/skipped stages, unavailable imports, size limits and unresolved specialization. Resource and operand checks cover these stages. A separate vertex/fragment interface check identifies mismatched numeric types/widths and proven missing vertex outputs in an imported pair; unknown declarations and unsupported stage combinations are excluded. Fixed compute workgroups are also compared with the current RenderingDevice limits when available. Configuration checks cover navigation, skeletons, animation, physics joints, camera effects and UI. No SDK or validation layer is required.

No Vulkan SDK, VkConfig, validation layer, D3D12 debug layer or validation subprocess is required. Vendor-specific adaptations only apply to an identified matching GPU family. They are project-level heuristics, not evidence that an API validator fired.

## Sample and checks

`sample_project/heavy_test.tscn` stresses Forward+ rendering. The separate scripts, physics and UI scenes cover those areas; `main.tscn` is a light smoke scene.

See [INSTALL.md](INSTALL.md) and [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
