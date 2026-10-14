# Install Render Lens 2.0.0

1. Install Render Lens from the Godot Asset Library (AssetLib tab), or extract the release ZIP and copy `sample_project/addons/render_lens` into your project's `addons` directory.
2. Enable **Render Lens** in Project Settings → Plugins. Connect your MCP client to `http://127.0.0.1:43788`.
3. Start the game from the editor or call `run_game`, then request measurements. Do not stop it at a breakpoint during a capture (a pause menu is fine).

For an upgrade, disable the old plugin and replace its addon directory completely before re-enabling it. This removes retired tools instead of leaving obsolete scripts in the package.

Render Lens has eighteen tools and the game measurement bridge. No SDK, validation layer, Python or other sidecar is needed by the installed plugin. Python is only used by repository development/build scripts.

Only one default-port server can run at once. The dock reports a bind failure if another editor already owns port 43788. Files written by measurements go under `.render_lens/captures`.

Render Lens is free (MIT). The **♥ Support Render Lens** link in its editor dock opens its [Ko-fi](https://ko-fi.com/christoskaramoustos) page if you want to support it and suggest what to improve; no account is needed.
