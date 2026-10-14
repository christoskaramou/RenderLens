# Measured effects of Render Lens suggestions

What each single-toggle suggestion that Render Lens reports on `sample_project/heavy_test.tscn` changes in GPU and frame time, measured on 2026-10-12, and which Godot GPU pass shrank. Effects depend on the scene and the GPU; this is one stress scene on one desktop GPU, not a promise for other projects.

## Setup

- NVIDIA GeForce RTX 4080 SUPER (driver 617.14, Vulkan 1.4.351), Intel Core i9-14900KS, Windows 11 (build 26300).
- Godot 4.7.2-stable, Forward+, a 1920x1080 window on display 1, V-Sync off, no frame cap.
- Each variant is a separate process that loads `heavy_test.tscn`, changes one setting, renders 300 warm-up frames, then records 600 frames. GPU time is the median of `RenderingServer.viewport_get_measured_render_time_gpu`; frame time is the median interval between frames. The measured project runs without the addon.
- Noise floor: three baselines, run first, in the middle and last: 6.041, 6.049 and 6.055 ms GPU (spread 0.014 ms), 7.851 to 7.860 ms per frame. Changes smaller than twice the spread are marked as within noise.
- Pass attribution: Render Lens `gpu_passes` through the editor-to-game bridge, 120 frames per variant, with `debug/settings/profiler/max_timestamp_query_elements` raised to 1024 (see the last section).
- In your own game: `measure_change finding=<rule id>` tries the same single change live (before, with the change, after restoring it) and reports the saving against the drift between the two "before" captures.
- Reproduce: `python scripts/measure/run_measure.py <godot console> <work dir>` and `TS_LIMIT=1024 python scripts/measure/crosscheck.py <godot console> <work dir> baseline omni_shadows_off ...`.

## Results

Baseline: 6.049 ms GPU, 7.854 ms per frame (median of the three baselines).

| Rule | Change | GPU ms | GPU change | Frame ms | Pass that shrank (`gpu_passes`) |
| --- | --- | --- | --- | --- | --- |
| `shadows.omni_shadow_count` | Shadows off on the 8 omni lights | 3.256 | -2.793 (-46.2%) | 5.005 | Render OmniLight Shadows -2.751 ms; render CPU time also halved (0.69 to 0.35 ms) |
| `shadows.spot_shadow_count` | Shadows off on the 6 spot lights | 4.859 | -1.190 (-19.7%) | 6.652 | Render GI + Directional/SpotLight Shadows (parallel) -1.044 ms |
| `gi.sdfgi_enabled` | SDFGI off | 5.652 | -0.397 (-6.6%) | 7.439 | SDFGI passes and the GI half of the parallel GI + shadow pass; timestamp span -0.364 ms |
| `gi.ssil_enabled` | SSIL off | 5.918 | -0.131 (-2.2%) | 7.737 | Process SSIL -0.114 ms |
| `post.dof_enabled` | Far depth of field off | 5.924 | -0.125 (-2.1%) | 7.736 | Depth of Field -0.125 ms |
| `post.glow_enabled` | Glow off | 5.950 | -0.099 (-1.6%) | 7.774 | Glow -0.062 ms, Tonemap -0.031 ms |
| `post.volumetric_fog` | Volumetric fog off | 5.963 | -0.086 (-1.4%) | 7.768 | Render Fog -0.048 ms |
| `post.ssr_enabled` | SSR off | 5.965 | -0.084 (-1.4%) | 7.781 | Process SSR -0.078 ms |
| `post.ssao_enabled` | SSAO off | 5.993 | -0.056 (-0.9%) | 7.819 | not captured |
| `gi.half_resolution_off` | `use_half_resolution` on (via override.cfg, read back as true) | 5.993 | -0.056 (-0.9%) | 7.825 | not captured |
| `shadows.directional_max_distance` | Directional shadow distance 180 to 100 | 6.007 | -0.042 (-0.7%) | 7.825 | not captured |
| `post.fog_sdfgi_inject` | Fog GI inject 0 | 6.037 | -0.012, within noise | 7.861 | not captured |
| `post.ssr_steps` | SSR max steps 96 to 64 | 6.040 | -0.009, within noise | 7.853 | not captured |
| All of the above | Every change at once | 0.792 | -5.257 (-86.9%) | 2.544 | |

What this shows:

- Every suggestion that has a cost in this scene moved GPU time in the direction its rule states. For the eight largest savings `gpu_passes` showed which pass the saving came from (the table's last column); the five smallest (0.056 ms and below) were not captured per pass, three of them above the noise floor.
- The size of the effect varies by two orders of magnitude. Omni-light shadows (eight cube maps) cost 2.8 ms, almost half the GPU frame, while SSR step count and fog GI injection are within noise here. This is why `advise` ranks measured pass shares first and moves a pass under 1% of the frame to the end of the performance findings.
- Frame time follows GPU time but stays about 1.8 ms above it, so this scene is not purely GPU-bound on this machine.
- Run-to-run variation of a single pass inside `gpu_passes` is larger than the viewport counter's: the OmniLight shadow pass read between 2.75 and 3.04 ms across captures. Pass rows are single captures; the GPU column above is the more precise number.

## Idle overhead

With no tool running, the only per-frame work Render Lens adds to the game is the recorder's `_process` with two early returns (its profilers are enabled only during a capture). Measured headless on Godot 4.7.2 (i9-14900KS, 2026-10-12): 0.22 to 0.33 us per frame over three runs of 200,000 calls, about 0.002% of a 16.7 ms frame. The game-side runtime does nothing at all when the game is not started from the editor (no debugger session).

## Finding: truncated pass captures (fixed)

The first cross-check used Godot's default of 256 GPU timestamps per frame (`debug/settings/profiler/max_timestamp_query_elements`). This scene records more than that, so Godot's RenderingDevice dropped every later timestamp and logged "Tried capturing more timestamps than the configured maximum" in the game. `gpu_passes` returned a breakdown missing depth of field, glow, tonemap, the final framebuffer copy and all 2D canvas rendering, a timestamp-span frame time 0.69 ms too short (7.337 instead of 8.024 ms), and no viewport counter, and its note blamed a counter underflow. Only the omni-shadows-off variant (215 timestamps) was complete.

Render Lens now records the per-frame timestamp count against the limit in the game. `gpu_passes` reports `timestamp_truncated` with a note naming the setting, and `advise` passes the note on (`gpu_passes_truncation`). Checked on the same scene through the real bridge: with the default limit, 120 of 120 frames are reported as truncated; at 1024, none are, and the missing passes and the viewport counter return.
