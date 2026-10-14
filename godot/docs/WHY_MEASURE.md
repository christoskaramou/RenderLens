# What measuring adds

The static audit is complete for configuration on its own: `audit_project_rendering` evaluates the 646 rules that need only project settings, scene files and scripts. That covers every native configuration warning, every documented cost statement Render Lens can check, and every Godot runtime warning that stored state predicts. It tells you what *might* be costing time.

The measurement tools answer the question that matters next: **which of those costs time in your game, on your hardware, right now.** Everything below is backed by a test or a measurement in this repository.

## 1. It measures, so you stop guessing

On the heavy sample scene ([MEASURED_EFFECTS.md](MEASURED_EFFECTS.md), RTX 4080 SUPER, 1920x1080), thirteen suggestions that a static audit reports with equal weight changed GPU time by anything from 2.79 ms (omni-light shadows, 46% of the frame) to 0.009 ms (SSR step count, within noise). A static list cannot tell those apart. `gpu_passes` reads Godot's per-pass GPU timestamps in the running game and attributes each cost to the pass that pays it; in that measurement, for each of the eight largest savings it showed which pass shrank (Render OmniLight Shadows, Process SSIL, Depth of Field, Glow, Render Fog, Process SSR); the five smallest were not captured per pass.

That table took one separate process per suggestion. `measure_change` does the same in your own running game: it applies a suggestion there only (36 findings carry a ready-made experiment, and other values of the rendering properties advice suggests, or of live project settings, can be tried directly), measures the frame before, with the change and after restoring it, and reports the frame and GPU saving against the drift between the two "before" captures, with the passes that moved. On the heavy sample scene the regression suite checks that turning the omni-light shadows off reads as faster with the omni shadow pass among the passes that shrank. Nothing in the project changes; settings Godot reads only at startup are refused with the two-run alternative.

## 2. Its advice is ranked by what was measured

`advise` combines a scan of the running scene, frame timing, GPU pass shares, script profiling and resource estimates. 57 rules need those measurements (pass shares, physics and script time, draw counts, memory, measured latency) and are evaluated only here. Frame and pass timings are taken with V-Sync and `max_fps` off, then the game's settings are restored. Measured costs lead the performance findings, one entry per measured pass, which come before visual upgrades, missing parts and a collapsed list of candidates no measurement ties to a cost; a pass under 1% of the frame goes last. Godot's own default trade-offs (cube-map omni shadows, four-split sun shadows, far plane 4000 and others) are raised only when the frame is over budget. A default project gets no performance findings, and the 139 official demo projects get a median of one.

## 3. It catches measurement traps

- Godot keeps at most 256 GPU timestamps per frame by default. Heavy scenes exceed that, and every later pass silently disappears from any timestamp-based breakdown: on the sample scene, depth of field, glow, tonemap and all 2D drawing, plus 0.69 ms of frame time. Render Lens reports the truncation in its result and names the setting to raise; the editor's Visual Profiler reads the same capped timestamps, and Godot only logs an error in the game output.
- Measurements always come from the game process; an unavailable game is reported, never replaced by editor timing, and an unexplained CPU/GPU gap is labeled unknown instead of being blamed on one side.

## 4. It sees the running game, not only the files

`scan_scene` inspects the live scene: nodes spawned by scripts, laid-out UI (some checks, such as a fit-mode TextureRect in a wrapping FlowContainer, depend on layout that only exists at runtime), and the effective environment and camera. `stutter_report` captures hitches over a time window, `script_profile` records per-frame process and physics time with script function rows when Godot provides them, `vram_report` estimates video memory per resource, `capture_compare` compares saved captures before and after a change, and `session_summary` summarizes a play session over time.

## 5. It is built to be trusted

- Every rule cites Godot's class reference, tutorials or engine source; quotes and engine messages are checked word for word against Godot 4.4, 4.5.2, 4.6.3 and 4.7.2 when the catalog is built ([UPSTREAM_RULES.md](UPSTREAM_RULES.md)).
- Full suites, including the real editor-to-game connection and a GPU screenshot, pass on all four versions.
- Building it found real engine problems: SpringBoneSimulator3D keeps an excluded collision active when the exclude list is out of child order (reproduced on 4.4 and 4.7.2, [DECLINED_RULES.md](DECLINED_RULES.md)), the TwoBoneIK3D "no pole target" warning tests the target node again (`two_bone_ik_3d.cpp:203-205` in 4.7.2), and Godot's 256-timestamp default silently truncates GPU captures of heavy frames ([MEASURED_EFFECTS.md](MEASURED_EFFECTS.md)).
- Its findings are structured for AI assistants: evidence, suggestion and trade-off for each, through MCP.

## What it does not do

It does not capture or replay GPU frames (use RenderDoc, Nsight Graphics or PIX), it does not run in exported release builds (it measures the game the editor launches, a debug build whose window title ends in "(DEBUG)"; GDScript there keeps its debug checks, so script and CPU times run higher than in a release export, while GPU pass times come from the same renderer), and its measurements are only as representative as the scene and hardware you run. See [COMPARISON.md](COMPARISON.md) for what Godot's own profilers and other tools already provide.
