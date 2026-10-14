"""Map every native get_configuration_warnings() warning in Godot 4.4 and 4.7.2 to a rule or an exclusion.

Usage: python scripts/godot_coverage.py <4.4-stable source> <4.5.2-stable source> <4.6.3-stable source> <4.7.2-stable source>
Writes docs/GODOT_COVERAGE.json and fails if a warning is unmapped or a mapped rule is missing.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STRING = re.compile(r'"((?:[^"\\]|\\.)*)"')
CALL = re.compile(r'(?:RTR|TTR|push_back|append)\(\s*((?:"(?:[^"\\]|\\.)*"\s*)+)')
VERSIONS = {"4.4": "4c311cbee68c0b66ff8ebb8b0defdd9979dd2a41", "4.5.2": "6ce3de25aa58466e14ef354703ba8d9791a417da",
            "4.6.3": "35e80b3a8822a9df9be390814b62f44c0a9c69e8", "4.7.2": "ed1daf0bf001b61586d9930840f2f1394092c079"}

# (class, warning prefix) -> scene check key, "rule:<id>" for a catalog rule, or "exclude:<reason>".
MAP = {
    ("AimModifier3D", "Forward axis"): "aim_modifier_axes",
    ("AnimatedSprite2D", "A SpriteFrames"): "sprite_frames_missing",
    ("AnimatedSprite3D", "A SpriteFrames"): "sprite_frames_missing",
    ("AnimationTree", "No root"): "animation_tree_root",
    ("AreaLight3D", "Projector texture"): "area_projector",
    ("AreaLight3D", "Rendering area light shadows"): "area_shadows",
    ("AreaLight3D", "Rendering textured"): "area_texture",
    ("BaseButton", "ButtonGroup"): "button_group_toggle",
    ("Bone2D", "A Bone2D only works"): "bone2d_hierarchy",
    ("Bone2D", "This Bone2D chain"): "bone2d_hierarchy",
    ("Bone2D", "This bone lacks"): "bone2d_rest",
    ("BoneAttachment3D", "BoneAttachment3D node is not bound"): "bone_attachment_bone",
    ("BoneAttachment3D", "External Skeleton3D"): "bone_attachment_external",
    ("BoneAttachment3D", "Parent node is not"): "bone_attachment_parent",
    ("CPUParticles2D", "CPUParticles2D animation"): "particles_animation_2d",
    ("CPUParticles3D", "CPUParticles3D animation"): "particles_animation_3d",
    ("CPUParticles3D", "Nothing is visible"): "cpu_mesh_missing",
    ("CSGShape3D", "The CSGShape3D has an empty shape"): "csg_empty_shape",
    ("CanvasGroup", "Ancestor \\\"%s\\\" clips"): "canvas_group_ancestor",
    ("CanvasGroup", "Ancestor \\\"%s\\\" is a CanvasGroup"): "canvas_group_ancestor",
    ("CanvasItem", "Ancestor \\\"%s\\\" clips"): "canvas_nested_clip",
    ("CanvasItem", "Ancestor \\\"%s\\\" is a CanvasGroup"): "canvas_group_clip",
    ("CanvasModulate", "Only one visible"): "canvas_modulate_multiple",
    ("CollisionObject2D", "This node has no shape"): "collision_object_empty",
    ("CollisionObject3D", "This node has no shape"): "collision_object_empty",
    ("CollisionObject3D", "With a non-uniform scale"): "collision_nonuniform",
    ("CollisionPolygon2D", "An empty"): "collision_polygon_empty",
    ("CollisionPolygon2D", "CollisionPolygon2D only serves"): "collision_polygon_parent",
    ("CollisionPolygon2D", "Invalid polygon. At least 2"): "collision_polygon_points",
    ("CollisionPolygon2D", "Invalid polygon. At least 3"): "collision_polygon_points",
    ("CollisionPolygon2D", "The One Way Collision"): "one_way_area",
    ("CollisionPolygon3D", "A non-uniformly"): "collision_nonuniform",
    ("CollisionPolygon3D", "An empty"): "collision_polygon_empty",
    ("CollisionPolygon3D", "CollisionPolygon3D only serves"): "collision_polygon_parent",
    ("CollisionShape2D", "A shape must"): "collision_resource",
    ("CollisionShape2D", "CollisionShape2D only serves"): "collision_parent",
    ("CollisionShape2D", "The CollisionShape2D node has limited editing"): "exclude:Editor editing-tool advice for polygon shapes; the shape collides normally at runtime.",
    ("CollisionShape2D", "The One Way Collision"): "one_way_area",
    ("CollisionShape3D", "A non-uniformly"): "collision_nonuniform",
    ("CollisionShape3D", "A shape must"): "collision_resource",
    ("CollisionShape3D", "CollisionShape3D only serves"): "collision_parent",
    ("CollisionShape3D", "When used for collision, ConcavePolygonShape3D"): "concave_dynamic",
    ("CollisionShape3D", "WorldBoundaryShape3D"): "boundary_dynamic",
    ("Container", "Container by itself"): "container_plain",
    ("Control", "The Hint Tooltip"): "tooltip_mouse_filter",
    ("Decal", "Decals are only available"): "rule:decals.compatibility_renderer",
    ("Decal", "The decal has a Normal"): "decal_albedo",
    ("Decal", "The decal has no textures"): "decal_textures",
    ("Decal", "The decal's Cull Mask"): "decal_mask",
    ("FogVolume", "Fog Volumes are only visible"): "fog_renderer",
    ("FogVolume", "Fog Volumes need volumetric fog"): "fog_environment",
    ("GPUParticles2D", "A material to process"): "gpu_process_missing",
    ("GPUParticles2D", "Particle sub-emitters"): "subemitter_renderer",
    ("GPUParticles2D", "Particle trails"): "trails_renderer",
    ("GPUParticles2D", "Particles2D animation"): "particles_animation_2d",
    ("GPUParticles3D", "A material to process"): "gpu_process_missing",
    ("GPUParticles3D", "Nothing is visible"): "gpu_mesh_missing",
    ("GPUParticles3D", "Only one Trail mesh"): "trails_multiple",
    ("GPUParticles3D", "Particle sub-emitters"): "subemitter_renderer",
    ("GPUParticles3D", "Particle trails"): "trails_renderer",
    ("GPUParticles3D", "Particles animation"): "particles_animation_3d",
    ("GPUParticles3D", "Trails active"): "trails_no_pose",
    ("GPUParticles3D", "Trails enabled"): "trails_material",
    ("GPUParticles3D", "Using Trail meshes with a skin"): "trails_skin",
    ("GPUParticlesCollisionSDF3D", "The Bake Mask"): "particle_sdf_bake_mask",
    ("GeometryInstance3D", "GeometryInstance3D transparency"): "geometry_transparency",
    ("GeometryInstance3D", "GeometryInstance3D visibility range transparency"): "geometry_fade",
    ("GeometryInstance3D", "The GeometryInstance3D is configured to fade in"): "visibility_fade_begin",
    ("GeometryInstance3D", "The GeometryInstance3D is configured to fade out"): "visibility_fade_end",
    ("GeometryInstance3D", "The GeometryInstance3D visibility range's End"): "visibility_range_invalid",
    ("GraphEdit", "Please be aware"): "exclude:API-stability notice for GraphEdit/GraphNode, not a configuration problem.",
    ("IterateIK3D", "Detecting settings"): "iterate_ik_target",
    ("Label", "Labels with autowrapping"): "label_autowrap_width",
    ("Label", "MSDF font pixel range"): "label_msdf_pixel_range",
    ("Label", "The current font does not support"): "label_missing_glyphs",
    ("Light3D", "A light's scale"): "light_scale",
    ("LightOccluder2D", "An occluder polygon must be set"): "light_occluder_missing",
    ("LightOccluder2D", "The occluder polygon for this occluder is empty"): "light_occluder_empty",
    ("LightmapGI", "Lightmaps can only be baked"): "exclude:Describes the editing machine's bake capability, not the scene.",
    ("LightmapGI", "Lightmaps cannot be baked on"): "exclude:Platform build notice (Android/iOS editors cannot bake), not the scene.",
    ("LightmapGI", "Lightmaps cannot be baked, as"): "exclude:Custom-build notice (lightmapper module disabled), not the scene.",
    ("LightmapGI", "The lightmap has no baked shadowmask"): "lightmap_shadowmask",
    ("LineEdit", "Secret Character"): "exclude:Unreachable from stored state: set_secret_character truncates to one character in 4.4 and 4.7.2.",
    ("LookAtModifier3D", "Forward axis"): "look_at_axes",
    ("MeshInstance2D", "MeshInstance2D requires"): "mesh_missing",
    ("MeshInstance3D", "MeshInstance3D requires"): "mesh_missing",
    ("MissingNode", ""): "missing_node",
    ("MultiplayerSpawner", "A valid NodePath"): "multiplayer_spawner_path",
    ("MultiplayerSynchronizer", "A valid NodePath"): "multiplayer_synchronizer_root",
    ("NavigationAgent2D", "The NavigationAgent2D"): "navigation_agent_parent",
    ("NavigationAgent3D", "The NavigationAgent3D"): "navigation_agent_parent",
    ("NavigationLink2D", "NavigationLink2D start"): "navigation_link_endpoints",
    ("NavigationLink3D", "NavigationLink3D start"): "navigation_link_endpoints",
    ("NavigationObstacle2D", "NavigationObstacle2D does not support"): "navigation_obstacle_scale",
    ("NavigationObstacle2D", "Skew has no effect"): "navigation_obstacle_skew",
    ("NavigationObstacle2D", "The agent radius"): "navigation_obstacle_nonuniform",
    ("NavigationObstacle3D", "NavigationObstacle3D does not support"): "navigation_obstacle_scale",
    ("NavigationObstacle3D", "NavigationObstacle3D only takes"): "navigation_obstacle_rotation",
    ("NavigationObstacle3D", "The agent radius"): "navigation_obstacle_nonuniform",
    ("NavigationRegion2D", "A Navigation"): "navigation_region_missing",
    ("NavigationRegion3D", "A NavigationMesh"): "navigation_region_missing",
    ("OccluderInstance3D", "No occluder mesh"): "occluder_missing",
    ("OccluderInstance3D", "Occlusion culling is disabled"): "occluder_culling_disabled",
    ("OccluderInstance3D", "The Bake Mask"): "occluder_bake_mask",
    ("OccluderInstance3D", "The occluder mesh has less"): "occluder_empty",
    ("OccluderInstance3D", "The polygon occluder"): "occluder_empty",
    ("OmniLight3D", "Projector texture only works"): "projector_shadows",
    ("OmniLight3D", "Projector textures are not supported"): "projector_renderer",
    ("OpenXRCompositionLayer", "Hole punching"): "openxr_layer_hole_punch",
    ("OpenXRCompositionLayer", "OpenXR composition layers must have an XROrigin3D"): "openxr_layer_parent",
    ("OpenXRCompositionLayer", "OpenXR composition layers must have orthonormalized"): "openxr_layer_transform",
    ("OpenXRRenderModel", "The render model extension"): "openxr_render_model_extension",
    ("OpenXRRenderModel", "This node must be a child"): "openxr_render_model_parent",
    ("OpenXRRenderModelManager", "Must specify a tracker"): "openxr_render_model_pose",
    ("OpenXRRenderModelManager", "The render model extension"): "openxr_render_model_extension",
    ("OpenXRRenderModelManager", "This node must be a child"): "openxr_render_model_parent",
    ("OpenXRVisibilityMask", "OpenXR visibility mask"): "openxr_visibility_mask_parent",
    ("ParallaxLayer", "ParallaxLayer node"): "parallax_layer_parent",
    ("PathFollow2D", "PathFollow2D only works"): "path_follow_parent",
    ("PathFollow3D", "PathFollow3D only works"): "path_follow_parent",
    ("PathFollow3D", "PathFollow3D's ROTATION_ORIENTED"): "path_follow_up_vector",
    ("PhysicalBone2D", "A PhysicalBone2D needs"): "physical_bone2d_bone",
    ("PhysicalBone2D", "A PhysicalBone2D node should"): "physical_bone2d_joint",
    ("PhysicalBone2D", "A PhysicalBone2D only works"): "physical_bone2d_parent",
    ("PhysicsBody2D", "PhysicsBody2D will not work"): "physics_body_interpolation",
    ("PhysicsBody3D", "PhysicsBody3D will not work"): "physics_body_interpolation",
    ("PointLight2D", "A texture with the shape"): "point_light_texture",
    ("PopupMenu", "The current theme style"): "popup_transparency",
    ("PopupPanel", "The current theme style"): "popup_transparency",
    ("Range", "If \\\"Exp Edit\\\""): "range_exp_min",
    ("RemoteTransform2D", "Path property"): "remote_transform_target",
    ("RemoteTransform3D", "The \\\"Remote Path\\\""): "remote_transform_target",
    ("RetargetModifier3D", "There is no child"): "retarget_children",
    ("RigidBody2D", "Size changes"): "rigid_scale",
    ("RigidBody3D", "Scale changes"): "rigid_scale",
    ("ScrollContainer", "ScrollContainer is intended"): "scroll_container_children",
    ("ShaderGlobalsOverride", "ShaderGlobalsOverride is not active"): "shader_globals_inactive",
    ("ShapeCast2D", "This node cannot interact"): "shape_cast_resource",
    ("ShapeCast3D", "ShapeCast3D does not support"): "shape_cast_concave",
    ("ShapeCast3D", "This node cannot interact"): "shape_cast_resource",
    ("SkeletonModifier3D", "Skeleton3D node not set"): "skeleton_modifier_parent",
    ("SoftBody3D", "This body will be ignored"): "mesh_missing",
    ("SplineIK3D", "Detecting settings"): "spline_ik_path",
    ("SpotLight3D", "A SpotLight3D with an angle"): "spot_shadows",
    ("SpotLight3D", "Projector texture only works"): "projector_shadows",
    ("SpotLight3D", "Projector textures are not supported"): "projector_renderer",
    ("SpringBoneCollision3D", "Parent node should"): "spring_bone_collision_parent",
    ("SubViewportContainer", "The default mouse cursor"): "subviewport_cursor",
    ("SubViewportContainer", "This node doesn't have a SubViewport"): "viewport_container_child",
    ("TextureRect", "STRETCH_TILE"): "texture_rect_atlas_tile",
    ("TileMap", "A TileMap layer is set as Y-sorted"): "tilemap_layer_ysort",
    ("TileMap", "A Y-sorted layer"): "tilemap_ysort_z",
    ("TileMap", "Isometric TileSet"): "tilemap_isometric_ysort",
    ("TileMap", "The TileMap node is deprecated"): "tilemap_deprecated",
    ("TileMap", "The TileMap node is set as Y-sorted"): "tilemap_node_ysort",
    ("Timer", "Very low timer"): "timer_short_wait",
    ("TwoBoneIK3D", "Detecting settings with no pole"): "two_bone_ik_targets",
    ("TwoBoneIK3D", "Detecting settings with no target"): "two_bone_ik_targets",
    ("VehicleWheel3D", "VehicleWheel3D serves"): "vehicle_wheel_parent",
    ("Viewport", "The Viewport size"): "exclude:Unreachable from stored state: Viewport::_set_size clamps both axes to at least 2 pixels in 4.4 and 4.7.2.",
    ("VoxelGI", "No VoxelGI data"): "voxel_gi_data",
    ("VoxelGI", "VoxelGI nodes are not supported when using the Compatibility"): "voxel_renderer",
    ("VoxelGI", "VoxelGI nodes are not supported when using the Dummy"): "exclude:Dummy renderer (headless) only; no frame is rendered.",
    ("WorldEnvironment", "Only one WorldEnvironment"): "worldenv_conflict",
    ("WorldEnvironment", "To have any visible effect"): "worldenv_empty",
    ("XRCamera3D", "XRCamera3D may not function"): "xr_camera_parent",
    ("XRCamera3D", "XRCamera3D should have"): "xr_interpolation",
    ("XRHandModifier3D", "XRHandModifier3D requires"): "xr_hand_tracking",
    ("XRNode3D", "No pose"): "xr_node_pose",
    ("XRNode3D", "No tracker"): "xr_node_tracker",
    ("XRNode3D", "XRNode3D may not function"): "xr_node_parent",
    ("XRNode3D", "XRNode3D should have"): "xr_interpolation",
    ("XROrigin3D", "Changing the scale"): "xr_origin_scale",
    ("XROrigin3D", "XR shaders are not enabled"): "xr_shaders_disabled",
    ("XROrigin3D", "XROrigin3D requires"): "xr_origin_camera",
}
NOTES = {
    "two_bone_ik_targets": "Godot 4.7.2's pole warning re-tests target_node; the rule follows _process_ik, which aborts without either node.",
    "iterate_ik_target": "The rule follows _process_ik: an unresolved target also aborts the setting, not only an empty path.",
    "spline_ik_path": "The rule follows _process_ik: an unresolved Path3D or an empty curve also aborts the setting.",
    "csg_empty_shape": "Partial: only root results are exposed; an empty child brush under a non-empty root is not detected.",
    "label_missing_glyphs": "Shapes untranslated source text (uppercase applied) up to 4096 characters.",
}


def extract(root):
    found = []
    for path in sorted(Path(root).rglob("*.cpp")):
        rel = path.relative_to(root).as_posix()
        if not rel.startswith(("scene/", "modules/")):
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        for match in re.finditer(r"PackedStringArray\s+(\w+)::get_configuration_warnings\(\)\s*const\s*\{", text):
            depth, index = 1, match.end()
            while depth and index < len(text):
                depth += {"{": 1, "}": -1}.get(text[index], 0)
                index += 1
            line = text[:match.start()].count("\n") + 1
            for group in CALL.findall(text[match.end():index]):
                found.append((match.group(1), " ".join(STRING.findall(group)), f"{rel}:{line}"))
    return found


def resolve(cls, warning):
    best = None
    for (key_cls, prefix), target in MAP.items():
        if key_cls == cls and warning.startswith(prefix) and (best is None or len(prefix) > len(best[0])):
            best = (prefix, target)
    return best[1] if best else None


def main():
    rules = {}
    for path in (ROOT / "addons/render_lens/rules").glob("*.json"):
        for rule in json.loads(path.read_text(encoding="utf-8")):
            rules[rule["id"]] = rule
    entries = {}
    for version, source in zip(VERSIONS, sys.argv[1:5]):
        for cls, warning, location in extract(Path(source)):
            entry = entries.setdefault((cls, warning), {"class": cls, "warning": warning.replace("\\n", "\n").replace('\\"', '"'), "source": {}})
            entry["source"][version] = f"https://github.com/godotengine/godot/blob/{VERSIONS[version]}/{location.replace(':', '#L')}"
    unmapped = []
    for (cls, warning), entry in sorted(entries.items()):
        target = resolve(cls, warning)
        if target is None:
            unmapped.append(f"{cls}: {warning[:80]}")
            continue
        if target.startswith("exclude:"):
            entry["status"] = "excluded"
            entry["reason"] = target[len("exclude:"):]
            continue
        rule_id = target[len("rule:"):] if target.startswith("rule:") else "scene_validation." + target
        assert rule_id in rules, f"{cls}: mapped rule {rule_id} is missing"
        entry["status"] = "implemented"
        entry["rule"] = rule_id
        if target in NOTES:
            entry["note"] = NOTES[target]
    assert not unmapped, "Unmapped native warnings:\n" + "\n".join(unmapped)
    items = [entries[key] for key in sorted(entries)]
    summary = {status: sum(1 for item in items if item["status"] == status) for status in ("implemented", "excluded")}
    document = {
        "scope": "Every native get_configuration_warnings() message in scene/ and modules/ of Godot 4.4-stable, 4.5.2-stable, 4.6.3-stable and 4.7.2-stable, extracted from source.",
        "versions": VERSIONS,
        "method": "Godot does not expose get_configuration_warnings() to scripts, so each predicate is reimplemented from the native body and tested with positive and negative fixtures on each version where the warning exists (tests/test_source_rules.gd). Script _get_configuration_warnings() overrides are never executed.",
        "summary": {"warnings": len(items), **summary},
        "warnings": items,
    }
    (ROOT / "docs/GODOT_COVERAGE.json").write_text(json.dumps(document, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    print(document["summary"])


if __name__ == "__main__":
    main()
