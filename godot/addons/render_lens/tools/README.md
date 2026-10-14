# Tool execution

The MCP server lists only tools whose scripts exist in the installed package. Game measurements use `game_bridge.gd` / `runtime/bridge.gd`; explicit `source=editor` stays in the editor. `frame_samples.gd` supplies actual elapsed frame intervals and optional EngineProfiler component samples. No measurement uses periodic Performance peaks as frame medians.

Static project audits use `scene_scan.gd` and `project_scan.gd`. `advise` requests a live game scene snapshot and checks its scene identity against timing and metrics. GPU passes and script function rows use the debugger helpers. Results identify their source; unavailable observations must remain unavailable rather than fabricated zero-cost proof.

Rule inputs come from Godot settings, scene properties and measurements. There is no validation-layer or SDK dependency. See the repository README, RULES.md and docs/UPSTREAM_RULES.md.
