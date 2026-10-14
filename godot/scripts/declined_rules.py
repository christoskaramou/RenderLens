"""Generate docs/DECLINED_RULES.md: every rule candidate that was declined, limited or left pending, and why.

Sources: docs/GODOT_COVERAGE.json, docs/GODOT_PERF_NOTES.json, docs/GODOT_TUTORIAL_NOTES.json, docs/GODOT_RUNTIME_WARNINGS.json, docs/VULKAN_COVERAGE.json and the curated
research decisions below (from docs/UPSTREAM_RULES.md, CHANGELOG.md and the 2026-10-11 review/coverage passes).
Usage: python scripts/declined_rules.py
"""
import json
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"

CATEGORIES = {
    "godot_restriction": "Godot does not expose the data",
    "unreachable": "Unreachable: the engine prevents the condition",
    "environment": "Environment-bound (editor, bake/import, platform, build, device or runtime)",
    "not_observable": "Runtime script state, not stored in scenes, resources or settings",
    "default_tradeoff": "Would flag Godot's defaults, is not a configuration problem, or has no reliable cost direction",
    "already_handled": "Already handled by Godot or by another rule",
    "content": "Asset or scene data that Godot repairs, converts or skips on load and reports itself",
    "internal": "Engine internals, leak reports and developer diagnostics",
    "partial": "Implemented with a stated gap",
    "pending": "Pending research (not counted as rules)",
    "policy": "Removed by product policy",
}

# Decisions recorded in prose rather than in an inventory file. "source" names where the evidence lives.
CURATED = [
    # 2026-10-11 coverage and review passes.
    ("SubViewport smaller than 2 px (Viewport::get_configuration_warnings)", "unreachable",
     "Viewport::_set_size clamps both axes with maxi(2) in 4.4 and 4.7.2, so stored state cannot produce the warning; the positive fixture read back (2, 64).",
     "godot/scene/main/viewport.cpp; docs/GODOT_COVERAGE.json"),
    ("LineEdit secret character longer than one character", "unreachable",
     "set_secret_character truncates to one character (with WARN_PRINT) in 4.4 and 4.7.2, so the warning cannot fire from stored state.",
     "godot/scene/gui/line_edit.cpp; docs/GODOT_COVERAGE.json"),
    ("Window viewports in the Viewport size check", "environment",
     "A Window's render size follows the window and display server state; only SubViewport sizes are authored.",
     "scene_checks.gd design note"),
    ("VoxelGI two bounces (VoxelGIData.use_two_bounces)", "default_tradeoff",
     "Defaults to true in 4.4 and 4.7.2; a rule would fire on every baked VoxelGI. Dropped after the negative fixture exposed the default.",
     "doc/classes/VoxelGIData.xml; docs/GODOT_PERF_NOTES.json"),
    ("IK/spring-bone mutable_bone_axes", "default_tradeoff",
     "Defaults to true; the documented gain from disabling it is 'slight' and only safe when bone pose positions never change.",
     "doc/classes/IKModifier3D.xml, SpringBoneSimulator3D.xml"),
    ("TileMapLayer.use_kinematic_bodies cost", "already_handled",
     "Only the deprecated TileMap.collision_animatable documents a cost (rule physics.tilemap_kinematic); TileMapLayer's description states none.",
     "doc/classes/TileMapLayer.xml"),
    ("Empty child CSG brushes under a non-empty root", "partial",
     "CSGShape3D only exposes the root result through get_meshes(); child brushes are private. csg_empty_shape covers an empty root (and reports its children).",
     "modules/csg/csg_shape.cpp"),
    ("Label missing glyphs in translated text", "partial",
     "label_missing_glyphs shapes the untranslated source text (uppercase applied, up to 4096 characters); Label's private translated/shaped paragraphs are not exposed.",
     "scene/gui/label.cpp"),
    ("Camera feed monitoring (CameraServer.monitoring_feeds)", "not_observable",
     "A runtime singleton toggled by scripts (4.7); a future game-metrics probe could read it.",
     "doc/classes/CameraServer.xml"),
    ("Input.use_accumulated_input disabled", "not_observable",
     "A runtime singleton toggled by scripts; not part of project settings.",
     "doc/classes/Input.xml"),
    ("OpenXR render-model nodes outside an OpenXR session", "environment",
     "The nodes log 'render_model_extension is null' on every notification without an OpenXR runtime; fixtures keep them out of the tree.",
     "modules/openxr/scene/openxr_render_model_manager.cpp"),
    ("Godot 4.4 Vulkan limits MAX_COMPUTE_SHARED_MEMORY_SIZE and MetalFX scaler min/max", "godot_restriction",
     "4.4's Vulkan limit_get logs an error instead of returning these; metrics skip them before 4.7 and shared-memory rules are 4.7-only.",
     "drivers/vulkan/rendering_device_driver_vulkan.cpp (4.4)"),
    ("Node configuration warnings via get_configuration_warnings()", "godot_restriction",
     "Not bound to scripts; every native predicate is reimplemented and tested instead. Script _get_configuration_warnings overrides are never executed.",
     "scene/main/node.cpp; docs/GODOT_COVERAGE.json"),
    # Earlier research passes (docs/UPSTREAM_RULES.md).
    ("Line2D antialiased batching note", "godot_restriction",
     "The antialiased property is stored but not passed to Line2D's triangle draw path in 4.4 or 4.7.2, so the documented batching effect cannot be observed.",
     "docs/UPSTREAM_RULES.md (1.8)"),
    ("AnimationMixer deterministic mode", "default_tradeoff",
     "Trades normalization work against reset writes; without active track weights there is no reliable cost direction.",
     "docs/UPSTREAM_RULES.md (1.8)"),
    ("Generic TileMap quadrant-size advice", "default_tradeoff",
     "Reducing quadrant size alone does not establish wasted work; replaced by tilemap_small_quadrants, which requires populated-cell evidence.",
     "docs/UPSTREAM_RULES.md (1.8)"),
    ("PhysicalSkyMaterial quarter-resolution sky", "godot_restriction",
     "No public quarter-resolution property in the checked tags.",
     "docs/UPSTREAM_RULES.md (1.8)"),
    ("RichTextLabel outline/shadow passes (extension of ui.label_effect_passes)", "godot_restriction",
     "Script-pushed formatting can override spans and the private stack_externally_modified state is not exposed.",
     "docs/UPSTREAM_RULES.md (1.19)"),
    ("Button outline plus shadow passes", "godot_restriction",
     "Button has an outline pass but no font-shadow pass in either native implementation, so the two-pass rule cannot apply.",
     "docs/UPSTREAM_RULES.md (1.19)"),
    ("Zero-count draws/dispatches as empty MultiMesh warnings", "already_handled",
     "Godot skips those calls itself.",
     "docs/UPSTREAM_RULES.md (Excluded checks)"),
    ("Barriers, descriptor updates, redundant binds, allocation flags, transient/lazy memory, queue ownership, pipeline-cache handles, render-pass load/store", "godot_restriction",
     "Require RenderingDevice-internal command state that the plugin cannot read.",
     "docs/UPSTREAM_RULES.md (Excluded checks)"),
    ("Depth attachment formats and index-cache efficiency", "godot_restriction",
     "Not inferable from scene settings; emulating a GPU vertex cache would need expensive mesh readbacks and still not know the submitted draw range.",
     "docs/UPSTREAM_RULES.md (Excluded checks)"),
    ("Sparse-index warning (pre-G71 Mali)", "environment",
     "Specific to old Mali GPUs; not generalized to modern hardware.",
     "docs/UPSTREAM_RULES.md (Excluded checks)"),
    ("Vulkan handle, layout and synchronization validity", "godot_restriction",
     "Engine-internal API usage; not observable from a plugin.",
     "docs/UPSTREAM_RULES.md (Excluded checks)"),
    ("Executed descriptor indices, live addresses, heap mappings, binding ranges, inter-invocation races (GPU-assisted validation)", "godot_restriction",
     "Ordinary scene data and imported shader declarations do not expose them.",
     "docs/UPSTREAM_RULES.md (1.12)"),
    ("Cooperative-matrix reservation and subgroup feature/flag/size state", "godot_restriction",
     "Not public audit evidence in Godot's RenderingDevice API.",
     "docs/UPSTREAM_RULES.md (1.21)"),
    ("Ray-query support on Godot 4.4", "godot_restriction",
     "4.4 does not expose SUPPORTS_RAY_QUERY; absence is treated as unknown, and ray-query rules are 4.7-gated.",
     "docs/UPSTREAM_RULES.md (1.9)"),
    ("Validation-layer log rules (VUID, SYNC-HAZARD, D3D12 message IDs) and api_validation_capture", "policy",
     "Removed in 1.3+: Render Lens no longer depends on the Vulkan SDK, VkConfig, validation layers or child validation launches.",
     "CHANGELOG.md; README.md"),
    # Former pending research, resolved 2026-10-12.
    ("Cooperative-vector offset/stride alignment (VUID-RuntimeSpirv 10096-10101) and 32-bit offsets (11809)", "partial",
     "Implemented as scene_validation.shader_cooperative_alignment and shader_cooperative_offset_width for constant offsets/strides and known offset types in the first entry block. Buffer base-pointer alignment, dynamic and specialized offsets cannot be known statically.",
     "Vulkan spec spirvenv (read 2026-10-12)"),
    ("Cooperative-matrix MulAdd contracts (scopes, M/N/K, operand uses, signedness flags)", "partial",
     "Implemented as scene_validation.shader_matrix_muladd for known cooperative-matrix value types and 32-bit constant dimensions; specialization-constant dimensions and values from untracked instructions are skipped.",
     "SPIRV-Tools validate_arithmetics.cpp ValidateCooperativeMatrixMulAddKHR (main, read 2026-10-12)"),
    ("Remaining cooperative-vector checks in ValidateCooperativeVector (VUIDs 10089, 10091, 10094, 10095)", "godot_restriction",
     "Every static clause of the function is implemented (10090, 10092, 10093 and the spec's 10096-10101, 11809); the remaining four compare against cooperativeVectorProperties, supported stages and maxCooperativeVectorComponents, which Godot does not expose.",
     "Vulkan-ValidationLayers cc_spirv_cooperative.cpp (pinned 99fd2cb5)"),
    ("Subgroup-uniform-control-flow conflict beyond the four repack opcodes", "partial",
     "scene_validation.shader_subgroup_repack now follows the Vulkan spec's ray-tracing-repack list (13 opcodes, including the NV/EXT shader-execution-reorder instructions); current Vulkan-ValidationLayers still checks four. Fixtures are synthesized bytecode; no Godot compiler emits the reorder instructions without the extension.",
     "Vulkan spec raytracing.adoc ray-tracing-repack; SPIR-V grammar (read 2026-10-12)"),
    ("2D MSAA enabled without 2D content", "already_handled",
     "Godot prints \"2D MSAA is enabled while there is no 2D content. Disable 2D MSAA for better performance.\" once at runtime; a static scan cannot see 2D content added by other scenes or autoloads.",
     "servers/rendering/renderer_viewport.cpp:756 (4.7.2)"),
    ("SpringBoneSimulator3D unsorted/duplicate exclusion paths", "partial",
     "Reproduced on Godot 4.4 and 4.7.2 (an excluded collision still pushes the bones) and implemented as scene_validation.spring_bone_exclude_order; not reported upstream yet.",
     "scene/3d/spring_bone_simulator_3d.cpp _find_collisions; tests/test_source_rules.gd (2026-10-12)"),
]


def perf_category(reason):
    import importlib.util
    spec = importlib.util.spec_from_file_location("godot_perf_notes", ROOT / "scripts/godot_perf_notes.py")
    notes = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(notes)
    table = {notes.BAKE: "environment", notes.EDITOR: "environment", notes.RUNTIME_CHANGE: "not_observable",
             notes.SCRIPT_API: "not_observable", notes.DEFAULT: "default_tradeoff", notes.SERVER_EQUIVALENT: "already_handled",
             notes.SCRIPT_TIP: "not_observable", notes.SERVER_SETTER: "already_handled", notes.ANIMATION_SLICE: "not_observable"}
    if "not analysed" in reason:
        return "pending"
    if "Godot 3" in reason:
        return "unreachable"
    if "export presets" in reason or "outside the project" in reason or reason.startswith("Bake, import or editor"):
        return "environment"
    if any(text in reason for text in ("made by scripts", "cannot be told", "cannot show", "not visible to", "needs semantic", "needs knowledge")):
        return "not_observable"
    if any(text in reason for text in ("covered by", "already reports")):
        return "already_handled"
    return table.get("exclude:" + reason, "default_tradeoff")


def vulkan_category(status):
    if "partial" in status or "adapted" in status or "implemented" in status:
        return "partial"
    if status in ("already followed by checked stock Godot", "related Godot guidance already exists"):
        return "already_handled"
    if status == "validation infrastructure":
        return "policy"
    return "godot_restriction"


def main():
    rows = defaultdict(list)
    for topic, category, reason, source in CURATED:
        rows[category].append((topic, reason, source))
    coverage = json.loads((DOCS / "GODOT_COVERAGE.json").read_text(encoding="utf-8"))
    for item in coverage["warnings"]:
        if item["status"] == "excluded":
            reason = item["reason"]
            category = "unreachable" if reason.startswith("Unreachable") else "default_tradeoff" if "notice" in reason and "API" in reason else "environment"
            rows[category].append((f"{item['class']} warning: {item['warning'].splitlines()[0][:110]}", reason, "docs/GODOT_COVERAGE.json"))
    perf = json.loads((DOCS / "GODOT_PERF_NOTES.json").read_text(encoding="utf-8"))
    not_costs = []
    for item in perf["notes"]:
        if item["status"] == "excluded":
            rows[perf_category(item["reason"])].append((f"{item['member']} (class-reference {item['kind']} note)", item["reason"], "docs/GODOT_PERF_NOTES.json"))
        elif item["status"] == "not_a_cost":
            not_costs.append((item["member"], item["reason"]))
    tutorials = json.loads((DOCS / "GODOT_TUTORIAL_NOTES.json").read_text(encoding="utf-8"))
    for item in tutorials["notes"]:
        if item["status"] == "excluded":
            rows[perf_category(item["reason"])].append((f"{item['paragraph']}... (tutorial paragraph)", item["reason"], "docs/GODOT_TUTORIAL_NOTES.json"))
        elif item["status"] == "not_a_cost":
            not_costs.append((item["paragraph"] + "...", item["reason"]))
    runtime = json.loads((DOCS / "GODOT_RUNTIME_WARNINGS.json").read_text(encoding="utf-8"))
    runtime_category = {"environment": "environment", "editor": "environment", "runtime": "environment", "script": "not_observable",
                        "candidate": "pending", "clamped": "already_handled", "content": "content", "internal": "internal"}
    for item in runtime["warnings"]:
        if item["status"] == "excluded":
            rows[runtime_category[item["category"]]].append((f"Runtime warning: {item['message'].splitlines()[0][:110]}", item["reason"], "docs/GODOT_RUNTIME_WARNINGS.json " + item["file"]))
    vulkan = json.loads((DOCS / "VULKAN_COVERAGE.json").read_text(encoding="utf-8"))
    for item in vulkan["checks"]:
        if item["status"] != "implemented":
            rows[vulkan_category(item["status"])].append((f"{item['check']} ({item['status']})", item.get("reason", ""), "docs/VULKAN_COVERAGE.json " + item["source"]["path"]))
    for item in vulkan["additional_review"]:
        rows[vulkan_category(item["status"])].append((f"{item['source']}: {item['scope']} ({item['status']})", item["reason"], "docs/VULKAN_COVERAGE.json"))

    lines = [
        "# Declined, limited and pending rules",
        "",
        "Generated by `python scripts/declined_rules.py` from the coverage inventories and the curated research decisions in that script. Every entry is a rule candidate that Render Lens does not implement (or implements only partially) and the reason. Pending items are not counted as rules.",
        "",
        "| Category | Entries |",
        "| --- | --- |",
    ]
    for key, title in CATEGORIES.items():
        lines.append(f"| {title} | {len(rows[key])} |")
    lines.append(f"| Keyword matches that are not costs (class reference and tutorials) | {len(not_costs)} |")
    lines.append("")
    for key, title in CATEGORIES.items():
        if not rows[key]:
            continue
        lines += [f"## {title}", "", "| Candidate | Reason | Evidence |", "| --- | --- | --- |"]
        for topic, reason, source in sorted(rows[key]):
            lines.append("| %s | %s | %s |" % tuple(text.replace("|", "\\|").replace("\n", " ") for text in (topic, reason, source)))
        lines.append("")
    lines += ["## Keyword matches that are not costs", "", "Class-reference notes and tutorial paragraphs matched by the performance keywords but describing motion, precision, methodology, concepts or a cost-free option (docs/GODOT_PERF_NOTES.json, docs/GODOT_TUTORIAL_NOTES.json).", "", "| Member | Reason |", "| --- | --- |"]
    for member, reason in sorted(not_costs):
        lines.append(f"| {member} | {reason} |")
    (DOCS / "DECLINED_RULES.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print({key: len(rows[key]) for key in CATEGORIES}, "not_a_cost", len(not_costs))


if __name__ == "__main__":
    main()
