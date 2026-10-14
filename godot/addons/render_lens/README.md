# Render Lens

Godot editor plugin with an embedded MCP server: it measures your running game (frame percentiles, GPU pass times, script profiles, stutter, video memory) and gives sourced rendering and performance advice that an AI assistant can act on, including `measure_change`, which tries a suggestion in the running game only and reports what it saves.

1. Enable **Render Lens** in Project Settings → Plugins.
2. Connect your MCP client to `http://127.0.0.1:43788`: `{"mcpServers":{"render-lens":{"url":"http://127.0.0.1:43788"}}}`
3. Start the game from the editor (or call `run_game`) and ask for measurements or advice.

Works with Godot 4.4 to 4.7. Free and open source under the MIT license (see `LICENSE` in this folder). If it saves you time, the **♥ Support Render Lens** link in the Render Lens dock opens its Ko-fi page, where you can tip without an account and suggest what to improve.
