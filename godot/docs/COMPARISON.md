# Render Lens and the free alternatives

What Godot and other free or listed tools already do for rendering performance, and where Render Lens differs. Third-party statements come from the linked pages, accessed 2026-10-11; Godot statements come from the 4.7 docs and class reference. Render Lens statements come from this repository's README and tests.

## Summary

| Need | Godot editor | Debug Menu addon | Godot MCP servers | Render Lens |
| --- | --- | --- | --- | --- |
| Frame rate and frame time of the running game | Monitors tab | In-game overlay, last 150 frames | Godot MCP Pro: `get_performance_monitors` | `frame_timing`: frame percentiles from elapsed intervals |
| GPU time per rendering pass | Visual Profiler tab | Total GPU time only | None found | `gpu_passes`: exclusive and inclusive pass times, Forward+ and Mobile |
| What a change would save | No (compare two profiler runs by hand) | No | None found | `measure_change`: the change tried in the running game only, frame and GPU saving against measured noise, and the passes that moved |
| Script time | Profiler tab | No | None found | `script_profile`: frame, process and physics samples, script rows when Godot delivers them |
| Video memory | Video RAM tab | Antz fork: total VRAM | None found | `vram_report` |
| Native configuration warnings | Scene dock, for the scene open in the editor | No | None found | All 189 warnings of 4.4 to 4.7 mapped; 181 checked in the running game and the open scene, and in scenes scanned by path except checks that need a scene tree |
| Rendering configuration advice | No | No | Godot MCP Pro: `analyze_scene_complexity` ("Analyze scene performance") | 703 rules, each citing a class-reference entry, tutorial or engine source checked at build time |
| An AI assistant can read the results | No | No | Yes | Yes, with evidence, suggestion and trade-off per finding |
| GPU frame capture, shader debugging | No | No | No | No (use RenderDoc, Nsight Graphics or PIX) |

## Godot editor

The Debugger panel ([docs](https://docs.godotengine.org/en/stable/tutorials/scripting/debug/debugger_panel.html)) already measures most of what Render Lens measures:

- The Profiler shows "what code is running while your project is in use, and how that effects performance".
- The Visual Profiler can "monitor what is taking the most time when rendering a frame on the CPU and GPU respectively". It "only measures CPU time taken for rendering tasks".
- Monitors graph FPS, memory and rendering statistics; the Video RAM tab lists resources by size; Godot 4.6 adds an ObjectDB profiler for memory snapshots.

Configuration warnings appear in the Scene dock. The class reference says for `Node._get_configuration_warnings`: "The elements in the array returned from this method are displayed as warnings in the Scene dock". The editor shows them for the scene being edited; it does not list them for every scene in a project or for the running game.

The editor gives no advice: it shows where time goes, not which setting caused it or what to change. Its results live in the editor UI and are not available to an assistant.

**Render Lens adds:** the same measurements as structured MCP output, configuration findings tied to the measured passes (performance first, measured costs leading and one entry per measured pass, then visual upgrades, missing parts and a collapsed list of unmeasured candidates to check), warnings for every scanned scene, and the rule catalog.

## Debug Menu (Calinou, MIT)

[godot-debug-menu](https://github.com/godot-extended-libraries/godot-debug-menu) "Displays FPS, frametime, CPU time and GPU time graphs" over "the last 150 rendered frames", shows hardware and graphics settings, and "Works with the Forward+, Mobile and Compatibility rendering methods". It also runs in exported builds. Its README explains how to read GPU-bound and CPU-bound frames. The [Antz fork](https://store.godotengine.org/asset/antz/antz-debug-menu/) adds draw calls, primitives and total VRAM.

It is an overlay for a person watching the game; it has no pass breakdown and no project findings. Render Lens has no in-game overlay, and its measurements need the editor's debugger connection, so they do not run in exported builds.

## Godot MCP servers

- **[Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp)** (MIT): launches the editor, runs projects, captures debug output, edits scenes, manages UIDs. No performance or rendering tools.
- **[Godot MCP Pro](https://github.com/youichi-uda/godot-mcp-pro)** (proprietary): 162 to 187 tools (the README gives both numbers). Profiling is `get_performance_monitors` ("All performance monitors (FPS, memory, physics, etc.)") and `get_editor_performance` ("Quick performance summary"); analysis includes `analyze_scene_complexity` and `run_stress_test`. The README does not describe pass timing, documentation-cited rules or a rendering-settings audit.
- **[Godot Forge](https://glama.ai/mcp/servers/gregario/godot-forge)** (MIT): GDScript pitfall and scene antipattern analyzers, tests, screenshots. Its listing puts "performance profiling" on the roadmap.
- **[GodotIQ](https://glama.ai/mcp/servers/salvo10f/godotiq)** (MIT, with a paid tier): spatial and code analysis, dependency and signal graphs. Its listing mentions no profiling.

Render Lens is narrower: it does not edit scenes or run tests. It covers rendering measurement and rendering advice in depth, and leaves general editor automation to these servers. They can be connected side by side.

## Vendor tools

[Arm Performance Studio](https://learn.arm.com/learning-paths/mobile-graphics-and-gaming/godot_packages/profile-godot-with-aps/) is "a free suite of analysis tools to profile game performance on mobile devices with Arm CPUs and GPUs". Its Performance Advisor "offers optimization suggestions", and a Godot extension (4.3 and later) adds timeline markers. It needs an Arm Android device and reports on captured hardware counters, not on Godot settings.

GPU frame debuggers (RenderDoc, NVIDIA Nsight Graphics, Microsoft PIX) capture and replay single frames down to draw calls and shader instructions. Render Lens does neither.

## Where Render Lens does not help

- Script logic: 293 cost statements in the docs depend on what scripts do at runtime. Render Lens measures their time (`script_profile`, frame timing). Its script text scan reports only specific calls listed in RULES.md (per-frame calls the class reference documents as costly, deprecated APIs, ignored draw arguments and similar); it does not judge script logic in general.
- Pass timing needs a RenderingDevice renderer (Forward+ or Mobile); the Compatibility renderer gets frame timing and configuration findings only.
- Static findings are candidates, not measurements. Each one names the trade-off; the measured effect of a toggle depends on the scene and the GPU.
