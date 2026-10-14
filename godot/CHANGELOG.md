# Changelog

## 2.0.0 — 2026-10-14

Render Lens is free and open source under the MIT license, in one package with all eighteen tools.

- Measures the running game from the editor through an embedded MCP server: frame percentiles with V-Sync and `max_fps` off, GPU pass times on Forward+ and Mobile, script profiles, stutter, video memory and pipeline compilations, always from the game process and never replaced by editor timing.
- `measure_change` tries a suggestion in the running game only and reports what it saves against the run's own noise, with the GPU passes that moved; 36 findings carry a ready-made experiment.
- `advise` ranks 703 rules in 30 areas by what was measured, in four areas: performance, visual upgrades, missing parts and candidates to check. Every rule cites Godot's class reference, tutorials or engine source, checked against Godot 4.4, 4.5.2, 4.6.3 and 4.7.2.
- The editor dock has a **♥ Support Render Lens** link to a Ko-fi page for tips; no account is needed.
- Install from the Godot Asset Library or from the release ZIP, `render-lens-<version>.zip`.
