"""Godot configuration predicates, checked against the 4.4 to 4.7 sources."""

import os
import re

from godot_versions import CHECKOUTS, DOCS, expand

UPSTREAM = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".tmp", "upstream")


def doc_quote(cls, quote, versions=("4.4", "4.7")):
    """Fail the build if a quoted class-reference sentence is absent from a present checkout of any covered version."""
    for checkout in (CHECKOUTS[version] for version in expand(versions)):
        path = os.path.join(UPSTREAM, checkout, "doc", "classes", cls + ".xml")
        if os.path.exists(path):
            text = re.sub(r"\s+", " ", re.sub(r"\[[^\]]+\]", " ", open(path, encoding="utf-8").read()))
            if quote not in text:
                raise SystemExit("quote not in %s (%s): %s" % (cls, checkout, quote))
    return quote


def tutorial_quote(page, quote, versions=("4.4", "4.7")):
    """Fail the build if a quoted godot-docs sentence is absent from a present docs checkout of each version (rst markup stripped)."""
    from pathlib import Path
    from godot_tutorial_notes import paragraphs
    for branch in (DOCS[version] for version in expand(versions)):
        path = Path(UPSTREAM, branch, page + ".rst")
        if Path(UPSTREAM, branch).is_dir() and not (path.exists() and any(quote in text for _, text in paragraphs(path))):
            raise SystemExit("quote not in %s (%s): %s" % (page, branch, quote))
    return quote

def _source_tag(versions):
    """Godot tag a source link points to: 4.4 when the rule covers it, otherwise the verified 4.7.2 checkout."""
    return "4.4" if "4.4" in versions else "4.7.2"


ALL = ["forward_plus", "mobile", "gl_compatibility"]
RD = ["forward_plus", "mobile"]
GL = ["gl_compatibility"]
OTHER = ["mobile", "gl_compatibility"]


def register(add):
    def check(key, title, file, evidence, suggestion, *, renderers=ALL, versions=("4.4", "4.7"), kind="correctness", lit=False, renderers_by_version=None):
        counter = "check_" + key
        tag = _source_tag(versions)
        condition = {"scene_gte": {"name": counter, "value": 1}}
        if lit:
            condition = {"all": [condition, {"setting_eq": {"path": "rendering/shading/overrides/force_vertex_shading", "value": False}}]}
        add(dict(id="scene_validation." + key, category="scene_validation", title=title,
                 kind=kind, severity="medium", renderers=renderers, versions=list(versions),
                 requires=["scene", "settings"] if lit else ["scene"], condition=condition,
                 offender_key=counter, evidence=evidence + " This describes the scanned state; scripts may configure it later.",
                 suggestion=suggestion, tradeoff="Confirm the node is intended to participate before changing it. No project changes are applied.",
                 expected_effect="Correct the configuration or explain why this state is intentional; no performance saving is asserted.",
                 verify_step="scan_scene, audit_project_rendering, capture_viewport; test the affected behavior in the running game",
                 source=f"https://github.com/godotengine/godot/blob/{tag}-stable/{file}",
                 evidence_kind="godot_configuration", **({"renderers_by_version": renderers_by_version} if renderers_by_version else {})))

    particles = "scene/3d/gpu_particles_3d.cpp"
    check("shader_compile_error", "An imported RenderingDevice shader records a compilation error", "doc/classes/RDShaderFile.xml",
          "The imported RDShaderFile base error or an RDShaderSPIRV stage error is nonempty. Unimported files are reported as unavailable scan coverage, not as successful shaders.",
          "Inspect the shader's import errors in Godot, fix the source and reimport.", renderers=RD)
    check("gpu_process_missing", "GPU particles have no process material", particles,
          "A GPUParticles2D or GPUParticles3D has no process material.", "Assign a process material if particle simulation is intended.")
    check("gpu_mesh_missing", "3D GPU particles have no draw mesh", particles,
          "None of the configured draw passes has a mesh.", "Assign a mesh to an active draw pass.")
    check("cpu_mesh_missing", "3D CPU particles have no mesh", "scene/3d/cpu_particles_3d.cpp",
          "The CPUParticles3D mesh is absent.", "Assign a particle mesh if visible particles are intended.")
    check("particles_animation_2d", "2D particle animation lacks an enabled animation material", "scene/2d/gpu_particles_2d.cpp",
          "GPU ParticleProcessMaterial or CPUParticles2D has animation speed/offset or curves, but the drawing material is absent or CanvasItemMaterial.particles_anim is off. Custom shaders are excluded.",
          "Enable particle animation on a CanvasItemMaterial and configure its frame grid.")
    check("particles_animation_3d", "3D particle animation lacks a particle billboard material", particles,
          "GPU or CPU 3D particle animation is configured, but no effective draw material supports particle billboards. Custom ShaderMaterials are treated as unknown and excluded.",
          "Set the intended BaseMaterial3D billboard mode to Particle Billboard and configure the frame grid.")
    check("trails_skin", "Particle Skin overrides built-in trail poses", particles,
          "Trails use both a trail mesh and a Skin.", "Remove the Skin if the built-in trail poses were intended, or confirm the override is deliberate.", kind="info")
    check("trails_no_pose", "Particle trails lack a trail mesh or Skin", particles,
          "Trails are enabled with neither built-in trail poses nor a Skin.", "Use RibbonTrailMesh/TubeTrailMesh or supply an appropriate Skin.")
    check("trails_multiple", "Multiple built-in trail meshes lack a Skin", particles,
          "More than one draw pass has built-in trail poses and no Skin is assigned.", "Use a single trail mesh, or provide a Skin for the multiple-mesh arrangement.")
    check("trails_material", "Particle trail material is missing or not trail-enabled", particles,
          "Trail poses exist, but an effective surface material is absent or a BaseMaterial3D has particle trails disabled. Overridden surface materials and custom shaders are excluded.",
          "Enable particle trails on the effective BaseMaterial3D, or assign a suitable material.", renderers=RD)
    check("trails_renderer", "Particle trails are unsupported in Compatibility", particles,
          "2D or 3D GPU particle trails are enabled under Compatibility.", "Use Forward+ or Mobile, or provide a separate trail effect.", renderers=GL)
    check("subemitter_renderer", "Particle sub-emitters are unsupported in Compatibility", particles,
          "A GPU particle sub-emitter path is set under Compatibility.", "Use Forward+ or Mobile, or spawn the secondary effect through game logic.", renderers=GL)

    decal = "scene/3d/decal.cpp"
    check("decal_textures", "A decal has no textures", decal,
          "All four decal texture slots are empty.", "Assign a texture to the intended decal channel.", renderers=RD)
    check("decal_albedo", "A normal/ORM decal lacks its albedo blend mask", decal,
          "A normal or ORM texture is assigned without an albedo texture.", "Assign an albedo texture with alpha; set Albedo Mix to zero if its color should remain invisible.", renderers=RD)
    check("decal_mask", "A decal cannot affect any visual layer", decal,
          "The decal cull mask is zero.", "Enable the target objects' visual layers in the decal cull mask.", renderers=RD)

    light = "scene/3d/light_3d.cpp"
    check("light_scale", "Scaling a light does not resize its illumination", light,
          "A Light3D has a non-unit local scale.", "Adjust the light's range or size properties if illumination size should change.", kind="info")
    check("projector_shadows", "A light projector needs shadows enabled", light,
          "An OmniLight3D or SpotLight3D has a projector texture with shadows disabled.", "Enable shadows if the projector is needed; measure the added shadow cost.", renderers=RD)
    check("projector_renderer", "Light projectors are unsupported in Compatibility", light,
          "An OmniLight3D or SpotLight3D has a projector texture under Compatibility.", "Use Forward+ or Mobile, or replace the projection effect.", renderers=GL)
    check("spot_shadows", "A spotlight at 90 degrees cannot cast shadows", light,
          "Shadows are enabled with a spot angle of at least 90 degrees; the engine's predicate includes exactly 90.", "Reduce the angle below 90 degrees if shadows are required.")
    for key, title, evidence, suggestion, renderers in (
        ("area_projector", "Area lights do not use the projector slot", "An AreaLight3D has a light_projector texture.", "Move the intended texture to area_texture.", ALL),
        ("area_texture", "Textured area lights are unsupported in Compatibility", "An AreaLight3D has area_texture under Compatibility.", "Use Forward+ or Mobile, or use an untextured light.", GL),
        ("area_shadows", "Area-light shadows are unsupported in Compatibility", "An AreaLight3D enables shadows under Compatibility.", "Use a supported renderer or a different shadow-casting light.", GL),
    ):
        check(key, title, light, evidence, suggestion, renderers=renderers, versions=("4.7",))

    check("fog_renderer", "FogVolume needs Forward+", "scene/3d/fog_volume.cpp",
          "A FogVolume is present under Mobile or Compatibility.", "Use Forward+ for volumetric fog, or use ordinary depth/height fog.", renderers=OTHER)
    check("fog_environment", "FogVolume has volumetric fog disabled in its world", "scene/3d/fog_volume.cpp",
          "A live FogVolume's effective camera/world Environment has volumetric fog disabled. Camera overrides and fallback environments are respected; detached scenes and absent environments are skipped.",
          "Enable volumetric fog in the effective Environment if the volume is needed, then measure its cost.", renderers=["forward_plus"])
    check("voxel_renderer", "VoxelGI is unsupported by this renderer", "doc/classes/VoxelGI.xml",
          "A VoxelGI node is present under Mobile or Compatibility.", "Use Forward+ or choose a GI solution supported by the target renderer.", renderers=OTHER)

    occluder = "scene/3d/occluder_instance_3d.cpp"
    check("occluder_missing", "An occluder has no occluder resource", occluder,
          "OccluderInstance3D.occluder is absent.", "Bake occluders or assign a suitable primitive occluder.")
    check("occluder_empty", "An occluder has insufficient geometry", occluder,
          "An ArrayOccluder3D has fewer than three indices, or a PolygonOccluder3D has fewer than three points.", "Bake valid occluder geometry or supply a valid polygon.")
    check("occluder_bake_mask", "An occluder's bake mask selects no layers", occluder,
          "The bake mask is zero. An already assigned occluder can still work; this only concerns a future bake.", "Select layers before baking if automatic occluder generation is intended.", kind="info")

    shape = "scene/3d/physics/collision_shape_3d.cpp"
    polygon = "scene/2d/physics/collision_polygon_2d.cpp"
    check("collision_parent", "A collision shape has the wrong direct parent", shape,
          "A CollisionShape2D/3D is not directly beneath a CollisionObject of the matching dimension.", "Parent the shape directly beneath the intended Area or physics body.")
    check("collision_resource", "A collision shape has no Shape resource", shape,
          "CollisionShape2D/3D.shape is absent.", "Assign the intended Shape resource.")
    check("collision_polygon_parent", "A collision polygon has the wrong direct parent", polygon,
          "A CollisionPolygon2D/3D is not directly beneath a CollisionObject of the matching dimension.", "Parent the polygon directly beneath the intended Area or physics body.")
    check("collision_polygon_empty", "A collision polygon has no points", polygon,
          "A CollisionPolygon2D/3D has an empty polygon.", "Define the collision outline.")
    check("collision_polygon_points", "A 2D collision polygon has too few points", polygon,
          "A nonempty polygon has fewer than three points in Solids mode, or fewer than two in Segments mode.", "Add enough points for the selected build mode.")
    check("one_way_area", "Area2D ignores one-way collision", "scene/2d/physics/collision_shape_2d.cpp",
          "A CollisionShape2D or CollisionPolygon2D under Area2D enables one-way collision.", "Use a physics body for one-way blocking, or handle directional detection in game logic.")
    check("collision_nonuniform", "A 3D collision node has nonuniform scale", shape,
          "A CollisionObject3D, CollisionShape3D or CollisionPolygon3D has unequal local scale axes, using Godot's approximate-zero comparison.", "Keep scale uniform and resize the shape resource or polygon vertices instead.")
    check("rigid_scale", "Physics can override a rigid body's scale", "scene/3d/physics/rigid_body_3d.cpp",
          "A RigidBody2D/3D local scale differs from unit scale by more than the engine's 0.05 tolerance.", "Keep the body scale at one and resize its child shapes and visuals.")
    check("concave_dynamic", "A moving 3D body uses a concave collision shape", shape,
          "A concave shape belongs to CharacterBody3D or a RigidBody3D that is not frozen in static mode.", "Use convex shapes or convex decomposition for moving bodies; keep concave geometry on static bodies.")
    check("boundary_dynamic", "A moving rigid body uses an infinite world-boundary shape", shape,
          "WorldBoundaryShape3D belongs to a RigidBody3D not frozen in static mode.", "Keep the world boundary on a static body and use a finite shape for moving objects.")
    check("mesh_missing", "A mesh instance has no mesh resource", "doc/classes/MeshInstance3D.xml",
          "The MeshInstance2D/3D mesh resource is absent.", "Assign a mesh if this node should render geometry.")
    check("worldenv_empty", "A WorldEnvironment has no resources", "scene/3d/world_environment.cpp",
          "Environment, camera attributes and compositor are all absent. Compositor-only nodes are deliberately excluded.", "Assign the intended resource or remove the unused node.")
    check("worldenv_conflict", "A WorldEnvironment resource is overridden in its world", "scene/3d/world_environment.cpp",
          "In a live tree, an assigned Environment, camera attributes or compositor differs from the resource selected by that node's viewport world. Detached scenes are skipped.",
          "Keep one intended provider per world; use separate viewport worlds where separate environments are needed.")

    geometry = "scene/3d/visual_instance_3d.cpp"
    check("visibility_range_invalid", "A visibility range cannot display its geometry", geometry,
          "The nonzero visibility range end is less than or equal to its begin. An end of zero disables the upper limit and is excluded.",
          "Set the end beyond the begin, or set end to zero to remove the upper limit.")
    for side in ("begin", "end"):
        check("visibility_fade_" + side, "A visibility fade has no " + side + " transition margin", geometry,
              f"Visibility fading is enabled, the {side} distance is nonzero and its margin is approximately zero.",
              f"Give the {side} margin a positive width if a smooth transition is intended.", renderers=["forward_plus"])
    check("geometry_transparency", "Geometry-instance transparency needs Forward+", geometry,
          "GeometryInstance3D.transparency is greater than zero under Mobile or Compatibility.",
          "Use a material transparency mode supported by the renderer, or select Forward+.", renderers=OTHER)
    check("geometry_fade", "Visibility-range fading needs Forward+", geometry,
          "A GeometryInstance3D enables Self or Dependencies visibility fading under an unsupported renderer.",
          "Use disabled fading with hysteresis, or select Forward+.", renderers=OTHER)
    check("point_light_texture", "A PointLight2D has no light texture", "scene/2d/light_2d.cpp",
          "PointLight2D.texture is absent.", "Assign a light texture if this light should illuminate the canvas.")
    for key, title, evidence in (
        ("light_occluder_missing", "A 2D light occluder has no polygon resource", "LightOccluder2D.occluder is absent."),
        ("light_occluder_empty", "A 2D light occluder has an empty polygon", "An assigned OccluderPolygon2D contains no points."),
    ):
        check(key, title, "scene/2d/light_occluder_2d.cpp", evidence, "Create an occluder polygon that follows the intended shadow-casting outline.")
    check("particle_sdf_bake_mask", "A particle SDF bake mask selects no geometry", "scene/3d/gpu_particles_collision_3d.cpp",
          "GPUParticlesCollisionSDF3D.bake_mask is zero. This concerns the next bake, not whether an existing texture works.",
          "Select the visual layers to include before baking the collision SDF.", renderers=RD, kind="info")
    check("particle_sdf_texture", "A particle SDF collider has no baked field texture", "doc/classes/GPUParticlesCollisionSDF3D.xml",
          "GPUParticlesCollisionSDF3D.texture is absent; the node has no assigned signed-distance field.",
          "Bake the collider or assign the intended Texture3D before relying on SDF collisions.", renderers=RD)
    check("particle_collision_scale", "A particle collider has unsupported nonuniform world scale", "doc/classes/GPUParticlesCollision3D.xml",
          "The absolute world scale of a live GPUParticlesCollision3D differs between axes. Detached nodes are skipped; a compensating parent scale is respected.",
          "Use uniform world scale and edit the collider's size or radius instead.", renderers=RD)
    check("viewport_container_child", "A SubViewportContainer has no direct SubViewport child", "scene/gui/subviewport_container.cpp",
          "None of the container's direct children is a SubViewport.", "Add the intended SubViewport as a direct child.")
    check("viewport_ssr_transparent", "A transparent SubViewport cannot use SSR", "doc/classes/Environment.xml",
          "A live SubViewport has transparent_bg enabled and SSR enabled in its effective camera/world Environment. Detached scenes are excluded.",
          "Use an opaque viewport background if SSR is required, or use reflection probes for this view.", renderers=["forward_plus"], versions=("4.5", "4.7"))
    check("sprite_frames_missing", "An animated sprite has no SpriteFrames resource", "scene/2d/animated_sprite_2d.cpp",
          "An AnimatedSprite2D or AnimatedSprite3D has no SpriteFrames resource.", "Assign the animation's SpriteFrames resource.")
    check("path_follow_parent", "A PathFollow node is outside its matching Path", "scene/3d/path_3d.cpp",
          "PathFollow2D does not have a direct Path2D parent, or PathFollow3D does not have a direct Path3D parent.",
          "Make the matching Path node the direct parent before using its curve.")
    check("path_follow_up_vector", "Oriented path following needs curve up vectors", "scene/3d/path_3d.cpp",
          "A PathFollow3D uses ROTATION_ORIENTED but its parent Path3D's assigned Curve3D has up_vector_enabled disabled.",
          "Enable up vectors on the curve, or use a rotation mode that does not require them.")
    check("remote_transform_target", "A RemoteTransform cannot use its target", "scene/3d/remote_transform_3d.cpp",
          "A live RemoteTransform2D/3D cannot resolve its remote_path to a matching Node2D/3D, or targets itself, an ancestor or a descendant. Godot's cache rejects those hierarchy relationships. Detached scenes are skipped.",
          "Point remote_path at a node of the matching dimension outside the remote transform's own ancestor/descendant chain.")

    check("navigation_agent_parent", "A navigation agent has the wrong parent dimension", "scene/3d/navigation_agent_3d.cpp",
          "NavigationAgent2D requires a Node2D-derived direct parent; NavigationAgent3D requires a Node3D-derived direct parent.",
          "Place the agent directly under the matching moving Node2D/Node3D.")
    check("navigation_region_missing", "An enabled navigation region has no navigation resource", "scene/3d/navigation_region_3d.cpp",
          "An enabled NavigationRegion3D has no NavigationMesh, or an enabled NavigationRegion2D has no NavigationPolygon. Disabled regions are excluded.",
          "Assign and bake the intended navigation resource, or disable this region until it is ready.")
    for key, title, evidence, suggestion, kind in (
        ("navigation_obstacle_rotation", "A navigation obstacle ignores its world X/Z rotation", "A live NavigationObstacle3D has nonzero world X or Z rotation; navigation uses its Y rotation only.", "Keep the obstacle upright, or author vertices matching its intended horizontal footprint.", "info"),
        ("navigation_obstacle_scale", "A navigation obstacle has unsupported world scale", "A live NavigationObstacle2D/3D has a world scale component below 0.001, using the engine warning's threshold. Negative and zero components are included.", "Use positive world scale on the obstacle and its parents; resize its radius or vertices as needed.", "correctness"),
        ("navigation_obstacle_nonuniform", "A navigation obstacle's radius cannot follow its nonuniform transform", "A live obstacle has positive radius and a nonconformal world transform. Godot scales the radius using the largest axis instead.", "Use uniform scaling for the radius or author a vertex-based obstacle for the intended outline.", "info"),
        ("navigation_obstacle_skew", "A navigation obstacle's radius ignores world skew", "A live NavigationObstacle2D has positive radius and nonzero world skew.", "Use vertices for a skewed outline or remove skew when relying on the radius.", "info"),
    ):
        check(key, title, "scene/2d/navigation_obstacle_2d.cpp" if key.endswith("skew") else "scene/3d/navigation_obstacle_3d.cpp", evidence, suggestion, kind=kind)
    for key, title, evidence, suggestion in (
        ("bone_attachment_parent", "A bone attachment has no parent Skeleton3D", "BoneAttachment3D does not use an external skeleton and its direct parent is not Skeleton3D.", "Parent the attachment to Skeleton3D or configure its external skeleton."),
        ("bone_attachment_external", "A bone attachment cannot resolve its external skeleton", "A live BoneAttachment3D enables an external skeleton, but the configured path does not resolve to Skeleton3D. Detached paths are skipped.", "Set the external skeleton path to the intended Skeleton3D."),
        ("bone_attachment_bone", "A bone attachment has no selected bone", "BoneAttachment3D.bone_idx is negative.", "Select a bone from the resolved skeleton."),
    ):
        check(key, title, "scene/3d/bone_attachment_3d.cpp", evidence, suggestion)
    check("bone2d_hierarchy", "A Bone2D chain does not end at a Skeleton2D", "scene/2d/skeleton_2d.cpp",
          "Following direct Bone2D parents reaches a node that is not Skeleton2D, or reaches no parent.",
          "Place each Bone2D directly under Skeleton2D or another Bone2D in that skeleton's chain.")
    check("bone2d_rest", "A Bone2D has no rest pose", "scene/2d/skeleton_2d.cpp",
          "Bone2D.rest is the all-zero transform used by Godot to mark an unset rest pose.",
          "Set the intended rest pose using the Skeleton2D tools before animating the rig.")
    check("animation_tree_root", "An AnimationTree has no root graph", "scene/animation/animation_tree.cpp",
          "AnimationTree.tree_root is absent.", "Assign the intended AnimationNode graph.")
    check("animation_mixer_root", "An active animation mixer cannot resolve its root node", "scene/animation/animation_mixer.cpp",
          "A live, active AnimationMixer (including AnimationPlayer/AnimationTree) cannot resolve root_node. Detached and inactive mixers are excluded.",
          "Point root_node at the node from which the animation's track paths should resolve.")
    check("canvas_group_clip", "A CanvasGroup child also requests child clipping", "doc/classes/CanvasGroup.xml",
          "A clipping CanvasItem has CanvasGroup in its actual CanvasItem parent chain. Godot documents that both features use the backbuffer and conflict. Top-level items, CanvasLayer, Viewport and non-CanvasItem hierarchy breaks are respected.",
          "Move clipping outside the CanvasGroup or restructure the group to avoid competing backbuffer operations.")

    check("shape_cast_resource", "A ShapeCast has no shape resource", "scene/3d/physics/shape_cast_3d.cpp",
          "ShapeCast2D.shape or ShapeCast3D.shape is absent.", "Assign the convex shape that the query should sweep.")
    check("shape_cast_concave", "A ShapeCast3D uses an unsupported concave shape", "scene/3d/physics/shape_cast_3d.cpp",
          "ShapeCast3D.shape is ConcavePolygonShape3D; Godot explicitly warns that collisions will not be reported.",
          "Use a convex shape for the sweep, or split the query into several convex sweeps.")
    check("vehicle_wheel_parent", "A vehicle wheel is outside a VehicleBody3D", "scene/3d/physics/vehicle_body_3d.cpp",
          "VehicleWheel3D does not have a direct VehicleBody3D parent.", "Parent the wheel directly to its VehicleBody3D.")
    check("joint_targets", "A physics joint has invalid body connections", "scene/3d/physics/joints/joint_3d.cpp",
          "A live joint resolves a non-body node, connects a body to itself, or lacks the required bodies. Joint2D needs two PhysicsBody2D nodes; Joint3D permits one PhysicsBody3D connected to the world. Detached paths are skipped.",
          "Connect distinct bodies with the matching dimension. For a 3D world anchor, keep one body assigned and leave the other endpoint empty.")
    check("lightmap_shadowmask", "Lightmap shadowmasking lacks a baked shadowmask atlas", "scene/3d/lightmap_gi.cpp",
          "LightmapGI requests a non-None shadowmask mode, has LightmapGIData assigned, but its stored shadowmask_textures array is empty. The separate missing-lightmap rule covers absent light_data.",
          "Rebake with shadowmasking enabled if directional shadows beyond the realtime shadow distance are required.")
    for key, title, file, evidence, suggestion in (
        ("camera_cull_mask", "A camera selects no geometry visibility layers", "Camera3D", "Camera3D.cull_mask is exactly zero, including all internal layers. This does not disable the sky, canvas UI or GI contributions.", "Enable the intended visibility layers if this camera should draw 3D geometry."),
        ("geometry_layers", "Geometry belongs to no camera visibility layer", "VisualInstance3D", "GeometryInstance3D.layers is exactly zero. GI participation is separate and is not inferred from this mask.", "Assign the intended visibility layers if cameras should draw this geometry."),
        ("light_cull_mask", "A 3D light selects no object layers", "Light3D", "Light3D.light_cull_mask is zero. The check concerns the object-layer selection, not whether the light contributes to baked or global illumination.", "Select the object layers that should receive the light."),
        ("navigation_layers", "Navigation selects no pathfinding layers", "NavigationAgent3D", "A navigation agent, or an enabled region/link, has navigation_layers set to zero. Disabled regions and links are excluded. Avoidance layers are independent.", "Select matching navigation layers for agents and regions/links if pathfinding should use them."),
        ("particle_collider_mask", "A particle collider selects no particle layers", "GPUParticlesCollision3D", "GPUParticlesCollision3D.cull_mask is zero.", "Select the rendering layers of the GPU particles that should collide with this shape."),
        ("particle_attractor_mask", "A particle attractor selects no particle layers", "GPUParticlesAttractor3D", "GPUParticlesAttractor3D.cull_mask is zero.", "Select the rendering layers of the GPU particles this attractor should affect."),
    ):
        check(key, title, "doc/classes/" + file + ".xml", evidence, suggestion, kind="info")
    check("particle_vector_texture", "A particle vector-field attractor has no field texture", "scene/3d/gpu_particles_collision_3d.cpp",
          "GPUParticlesAttractorVectorField3D.texture is absent; no authored vector field is assigned.",
          "Assign the intended Texture3D, such as NoiseTexture3D, before relying on this field.", renderers=RD)
    check("range_exp_min", "An exponential UI range has an invalid minimum", "scene/gui/range.cpp",
          "Range.exp_edit is enabled with min_value <= 0 in Godot 4.4, or min_value < 0 in Godot 4.7. The inspector uses the running engine's version; 4.7 permits exactly zero.",
          "Use a positive minimum on 4.4, or a nonnegative minimum on 4.7; alternatively use a linear range.")
    check("tooltip_mouse_filter", "A Control tooltip is suppressed by its mouse filter", "scene/gui/control.cpp",
          "Control.tooltip_text is nonempty while mouse_filter is MOUSE_FILTER_IGNORE.",
          "Use Stop or Pass if this control should receive pointer input and show its tooltip; check input propagation after changing the filter.")
    check("particle_points_data", "Point-based particle emission has incomplete data", "scene/resources/particle_process_material.cpp",
          "A GPU particle system's ParticleProcessMaterial uses Points/Directed Points but lacks the point texture, has a nonpositive point count, or uses Directed Points without a normal texture. Other shapes and custom process shaders are excluded.",
          "Generate emission points from the intended mesh/node or supply the matching point count, point texture and directed normal texture.")
    check("particle_subemitter_target", "A GPU particle sub-emitter path cannot attach its target", "scene/3d/gpu_particles_3d.cpp",
          "A live GPUParticles2D/3D has a nonempty sub_emitter path that resolves to itself, no node, or a node other than GPUParticles2D/3D of the matching dimension. Detached paths are skipped.",
          "Point sub_emitter at a different GPU particle node of the same dimension.", renderers=RD)
    check("path_curve_data", "A path follower has no usable curve segment", "scene/3d/path_3d.cpp",
          "A PathFollow2D/3D has the correct direct Path parent, but that parent's curve is absent or contains fewer than two points. Coincident multi-point curves are not evaluated or baked by the audit.",
          "Assign a curve with at least two distinct points if the follower should move along a path.")
    check("camera_dof_renderer", "Practical camera depth of field is unsupported in Compatibility", "doc/classes/CameraAttributesPractical.xml",
          "A Camera3D or WorldEnvironment has CameraAttributesPractical with near or far blur enabled. Assigned resources are inspected, not only the currently selected camera.",
          "Use Forward+ or Mobile for this depth-of-field effect, or disable the unused blur settings.", renderers=GL)
    check("camera_autoexposure_renderer", "Camera auto-exposure is unsupported by this renderer", "servers/rendering/storage/camera_attributes_storage.cpp",
          "A Camera3D or WorldEnvironment has assigned CameraAttributes with auto_exposure_enabled under a renderer without auto-exposure. Godot 4.4 and 4.5 warn under Compatibility; 4.6 and later also under Mobile.",
          "Use manual exposure on this renderer, or choose Forward+ for automatic exposure.", renderers=OTHER, renderers_by_version={"4.4": GL, "4.6": OTHER})
    check("viewport_dof_transparent", "A transparent SubViewport cannot use practical depth of field", "doc/classes/CameraAttributesPractical.xml",
          "A live transparent SubViewport has near/far blur enabled in its effective CameraAttributesPractical. Current-camera overrides take precedence over world attributes. Detached scenes and physical lens calculations are excluded.",
          "Use an opaque viewport background if depth of field is required, or remove the unused blur settings.", renderers=RD, versions=("4.5", "4.7"))
    check("spring_bone_exclude_order", "A spring-bone exclude list is out of child order", "scene/3d/spring_bone_simulator_3d.cpp",
          "A SpringBoneSimulator3D setting with all child collisions enabled lists excluded collisions whose child indices are not strictly increasing (out of order or repeated). SpringBoneSimulator3D::_find_collisions merges the exclude list into the child list assuming ascending order, so some excluded collisions stay active; reproduced on Godot 4.4 and 4.7.2, where exclude list [1, 0] still applied child 0 and [0, 0, 1] still applied child 1 (tests/test_source_rules.gd checks this engine behaviour on every version).",
          "List excluded collisions in their child order, without duplicates, or reorder the collision children to match.")
    check("skeleton_modifier_parent", "An active skeleton modifier has no direct Skeleton3D parent", "scene/3d/skeleton_modifier_3d.cpp",
          "An active SkeletonModifier3D is not directly parented to Skeleton3D. Inactive modifiers are excluded.",
          "Place the modifier directly under the skeleton it should modify.")
    check("viewport_shrink_ignored", "SubViewportContainer shrink is ignored without stretch", "doc/classes/SubViewportContainer.xml",
          "SubViewportContainer.stretch_shrink is greater than one while stretch is disabled.",
          "Enable stretch if the container should control and reduce the child viewport's render resolution.", kind="info")
    check("canvas_nested_clip", "CanvasItem child clipping is nested inside another clipping item", "doc/classes/CanvasItem.xml",
          "An enabled clip_children node has another enabled clip_children item in its actual CanvasItem parent chain. CanvasItem clipping cannot be nested; this is distinct from Control.clip_contents. Separate canvas/root-item boundaries are excluded.",
          "Keep one CanvasItem clipping level or restructure the effect using separate rendering surfaces.")
    check("collision_object_empty", "A live physics object has no registered shape owners", "scene/3d/physics/collision_object_3d.cpp",
          "A live CollisionObject2D/3D has an empty get_shape_owners() array, matching the native shapes-map warning. Detached bodies are excluded because their child shapes may not be registered yet. An existing empty owner is not treated as an absent owner.",
          "Add an appropriate CollisionShape or CollisionPolygon child if the object should participate in collision or area queries.")

    check("navigation_link_endpoints", "Navigation link start and end positions coincide", "scene/3d/navigation_link_3d.cpp",
          "An enabled NavigationLink2D/3D has approximately equal local start_position and end_position, matching both native configuration warnings.",
          "Place the endpoints at the distinct navigation positions the link should connect, or disable the unused link.")
    check("scroll_container_children", "ScrollContainer does not have one layout child", "scene/gui/scroll_container.cpp",
          "A ScrollContainer has zero or multiple visible, non-top-level direct Control children. Internal scrollbars and 4.7 decoration nodes are excluded; hidden or top-level controls do not participate in its layout.",
          "Use one direct layout container for scrollable content and put its controls beneath it.")
    check("texture_rect_atlas_tile", "Tiled TextureRect uses atlas margins", "scene/gui/texture_rect.cpp",
          "A TextureRect uses STRETCH_TILE and an AtlasTexture in its chain has a nonzero margin. Godot 4.7 warns that this combination is unsupported. Inspection is bounded to 16 distinct atlas resources; deeper unresolved chains are not inferred.",
          "Use a margin-free texture for tiling, or choose a non-tiled stretch mode.", versions=("4.7",))

    check("fog_aerial", "Aerial-perspective fog is unavailable in Compatibility", "drivers/gles3/shaders/scene.glsl",
          "An assigned Environment enables regular fog with positive fog_aerial_perspective, a sky background and a sky material. The aerial-perspective sampling block is commented out in the 4.4 and 4.7.2 Compatibility shaders.",
          "Use a fixed fog color or a supported renderer if sky-colored aerial perspective is required.", renderers=GL)

    look_at = "scene/3d/look_at_modifier_3d.cpp"
    check("look_at_axes", "Look-at forward and rotation axes are parallel", look_at,
          "An active LookAtModifier3D uses the same unsigned axis for forward_axis and primary_rotation_axis, including either forward-axis sign. This reproduces the native configuration warning.",
          "Choose a primary rotation axis perpendicular to the bone's forward axis.")
    check("look_at_bone", "Look-at modifier has no valid skeleton bone", look_at,
          "A live active LookAtModifier3D directly under Skeleton3D has a negative or out-of-range bone index. The native modification returns before applying a pose. Detached nodes are excluded because bone names resolve on tree entry.",
          "Select an existing bone from the parent skeleton and verify the binding after skeleton changes.")
    check("look_at_target", "Assigned look-at target does not resolve to Node3D", look_at,
          "A live active LookAtModifier3D has a nonempty target_node path that is missing or resolves to another node type. The native modifier preserves the current bone rotation when no Node3D target resolves. Empty target paths are excluded because they may intentionally suspend aiming.",
          "Repair the target path or clear it if aiming is intentionally suspended.")
    retarget = "scene/3d/retarget_modifier_3d.cpp"
    check("retarget_children", "Retarget modifier has no direct destination skeleton", retarget,
          "An active RetargetModifier3D has no direct Skeleton3D child. The native destination cache considers direct children only; a skeleton beneath an intermediary Node is not a destination.",
          "Place the intended destination Skeleton3D directly under the modifier.")
    check("retarget_profile", "Retarget modifier has no skeleton profile", retarget,
          "An active RetargetModifier3D has no SkeletonProfile. The native cache_rests method clears the source bone IDs and returns without a profile, leaving no bone mappings to retarget.",
          "Assign the SkeletonProfile that describes the matching source and destination bone names.")

    check("skeleton_ik_bones", "An IK modifier has invalid root or tip bone selections", "scene/3d/skeleton_ik_3d.cpp",
          "An active, unscripted native SkeletonIK3D has a direct Skeleton3D parent, but a selected root/tip bone name is missing or the root bone index is at least the tip index. Both checked native task builders reject these selections. This checks current resource configuration; a task created before bone renaming may retain earlier indices. No IK task is created and no solve is invoked by the audit. An ancestry requirement is not invented: the native builder's explicit index checks are the predicate.",
          "Choose existing root and tip bones for the intended chain, with the root index below the tip index, and reload/reinitialize the IK chain after correcting the configuration. Confirm the selected root is the intended ancestor.")

    material = "scene/resources/material.cpp"
    for key, title, evidence, suggestion, kind in (
        ("material_height_triplanar", "Height mapping is ignored with UV1 triplanar mapping", "An effective BaseMaterial3D enables both height mapping and UV1 triplanar mapping.", "Use mesh UVs for height mapping, or disable the unused height-map feature.", "correctness"),
        ("material_msdf_triplanar", "MSDF albedo is ignored with UV1 triplanar mapping", "An effective BaseMaterial3D enables both MSDF albedo and UV1 triplanar mapping.", "Use mesh UVs when sampling an MSDF albedo texture.", "correctness"),
        ("material_unshaded_features", "Unshaded materials ignore clearcoat and rim lighting", "An unshaded BaseMaterial3D enables clearcoat or rim lighting.", "Select a lit shading mode if those lighting effects are needed, or disable the unused features.", "info"),
        ("material_particle_trails", "A particle-trail material is used on ordinary mesh geometry", "An effective BaseMaterial3D enables use_particle_trails outside a GPUParticles3D draw pass.", "Use a separate material with particle trails disabled for ordinary mesh geometry.", "correctness"),
        ("material_anisotropy_tangents", "An anisotropic material's ArrayMesh surface lacks tangents", "An effective per-pixel BaseMaterial3D enables nonzero anisotropy on an ArrayMesh surface without ARRAY_FORMAT_TANGENT. Triplanar modes generate tangent space in the shader and are excluded, as are other mesh types and unknown custom shader semantics.", "Generate tangents during mesh import, or disable anisotropy where it is unnecessary.", "correctness"),
    ):
        tangents = key == "material_anisotropy_tangents"
        check(key, title, "doc/classes/BaseMaterial3D.xml" if tangents else material, evidence, suggestion,
              kind=kind, renderers=["forward_plus"] if tangents else ALL, lit=tangents)

    # Remaining native get_configuration_warnings() predicates; docs/GODOT_COVERAGE.json maps every warning.
    check("missing_node", "A scene node's class or instanced scene is missing", "scene/main/missing_node.cpp",
          "A MissingNode placeholder stands in for a node whose class or instanced scene was unavailable when the scene loaded. The offender lists the original class and scene. Godot keeps the stored properties only while the placeholder is saved unchanged.",
          "Restore the missing class (plugin, GDExtension or script class) or scene file, or replace the node deliberately before saving the scene.")
    check("canvas_modulate_multiple", "More than one visible CanvasModulate shares a canvas", "scene/2d/canvas_modulate.cpp",
          "Two or more visible CanvasModulate nodes are registered for the same canvas. Godot applies only one of them, and which one is undefined.",
          "Keep one visible CanvasModulate per canvas; hide or remove the others, or move them to separate CanvasLayers.")
    check("timer_short_wait", "A Timer waits less than 0.05 seconds", "scene/main/timer.cpp",
          "Timer.wait_time is below 0.05 s. Godot warns that such timers behave differently depending on the rendered or physics frame rate, because a Timer can fire at most once per processed frame.",
          "Use a process loop for very short periodic work, or accept and document the frame-rate-dependent firing.")
    check("shader_globals_inactive", "A ShaderGlobalsOverride is inactive because another one exists", "scene/main/shader_globals_override.cpp",
          "A ShaderGlobalsOverride inside the tree is not in the active override group: another override node is already active, so this node's values are ignored.",
          "Keep a single ShaderGlobalsOverride per scene tree and merge the overridden parameters into it.")
    check("container_plain", "A plain Container has no layout script", "scene/gui/container.cpp",
          "A node of exact class Container has no script, so nothing positions its children.",
          "Use a concrete container (VBoxContainer, HBoxContainer, MarginContainer ...) or a plain Control.", kind="info")
    check("button_group_toggle", "A ButtonGroup member is not in toggle mode", "scene/gui/base_button.cpp",
          "A BaseButton has a ButtonGroup but toggle_mode is false, so the group cannot keep a single pressed button.",
          "Enable toggle_mode on group members, or remove the ButtonGroup.")
    check("label_autowrap_width", "An autowrapping Label has no width constraint", "scene/gui/label.cpp",
          "Godot 4.7: an in-tree Label wraps text but its custom minimum width and combined maximum width are both zero. Godot 4.4: a wrapping Label inside a Container has no custom minimum size. Godot warns the label cannot size correctly, typically collapsing to one character per line.",
          "Set a positive custom minimum (or 4.7 maximum) width, or let a container with a fixed width size the label.")
    check("label_missing_glyphs", "A Label's font cannot render some of its characters", "scene/gui/label.cpp",
          "Shaping the Label's text (uppercase applied, up to 4096 characters, untranslated) with its effective font and fallbacks leaves glyphs without a font, which render as boxes or nothing. Godot 4.7 ignores zero-index control glyphs; 4.4 reports any unfonted glyph.",
          "Add a fallback font that covers the characters, or change the text. Check translated strings too.")
    check("label_msdf_pixel_range", "An MSDF Label outline exceeds the font's pixel range", "scene/gui/label.cpp",
          "The Label uses an MSDF FontFile whose msdf_pixel_range is too small for the combined outline and stacked outline/shadow sizes at this font size, so part of the outline or shadow is not drawn.",
          "Raise msdf_pixel_range on the font import (Godot reports the required minimum), or reduce the outline sizes.", versions=("4.6", "4.7"))
    check("popup_transparency", "Rounded or shadowed popups lack window transparency", "scene/gui/popup.cpp",
          "A PopupPanel or PopupMenu (including the popup of a MenuButton or OptionButton) uses a StyleBoxFlat panel with shadows or rounded corners, subwindows are not embedded, and the display server reports no window transparency, so the corners and shadow render opaque.",
          "Enable display/window/per_pixel_transparency/allowed on platforms that support it, embed subwindows, or use a square shadowless popup style.")
    check("subviewport_cursor", "A SubViewportContainer sets a default cursor shape", "scene/gui/subviewport_container.cpp",
          "SubViewportContainer.mouse_default_cursor_shape is not CURSOR_ARROW; Godot ignores it for this node.",
          "Set the cursor on the Controls inside the SubViewport instead, and leave the container at CURSOR_ARROW.", kind="info")
    check("parallax_layer_parent", "A ParallaxLayer is not a child of ParallaxBackground", "scene/2d/parallax_layer.cpp",
          "A ParallaxLayer's parent is not a ParallaxBackground, so it does not scroll with the parallax camera.",
          "Move the layer under a ParallaxBackground, or use Parallax2D.")
    check("voxel_gi_data", "A VoxelGI node has no baked data", "scene/3d/voxel_gi.cpp",
          "VoxelGI.data is empty, so the node is disabled and contributes no global illumination.",
          "Bake the VoxelGI, or remove the node if it is unused.", renderers=RD)
    check("occluder_culling_disabled", "Occluders exist but occlusion culling is disabled", "scene/3d/occluder_instance_3d.cpp",
          "An OccluderInstance3D exists while rendering/occlusion_culling/use_occlusion_culling is false, so the root viewport performs no occlusion culling with it.",
          "Enable occlusion culling in the project settings, or remove unused occluders.")
    tilemap = "scene/2d/tile_map.cpp"
    check("tilemap_deprecated", "A deprecated TileMap node is used", tilemap,
          "The scene uses TileMap, which Godot deprecates in favor of separate TileMapLayer nodes.",
          "Use the TileMap bottom panel's Extract TileMap layers command to convert it to TileMapLayer nodes.", kind="info")
    check("tilemap_ysort_z", "A Y-sorted TileMap layer shares a Z index with an unsorted layer", tilemap,
          "A TileMap has a layer without Y-sort at the same Z index as a Y-sorted layer, so the unsorted layer is Y-sorted as a whole together with the sorted tiles.",
          "Give unsorted layers a different Z index, or enable Y-sort on them.")
    check("tilemap_layer_ysort", "A TileMap layer is Y-sorted but the TileMap node is not", tilemap,
          "At least one TileMap layer enables Y-sort while the TileMap node itself does not.",
          "Enable Y-sort on the TileMap node as well.")
    check("tilemap_node_ysort", "A Y-sorted TileMap has no Y-sorted layers", tilemap,
          "The TileMap node enables Y-sort but none of its layers do, so each layer is Y-sorted as a whole.",
          "Enable Y-sort on the layers that need per-tile sorting.")
    check("tilemap_isometric_ysort", "An isometric TileMap is not fully Y-sorted", tilemap,
          "The TileSet uses isometric tiles while Y-sort is off on the TileMap or on at least one layer, which Godot warns will likely not draw as intended.",
          "Enable Y-sort on the TileMap and all of its layers.")
    bone2d = "scene/2d/physics/physical_bone_2d.cpp"
    check("physical_bone2d_parent", "A PhysicalBone2D has no Skeleton2D ancestor", bone2d,
          "Walking up through parent PhysicalBone2D nodes does not reach a Skeleton2D, so the bone cannot follow or drive a skeleton.",
          "Place PhysicalBone2D nodes under a Skeleton2D, directly or through other PhysicalBone2D nodes.")
    check("physical_bone2d_bone", "A PhysicalBone2D is not assigned to a Bone2D", bone2d,
          "The PhysicalBone2D has a Skeleton2D but bone2d_index is -1.",
          "Set bone2d_nodepath (or bone2d_index) to the Bone2D it should simulate.")
    check("physical_bone2d_joint", "A child PhysicalBone2D has no Joint2D", bone2d,
          "A PhysicalBone2D whose parent is another PhysicalBone2D has no Joint2D child, so nothing keeps the two bones connected.",
          "Add a PinJoint2D (or another Joint2D) as a child of the bone.")
    check("physics_body_interpolation", "A physics body sits on a non-interpolated branch", "scene/3d/physics/physics_body_3d.cpp",
          "Physics interpolation is enabled for the project, but this PhysicsBody2D/3D resolves to physics_interpolation_mode OFF through its own or an inherited mode. Godot warns it will not work correctly there.",
          "Set the body (and its ancestors) to Inherit or On, and keep non-interpolated visuals on separate branches.", versions=("4.5", "4.7"))
    check("canvas_group_ancestor", "A CanvasGroup has a clipping or CanvasGroup ancestor", "scene/2d/canvas_group.cpp",
          "An in-tree CanvasGroup has an ancestor CanvasGroup or an ancestor CanvasItem that clips its children, so Godot warns the group will not function properly.",
          "Move the CanvasGroup out of the clipping ancestor or the outer CanvasGroup.", versions=("4.5", "4.7"))
    xr = "scene/3d/xr/xr_nodes.cpp"
    check("xr_camera_parent", "An XRCamera3D is not a child of XROrigin3D", xr,
          "A visible in-tree XRCamera3D has a parent that is not an XROrigin3D, so its tracking space is undefined.",
          "Make the XRCamera3D a direct child of the XROrigin3D.")
    check("xr_node_parent", "An XR controller or anchor is not a child of XROrigin3D", xr,
          "A visible in-tree XRNode3D (XRController3D, XRAnchor3D ...) has a parent that is not an XROrigin3D.",
          "Make tracked XR nodes direct children of the XROrigin3D.")
    check("xr_node_tracker", "An XR tracked node has no tracker name", xr,
          "A visible in-tree XRNode3D has an empty tracker name, so it follows nothing.",
          "Set the tracker (for example left_hand or right_hand).")
    check("xr_node_pose", "An XR tracked node has no pose name", xr,
          "A visible in-tree XRNode3D has an empty pose name.",
          "Set the pose (default, aim or grip).")
    check("xr_interpolation", "An XR camera or tracked node is physics-interpolated", xr,
          "Physics interpolation is enabled and a visible XRCamera3D or XRNode3D is interpolated; Godot warns this causes jitter because tracking updates every rendered frame.",
          "Set physics_interpolation_mode to Off on XR cameras and tracked nodes.", versions=("4.5", "4.7"))
    check("xr_origin_camera", "An XROrigin3D has no XRCamera3D child", xr,
          "A visible in-tree XROrigin3D has no XRCamera3D child, so nothing renders from the headset pose.",
          "Add an XRCamera3D as a child of the XROrigin3D.")
    check("xr_origin_scale", "An XROrigin3D is scaled", xr,
          "The XROrigin3D's scale is not (1, 1, 1); Godot does not support scaling it.",
          "Reset the scale and change XRServer world scale instead.", versions=("4.6", "4.7"))
    check("xr_shaders_disabled", "An XR scene runs without XR shaders", xr,
          "An XROrigin3D exists while xr/shaders/enabled is false, so stereoscopic output is not supported.",
          "Enable xr/shaders/enabled in the project settings.")
    check("xr_hand_tracking", "Hand skeleton modifiers lack the OpenXR hand-tracking extension", "scene/3d/xr/xr_hand_modifier_3d.cpp",
          "An XRHandModifier3D exists while OpenXR is enabled but xr/openxr/extensions/hand_tracking is off, so no hand data arrives.",
          "Enable the OpenXR hand-tracking extension in the project settings.")
    openxr = "modules/openxr/scene/openxr_composition_layer.cpp"
    check("openxr_layer_transform", "An OpenXR composition layer has scale or shear", openxr,
          "The OpenXRCompositionLayer's local basis is not orthonormal; OpenXR composition layers support rotation and translation only.",
          "Size the layer through its shape properties and keep the node's scale at 1.")
    check("openxr_layer_hole_punch", "A hole-punching OpenXR layer is sorted in front", openxr,
          "enable_hole_punch is on while sort_order is zero or positive; hole punching only works for layers sorted behind the projection layer.",
          "Use a negative sort_order for hole-punched layers.")
    check("openxr_layer_parent", "An OpenXR composition layer is not under XROrigin3D", openxr,
          "Godot 4.4: a visible in-tree OpenXRCompositionLayer's parent is not an XROrigin3D.",
          "Make the layer a child of the XROrigin3D.", versions=("4.4", "4.6"))
    check("openxr_visibility_mask_parent", "An OpenXR visibility mask is not under XRCamera3D", "modules/openxr/scene/openxr_visibility_mask.cpp",
          "A visible in-tree OpenXRVisibilityMask's parent is not an XRCamera3D.",
          "Make the visibility mask a child of the XRCamera3D.")
    check("openxr_render_model_parent", "An OpenXR render model is outside its XR origin", "modules/openxr/scene/openxr_render_model_manager.cpp",
          "An OpenXRRenderModel's parent is neither an XROrigin3D nor an OpenXRRenderModelManager, or an OpenXRRenderModelManager has no XROrigin3D parent (or, for a specific tracker, no XROrigin3D ancestor).",
          "Place render models under an OpenXRRenderModelManager that is under the XROrigin3D.", versions=("4.5", "4.7"))
    check("openxr_render_model_extension", "OpenXR render models lack their extension", "modules/openxr/scene/openxr_render_model.cpp",
          "An OpenXRRenderModel or OpenXRRenderModelManager exists while xr/openxr/extensions/render_model is off.",
          "Enable the OpenXR render-model extension in the project settings.", versions=("4.5", "4.7"))
    check("openxr_render_model_pose", "An OpenXR render-model manager needs a tracker for its pose", "modules/openxr/scene/openxr_render_model_manager.cpp",
          "An OpenXRRenderModelManager tracks any or no device while make_local_to_pose is set; a pose needs a specific tracker.",
          "Select a hand tracker, or clear make_local_to_pose.", versions=("4.5", "4.7"))
    check("multiplayer_spawner_path", "A MultiplayerSpawner's spawn path is invalid", "modules/multiplayer/multiplayer_spawner.cpp",
          "MultiplayerSpawner.spawn_path is empty or does not resolve, so it cannot spawn nodes. Absolute paths are skipped outside a running tree.",
          "Point spawn_path at the node that receives spawned scenes.")
    check("multiplayer_synchronizer_root", "A MultiplayerSynchronizer's root path is invalid", "modules/multiplayer/multiplayer_synchronizer.cpp",
          "MultiplayerSynchronizer.root_path is empty or does not resolve, so it cannot synchronize properties. Absolute paths are skipped outside a running tree.",
          "Point root_path at the node whose properties are replicated.")
    check("csg_empty_shape", "A CSG shape produces no geometry", "modules/csg/csg_shape.cpp",
          "The in-tree root CSG result for this shape has no surfaces, which Godot reports as an empty shape; it usually means a non-manifold mesh. Only root results are exposed, so an empty child brush under a non-empty root is not detected.",
          "Use closed, manifold meshes (every edge shared by exactly two faces) in CSGMesh3D, or check the CSG operations.")
    check("spring_bone_collision_parent", "A spring-bone collider is not under SpringBoneSimulator3D", "scene/3d/spring_bone_collision_3d.cpp",
          "A SpringBoneCollision3D's parent is not a SpringBoneSimulator3D, so no simulator uses it.",
          "Move the collider under the SpringBoneSimulator3D that should collide with it.")
    check("aim_modifier_axes", "An AimModifier3D setting has parallel forward and rotation axes", "scene/3d/aim_modifier_3d.cpp",
          "A setting using Euler rotation has a forward axis parallel to its primary rotation axis, which cannot aim.",
          "Choose a primary rotation axis perpendicular to the forward axis.", versions=("4.5", "4.7"))
    check("iterate_ik_target", "An iterative IK chain has no valid target", "scene/3d/iterate_ik_3d.cpp",
          "An in-tree IterateIK3D (FABRIK3D, CCDIK3D, JacobianIK3D) has a setting whose target is empty or does not resolve to a Node3D. _process_ik skips that setting every frame.",
          "Assign a Node3D target to every setting, or remove unused settings.", versions=("4.6", "4.7"))
    check("spline_ik_path", "A SplineIK3D setting has no usable Path3D", "scene/3d/spline_ik_3d.cpp",
          "An in-tree SplineIK3D has a setting whose Path3D is missing or does not resolve, or whose curve has no points. _process_ik skips that setting every frame.",
          "Assign a Path3D with a curve to every setting.", versions=("4.6", "4.7"))
    check("two_bone_ik_targets", "A TwoBoneIK3D setting lacks a target or pole node", "scene/3d/two_bone_ik_3d.cpp",
          "An in-tree TwoBoneIK3D has a setting whose target or pole does not resolve to a Node3D. _process_ik aborts that setting each frame. (Godot 4.7.2's pole warning re-tests the target path; the processing code requires both.)",
          "Assign Node3D target and pole nodes to every setting.", versions=("4.6", "4.7"))

    def perf(key, title, category, evidence, suggestion, tradeoff, file, *, renderers=ALL, lit=False, renderers_by_version=None, verify=None, versions=("4.4", "4.7"), threshold=1, also=None, source=None):
        counter = "check_" + key
        condition = {"scene_gte": {"name": counter, "value": threshold}}
        if also:
            condition = {"all": [condition, also]}
        if lit:
            condition = {"all": [condition, {"setting_eq": {"path": "rendering/shading/overrides/force_vertex_shading", "value": False}}]}
        rule = dict(id=category + "." + key, category=category, title=title,
                 severity="low", renderers=renderers, versions=list(versions),
                 requires=["scene", "settings"] if lit else ["scene"], condition=condition,
                 offender_key=counter, heuristic=True,
                 heuristic_rationale="A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.",
                 evidence=evidence, suggestion=suggestion, tradeoff=tradeoff,
                 expected_effect="Potentially reduce work for this feature; no frame-time saving is predicted from configuration alone.",
                 verify_step=verify or "Capture a visual reference; change one feature and repeat frame timing plus relevant CPU or GPU profiling in the same scene on target hardware.",
                 source=source or f"https://github.com/godotengine/godot/blob/{_source_tag(versions)}-stable/{file}", evidence_kind="godot_feature",
                 dedupe_key="heightmap" if key == "material_deep_parallax" else "")
        if renderers_by_version:
            rule["renderers_by_version"] = renderers_by_version
        add(rule)

    # Costs stated in the Godot class reference (docs/GODOT_PERF_NOTES.json); quotes are verified at build time.
    def documented(key, title, category, cls, quote, evidence, suggestion, tradeoff, *, renderers=ALL, threshold=1, also=None):
        perf(key, title, category, "%s Godot class reference: \"%s\"" % (evidence, doc_quote(cls, quote)), suggestion, tradeoff,
             "doc/classes/%s.xml" % cls, renderers=renderers, threshold=threshold, also=also)

    # Costs stated in the godot-docs tutorials (docs/GODOT_TUTORIAL_NOTES.json); quotes are verified at build time.
    def tutorial(key, title, category, page, quote, evidence, suggestion, tradeoff, *, renderers=ALL, threshold=1, also=None, versions=("4.4", "4.7")):
        perf(key, title, category, "%s Godot docs: \"%s\"" % (evidence, tutorial_quote(page, quote, versions)), suggestion, tradeoff,
             None, renderers=renderers, threshold=threshold, also=also, versions=versions,
             source="https://docs.godotengine.org/en/%s/%s.html" % (versions[0], page))

    # Project-setting costs stated in the godot-docs tutorials.
    def tutorial_setting(rid, title, path, value, page, quote, suggestion, tradeoff, *, severity="low", renderers=ALL, versions=("4.4", "4.7")):
        add(dict(id=rid, category=rid.split(".")[0], title=title, severity=severity, kind="performance",
                 renderers=renderers, versions=list(versions), requires=["settings"],
                 condition={"setting_eq": {"path": path, "value": value}},
                 evidence="%s is %s. Godot docs: \"%s\"" % (path, str(value).lower(), tutorial_quote(page, quote, versions)),
                 suggestion=suggestion, setting=path, tradeoff=tradeoff,
                 expected_effect="Re-measure with collect_metrics after changing this setting. No frame-time percentage is predicted.",
                 verify_step="collect_metrics", source="https://docs.godotengine.org/en/%s/%s.html" % (versions[0], page)))

    tutorial_setting("memory.gdscript_track_call_stacks", "GDScript call stacks are tracked in release builds",
                     "debug/settings/gdscript/always_track_call_stacks", True, "tutorials/scripting/logging",
                     "In projects exported in release mode, backtraces are disabled by default for performance reasons.",
                     "Turn debug/settings/gdscript/always_track_call_stacks off unless shipped builds report script backtraces (for example to a remote crash service).",
                     "Release builds can no longer capture script backtraces; the page recommends keeping it on when a custom logger reports exceptions remotely.",
                     versions=("4.5", "4.7"))
    tutorial_setting("navigation.region_sync_on_main_thread", "Navigation regions synchronize on the main thread",
                     "navigation/world/region_use_async_iterations", False, "tutorials/migrating/upgrading_to_godot_4.5",
                     "By default, the regions in a NavigationServer map now update asynchronously using threads to improve performance.",
                     "Turn navigation/world/region_use_async_iterations back on so region changes synchronize on a background thread.",
                     "Region changes take effect after an extra delay.", severity="medium", versions=("4.5", "4.7"))

    tutorial("screen_texture", "An XR project reads the screen texture", "xr", "tutorials/xr/xr_full_screen_effects",
             "Full screen effects that require reading from the screen texture effectively disable all rendering performance optimizations in XR.",
             "xr/openxr/enabled is on and a spatial ShaderMaterial declares a hint_screen_texture uniform, or a BaseMaterial3D enables refraction (which samples the screen texture); comments are ignored. The page adds that Godot then makes a full copy of the render buffer.",
             "Write XR full-screen effects as per-pixel shaders that do not sample the screen (the page's vignette example), and avoid refraction on XR-visible materials.",
             "Effects that distort or blur the rendered image need the screen texture.",
             also={"setting_eq": {"path": "xr/openxr/enabled", "value": True}})
    tutorial("positional_light_dynamic_bake", "Omni or spot lights stay Dynamic in a lightmapped scene", "lights",
             "tutorials/performance/optimizing_3d_performance",
             "For best performance, you should set lights' bake mode to Static as opposed to the default Dynamic, as this will skip real-time lighting on meshes that have baked lighting.",
             "A visible OmniLight3D or SpotLight3D keeps light_bake_mode Dynamic while the scene has a baked LightmapGI.",
             "Set light_bake_mode to Static on omni and spot lights the lightmap covers and rebake; the same page suggests keeping Dynamic on the DirectionalLight3D.",
             "Static lights can't cast shadows onto meshes with baked lighting, so moving objects lose those shadows.",
             also={"scene_gte": {"name": "lightmap_baked_count", "value": 1}})
    tutorial("subviewport_3d_unused", "A 2D-only SubViewport keeps 3D enabled", "ui", "tutorials/rendering/viewports",
             "Disabling 3D is slightly faster and uses less memory compared to enabled 3D.",
             "A SubViewport has disable_3d off and no Node3D anywhere below it, so it renders only 2D.",
             "Turn on disable_3d for SubViewports that only show 2D content.",
             "3D nodes added to the SubViewport later do not render until disable_3d is turned off again.")
    tutorial("auto_exposure", "Camera auto exposure is enabled", "post", "tutorials/3d/environment_and_post_processing",
             "Auto exposure needs to evaluate the scene's brightness every frame, which has a moderate performance cost.",
             "A Camera3D or WorldEnvironment has CameraAttributes with auto_exposure_enabled.",
             "Leave auto exposure disabled if it doesn't make much of a difference in the scene, as the page recommends; set a fixed exposure instead.",
             "Scenes with large brightness changes (indoor to outdoor) need manual exposure changes instead.", renderers=["forward_plus"])
    tutorial("material_alpha_to_coverage", "Materials use alpha to coverage", "materials", "tutorials/3d/3d_antialiasing",
             "Alpha to coverage has a moderate performance cost, but it's effective at reducing aliasing on transparent materials without introducing any blurriness.",
             "A BaseMaterial3D with Alpha Scissor or Alpha Hash transparency has alpha_antialiasing_mode set (material.cpp emits alpha to coverage only for those two modes).",
             "Keep alpha antialiasing on foliage, fences and hair whose edges visibly alias, and turn it off elsewhere; it has no effect without MSAA.",
             "Alpha-tested edges alias again where it is turned off.")
    tutorial("color_correction_lut_large", "The color-correction LUT is larger than 65 per side", "post", "tutorials/3d/environment_and_post_processing",
             "since color correction is low-frequency data, sticking to low resolutions is recommended for performance reasons.",
             "An Environment with adjustments enabled uses a 3D color-correction texture wider than 65 texels; the page lists 17 to 65 per side as typical sizes. The 65 cutoff is a review heuristic.",
             "Resample the LUT to 33 or 65 per side.",
             "Very fine color grades may need the larger LUT.")
    tutorial("lightmap_data_embedded", "Lightmap data is embedded in a text scene", "gi", "tutorials/3d/global_illumination/using_lightmap_gi",
             "If you are using a scene in .tscn format, you should save this resource to an external binary .lmbake file to avoid bloating the .tscn scene with binary data encoded in Base64.",
             "A LightmapGI's light_data is built into a .tscn scene (or not saved to its own file), so the capture data is stored as Base64 text in the scene.",
             "Save light_data to an external .lmbake file (Godot's bake does this when given a path) and reference it from the LightmapGI.",
             "One more file to keep with the scene.")
    tutorial("fog_density_texture_large", "A FogVolume density texture is larger than 64 per side", "post", "tutorials/3d/volumetric_fog",
             "To improve performance, it's recommended to use low texture sizes (64×64×64 or lower), as high-frequency detail is difficult to notice in a FogVolume.",
             "A FogVolume's FogMaterial uses a 3D density texture wider, taller or deeper than 64 texels.",
             "Resample the density texture to 64×64×64 or lower.",
             "Finer density detail needs a larger volumetric fog volume size anyway, which the page notes has its own cost.", renderers=["forward_plus"])
    tutorial("tilemap_scene_tiles", "A TileMapLayer places many scene tiles", "canvas", "tutorials/2d/using_tilesets",
             "Scene tiles come with a greater performance overhead compared to atlases, as every scene is instanced individually for every placed tile.",
             "An enabled TileMapLayer places more than 256 cells from a TileSetScenesCollectionSource (bounded to 4096 inspected cells per scan). The 256 cutoff is a review heuristic shared with the other TileMap checks.",
             "Use atlas tiles for static decoration and keep scene tiles for cells that need their own nodes (scripts, collision behaviour, lights).",
             "Atlas tiles cannot carry per-cell scripts or child nodes.")
    tutorial("shader_discard", "Custom spatial shaders use discard", "materials", "tutorials/shaders/shader_reference/shading_language",
             "Beware that discard has a performance cost when used, as it will prevent the depth prepass from being effective on any surfaces using the shader.",
             "A spatial ShaderMaterial's shader code contains a discard statement (comments ignored).",
             "Use discard only where alpha testing is needed, and keep it out of shaders used on large opaque surfaces; BaseMaterial3D alpha scissor has the same cost.",
             "Cut-out shapes (foliage, fences) need discard or alpha blending.", renderers=["forward_plus", "gl_compatibility"])
    tutorial("body_many_shapes", "A physics body has more than 16 collision shapes", "physics", "tutorials/physics/troubleshooting_physics_issues",
             "Convex collision shapes should use a number of shapes as low as possible for performance reasons.",
             "A CollisionObject2D or CollisionObject3D owns more than 16 enabled shapes (for example from automatic convex decomposition). The 16 cutoff is a review heuristic.",
             "Replace generated shape sets with a few primitive shapes (box, sphere, capsule), or a single concave shape on static level geometry.",
             "Fewer shapes follow the visual mesh less closely.")
    tutorial("obstacle_static_and_dynamic", "A navigation obstacle is both static and dynamic", "navigation", "tutorials/navigation/navigation_using_navigationobstacles",
             "While both static and dynamic properties can be active at the same time on the same obstacle this is not recommended for performance.",
             "A NavigationObstacle2D/3D with avoidance enabled has both a radius (dynamic) and an outline of three or more vertices (static).",
             "Use the radius while the obstacle moves and the vertices once it rests, as the page describes, instead of both at once.",
             "Switching between the two needs a script.")
    tutorial("frame_navigation_reachable", "Path reachability is checked every frame", "scripts", "tutorials/navigation/navigation_optimizing_performance",
             "Do not check beforehand if a target position is reachable every frame. What looks like an innocent check is the equivalent of an expensive path query behind the scene.",
             "Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces finds is_target_reachable(). Methods match by name.",
             "Request the path directly and compare its last point with the target, as the page suggests, instead of checking reachability every frame.",
             "None; the path query is needed anyway.")
    tutorial("area_light_cost", "Area lights are in the scene", "lights", "tutorials/3d/lights_and_shadows",
             "This type of light is the most expensive to render in real-time. It should be used sparingly, especially when shadows are enabled.",
             "A visible AreaLight3D with non-zero energy is in the scene. In Forward+, one visible area light adds cost to every rendered object; in Mobile and Compatibility only to the objects it reaches.",
             "Use area lights sparingly (the page suggests cinematics or high-end targets), turn off their shadows or set Size to 0.0 to drop the PCSS penumbra, and prefer omni or spot lights elsewhere.",
             "Omni and spot lights do not reproduce the soft, shaped highlights of an area light.", versions=("4.7",))

    documented("animation_value_transforms", "Value tracks animate 3D position, rotation or scale", "cpu", "Animation",
               "track types instead of is recommended for performance reasons.",
               "An AnimationPlayer/AnimationTree library has a value track whose property is position, rotation, rotation_degrees, quaternion or scale on a node that resolves to Node3D. Unresolved targets are skipped.",
               "Use dedicated Position 3D, Rotation 3D and Scale 3D tracks for Node3D transforms.",
               "Value tracks can animate any property; dedicated tracks only cover transforms.")
    documented("animation_cubic_3d", "A complex 3D animation uses cubic transform interpolation", "cpu", "Animation",
               "Stick to for complex 3D animations imported from external software, even if it requires using a higher animation framerate in return.",
               "One animation has at least 16 position/rotation/scale 3D tracks with cubic or cubic-angle interpolation. The 16-track cutoff is a review heuristic for complex animations.",
               "Switch imported 3D transform tracks to linear interpolation and raise the import animation FPS if motion needs it.",
               "Linear interpolation may need more keys for the same smoothness.")
    documented("gi_dynamic", "Geometry uses dynamic GI with a VoxelGI in the scene", "gi", "GeometryInstance3D",
               "but it has a higher performance impact than .",
               "A visible GeometryInstance3D uses GI_MODE_DYNAMIC and the scan found a VoxelGI, the only GI that dynamic mode affects.",
               "Use GI_MODE_STATIC for objects that do not move, and keep dynamic mode for moving objects that must contribute to VoxelGI.",
               "Static objects stop contributing correctly if they later move.", renderers=RD,
               also={"scene_gte": {"name": "voxel_gi_count", "value": 1}})
    documented("small_shadow_casters", "Many tiny meshes cast shadows", "shadows", "GeometryInstance3D",
               "Use this to improve performance for small geometry that is unlikely to cast noticeable shadows (such as debris).",
               "At least 64 visible MeshInstance3D nodes cast shadows although their scaled bounds are under 0.2 units on every axis. The size and count cutoffs are review heuristics.",
               "Set cast_shadow to Off on small debris and props whose shadows are not noticeable.",
               "Small objects lose contact shadows.", threshold=64)

    documented("light_shadow_fade", "A light's shadow fades no earlier than the light", "shadows", "Light3D",
               "Set this to a value lower than + to further improve performance, as shadow rendering is often more expensive than light rendering itself.",
               "A visible OmniLight3D/SpotLight3D casts shadows with distance fade enabled, and distance_fade_shadow is at least distance_fade_begin + distance_fade_length, so shadows render for the light's whole fade range.",
               "Lower distance_fade_shadow below the light's fade end so distant lights stop rendering shadows first.",
               "Distant lights lose their shadows before the light itself fades.")
    documented("shadow_blend_splits", "Directional shadow splits are blended", "shadows", "DirectionalLight3D",
               "Enabling shadow blend splitting also has a moderate performance cost.",
               "A visible, shadow-casting DirectionalLight3D uses PSSM splits with directional_shadow_blend_splits enabled.",
               "Disable directional_shadow_blend_splits unless the seams between shadow splits are visible during play.",
               "Transitions between shadow cascades become visible as a sharper change in shadow detail.")
    documented("decal_normal_fade", "A decal uses normal-angle fading", "decals", "Decal",
               "Setting to a value greater than 0.0 has a small performance cost due to the added normal angle computations.",
               "A visible Decal with a nonzero cull_mask has normal_fade above 0.",
               "Set normal_fade to 0 where the decal does not need to fade on steep surfaces.",
               "Without normal fade the decal also projects onto surfaces nearly parallel to it.", renderers=RD)
    documented("lightmap_directional", "Directional lightmaps add shader work", "gi", "LightmapGI",
               "This has a small run-time performance cost as the shader has to perform more work to interpret the direction information from the lightmap.",
               "A baked LightmapGI has directional enabled.",
               "Rebake without directional where normal-mapped detail under baked light is not needed.",
               "Normal maps react less to baked light, and rough baked reflections are lost.")
    documented("parallax_layers", "Deep parallax uses more layers than the default", "materials", "BaseMaterial3D",
               "Higher values have a significant cost on the GPU, so it should only be increased on materials where it makes a significant visual difference.",
               "An effective BaseMaterial3D uses deep parallax with heightmap_max_layers above 32 or heightmap_min_layers above 8 (the defaults).",
               "Return heightmap_max_layers/min_layers toward 32/8 unless steep height changes visibly need more.",
               "Steep height changes show more layering artifacts up close.")
    documented("multimesh_custom_aabb", "A large MultiMesh has no custom AABB", "geometry", "MultiMesh",
               "Setting this manually prevents costly runtime AABB recalculations.",
               "A visible MultiMeshInstance3D holds at least 4096 instances and its MultiMesh has no custom_aabb, so every instance change recomputes the bounds. Whether instances change at runtime is not observed.",
               "Set MultiMesh.custom_aabb to bounds that cover all instances, especially when scripts update instance transforms.",
               "A custom AABB that is too small culls instances incorrectly; keep it conservative.")
    documented("trail_mesh_detail", "A particle trail mesh uses more segments than the default", "particles", "TubeTrailMesh",
               "Higher values result in a more detailed tube at the cost of performance.",
               "A trail-enabled GPUParticles3D draws a RibbonTrailMesh with section_segments above 3, or a TubeTrailMesh with radial_steps above 8 or section_rings above 3 (the defaults); every particle draws that geometry.",
               "Return the trail mesh's segment counts toward the defaults unless the curve visibly needs them.",
               "Trails look more faceted or less smooth along fast curves.", renderers=RD)
    documented("occluder_dense", "An occluder has many triangles or points", "geometry", "OccluderInstance3D",
               "The occluder geometry is rendered on the CPU, so it is important to keep its geometry as simple as possible.",
               "An OccluderInstance3D uses an ArrayOccluder3D with more than 10,000 triangles or a PolygonOccluder3D with more than 64 points.",
               "Rebake with a higher bake_simplification_distance, or use fewer, simpler occluder shapes.",
               "Simpler occluders cull less precisely.")
    documented("label3d_font_size", "A Label3D renders a large dynamic font size", "ui", "Label3D",
               "Higher font sizes require more time to render new characters, which can cause stuttering during gameplay.",
               "A visible Label3D with text uses font_size above 64 with a non-MSDF font, so each new glyph is rasterized at that size.",
               "Lower font_size and raise pixel_size, or use an MSDF font for large 3D text.",
               "Smaller rasterized text looks softer up close.")
    documented("tilemap_kinematic", "A TileMap syncs its collisions as kinematic bodies", "physics", "TileMap",
               "Enabling may have a small performance impact, only do it if the TileMap is moving and has colliding tiles.",
               "A TileMap enables collision_animatable.",
               "Disable collision_animatable unless the TileMap moves and other bodies collide with it.",
               "Moving TileMap platforms need it to carry bodies correctly.")

    perf("hidden_video", "A hidden video player can keep decoding frames", "ui",
         "A hidden in-tree VideoStreamPlayer has a recognized, unscripted native Theora stream and a nonempty video texture. It is unpaused and can_process() is true, including inherited process and tree-pause state. In a running game, playback and internal processing must both be active; in the editor, autoplay is a configuration candidate only. Both verified native players update playback independently of visibility, and Theora decodes, converts and uploads new frames. Stopped runtime playback, detached nodes, custom streams and zero playback speed/time scale where the player supports scaling are excluded. This does not measure decoder cost or prove the texture is unused elsewhere.",
         "If this hidden video is not needed for audio, timing or another consumer of get_video_texture(), pause playback while it is hidden and compare CPU/frame timing during that interval.",
         "Pausing also pauses audio and playback position. Another node or shader may still display the video texture, and gameplay may depend on its timing; keep playback active when needed.", "scene/gui/video_stream_player.cpp",
         verify="Compare the same hidden-video interval before and after explicitly pausing the player, checking audio, playback position and every consumer of its video texture while measuring CPU/frame timing.")

    audio_verify = "Compare the same active audio mix on target hardware, listening for quality changes and underruns while measuring CPU/frame timing. Runtime code may replace the editor's bus layout."
    perf("reverb_dry_only", "A dry-only reverb still processes its filter network", "audio",
         "An enabled native AudioEffectReverb on a non-bypassed current audio bus has wet exactly 0 and dry exactly 1. Both checked versions call the reverb processor for each stereo channel, and its comb/all-pass loops run before the final wet/dry mix. There is no zero-wet bypass in that path. Bus activity is unknown; scripted/custom effects are skipped. This is a configured processing candidate, not measured CPU cost.",
         "Compare bypassing this effect if the wet mix stays zero and later automation does not need the reverb's warmed tail.",
         "Bypassing stops updating delay/filter history. Re-enabling later can change the tail or transients; preserve intentionally warmed effects and verify the complete mix.",
         "servers/audio/effects/reverb_filter.cpp", verify=audio_verify)
    perf("stereo_neutral", "A neutral stereo-enhancement effect still processes samples", "audio",
         "An enabled native AudioEffectStereoEnhance on a non-bypassed current audio bus has pan_pullout exactly 1, time_pullout_ms exactly 0 and surround exactly 0. The source still computes center/side channels and writes and reads the delay ring for every sample. These settings request no stereo enhancement; this does not assert bit-identical floating-point output or prove that the bus is active. Scripted/custom effects are skipped.",
         "Compare bypassing this effect when these neutral settings stay fixed throughout the workload.",
         "Runtime pan/delay/surround automation may need the effect and its delay history. Bypass can change floating-point rounding and later transients; listen to the full mix.",
         "servers/audio/effects/audio_effect_stereo_enhance.cpp", verify=audio_verify)
    perf("eq_many_bands", "An audio equalizer processes more than ten bands", "audio",
         "An enabled native AudioEffectEQ6/EQ10/EQ21 on a non-bypassed current audio bus reports more than ten bands. The native EQ loop processes every band for both channels on every sample, including bands whose gain is 0 dB. The cutoff distinguishes the 21-band resource from the 6/10-band alternatives; it is a review heuristic, not a device limit. Flat gains are not assumed to make the filter bank an identity operation. Bus activity and actual CPU cost are unknown; scripted/custom effects are skipped.",
         "Compare EQ6 or EQ10 where the mix does not need 21 separately adjustable bands, retuning the replacement by ear or against an audio reference.",
         "Fewer bands change frequency resolution and filter response. Do not copy gain numbers between different band layouts or assume a flat EQ is equivalent to bypass.",
         "servers/audio/effects/audio_effect_eq.cpp", verify=audio_verify)
    perf("spectrum_history", "A spectrum analyzer is configured with more than four seconds of history", "audio",
         "A native AudioEffectSpectrumAnalyzer on the current audio layout has a finite buffer_length above four seconds. AudioServer creates effect instances independently of bypass/enable state; disabling an effect or bypassing its bus does not release this history, so those states remain eligible. Instantiation allocates floor(buffer_length / (fft_size / mix_rate)) + 1 history arrays, each holding fft_size stereo AudioFrame values. This history grows roughly with duration and mix rate; a longer history does not by itself increase the FFT execution rate. Four seconds is a review cutoff matching the inspector range, not a native limit. Existing instances retain the history allocated at creation; this rule describes resource configuration. Scripted/custom effects are skipped.",
         "Compare the default two seconds or the shortest history that preserves the application's spectrum queries and audio/display latency tolerance, then recreate or reload the effect.",
         "Shorter history can remove spectra needed by delayed visualization or analysis. Changing the resource alone does not resize an existing instance; verify the consumer after recreation.",
         "servers/audio/effects/audio_effect_spectrum_analyzer.cpp",
         verify="Recreate/reload the configured analyzer, compare process memory under the same mix, and verify spectrum queries and display timing. Do not infer a CPU or frame-time saving from history duration alone. Runtime code may replace the editor's audio layout.")
    perf("pitch_shift_oversampling", "A pitch-shift effect increases FFT oversampling", "audio",
         "An enabled native AudioEffectPitchShift on a non-bypassed current audio bus has a non-unity pitch scale and oversampling above its default of 4. The source shortens the FFT hop as oversampling increases; Godot documents the higher CPU demand. Unity pitch bypasses this work and is excluded. Zero-hop configurations receive a separate correctness finding. This is a configured processing path, not proof the bus is receiving audio or causing frame-time cost. Scripted/custom effects are skipped.",
         "Compare the default oversampling of 4 or the lowest value that preserves acceptable pitch-shift quality under the intended mix.",
         "Lower oversampling can add pitch-shift artifacts. Preserve automated pitch/quality changes and test during the loudest or busiest mix.",
         "servers/audio/effects/audio_effect_pitch_shift.cpp", verify=audio_verify)
    perf("chorus_voices", "A chorus effect processes more than two voices", "audio",
         "An enabled native AudioEffectChorus on a non-bypassed current audio bus requests a nonzero wet mix and more than two voices with nonzero cutoff. Each such voice enters its own sample-processing loop. A zero cutoff skips that voice in both checked versions and is excluded. Two voices is the resource default, not a hardware limit; current configuration does not prove audible processing or measured cost.",
         "Compare two chorus voices or fewer on buses where the extra modulation is not audible in the complete mix.",
         "Reducing voices changes modulation, stereo width and texture. Preserve intentional layering and any runtime voice automation.",
         "servers/audio/effects/audio_effect_chorus.cpp", verify=audio_verify)
    perf("chorus_dry_only", "A dry-only chorus still has voice processing configured", "audio",
         "An enabled native AudioEffectChorus on a non-bypassed current audio bus has wet exactly 0, dry exactly 1 and at least one voice with nonzero cutoff. The native voice loop still runs when wet is zero, even though no wet contribution is requested. Bus activity is unknown; this is a measurement candidate. Scripted/custom effects are skipped.",
         "Compare bypassing this effect if the wet mix remains zero throughout the workload. Keep it active when upcoming automation needs its warmed delay/filter history.",
         "Bypassing freezes the chorus history and phase; enabling it later can change transients. Do not remove an intentionally warmed effect used by future automation.",
         "servers/audio/effects/audio_effect_chorus.cpp", verify=audio_verify)
    add(dict(id="scene_validation.audio_pitch_zero_hop", category="scene_validation",
             title="A pitch-shift effect is configured with a zero FFT hop", kind="correctness", severity="medium", heuristic=False,
             renderers=ALL, versions=["4.4", "4.7"], requires=["scene"],
             condition={"scene_gte": {"name": "check_audio_pitch_zero_hop", "value": 1}}, offender_key="check_audio_pitch_zero_hop",
             evidence="An enabled native AudioEffectPitchShift on a non-bypassed current audio bus has non-unity pitch and oversampling greater than its configured FFT frame size (256/512/1024/2048/4096). Native instantiation captures that size; integer frame_size/oversampling then yields a zero hop, so the output FIFO fill loop has no iterations. This describes the resource configuration when instantiated; existing instances may retain an earlier FFT size, and inactive buses may not process audio. Scripted/custom effects are skipped.",
             suggestion="Use oversampling no greater than the selected FFT frame size, normally starting with the default 4. Recreate/reload the effect after changing FFT size and test the intended pitch shift.",
             tradeoff="Changing oversampling or FFT size affects quality and latency. Preserve runtime automation and listen for startup artifacts when recreating the effect.",
             expected_effect="Restore a positive FFT hop when the configured effect is instantiated; no frame-time saving is asserted.",
             verify_step=audio_verify, source="https://github.com/godotengine/godot/blob/4.4-stable/servers/audio/effects/audio_effect_pitch_shift.cpp", evidence_kind="godot_configuration"))

    tilemap = "scene/2d/tile_map_layer.cpp"
    perf("tilemap_occluders", "A TileMapLayer creates many per-cell light occluders", "canvas",
         "An enabled, locally visible TileMapLayer with occlusion_enabled has more than 256 inspected atlas-cell occluder polygons on layers with nonzero light masks or SDF collision enabled. Closed polygons require at least three points; open polygons require two. The native path creates a separate occluder for each cell/layer/polygon. This object-count cutoff is a review heuristic, not proof of active shadow or SDF cost. Runtime tile-data overrides and invalid references are skipped; cell and resource limits are reported.",
         "Compare consolidated static occluder outlines, or disable tile occlusion where neither 2D shadows nor SDF collision need it. Measure canvas CPU/GPU time while moving lights and editing tiles.",
         "Changing outlines or disabling occlusion changes 2D shadows and SDF-based effects or particle collision. Preserve holes, light masks, moving tiles and dynamic updates.", tilemap)
    perf("tilemap_animation_slices", "Animated tiles record many canvas animation slices", "canvas",
         "An enabled, locally visible TileMapLayer has more than 4096 authored animation frames summed across inspected texture-assigned atlas cells with more than one frame. The native draw path records an animation slice and texture-region command for every authored frame, plus a reset slice. This counts configured command construction, not simultaneous GPU draws; inactive slices do not draw every frame. The threshold is a measurement heuristic. Runtime tile-data overrides and uninspected cells are not inferred.",
         "Compare fewer authored animation frames or fewer animated background cells, measuring both canvas frame time and tile-edit/rebuild spikes along the same camera route.",
         "Fewer frames reduce animation smoothness; static replacements remove motion. Lowering playback speed alone does not reduce the recorded frame commands.", tilemap)
    perf("tilemap_small_quadrants", "A populated TileMapLayer uses small rendering quadrants", "canvas",
         "An enabled, locally visible TileMapLayer without Y sorting has rendering_quadrant_size at most 4 and more than 256 inspected atlas cells with assigned textures. Native rendering groups cells into quadrants, then canvas items. The cutoff is a measurement heuristic; tile count is not draw-call count. Scene-collection cells, invalid references and runtime tile-data overrides are skipped. At most 4096 cells per scene scan and 32 data layers and 32 collision/occlusion polygons per layer per tile are inspected; omissions are reported.",
         "Compare the default rendering quadrant size of 16, profiling canvas work along the same camera route and during tile edits.",
         "Larger quadrants reduce culling/update granularity and may rebuild more content after an edit. Retain small quadrants where measurements favor them.", tilemap)
    perf("tilemap_y_sort_groups", "A Y-sorted TileMapLayer creates many rendering groups", "canvas",
         "An enabled, locally visible TileMapLayer uses Y sorting with more than 256 inspected texture-assigned atlas cells across more than 64 Y-position buckets. Buckets follow the checked native formula: int((map_to_local(cell).y + tile y_sort_origin + layer y_sort_origin) * 100). Y sorting uses these groups instead of rendering_quadrant_size. Group count does not prove visible draw calls or cost. Runtime tile-data overrides are skipped and scan omissions are reported.",
         "Compare separating flat floor/background tiles into a layer without Y sorting while keeping overlap-sensitive tiles on the sorted layer.",
         "Disabling sorting can break character/prop overlap and visual order. Preserve per-tile origins and verify movement through the scene.", tilemap)
    perf("tilemap_navigation_regions", "A TileMapLayer creates many per-cell navigation regions", "navigation",
         "An enabled TileMapLayer with navigation_enabled has more than 256 inspected cell/layer navigation polygons containing baked polygons or outlines and nonzero navigation layers. Both native versions create a region per qualifying cell and navigation layer. This is an object-count review cutoff, not a measured pathfinding or map-synchronization cost. Runtime tile-data overrides and scene-collection sources are skipped; resource/cell inspection limits are reported.",
         "For a mostly static level, compare a consolidated NavigationRegion2D bake and disable per-cell navigation only after the replacement preserves valid paths.",
         "Baking changes update granularity, connectivity and layer handling. Preserve doors, streaming and dynamic edits, and avoid overlapping old and replacement regions.", tilemap)
    perf("tilemap_physics_chunking", "A populated TileMapLayer disables physics chunking", "physics",
         "On verified Godot 4.7, an enabled TileMapLayer with collision_enabled uses physics_quadrant_size 1 and more than 256 inspected atlas cells have collision polygons with at least three points on layers with nonzero collision layer/mask bits. Native quadrant updates merge polygons with matching physics properties; size 1 disables cross-cell chunking. Godot 4.4 has no such public property and is excluded. Runtime tile-data overrides and inspection omissions are not guessed.",
         "If exact per-cell body identification is unnecessary, compare the default physics quadrant size of 16 and measure physics processing and tile-edit spikes.",
         "Larger quadrants make get_coords_for_body_rid less precise and change rebuild granularity. Keep size 1 when gameplay depends on identifying the exact collision cell.", tilemap, versions=("4.5", "4.7"))
    perf("gridmap_small_octants", "A populated GridMap uses very small rendering octants", "geometry",
         "A visible, unbaked GridMap sets cell_octant_size to 1 or 2 and more than 256 inspected cells refer to library items with recognized native meshes containing at least one surface. Custom mesh classes and empty meshes are skipped. Both native versions create a MultiMesh/render instance for each occupied item/octant combination. The cutoff is a review heuristic, not a measured batch count. Baked meshes use a different path and are excluded. At most 4096 cells across qualifying GridMaps are inspected; skipped cells are reported, and the public cell-list getter still returns its full list.",
         "Compare the default octant size of 8 or a size that fits the level, then measure draw calls and frame time along the same camera route.",
         "Larger octants reduce culling granularity and can draw more offscreen geometry. Small octants can be the right choice for sparse or frequently edited maps.", "modules/gridmap/grid_map.cpp")
    perf("gridmap_navigation_regions", "A GridMap creates many per-cell navigation regions", "navigation",
         "A GridMap with bake_navigation enabled has more than 256 inspected cells referencing nonempty item navigation meshes with nonzero navigation layers. Native octant updates create a NavigationServer3D region per qualifying cell. The cutoff is a review heuristic; map synchronization and path cost are not measured. At most 4096 cells across qualifying GridMaps are inspected and omitted cells are reported.",
         "For static levels, compare baking a consolidated NavigationRegion3D from the level geometry, then disable per-cell GridMap navigation only after the replacement works.",
         "Consolidation changes bake/update granularity, navigation layers and region boundaries. Preserve dynamic doors, streaming and path connectivity, and avoid overlapping old and replacement navigation.", "modules/gridmap/grid_map.cpp")
    perf("character_slide_budget", "A character body permits extra slide iterations", "physics",
         "A CharacterBody2D/3D with an enabled collision shape, nonzero collision mask and a process mode other than disabled raises max_slides above its default of 4 in 2D or 6 in 3D. Native grounded and floating movement repeat move_and_collide up to this limit. Actual work depends on calling move_and_slide and on the contacts encountered; a raised limit alone does not consume all iterations.",
         "Profile move_and_slide in collision-heavy movement and compare the default limit where gameplay permits.", "A smaller limit can change movement in corners, on slopes or among moving platforms. Test movement correctness before keeping it.", "scene/3d/physics/character_body_3d.cpp")
    perf("softbody_precision", "A soft body requests additional solver iterations", "physics",
         "A SoftBody3D with a mesh surface requests simulation_precision above its default 5 and is not explicitly disabled with remove mode. Godot Physics repeats its link solver iteration_count times; Jolt maps the same setting to its iteration count. Mesh complexity and activity determine actual cost, and the scanner does not claim the two backends have identical work per iteration.",
         "Compare a lower simulation precision while profiling physics with this soft body active.", "Fewer iterations can make cloth or other deformable bodies less stable and less accurate. Inspect deformation and collisions under stress.", "modules/godot_physics_3d/godot_soft_body_3d.cpp")
    perf("shape_cast_results", "A ShapeCast permits more contact queries per update", "physics",
         "An enabled ShapeCast2D/3D with a shape, a nonzero collision mask and an enabled collision target permits more than the default 32 results. Native shape casts repeatedly call rest_info, excluding each hit, until no further hit is found or max_results is reached. The limit permits extra work; it does not prove that enough objects are hit to use it. Unsupported concave 3D shapes are excluded.",
         "Profile shape-cast updates in dense collision scenes and compare a smaller result limit if gameplay needs only a few contacts.", "Reducing the limit omits contacts and can change gameplay. Keep enough results for the worst case the game must handle.", "scene/3d/physics/shape_cast_3d.cpp")
    perf("viewport_shadow_atlas", "A SubViewport requests a larger or deeper shadow atlas", "shadows",
         "An update-enabled 3D SubViewport requests a positional shadow atlas above its default 2048 size or disables its default 16-bit depth mode. The RD renderer allocates atlas width and height from this size and selects D16 or D32. Allocation and rendering depend on actual shadow use; this is not a measured VRAM value.",
         "Compare the default atlas size and 16-bit mode one at a time while checking omni/spot shadows in this viewport.", "Smaller atlases reduce shadow detail; 16-bit depth may introduce shadow acne or precision artifacts.", "servers/rendering/renderer_rd/storage_rd/light_storage.cpp", renderers=RD)
    perf("viewport_msaa_fxaa", "A SubViewport combines MSAA with FXAA", "antialiasing",
         "An update-enabled 3D SubViewport enables both MSAA and FXAA. The native RD post-process selects FXAA independently of the MSAA setting; their costs can combine. The methods target different aliasing, so combining them is not automatically wrong.",
         "Compare each method on its own in this viewport, measuring GPU time and inspecting both geometry edges and specular shimmer.", "Removing MSAA can worsen geometric edges; removing FXAA can expose shader aliasing. FXAA can also soften fine detail.", "servers/rendering/renderer_rd/renderer_scene_render_rd.cpp", renderers=RD)
    perf("noise_texture_startup", "A procedural noise texture has a large generation workload", "textures",
         "An observed NoiseTexture2D/3D with an assigned generator contains at least 1048576 configured texels. Native texture updates explicitly run the first update without a worker thread; later updates can use workers. Resource lifecycle determines whether that first update already had its generator. The scanner reads dimensions only and never generates or downloads the texture.",
         "For static noise, compare a pre-generated imported texture; otherwise prepare it during a loading phase and measure startup or regeneration spikes.", "Stored textures trade disk/package size against runtime generation and must preserve dimensions, wrapping, color space and normal-map interpretation. Keep generation when procedural variation is required.", "modules/noise/noise_texture_2d.cpp", verify="Measure scene-load/first-use time and peak frame timing after changing the noise resource; compare the visual output and resulting texture memory.")
    perf("noise_texture_octaves", "A noise texture samples more fractal layers than the default", "textures",
         "An observed noise texture of at least 65536 texels uses FastNoiseLite with active ordinary fractal octaves above five, or enabled fractal domain warp above five. The wrapper forwards octave counts and the native implementation loops over them per sample. Disabled fractal/warp modes are excluded; these are generation costs, not continuous fragment-shader costs.",
         "Compare fewer noise or warp octaves while keeping the detail needed at the displayed scale; profile regeneration, especially during loading.", "Fine structure or warping can change. Reducing texture dimensions changes a different quality setting and should be tested separately.", "modules/noise/fastnoise_lite.cpp", verify="Compare generation or loading time for the same dimensions and generator seed, then inspect the texture at its intended scale.")

    perf("primitive_density", "A procedural primitive requests dense geometry", "geometry",
         "A MeshInstance2D/3D uses a PlaneMesh, BoxMesh, SphereMesh, CylinderMesh, CapsuleMesh or TorusMesh whose native subdivision loops generate at least 8192 vertices. The estimate uses only stored segment counts; cylinder caps are omitted, making it a lower bound. No mesh generation or GPU buffer download is requested by this check. 8192 is a review cutoff, not an engine limit.",
         "Compare fewer subdivisions at the intended viewing distance, retaining enough vertices for displacement and deformation.", "Silhouettes, curved lighting and displaced surfaces may become faceted. Primitive generation is cached; rendering cost depends on submitted geometry and visibility.", "scene/resources/3d/primitive_meshes.cpp")
    perf("path_dense_cache", "A path requests a very fine baked-point cache", "memory",
         "A Path2D/3D has at least two control points and a positive bake_interval below 1 pixel in 2D or 0.05 metres in 3D. Defaults are 5 pixels and 0.2 metres. Smaller intervals increase cached samples and rebuild work when the cache is used. The scanner reads the interval and control-point count without baking or measuring path length.",
         "Compare a coarser bake interval while moving followers along tight curves, then inspect cache memory and rebuild spikes after path edits.", "Followers can lose positional or orientation accuracy. Actual memory depends on curve length; an unchanged cache is not rebuilt each frame.", "scene/resources/curve.cpp")
    perf("navigation_polygons", "A navigation region contains a large polygon graph", "navigation",
         "An enabled NavigationRegion3D with nonzero navigation layers has more than 8192 baked navigation polygons. Native path queries search polygon connections; polygon count bounds graph size but is not the number visited by each query. This reads stored polygon count without rebaking the mesh. The cutoff is heuristic.",
         "Profile long and unreachable path requests, then simplify unnecessary navigation geometry on flat areas while preserving routes and agent clearance.", "Coarser navigation geometry can remove narrow routes or change paths. Splitting into regions without reducing polygons does not automatically reduce query work.", "modules/navigation/3d/nav_mesh_queries_3d.cpp")

    perf("font_msdf_size", "A text node uses an enlarged MSDF glyph cache", "ui",
         "A Label, Button or explicitly font-assigned Label3D uses a FontFile with source data, MSDF enabled and msdf_size above its default 48. Native glyph caches use this source size; larger values increase generation work and memory. Up to eight explicit FontVariation base links are followed; fallback glyph fonts are not inferred.",
         "Compare the default MSDF source size where glyph detail remains adequate; measure first-use text generation and font memory as well as appearance.", "Fine glyph details or large text can lose precision. Preserve the required outline pixel range and do not switch off MSDF merely to reduce this size.", "doc/classes/FontFile.xml")
    perf("font_subpixel_large", "Large text forces subpixel glyph variants", "ui",
         "An observed dynamic non-MSDF FontFile forces half- or quarter-pixel positioning and the text node requests a font size above 20. In both checked versions AUTO stops subpixel variants above 20 pixels; 4.7 stores that size in 1/64 units internally. Actual raster size can also depend on scaling, so this is a review candidate.",
         "Compare AUTO subpixel positioning at the actual viewport scale, checking text sharpness and first-use cache generation.", "Kerning and small text sharpness may change. Cached glyphs do not necessarily cost fresh rasterization every frame.", "modules/text_server_adv/text_server_adv.cpp")
    perf("font_local_mipmaps", "An observed font resource generates mipmaps", "ui",
         "A Label, Button or explicitly font-assigned Label3D resolves to a FontFile with source data and generate_mipmaps enabled. Native atlas upload generates the mip chain when dirty. This inspects the actual font override, independently of the project's default-font setting.",
         "Compare disabling mipmaps for fonts displayed at a stable native size with no minification; retain them for shrinking or distant text.", "Removing mipmaps can cause shimmering or grainy minified text and may increase sampling cost. Profile atlas updates and memory, not only unchanged cached text.", "modules/text_server_adv/text_server_adv.cpp")
    perf("spring_bone_collision_pairs", "A spring-bone simulator declares many joint/collider pairs", "physics",
         "A live active unscripted SpringBoneSimulator3D has a direct unscripted Skeleton3D parent with bones, can_process() true and an enabled internal idle/physics tick. Across the first 128 settings, configured joint counts times verified eligible unscripted direct SpringBoneCollision3D children exceed 128. Only the first 128 children and collision paths are inspected. Allow lists deduplicate verified direct references; full child lists remove resolved exclusions. Settings with more than 128 exclusions are skipped. Both native versions loop over colliders for every initialized joint. This is a configured workload indicator: joints without Verlet state and other initialization/processing early-outs can reduce actual calls, so it is not a measured collision count or CPU cost. The 128-pair threshold is heuristic; inactive, paused, detached, scripted and empty cases are excluded. The audit never initializes joints, rebuilds native collision caches, clears paths or runs collision callbacks.",
         "Compare restricting each chain's collision list to relevant nearby colliders, reducing decorative joints/colliders, or deactivating unused simulation. Profile skeleton/physics CPU work during the same animation, then verify contact and motion.",
         "Removing colliders or joints changes secondary motion and contact. Keep gameplay-relevant contacts; configuration alone does not establish measured cost.", "scene/3d/spring_bone_simulator_3d.cpp")
    perf("skeleton2d_zero_strength", "A zero-strength 2D skeleton stack still dispatches native modifiers", "cpu",
         "An in-tree unscripted Skeleton2D can process and owns a setup, enabled, unscripted SkeletonModificationStack2D with strength exactly zero. One of the first 128 modifications is an enabled unscripted native TwoBoneIK, LookAt, Jiggle, CCDIK or FABRIK modification whose execution mode has the corresponding internal idle or physics tick enabled. Both checked stacks dispatch matching modifications without a strength early-out. All five reviewed native implementations use strength in pose-override writes after their configured work. Invalid cached targets or bones and empty chains may return early, so dispatch is not proof of a successful solve or measured CPU cost. Detached, disabled, paused, uninitialized, shared-with-another-skeleton, scripted and unrecognized native classes are excluded. Offenders identify the modification index and native class. The audit reads native getters and never executes a stack or solver. Bone-count queries are avoided because they can rebuild caches and emit bone_setup_changed.",
         "When these modifiers should remain unused, compare disabling the stack or unused modifications. Zero strength suppresses pose blending but is not a processing-off switch. Measure skeleton/animation CPU work during the intended zero-strength interval.",
         "Keep IK transitions and other stack modifications working. Disabling a stack does not remove all Skeleton2D per-bone bookkeeping; disabling stateful work such as Jiggle can change its next visible result. Custom modification semantics are not inferred.", "scene/resources/2d/skeleton/skeleton_modification_stack_2d.cpp")
    perf("skeleton2d_jiggle_colliders", "A native 2D Jiggle chain requests many collision rays", "physics",
         "One of the first 128 modifications in a live, setup, owned, enabled, unscripted Skeleton2D stack is an enabled unscripted native SkeletonModification2DJiggle with use_colliders true, nonzero collision_mask, physics execution mode, an enabled internal physics tick and more than 16 configured joints. Each joint that reaches the reviewed native collision branch performs a PhysicsDirectSpaceState2D intersect_ray query. The 16-joint threshold is a review heuristic, not a Godot budget. Invalid targets or joint caches can return early, so the configured joint count is not a measured ray count or CPU cost. Strength zero does not bypass this work. Paused, detached, disabled, scripted and unrecognized native cases are excluded; the audit does not run physics queries or modifiers.",
         "For decorative chains, compare disabling collision where contact is unnecessary, reducing the joint chain while preserving its motion, or narrowing collision_mask. Measure physics CPU work during the same animation and camera route.",
         "Removing collision or joints changes how bones react to obstacles; a narrower mask must retain relevant gameplay surfaces. Keep collisions that are necessary for the intended motion.", "scene/resources/2d/skeleton/skeleton_modification_2d_jiggle.cpp")
    check("skeleton2d_jiggle_collision_mode", "A native 2D Jiggle modifier requests collision in idle mode", "scene/resources/2d/skeleton/skeleton_modification_2d_jiggle.cpp",
          "One of the first 128 modifications in a live, setup, owned, enabled, unscripted Skeleton2D stack is an enabled unscripted native SkeletonModification2DJiggle with at least one configured joint, use_colliders true, idle execution mode and an enabled internal idle tick. Both checked native implementations skip intersect_ray and issue a once-only warning when such a joint reaches the collider branch. Invalid targets or joint caches may return early; this reports the configured mode conflict, not a captured warning. Detached, paused, disabled, empty-chain and scripted cases are excluded. The audit never executes a modifier or physics query.",
          "Set the modification to physics_process if collisions are intended, or disable use_colliders when collision is unnecessary. Verify skeletal motion after changing the update clock.")
    perf("skeleton_zero_influence", "An active skeleton modifier has zero pose influence", "cpu",
         "An in-tree unscripted SkeletonModifier3D is active with influence exactly zero. Its direct Skeleton3D parent has bones, can_process() is true and internal idle or physics processing is enabled. Both checked skeletons still enter the partial-influence modifier path; zero influence does not bypass the modifier dispatch. Godot 4.4 copies old/new bone poses and 4.7 iterates applied-pose state. A native modifier may have its own early-out, so this does not assert a particular IK/physics solve or measured CPU cost. Detached, empty, inactive, scripted and manually advanced/nonprocessing skeletons are excluded.",
         "If a modifier should remain unused, compare deactivating its processing body; for a permanently unused modifier, consider removing it after checking dependencies. Simply setting influence to zero is not a processing-off switch. Profile skeleton/animation CPU work during the intended zero-influence interval.",
         "Processing can maintain simulation state and emit modification_processed signals even with no pose contribution. Preserve physics, IK transitions, signal consumers and runtime activation. Deactivation does not remove all parent pose bookkeeping, and disabling a stateful modifier can change the next visible pose.", "scene/3d/skeleton_3d.cpp")
    perf("font_oversampling", "A canvas text font overrides oversampling above 2", "ui",
         "A nonempty Label or Button resolves through at most eight native FontVariation links to an unscripted FontFile with source data, MSDF disabled, fixed_size zero and a finite oversampling override above 2. Godot 4.4 scales the glyph raster size inside its cache; 4.7 requests a larger size cache during canvas drawing. Larger outline glyphs can increase first-use raster work and atlas memory; embedded color bitmap strikes can behave differently. The threshold is a review heuristic, not a measured cost. Label3D, system/fallback glyph selection, scripted fonts and automatic viewport oversampling are not inferred.",
         "Compare a smaller explicit font oversampling override at the intended display scale. Measure first-use text rendering and font memory, and inspect small text and outlines before keeping the change. Zero restores automatic oversampling and does not necessarily reduce it.",
         "Lower oversampling can blur or distort text, especially with viewport scaling or high-density displays. Cached text need not rerasterize every frame, and a configured primary font may not supply every displayed glyph.", "modules/text_server_adv/text_server_adv.cpp")
    perf("textmesh_detail", "A TextMesh requests dense glyph geometry", "geometry",
         "A MeshInstance2D/3D assigns a nonblank TextMesh with curve_step below 0.5 or font_size above 63. Native curve subdivision uses curve_step divided by curve length; contours are obtained at font_size. Generated glyph geometry is cached and rebuilt on relevant changes, not automatically every frame. The cutoffs are review heuristics.",
         "Compare the default curve step and a smaller font size while preserving apparent size. For animated size changes, scale the node instead of regenerating mesh settings.", "Curves can become faceted. Changing font_size or pixel_size regenerates geometry; node scaling also scales extrusion depth.", "scene/resources/3d/primitive_meshes.cpp")
    perf("panel_corner_detail", "A rounded panel uses high corner geometry detail", "ui",
         "A visible Panel or PanelContainer uses an effective native, unscripted StyleBoxFlat with corner_detail above the default 8, nonnegative border/radius settings with at least one positive corner radius, and an enabled nontransparent fill, border or shadow. The expanded rectangle must be finite, not approximately zero-sized, and larger in both dimensions than twice its largest border width, excluding degenerate or border-filled cases where native radius adaptation can remove rounding. Both versions build more vertices per rounded fill/ring as corner_detail increases; borders, shadows and antialiasing can add rings. The threshold is a review heuristic, not evidence of a frame-time bottleneck. Canvas geometry is cached between redraws; no per-frame CPU rebuild is claimed.",
         "Compare corner_detail 8 or a lower visually acceptable value on these panels, checking corner smoothness at the actual UI scale and measuring canvas cost and redraw-heavy UI updates.",
         "Lower detail can make large or magnified corners visibly angular. Retain the current value when the visual benefit matters; a small number of panels may have negligible cost.", "scene/resources/style_box_flat.cpp")

    perf("label_effect_passes", "A long Label draws both outline and shadow passes", "ui",
         "A Label with at least 128 text characters and visible_characters not zero enables both a visible outline and visible shadow. Native drawing processes separate shadow, outline and fill steps; a shadow outline can add more work. LabelSettings overrides take precedence. Character count is not a visible-glyph or draw-call count.",
         "Compare using only the outline or only the shadow for long UI text, and measure canvas rendering while checking readability.", "Text contrast and legibility can suffer; keep both effects where they are required. Wrapping, clipping and visible-character limits may reduce actual work.", "scene/gui/label.cpp")
    perf("compositor_msaa_resolve", "A custom compositor requests an intermediate MSAA resolve", "post",
         "The active camera/world compositor has an enabled pre-opaque, post-opaque or pre-transparent effect requesting resolved color or depth while its live viewport enables 3D MSAA. Forward+ tests those stage flags before resolving. Post-sky and post-transparent stages are excluded from this extra-resolve claim; shared resolves are not counted individually.",
         "Review the effect callback: remove a resolved-buffer request only when it does not read that buffer, or restructure compatible effects to share a rendering stage.", "An effect that samples an unresolved or stale buffer can render incorrectly. Rendering order is part of the effect's behavior; do not disable requirements blindly.", "servers/rendering/renderer_rd/forward_clustered/render_forward_clustered.cpp", renderers=["forward_plus"])
    perf("compositor_motion", "A custom compositor requests motion-vector rendering", "post",
         "An enabled effect in the active live compositor requests motion vectors, while viewport TAA is off and scaling is bilinear or FSR1. Forward+ enables its motion-vector path for this request. Debug views or other consumers may still need those vectors; no frame-time saving is assumed.",
         "Verify that the effect consumes motion vectors; remove the request only after adapting the callback to work without them.", "Temporal effects and motion reconstruction can fail without velocity data.", "servers/rendering/renderer_rd/forward_clustered/render_forward_clustered.cpp", renderers=["forward_plus"])
    perf("compositor_extra_buffers", "A custom compositor requests auxiliary lighting buffers", "post",
         "An enabled effect in the active live compositor requests separate specular, or normal/roughness with a resolved Environment. Forward+ can select auxiliary render targets and a specular combine. Other rendering features may already require these buffers. Camera overrides, disabled viewport updates and disabled 3D are respected.",
         "Audit the callback's actual inputs and remove unused normal/roughness or separate-specular requirements, then profile the affected passes.", "Custom lighting and post effects may rely on these buffers. Removing an input flag without changing the consumer is not a valid optimization.", "servers/rendering/renderer_rd/forward_clustered/render_forward_clustered.cpp", renderers=["forward_plus"])

    perf("rigid_sleep_disabled", "A dynamic rigid body cannot automatically sleep", "physics",
         "An unfrozen RigidBody2D or RigidBody3D disables can_sleep. Sleeping bodies skip motion and force calculations until woken; disabling automatic sleep removes that opportunity when a body settles. This does not claim that a moving body could already be sleeping.",
         "Enable automatic sleeping where settled bodies need no continuous simulation, then compare the same settling scene and physics CPU time.", "Sleep/wake timing can affect custom force logic and interactions; keep continuous simulation where the gameplay requires it.", "doc/classes/RigidBody3D.xml")
    perf("rigid_contact_budget", "A rigid body allows a large contact-report list", "physics",
         "An unfrozen RigidBody2D or RigidBody3D enables contact monitoring with max_contacts_reported above 32, a heuristic review cutoff. Native monitoring builds temporary lists and walks actual reported contacts during state callbacks. The configured cap permits work but does not establish the actual contact count or cost; multiple contacts can belong to one collision.",
         "Profile crowded contact cases and compare a smaller report cap only if gameplay still receives every contact it needs.", "A lower cap can omit body or shape events and get_colliding_bodies entries. Keep enough reports for gameplay; collision response itself is separate from reporting.", "scene/3d/physics/rigid_body_3d.cpp")

    perf("line_round_precision", "A rounded Line2D exceeds the default arc precision", "canvas",
         "A visible Line2D has positive width, enough points for its rounded joints or enabled open caps, and round_precision above eight. LineBuilder uses this value to subdivide arcs into triangles. The threshold is the documented default, not a hardware budget.",
         "Compare the default precision on rounded lines, especially lines rebuilt frequently or displayed small.", "Corners and end caps can look more faceted; retain detail for large on-screen curves.", "scene/2d/line_builder.cpp")
    perf("gradient_hdr_size", "A large procedural gradient uses full-float pixels", "textures",
         "A built-in Sprite2D, Sprite3D or TextureRect texture is a GradientTexture2D with HDR enabled and at least 512 by 512 pixels in total. Native generation selects RGBAF rather than RGBA8: four times the base pixel bytes. The size cutoff is heuristic and does not measure GPU residency or regeneration frequency.",
         "Compare a smaller gradient, or disable HDR only when overbright colors and float precision are unnecessary.", "Lower resolution may reveal banding or interpolation artifacts; LDR clamps overbright colors and can change glow or precision.", "scene/resources/gradient_texture.cpp")
    perf("skin_eight_weights", "A live skinned mesh uses eight bone influences", "geometry",
         "An ArrayMesh surface with bone attributes uses the eight-weight format and resolves to a nonempty live Skeleton3D. The RD skinning shader loads and combines four additional influences in this format. Only stored surface metadata is read; weight buffers are not downloaded. Skinning updates can be cached when unchanged.",
         "For measured skinning bottlenecks, compare an asset limited to four normalized influences per vertex and inspect every animation.", "Reducing influences can deform joints or lose authored detail. This requires asset processing, not a safe automatic scene edit.", "servers/rendering/renderer_rd/shaders/skeleton.glsl", renderers=RD)

    perf("fog_sdfgi_inject", "Volumetric fog enables SDFGI sampling", "post",
         "An assigned Environment enables volumetric fog and SDFGI with GI injection above the native 0.0001 threshold. The fog renderer selects its SDFGI shader path when the SDFGI buffers are available. This does not infer VoxelGI, LightmapGI or SSIL contributions.",
         "Compare zero fog GI injection where bounced lighting contributes little to the intended fog appearance.", "Indirect illumination in fog changes; direct lighting is controlled separately.", "servers/rendering/renderer_rd/environment/fog.cpp", renderers=["forward_plus"])
    perf("light_volumetric_fog", "A light contributes to active volumetric fog", "lights",
         "A visible non-editor-only Light3D has positive light and volumetric-fog energy and resolves to an Environment with volumetric fog enabled. Godot documents that zero fog energy skips fog computation for that light. Live current-camera environment overrides are honored; unresolved detached environments are excluded.",
         "Compare zero volumetric-fog energy on lights whose contribution is unnecessary, especially many short-lived effect lights.", "Those lights no longer illuminate fog, which may remove important shafts or atmosphere.", "doc/classes/Light3D.xml", renderers=["forward_plus"])
    perf("light_shadow_blur", "Shadow blur exceeds the default", "shadows",
         "A visible non-editor-only Light3D enables shadows with shadow_blur above its default of 1.0. Godot documents possible performance impact at high values; the actual effect depends on the shadow filtering path and hardware.",
         "Compare a blur value near one while holding other shadow settings constant.", "Shadow edges may look sharper or reveal low-resolution artifacts.", "doc/classes/Light3D.xml", renderers=RD)
    perf("viewport_pick_sort", "A SubViewport sorts 2D physics mouse picks", "cpu",
         "A SubViewport enables physics object picking and its sorting option, with input enabled. The native point-query path sorts up to 64 picked shapes by z order and tree order. Cost depends on input activity and overlapping pickable objects; it is not a GPU rendering cost.",
         "Compare unsorted picking if the application does not depend on topmost-object ordering.", "Input recipients can arrive in a different order, changing interaction behavior.", "scene/main/viewport.cpp")
    perf("viewport_hdr2d", "A SubViewport uses a wide HDR canvas buffer", "memory",
         "An update-enabled SubViewport uses HDR 2D. The documented RGBA16 canvas target uses more bytes per pixel than an RGBA8 target. This applies to Forward+ in 4.4 and 4.5 and RD renderers from 4.6; Mobile's RGB10_A2 target in 4.4 and 4.5 is excluded from this wider-buffer claim.",
         "Compare disabling HDR 2D if this viewport needs neither HDR effects nor linear-space canvas compositing.", "Glow, gradients, color blending and texture use in 3D can change; preserve HDR where the visual result requires it.", "doc/classes/Viewport.xml", renderers=RD, renderers_by_version={"4.4": ["forward_plus"], "4.6": RD})
    perf("particle_sdf2d_quality", "2D particle collisions use an enlarged or high-resolution SDF", "particles",
         "A live GPUParticles2D uses built-in collision and its owning viewport has SDF scale above 50 percent or oversize above 120 percent. These exceed viewport defaults and increase the SDF workload when collision rendering uses it. Custom process shaders and unresolved detached viewports are excluded.",
         "Compare the default SDF scale/oversize while moving the camera and testing particle collisions at viewport edges.", "Coarser SDFs reduce precision; smaller coverage can lose offscreen colliders needed by approaching particles.", "doc/classes/Viewport.xml", renderers=RD)
    perf("mesh_cull_margin", "Mesh culling margin exceeds its largest stored bound dimension", "geometry",
         "An ArrayMesh instance has extra_cull_margin larger than the largest positive AABB dimension. Instance custom bounds take precedence over resource custom bounds and stored mesh bounds. The native culler grows bounds on every side by the margin; this scale-relative review threshold is heuristic.",
         "Inspect shader deformation and animation extents, then compare a tighter margin only if the expanded bound is unnecessary.", "A too-small margin makes displaced or animated geometry disappear; stored bounds may not cover every pose.", "servers/rendering/renderer_scene_cull.cpp")
    perf("animated_texture", "A sprite or texture control uses an actively animated texture resource", "textures",
         "Sprite2D, Sprite3D or TextureRect assigns an AnimatedTexture with multiple frames, nonzero speed and playback unpaused. Godot warns that this deprecated implementation is inefficient on modern renderers. Custom/parent canvas materials and 3D material overrides are excluded.",
         "For these node uses, compare AnimatedSprite2D/3D or explicit texture/frame animation while preserving playback timing and visual output.", "AnimatedTexture has no universal drop-in replacement for every resource use; replacing a sprite/control requires adapting scene or animation data.", "doc/classes/AnimatedTexture.xml")
    perf("sprite_opaque_prepass", "A 3D sprite or label requests an opaque alpha prepass", "canvas",
         "SpriteBase3D or Label3D uses ALPHA_CUT_OPAQUE_PREPASS without a material override. Both class references describe this mode as slower than alpha blending or discard because it first draws fully opaque pixels in the depth prepass.",
         "Compare alpha discard where hard cutouts are acceptable, or alpha blending where overlap sorting remains correct.", "Discard can harm antialiased text and translucent edges; blending can introduce sorting errors. Keep the prepass when correct appearance needs it.", "doc/classes/SpriteBase3D.xml")

    perf("material_orm_pack", "Separate metallic and roughness maps can share a packed texture", "materials",
         "An effective per-pixel StandardMaterial3D has metallic and roughness textures with nonzero multipliers. The generated shader samples them separately; ORMMaterial3D reads channels from one ORM sample. AO using UV2 is excluded because packed ORM uses UV1.",
         "Compare an ORMMaterial3D with correctly packed AO/roughness/metallic channels; preserve scalar multipliers in the packed data and verify texture import/color-space settings.", "Packing requires asset work and can trade resolution or compression quality between channels. Preserve any AO map and compare the resulting material visually.", "scene/resources/material.cpp", lit=True)
    perf("backbuffer_full", "A BackBufferCopy copies the entire viewport", "canvas",
         "A visible BackBufferCopy uses viewport mode or rectangle mode with an exactly empty Rect2, which the native renderer also treats as a full copy. The copied pixel count scales with viewport size.",
         "Compare a tight nonempty copy rectangle that contains all screen-texture samples needed by the following effects, or disable an unused copy.", "Sampling outside the copied region produces undefined or stale content; camera movement and effect offsets must fit the region.", "servers/rendering/renderer_canvas_cull.cpp")
    perf("csg_composition", "A CSG hierarchy retains runtime construction work", "cpu",
         "A root CSGShape3D has a direct CSGShape3D child. Godot documents significant CPU construction cost for CSG and recommends baking final results. This identifies a runtime composition, not proof of rebuilding every frame; static results are cached until dirtied.",
         "For finished static geometry, compare a baked mesh and matching collision geometry; retain CSG when runtime boolean changes are required.", "Baked geometry loses editable runtime boolean operations and must preserve materials, transforms and collision behavior.", "modules/csg/doc_classes/CSGShape3D.xml", verify="Compare scene-load/first-frame time and CPU spikes during the same CSG edits; also compare a screenshot and collision behavior before replacing the hierarchy.")
    perf("navigation_neighbors", "Avoidance agents allow more neighbours than the default", "navigation",
         "An avoidance-enabled NavigationAgent2D/3D searches a positive distance and allows more than ten neighbours. Godot's RVO code retains up to max_neighbors candidates and builds a constraint for each retained neighbour. Ten is the default-based review cutoff; actual nearby agents determine work.",
         "Compare a smaller neighbour limit in representative dense crowds and profile CPU avoidance time.", "Too few neighbours can cause collisions, unstable crowd movement or poor avoidance.", "thirdparty/rvo2/rvo2_3d/Agent3d.cpp")
    perf("richtext_sync", "A large RichTextLabel processes text synchronously", "ui",
         "RichTextLabel has over 32768 current characters according to get_total_character_count() with threaded disabled. The getter walks the native item list without triggering shaping or custom effects; it counts text, newlines and image placeholders, excluding markup and stale stored text after programmatic edits. Its cache-validation path processes invalid lines synchronously; unchanged valid text is cached. The character cutoff is heuristic, not a rendered-glyph or millisecond estimate. Counting cost scales with the number of native rich-text items.",
         "Compare threaded text processing if long text updates stall the UI, and wait for finished before relying on completed layout dimensions.", "Text/layout completion becomes asynchronous; this moves work off the caller rather than eliminating shaping work.", "scene/gui/rich_text_label.cpp", verify="Profile the same long-text insertion or replacement and UI response time; verify finished/layout behavior and text appearance. Do not benchmark only an unchanged cached label.")

    perf("gpu_depth_sort", "3D GPU particles request a depth-sort pass", "particles",
         "GPUParticles3D uses DRAW_ORDER_VIEW_DEPTH with more than one particle. The RD backend allocates a sort buffer and runs SortEffects for this mode. Lifetime ordering does not take this GPU sorting branch.",
         "Compare index ordering for opaque or order-independent particle effects; retain depth sorting where transparency needs it.", "Overlapping transparent particles can composite incorrectly without depth ordering.", "servers/rendering/renderer_rd/storage_rd/particles_storage.cpp", renderers=RD)
    perf("cpu_particle_sort", "CPU particles sort a nontrivial particle array", "cpu",
         "CPUParticles2D/3D uses lifetime ordering, or CPUParticles3D uses view-depth ordering, with amount at least 64. Native update code sorts the particle-index array; 64 is a review heuristic. Depth sorting additionally requires a current camera.",
         "Compare index ordering where the effect does not require a sorted blend order, and profile CPU frame time.", "Particle overlap and transparency can change.", "scene/3d/cpu_particles_3d.cpp")
    perf("heightfield_camera", "Particle height-field collision follows camera movement", "particles",
         "The height-field collider follows the camera in UPDATE_MODE_WHEN_MOVED. Godot documents that camera movement forces height-map updates. UPDATE_MODE_ALWAYS is already covered by its own finding.",
         "Compare a fixed collider or lower resolution if the effect permits it; measure while moving the same camera path.", "A fixed collider may stop covering moving-camera effects, and lower resolution reduces collision precision.", "doc/classes/GPUParticlesCollisionHeightField3D.xml", renderers=RD)
    perf("skin_dynamic_bounds", "A skinned mesh uses automatically updated bounds", "cpu",
         "A live MeshInstance3D resolves to a nonempty Skeleton3D and uses an ArrayMesh with bone attributes, with neither instance nor mesh custom AABB. The RD backend can recalculate bone bounds when the skeleton version changes and caches unchanged skeletons. Pose-update frequency and the actual cost are not inferred.",
         "If CPU profiling identifies bounds updates, compare a carefully authored custom AABB that encloses every required animation pose.", "Too-small bounds cause visible geometry to disappear; oversized bounds weaken culling. Never use a single current pose as the full animation bound.", "servers/rendering/renderer_rd/storage_rd/mesh_storage.cpp", renderers=RD)
    perf("fog_ambient_inject", "Volumetric fog includes ambient-light injection", "post",
         "An assigned Environment enables volumetric fog with positive ambient injection. The fog shader evaluates the ambient branch and can sample sky radiance. The documented cost is small; the configured feature alone does not establish a bottleneck.",
         "Compare zero ambient injection if ambient lighting adds little to the intended fog appearance.", "Fog lighting and color can change.", "servers/rendering/renderer_rd/shaders/environment/volumetric_fog_process.glsl", renderers=["forward_plus"])
    perf("sdfgi_small_cells", "SDFGI cells are smaller than the default", "gi",
         "An assigned Environment enables SDFGI with sdfgi_min_cell_size below the 0.2 default. Smaller cells make updates more demanding and can increase stutter during camera movement. The default is a review threshold, not a minimum.",
         "Compare larger cells while repeating the same camera movement, checking both lighting detail and frame-time spikes.", "Fine indirect-lighting detail decreases and cascade coverage changes.", "doc/classes/Environment.xml", renderers=["forward_plus"])
    perf("ssao_large_radius", "SSAO radius exceeds the default", "post",
         "An assigned Environment enables SSAO with radius above its 1.0 default. Godot documents greater occlusion distance at a performance and quality cost. Compatibility supports this feature from 4.6 (the 4.5 GLES3 driver only stores the settings).",
         "Compare a smaller SSAO radius that still captures the intended contact shading.", "Broad ambient occlusion becomes weaker or disappears.", "doc/classes/Environment.xml", renderers=["forward_plus", "gl_compatibility"], renderers_by_version={"4.4": ["forward_plus"], "4.6": ["forward_plus", "gl_compatibility"]})

    perf("particle_trail_segments", "2D particle trails exceed the default mesh complexity", "particles",
         "GPUParticles2D enables trails with trail_sections times trail_section_subdivisions above the default 8 times 4. The native trail mesh uses this product as its segment count; 32 is a review heuristic, not a limit.",
         "Compare fewer trail sections or subdivisions while preserving the required curve smoothness.", "Trails may look more angular.", "scene/2d/gpu_particles_2d.cpp", renderers=RD)
    perf("fog_aerial", "Fog samples sky radiance for aerial perspective", "post",
         "An assigned Environment enables regular fog with positive fog_aerial_perspective, a sky background and a sky material. The Forward+ and Mobile fog shaders sample sky radiance; the documentation describes a small performance cost.",
         "Compare a fixed fog color by setting aerial perspective to zero where the visual difference is acceptable.", "Fog no longer follows sky colors.", "doc/classes/Environment.xml", renderers=RD)
    perf("probe_lod_disabled", "A reflection probe disables automatic mesh LOD", "gi",
         "A ReflectionProbe with a nonzero cull mask has mesh_lod_threshold set to zero, disabling automatic mesh LOD in its captures. A saving requires captured meshes with generated LODs; update-once probes pay during their capture rather than every frame.",
         "Compare a threshold of one pixel or higher and measure the reflection capture, especially for continuously updated probes.", "Reflected geometry may lose detail; manual visibility ranges remain independent.", "doc/classes/ReflectionProbe.xml", renderers=RD)
    perf("viewport_lod_disabled", "A SubViewport disables automatic mesh LOD", "geometry",
         "A SubViewport with updates and 3D enabled has mesh_lod_threshold set to zero. This is its own threshold, independent of the root viewport's project setting. Meshes without generated LODs receive no benefit from changing it.",
         "Compare a threshold of one pixel or higher in this SubViewport with meshes that have generated LODs.", "Geometry may lose distant detail; manual visibility ranges remain independent.", "doc/classes/Viewport.xml")
    perf("viewport_supersampling", "A SubViewport renders 3D above its output resolution", "resolution",
         "A SubViewport with updates and 3D enabled uses bilinear scaling above 1.0. Godot documents this as supersampling with high performance cost. This checks the SubViewport's own scale, independent of the project setting.",
         "Compare a scale of 1.0 and use appropriate antialiasing if polygon edges need smoothing.", "Fine details and shader-induced edges can become less smooth.", "doc/classes/Viewport.xml", renderers=RD)
    perf("viewport_msaa_2d", "A SubViewport uses 4x or 8x 2D MSAA", "antialiasing",
         "An update-enabled SubViewport has msaa_2d set to 4x or 8x. Its canvas sample count is independent of the root viewport's project setting. Disabled viewport updates are excluded.",
         "Compare 2x MSAA or disabled MSAA for this viewport's 2D content.", "Canvas geometry edges may alias more; MSAA does not fix texture or shader aliasing.", "doc/classes/Viewport.xml")
    perf("camera_blur_amount", "Depth-of-field blur exceeds the documented default amount", "post",
         "Assigned CameraAttributesPractical enables near or far depth of field with dof_blur_amount above its 0.1 default. Higher blur amounts can be more expensive; the default is a review threshold, not a quality limit. Physical camera attributes are excluded.",
         "Compare a lower blur amount and remeasure with the same camera and focus distances.", "Out-of-focus regions become sharper.", "doc/classes/CameraAttributesPractical.xml", renderers=RD)

    perf("geometry_fade_cost", "Visibility ranges enable alpha fading", "geometry",
         "A valid visibility range enables Self or Dependencies fading with a positive transition margin at a nonzero boundary. Geometry can enter the transparent path while fading; actual camera distance is not evaluated.",
         "Compare disabled fading with a nonzero hysteresis margin where popping is acceptable.", "Transitions can pop instead of blending.", "doc/classes/GeometryInstance3D.xml", renderers=["forward_plus"])
    perf("particle_warmup", "GPU particles request substantial startup preprocessing", "particles",
         "GPUParticles2D/3D.preprocess multiplied by fixed_fps (30 when zero) is at least 120 estimated simulation steps. The 120-step review threshold is heuristic, not a timeout limit.",
         "Reduce preprocessing for emitters that can start gradually, and measure the first frame or restart separately.", "The initial particle distribution changes.", "doc/classes/GPUParticles3D.xml")
    perf("particle_sdf_large", "A particle collision SDF has a large texture dimension", "particles",
         "An assigned SDF Texture3D has a dimension of at least 256 voxels. This inspects the actual texture, not a resolution setting awaiting a bake. Shape, format and other dimensions determine memory cost.",
         "Test a lower-resolution rebake if collision precision allows it, then compare the assigned texture dimensions and VRAM.", "Thin collision features may disappear.", "doc/classes/GPUParticlesCollisionSDF3D.xml", renderers=RD)
    perf("particle_heightfield_always", "A particle height field updates every frame", "particles",
         "GPUParticlesCollisionHeightField3D.update_mode is UPDATE_MODE_ALWAYS.",
         "Use UPDATE_MODE_WHEN_MOVED when the collision geometry does not change independently of the collider.", "Moving or deforming geometry may require continuous updates to keep collisions correct.", "doc/classes/GPUParticlesCollisionHeightField3D.xml", renderers=RD)
    perf("particle_turbulence", "GPU particles enable turbulence noise", "particles",
         "An effective ParticleProcessMaterial on GPUParticles2D/3D enables turbulence. Godot documents a high GPU cost; custom process shaders are not inferred.",
         "Compare disabled turbulence or a simpler motion pattern on distant effects, especially on mobile/web targets.", "Particle motion loses its turbulent variation.", "doc/classes/ParticleProcessMaterial.xml")
    perf("canvas_group_mipmaps", "A CanvasGroup generates backbuffer mipmaps", "canvas",
         "CanvasGroup.use_mipmaps is enabled, generating backbuffer mipmaps before the group is drawn.",
         "Disable mipmaps if the group's custom material does not sample them.", "Blur or other mip-dependent shader effects change.", "doc/classes/CanvasGroup.xml")
    perf("canvas_group_margins", "A CanvasGroup expands its backbuffer margins beyond the default", "canvas",
         "CanvasGroup.clear_margin or fit_margin exceeds the documented 10-pixel default. This is a review threshold, not a GPU limit; actual cost depends on the resulting area.",
         "Reduce margins toward the smallest values that preserve shader effects and avoid mipmap edge artifacts.", "Too-small margins can clip effects or produce edge artifacts.", "doc/classes/CanvasGroup.xml")
    perf("particle_vector_resolution", "A particle vector field exceeds the documented low-resolution example", "particles",
         "A vector-field attractor with nonzero strength and nonempty layer mask has more than 64*64*64 texture voxels. Godot describes 64-cubed as an example appropriate for low-frequency attraction data; it is not a hardware limit.",
         "Compare a lower-resolution field while preserving the attractor's world size.", "Fine variations in the force field may be lost.", "doc/classes/GPUParticlesAttractorVectorField3D.xml", renderers=RD)
    perf("sprite_shaded", "3D sprites or labels enable lighting", "canvas",
         "SpriteBase3D or Label3D enables shaded with no material override. This activates the built-in lighting path; actual lighting cost depends on coverage and lights.",
         "Compare unshaded sprites or labels for UI-like elements that should not react to scene lights.", "The sprite or text stops responding to scene lighting.", "doc/classes/SpriteBase3D.xml", renderers=["forward_plus"], lit=True)
    for key, title, evidence, suggestion, tradeoff, lit in (
        ("material_next_pass", "Materials request additional geometry passes", "An effective spatial material has next_pass assigned; the surface is drawn again with that material.", "Remove a next pass only if its outline or other visual effect is unnecessary.", "The extra pass's visual effect disappears.", False),
        ("material_triplanar_uv1", "Albedo textures use UV1 triplanar sampling", "An effective BaseMaterial3D has UV1 triplanar enabled and an albedo texture assigned; triplanar sampling combines three projections per texture lookup.", "Compare imported mesh UVs with triplanar mapping on assets where UV authoring is practical.", "UV mapping changes and seams may appear.", False),
        ("material_triplanar_uv2", "Detail albedo uses UV2 triplanar sampling", "Detail mapping is enabled with a detail albedo texture, UV2 selected and UV2 triplanar enabled.", "Use mesh UV2 for detail mapping where its appearance is acceptable.", "Detail placement and seams change.", False),
        ("material_deep_parallax", "Height maps use deep parallax sampling", "Height mapping and deep parallax are enabled with a height texture and UV1 triplanar disabled.", "Compare simple parallax, fewer parallax layers or a normal map at the intended viewing distance.", "Surface relief becomes less convincing.", False),
        ("material_clearcoat", "Per-pixel materials enable clearcoat lighting", "An effective per-pixel material enables clearcoat with a positive amount, adding the clearcoat lighting term.", "Compare clearcoat disabled on surfaces where the coating is hard to see.", "The second specular highlight disappears.", True),
        ("material_rim", "Per-pixel materials enable rim lighting", "An effective per-pixel material enables rim lighting with a positive amount.", "Compare rim lighting disabled on materials that do not need the stylized edge effect.", "The rim highlight disappears.", True),
        ("material_anisotropy", "Per-pixel materials enable anisotropic lighting", "An effective per-pixel material enables nonzero anisotropy, adding anisotropic lighting calculations.", "Compare isotropic lighting on surfaces whose directional highlights are not prominent.", "Brushed-metal and similar directional highlights change.", True),
        ("material_detail", "Materials sample a detail texture layer", "Detail mapping is enabled with detail albedo, or with detail normal on a per-pixel material.", "Compare a baked base texture or disabled detail layer where extra close-up detail is not visible.", "Close-up surface detail changes; baking can increase base texture size.", True),
        ("material_normal", "Per-pixel materials sample normal maps", "Normal mapping is enabled with a normal texture and nonzero normal scale on an effective per-pixel material.", "Compare disabling normal maps only on distant or visually flat surfaces.", "Fine lighting detail disappears.", True),
    ):
        perf(key, title, "materials", evidence, suggestion, tradeoff,
             "doc/classes/Material.xml" if key == "material_next_pass" else "doc/classes/BaseMaterial3D.xml",
             renderers=["forward_plus"] if lit else (RD if key == "material_deep_parallax" else ALL), lit=lit)

    for key, title in (("env_ssao", "SSAO"), ("env_ssil", "SSIL"), ("env_ssr", "SSR"), ("env_sdfgi", "SDFGI"), ("env_volumetric_fog", "Volumetric fog")):
        add(dict(id="scene_validation." + key + "_renderer", category="scene_validation",
                 title=title + " is unsupported by this renderer", kind="correctness", severity="medium", heuristic=False,
                 renderers=OTHER, versions=["4.4", "4.7"], requires=["scene"],
                 renderers_by_version={"4.6": ["mobile"]} if key == "env_ssao" else {},
                 condition={"scene_gte": {"name": key, "value": 1}},
                 offender_key=key,
                 evidence=title + " is enabled on a scanned Environment under an unsupported renderer. " + ("SSAO is supported by Compatibility from 4.6 and is excluded there. " if key == "env_ssao" else "") + "No performance saving is asserted.",
                 suggestion="Use Forward+ or a supported alternative effect for the target hardware.",
                 tradeoff="Switching renderers changes performance and platform support.",
                 expected_effect="Restore the intended appearance using a supported feature.",
                 verify_step="audit_project_rendering, capture_viewport on the target renderer",
                 source="https://github.com/godotengine/godot/blob/4.7.2-stable/doc/classes/Environment.xml",
                 evidence_kind="godot_configuration"))
