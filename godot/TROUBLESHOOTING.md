# Troubleshooting

## Game measurements unavailable

Run the project from the editor and keep it out of the debugger: a game stopped at a breakpoint or error is refused at once, while a pause menu (a paused SceneTree) is measured. Measurements require the `RenderLensRuntime` autoload and an active debugger connection. Re-enable the plugin after replacing an older addon. A failed game capture returns an error; `source=editor` explicitly requests editor counters/screenshots instead.

## Large process time or an unknown bottleneck

`Performance.TIME_PROCESS` is a periodically updated maximum. It includes rendering synchronization, so it is not a median or proof of CPU work. Use the actual game frame samples and script/GPU evidence. An `unknown` bound is intentional when the available measurements do not isolate the cause.

Embedding, VSync, frame caps and external contention can affect elapsed frame intervals. Compare embedding enabled and disabled on the same stable workload. Sequential advisor captures are diagnostic evidence, not a synchronized CPU/GPU trace.

On 2026-10-10, the 1280×720 heavy scene on an RTX 4080 SUPER / Godot 4.7.2 measured 166–171 ms median in both embedded and separate-window runs with globally forced validation. Disabling validation checks only in the test processes reduced medians to 13–30 ms. The layer remained loaded because VkConfig forced it on. This identifies validation overhead as a major contributor in that setup; it does not predict performance on other machines or exclude smaller embedding effects. Check for globally forced validation before ordinary profiling. Render Lens neither requires nor changes that configuration.

## No GPU passes or zero GPU counter

GPU passes need Forward+ or Mobile and a running debugger-connected game. Compatibility still supports elapsed frame timing and screenshots. Invalid/underflowed viewport GPU counters are discarded. Missing GPU data is not interpreted as proof of a CPU bottleneck.

## Script and VRAM detail

Godot does not always forward built-in per-function profiling messages to editor plugins. `script_profile` reports its source and whether function rows arrived; an absent function list does not mean scripts cost zero. VRAM estimates do not include every driver allocation and are labeled as estimates.

## Validation SDK / VkConfig

Neither is required. The upstream-inspired rules use directly observed Godot settings and scene properties. Unknown or different GPU vendors do not activate Arm/Imagination-specific adaptations.

## Slow or disconnected capture

Stutter/session durations use elapsed time. A game stopped in the debugger is refused at once; continue it and repeat. If the game stops responding, the editor cancels the request after its timeout, and the game accepts a new measurement once the old one has unwound (at most 5 s); until then it answers "A game measurement is still active". No user editor process is killed.
