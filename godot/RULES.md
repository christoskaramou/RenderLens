# Render Lens rules

Version 2.0.0. Generated from `addons/render_lens/rules/*.json`.
Each rule is data. The evaluator in `rule_engine.gd` does not apply changes.

A heuristic threshold is labeled in the rule. Costs in suggestions are qualitative unless a measured pass share, frame-time share, or memory share is attached.
A rule's versions are the Godot versions it is verified on (4.4, 4.5.2, 4.6.3, 4.7.2): its quotes, ProjectSettings paths and class members exist in each, and the test suites run on each. It is evaluated from its first to its last verified version; a rule verified on 4.7 also applies to later 4.x releases with an `engine_version_note`. `min_version` and `max_version` narrow that range.

## Counts

| Category | Rules |
| --- | --- |
| renderer_platform | 12 |
| resolution | 12 |
| antialiasing | 20 |
| shadows | 27 |
| lights | 11 |
| gi | 36 |
| post | 41 |
| materials | 27 |
| geometry | 22 |
| textures | 14 |
| particles | 18 |
| decals | 5 |
| sky | 6 |
| canvas | 19 |
| cpu | 26 |
| memory | 15 |
| stutter | 8 |
| pacing | 10 |
| audio | 15 |
| platform | 6 |
| ui | 17 |
| navigation | 17 |
| physics | 33 |
| xr | 8 |
| renderer | 3 |
| animation | 1 |
| scripts | 28 |
| import | 12 |
| scene_validation | 219 |
| gpu_best_practices | 15 |
| **total** | **703** |

## renderer_platform

### `renderer.compatibility_method`

- **Title:** Compatibility renderer is selected
- **Severity:** info
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/renderer/rendering_method`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/performance/optimizing_3d_performance.html

### `renderer.mobile_method`

- **Title:** Mobile renderer is selected
- **Severity:** info
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/renderer/rendering_method`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/environment_and_post_processing.html

### `renderer.thread_model_unsafe`

- **Title:** Rendering thread model is Unsafe (deprecated)
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/driver/threads/thread_model`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/performance/thread_safe_apis.html

### `renderer.depth_prepass_disabled`

- **Title:** Depth prepass is disabled
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/driver/depth_prepass/enable`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/performance/gpu_optimization.html

### `renderer.depth_prepass_vendor_list`

- **Title:** Adapter vendor is on the depth-prepass disable list
- **Severity:** info
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/driver/depth_prepass/disable_for_vendors`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `renderer.force_vertex_shading`

- **Title:** Vertex shading is forced project-wide
- **Severity:** low
- **Kind:** quality_up
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/shading/overrides/force_vertex_shading`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/performance/gpu_optimization.html

### `renderer.force_lambert`

- **Title:** Lambert is forced over Burley
- **Severity:** low
- **Kind:** quality_up
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/shading/overrides/force_lambert_over_burley`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `renderer.cluster_elements_scene`

- **Title:** Lights, decals, or probes exceed the clustered-element budget
- **Severity:** high
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** The largest of the scene's omni, spot and area light (hidden lights excluded), decal and reflection-probe counts is compared with rendering/limits/cluster_builder/max_clustered_elements: ClusterBuilderRD caps each type on its own (cluster_builder_rd.h add_light/add_box), although the class reference describes a sum. Scene counts include elements outside the view, so this is not the engine's per-view count. Mobile does not use the cluster builder (RenderForwardMobile::get_max_elements is a fixed 256).
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/limits/cluster_builder/max_clustered_elements`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/using_decals.html

### `renderer.gl_light_limit`

- **Title:** Compatibility light count is above max_renderable_lights
- **Severity:** high
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** The cap applies to the lights visible in a frame; the scan counts the scene's visible omni, spot and area lights, including any outside the camera view.
- **Renderers:** gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/limits/opengl/max_renderable_lights`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `renderer.vrs_off_while_gpu_bound`

- **Title:** Variable rate shading is off while the frame is over a GPU budget
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** The rule only suggests VRS when frame_timing says the frame is over budget and GPU-bound. It does not estimate the shading-rate saving.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/vrs/mode`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/variable_rate_shading.html

### `renderer.gl_lights_per_object`

- **Title:** Compatibility allows more than 8 omni or spot lights per object
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/limits/opengl/max_lights_per_object`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `renderer.gl_element_cap`

- **Title:** The Compatibility element cap is above 65536
- **Severity:** low
- **Kind:** info
- **Heuristic:** no
- **Renderers:** gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/limits/opengl/max_renderable_elements`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

## resolution

### `resolution.scale_above_one`

- **Title:** 3D render scale is above 1 (supersampling)
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/scaling_3d/scale`
- **Try live:** `measure_change finding=resolution.scale_above_one` applies `[{"setting": "rendering/scaling_3d/scale", "value": 1.0}]`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/resolution_scaling.html

### `resolution.full_scale_gpu_over_budget`

- **Title:** Full 3D resolution while the GPU frame is over budget
- **Severity:** high
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Suggests leaving scale 1.0 only after frame_timing reports a GPU-bound over-budget frame. The resolution scaling page says lowering scale helps GPU-bound scenes. No target scale is prescribed.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/scaling_3d/scale`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/resolution_scaling.html

### `resolution.fsr2_native_over_budget`

- **Title:** FSR 2.2 is on at native resolution while over budget
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/scaling_3d/mode`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/3d_antialiasing.html

### `resolution.fsr2_enabled`

- **Title:** FSR 2.2 upscaling is selected
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/scaling_3d/mode`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/resolution_scaling.html

### `resolution.bilinear_while_upscaling`

- **Title:** Upscaling with bilinear filtering
- **Severity:** low
- **Kind:** quality_up
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/scaling_3d/mode`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/resolution_scaling.html

### `resolution.fsr_sharpness_extreme`

- **Title:** FSR sharpness is at a documented extreme
- **Severity:** low
- **Kind:** quality_up
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/scaling_3d/fsr_sharpness`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/resolution_scaling.html

### `resolution.negative_mip_bias`

- **Title:** Texture mipmap bias is negative
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/textures/default_filters/texture_mipmap_bias`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/resolution_scaling.html

### `pass.fsr2`

- **Title:** FSR 2.2 is in the capture
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** The trigger is a RenderingDevice timestamp label substring from Godot's clustered renderer. Labels are not a stable public API. The rule fires only when that pass has exclusive time above 0.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/resolution_scaling.html

### `resolution.nearest_upscale`

- **Title:** 3D scaling mode is nearest
- **Severity:** low
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.7
- **min_version:** 4.7
- **Setting:** `rendering/scaling_3d/mode`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/resolution_scaling.html

### `resolution.viewport_supersampling`

- **Title:** A SubViewport renders 3D above its output resolution
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_viewport_supersampling", "value": 1}}`
- **Evidence and limits:** A SubViewport with updates and 3D enabled uses bilinear scaling above 1.0. Godot documents this as supersampling with high performance cost. This checks the SubViewport's own scale, independent of the project setting.
- **Suggested action:** Compare a scale of 1.0 and use appropriate antialiasing if polygon edges need smoothing.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/Viewport.xml

### `resolution.upscaler_renderer`

- **Title:** The 3D scaling mode needs a renderer that is not selected
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/scaling_3d/mode`
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"any": [{"setting_eq": {"path": "rendering/scaling_3d/mode", "value": 1}}, {"setting_eq": {"path": "rendering/scaling_3d/mode", "value": 2}}, {"setting_eq": {"path": "rendering/scaling_3d/mode", "value": 4}}, {"all": [{"setting_eq": {"path": "rendering/renderer/rendering_method", "value": "gl_compatibility"}}, {"setting_eq": {"path": "rendering/scaling_3d/mode", "value": 3}}]}]}`
- **Evidence and limits:** Godot prints "FSR2 3D scaling is only available when using the Forward+ renderer." when rendering/scaling_3d/mode is FSR 1.0 (1), FSR 2.2 (2) or MetalFX Temporal (4) outside Forward+, or MetalFX Spatial (3) under Compatibility. Godot 4.4, 4.5 and 4.7 reject the mode and 4.6 falls back to bilinear scaling, so the chosen upscaler never runs.
- **Suggested action:** Use bilinear scaling (0) with this renderer, or switch to a renderer that supports the upscaler.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/renderer_viewport.cpp

### `resolution.upscaler_downsampling`

- **Title:** An upscaler is selected with a 3D scale above 1
- **Severity:** low
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/scaling_3d/mode`
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"all": [{"setting_gt": {"path": "rendering/scaling_3d/scale", "value": 1.0}}, {"setting_neq": {"path": "rendering/scaling_3d/mode", "value": 0}}]}`
- **Evidence and limits:** Godot prints "FSR, MetalFX, and nearest-neighbor 3D resolution scaling are not designed for downsampling. Falling back to bilinear 3D resolution scaling." when rendering/scaling_3d/scale is above 1.0 and the scaling mode is not bilinear. FSR, MetalFX and (4.7) nearest-neighbor scaling are replaced by bilinear supersampling.
- **Suggested action:** Set the scaling mode to bilinear (0) when supersampling, or lower the scale to 1.0 or below to use the upscaler.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/renderer_viewport.cpp

## antialiasing

### `antialiasing.msaa_4x`

- **Title:** MSAA 3D is 4×
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/anti_aliasing/quality/msaa_3d`
- **Try live:** `measure_change finding=antialiasing.msaa_4x` applies `[{"setting": "rendering/anti_aliasing/quality/msaa_3d", "value": 1}]`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/3d_antialiasing.html

### `antialiasing.msaa_8x`

- **Title:** MSAA 3D is 8×
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/anti_aliasing/quality/msaa_3d`
- **Try live:** `measure_change finding=antialiasing.msaa_8x` applies `[{"setting": "rendering/anti_aliasing/quality/msaa_3d", "value": 2}]`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/3d_antialiasing.html

### `antialiasing.msaa_on_mobile_renderer`

- **Title:** MSAA 3D is on with the Mobile renderer
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/anti_aliasing/quality/msaa_3d`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/3d_antialiasing.html

### `antialiasing.msaa_and_taa`

- **Title:** MSAA and TAA are both enabled
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** The antialiasing page says stacking techniques is usually unnecessary. It does not forbid the combination.
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/anti_aliasing/quality/use_taa`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/3d_antialiasing.html

### `antialiasing.taa_enabled`

- **Title:** TAA is enabled
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/anti_aliasing/quality/use_taa`
- **Try live:** `measure_change finding=antialiasing.taa_enabled` applies `[{"setting": "rendering/anti_aliasing/quality/use_taa", "value": false}]`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/3d_antialiasing.html

### `antialiasing.fxaa_enabled`

- **Title:** FXAA is the screen-space antialiasing mode
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/anti_aliasing/quality/screen_space_aa`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/3d_antialiasing.html

### `antialiasing.no_aa`

- **Title:** No 3D antialiasing is enabled
- **Severity:** low
- **Kind:** quality_up
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/anti_aliasing/quality/use_taa`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/3d_antialiasing.html

### `antialiasing.roughness_limiter_off`

- **Title:** Screen-space roughness limiter is off
- **Severity:** low
- **Kind:** quality_up
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/anti_aliasing/screen_space_roughness_limiter/enabled`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/3d_antialiasing.html

### `antialiasing.debanding_on`

- **Title:** Debanding is enabled
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/anti_aliasing/quality/use_debanding`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `antialiasing.msaa_2d_high`

- **Title:** 2D MSAA is 4× or 8×
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/anti_aliasing/quality/msaa_2d`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/3d_antialiasing.html

### `pass.taa`

- **Title:** TAA is in the capture
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** The trigger is a RenderingDevice timestamp label substring from Godot's clustered renderer. Labels are not a stable public API. The rule fires only when that pass has exclusive time above 0.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Try live:** `measure_change finding=pass.taa` applies `[{"setting": "rendering/anti_aliasing/quality/use_taa", "value": false}]`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/3d_antialiasing.html

### `antialiasing.smaa_enabled`

- **Title:** SMAA is the screen-space antialiasing mode
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.5, 4.6, 4.7
- **min_version:** 4.5
- **Setting:** `rendering/anti_aliasing/quality/screen_space_aa`
- **Try live:** `measure_change finding=antialiasing.smaa_enabled` applies `[{"setting": "rendering/anti_aliasing/quality/screen_space_aa", "value": 0}]`
- **Source:** https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html

### `antialiasing.smaa_threshold_low`

- **Title:** SMAA edge detection is more sensitive than the default
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.5, 4.6, 4.7
- **min_version:** 4.5
- **Setting:** `rendering/anti_aliasing/quality/smaa_edge_detection_threshold`
- **Source:** https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html

### `antialiasing.viewport_msaa_fxaa`

- **Title:** A SubViewport combines MSAA with FXAA
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_viewport_msaa_fxaa", "value": 1}}`
- **Evidence and limits:** An update-enabled 3D SubViewport enables both MSAA and FXAA. The native RD post-process selects FXAA independently of the MSAA setting; their costs can combine. The methods target different aliasing, so combining them is not automatically wrong.
- **Suggested action:** Compare each method on its own in this viewport, measuring GPU time and inspecting both geometry edges and specular shimmer.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/servers/rendering/renderer_rd/renderer_scene_render_rd.cpp

### `antialiasing.viewport_msaa_2d`

- **Title:** A SubViewport uses 4x or 8x 2D MSAA
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_viewport_msaa_2d", "value": 1}}`
- **Evidence and limits:** An update-enabled SubViewport has msaa_2d set to 4x or 8x. Its canvas sample count is independent of the root viewport's project setting. Disabled viewport updates are excluded.
- **Suggested action:** Compare 2x MSAA or disabled MSAA for this viewport's 2D content.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/Viewport.xml

### `antialiasing.taa_with_temporal_upscaler`

- **Title:** TAA is enabled together with a temporal upscaler
- **Severity:** low
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/anti_aliasing/quality/use_taa`
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"all": [{"setting_eq": {"path": "rendering/anti_aliasing/quality/use_taa", "value": true}}, {"any": [{"setting_eq": {"path": "rendering/scaling_3d/mode", "value": 2}}, {"setting_eq": {"path": "rendering/scaling_3d/mode", "value": 4}}]}]}`
- **Evidence and limits:** Godot prints "FSR 2 or MetalFX Temporal is not compatible with TAA. Disabling TAA internally." when use_taa is on and the scaling mode is FSR 2.2 (2) or MetalFX Temporal (4). The upscaler provides its own temporal antialiasing and Godot turns TAA off.
- **Suggested action:** Turn rendering/anti_aliasing/quality/use_taa off; the temporal upscaler already antialiases.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/renderer_viewport.cpp

### `antialiasing.taa_renderer`

- **Title:** TAA is enabled outside Forward+
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/anti_aliasing/quality/use_taa`
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"setting_eq": {"path": "rendering/anti_aliasing/quality/use_taa", "value": true}}`
- **Evidence and limits:** Godot prints "TAA is only available when using the Forward+ renderer." when use_taa is on under the Mobile or Compatibility renderer, which have no TAA pass.
- **Suggested action:** Turn use_taa off for this renderer and choose another antialiasing method (MSAA or FXAA where available).
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/renderer_viewport.cpp

### `antialiasing.screen_space_aa_renderer`

- **Title:** Screen-space antialiasing is set under Compatibility
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** gl_compatibility
- **Godot versions:** 4.5, 4.6, 4.7
- **Setting:** `rendering/anti_aliasing/quality/screen_space_aa`
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"setting_neq": {"path": "rendering/anti_aliasing/quality/screen_space_aa", "value": 0}}`
- **Evidence and limits:** Godot prints "Screen-space AA is only available when using the Forward+ or Mobile renderer." when screen_space_aa is FXAA or SMAA under the Compatibility renderer, which does not run it.
- **Suggested action:** Set screen_space_aa to Disabled and use MSAA under Compatibility.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/renderer_viewport.cpp

### `antialiasing.msaa_2d_renderer`

- **Title:** 2D MSAA is set under Compatibility
- **Severity:** low
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/anti_aliasing/quality/msaa_2d`
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"setting_gt": {"path": "rendering/anti_aliasing/quality/msaa_2d", "value": 0}}`
- **Evidence and limits:** Godot prints "2D MSAA is not yet supported for GLES3." when msaa_2d is above Disabled under the Compatibility renderer, so 2D content is not multisampled.
- **Suggested action:** Set msaa_2d to Disabled, or antialias 2D lines and polygons with their antialiased properties.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/storage/texture_storage.cpp

### `antialiasing.metalfx_temporal_msaa`

- **Title:** MetalFX Temporal upscaling is combined with 3D MSAA
- **Severity:** low
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/scaling_3d/mode`
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"all": [{"setting_eq": {"path": "rendering/scaling_3d/mode", "value": 4}}, {"setting_gt": {"path": "rendering/anti_aliasing/quality/msaa_3d", "value": 0}}]}`
- **Evidence and limits:** Godot prints "MetalFX temporal upscaling does not support 3D MSAA. Disabling 3D MSAA internally." on Apple devices that run MetalFX Temporal (scaling mode 4) when msaa_3d is enabled; MSAA is turned off while the upscaler runs.
- **Suggested action:** Set msaa_3d to Disabled when using MetalFX Temporal, or choose another scaling mode.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/renderer_viewport.cpp

## shadows

### `shadows.directional_size_above_default`

- **Title:** Directional shadow map is larger than the default
- **Severity:** high
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** The default directional shadow size is 4096 (2048 on the .mobile override). Larger than 4096 is above that default, which stores more shadow texels.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/lights_and_shadows/directional_shadow/size`
- **Try live:** `measure_change finding=shadows.directional_size_above_default` applies `[{"setting": "rendering/lights_and_shadows/directional_shadow/size", "value": 4096}]`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/lights_and_shadows.html

### `shadows.positional_atlas_above_default`

- **Title:** Positional shadow atlas is larger than the default
- **Severity:** high
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** The positional atlas default is 4096. Values above that increase the atlas beyond the documented default.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/lights_and_shadows/positional_shadow/atlas_size`
- **Try live:** `measure_change finding=shadows.positional_atlas_above_default` applies `[{"setting": "rendering/lights_and_shadows/positional_shadow/atlas_size", "value": 4096}]`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/lights_and_shadows.html

### `shadows.directional_filter_high`

- **Title:** Directional soft shadow filter is High or Ultra
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality`
- **Try live:** `measure_change finding=shadows.directional_filter_high` applies `[{"setting": "rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality", "value": 2}]`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/lights_and_shadows.html

### `shadows.positional_filter_high`

- **Title:** Positional soft shadow filter is High or Ultra
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality`
- **Try live:** `measure_change finding=shadows.positional_filter_high` applies `[{"setting": "rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality", "value": 2}]`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/lights_and_shadows.html

### `shadows.directional_32_bit`

- **Title:** Directional shadows are not 16-bit
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/lights_and_shadows/directional_shadow/16_bits`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `shadows.positional_32_bit`

- **Title:** Positional shadow atlas is not 16-bit
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/lights_and_shadows/positional_shadow/atlas_16_bits`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `shadows.quadrant_subdiv_high`

- **Title:** A positional shadow quadrant allows 256 or more shadows
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/lights_and_shadows/positional_shadow/atlas_quadrant_3_subdiv`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/lights_and_shadows.html

### `shadows.tighter_culling_off`

- **Title:** Tighter shadow caster culling is off
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/lights_and_shadows/tighter_shadow_caster_culling`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `shadows.directional_pssm4`

- **Title:** A DirectionalLight3D uses 4 PSSM splits
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `DirectionalLight3D.directional_shadow_mode`
- **Try live:** `measure_change finding=shadows.directional_pssm4` applies `[{"class": "DirectionalLight3D", "property": "directional_shadow_mode", "value": 1, "only_above": 1}]`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/lights_and_shadows.html

### `shadows.directional_max_distance`

- **Title:** Directional shadow max distance is above the node default
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** DirectionalLight3D.directional_shadow_max_distance defaults to 100 in Godot 4.4. Above that spreads the same shadow map over more world space.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `DirectionalLight3D.directional_shadow_max_distance`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/lights_and_shadows.html

### `shadows.omni_cube`

- **Title:** Omni shadows use cube maps
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `OmniLight3D.omni_shadow_mode`
- **Try live:** `measure_change finding=shadows.omni_cube` applies `[{"class": "OmniLight3D", "property": "omni_shadow_mode", "value": 0}]`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/lights_and_shadows.html

### `shadows.omni_shadow_count`

- **Title:** More than one omni light casts shadows
- **Severity:** high
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Two or more shadow-casting omni lights is the cut. Each one renders its own shadow map. The number is not a Godot budget.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Light3D.shadow_enabled`
- **Try live:** `measure_change finding=shadows.omni_shadow_count` applies `[{"class": "OmniLight3D", "property": "shadow_enabled", "value": false}]`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/performance/optimizing_3d_performance.html

### `shadows.spot_shadow_count`

- **Title:** More than one spot light casts shadows
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Two or more shadow-casting spot lights is a review cut, not an engine limit.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Light3D.shadow_enabled`
- **Try live:** `measure_change finding=shadows.spot_shadow_count` applies `[{"class": "SpotLight3D", "property": "shadow_enabled", "value": false}]`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/performance/optimizing_3d_performance.html

### `shadows.no_distance_fade`

- **Title:** Shadow-casting positional lights have no distance fade
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Light3D.distance_fade_enabled`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/lights_and_shadows.html

### `shadows.light_size_soft`

- **Title:** Shadow lights use size or angular distance
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Light3D.light_size`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/lights_and_shadows.html

### `shadows.shadow_2d_atlas`

- **Title:** 2D shadow atlas is larger than the default
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** rendering/2d/shadow_atlas/size defaults to 2048. Above that is more 2D shadow texels than the default.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/2d/shadow_atlas/size`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/2d/2d_lights_and_shadows.html

### `shadows.double_sided_casters`

- **Title:** Meshes cast double-sided shadows
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `GeometryInstance3D.cast_shadow`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_geometryinstance3d.html

### `pass.shadows`

- **Title:** A shadow timestamp is in the capture
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** The trigger is a RenderingDevice timestamp label substring from Godot's clustered renderer. Labels are not a stable public API. The rule fires only when that pass has exclusive time above 0.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/lights_and_shadows.html

### `shadows.directional_mobile_size`

- **Title:** The mobile directional shadow map is above 2048
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/lights_and_shadows/directional_shadow/size.mobile`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `shadows.positional_mobile_size`

- **Title:** The mobile positional shadow atlas is above 2048
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/lights_and_shadows/positional_shadow/atlas_size.mobile`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `shadows.mobile_filter_raised`

- **Title:** The mobile directional shadow filter is above the low-end default
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality.mobile`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `shadows.positional_mobile_filter_raised`

- **Title:** The mobile omni/spot shadow filter is above the low-end default
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality.mobile`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `shadows.small_shadow_casters`

- **Title:** Many tiny meshes cast shadows
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_small_shadow_casters", "value": 64}}`
- **Evidence and limits:** At least 64 visible MeshInstance3D nodes cast shadows although their scaled bounds are under 0.2 units on every axis. The size and count cutoffs are review heuristics. Godot class reference: "Use this to improve performance for small geometry that is unlikely to cast noticeable shadows (such as debris)."
- **Suggested action:** Set cast_shadow to Off on small debris and props whose shadows are not noticeable.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/GeometryInstance3D.xml

### `shadows.light_shadow_fade`

- **Title:** A light's shadow fades no earlier than the light
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_light_shadow_fade", "value": 1}}`
- **Evidence and limits:** A visible OmniLight3D/SpotLight3D casts shadows with distance fade enabled, and distance_fade_shadow is at least distance_fade_begin + distance_fade_length, so shadows render for the light's whole fade range. Godot class reference: "Set this to a value lower than + to further improve performance, as shadow rendering is often more expensive than light rendering itself."
- **Suggested action:** Lower distance_fade_shadow below the light's fade end so distant lights stop rendering shadows first.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/Light3D.xml

### `shadows.shadow_blend_splits`

- **Title:** Directional shadow splits are blended
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_shadow_blend_splits", "value": 1}}`
- **Evidence and limits:** A visible, shadow-casting DirectionalLight3D uses PSSM splits with directional_shadow_blend_splits enabled. Godot class reference: "Enabling shadow blend splitting also has a moderate performance cost."
- **Suggested action:** Disable directional_shadow_blend_splits unless the seams between shadow splits are visible during play.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/DirectionalLight3D.xml

### `shadows.viewport_shadow_atlas`

- **Title:** A SubViewport requests a larger or deeper shadow atlas
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_viewport_shadow_atlas", "value": 1}}`
- **Evidence and limits:** An update-enabled 3D SubViewport requests a positional shadow atlas above its default 2048 size or disables its default 16-bit depth mode. The RD renderer allocates atlas width and height from this size and selects D16 or D32. Allocation and rendering depend on actual shadow use; this is not a measured VRAM value.
- **Suggested action:** Compare the default atlas size and 16-bit mode one at a time while checking omni/spot shadows in this viewport.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/servers/rendering/renderer_rd/storage_rd/light_storage.cpp

### `shadows.light_shadow_blur`

- **Title:** Shadow blur exceeds the default
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_light_shadow_blur", "value": 1}}`
- **Evidence and limits:** A visible non-editor-only Light3D enables shadows with shadow_blur above its default of 1.0. Godot documents possible performance impact at high values; the actual effect depends on the shadow filtering path and hardware.
- **Suggested action:** Compare a blur value near one while holding other shadow settings constant.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/Light3D.xml

## lights

### `lights.many_realtime`

- **Title:** The scene has many real-time lights
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Eight or more Light3D nodes is a review cut. The optimizing-3D page says real-time lights are costly and does not publish this count.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Light3D.light_bake_mode`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/performance/optimizing_3d_performance.html

### `lights.omni_range`

- **Title:** Omni range is far above the node default
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** OmniLight3D.omni_range defaults to 5. A range of 20 or more is four times that default and increases overlap; it is not an engine error.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `OmniLight3D.omni_range`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/lights_and_shadows.html

### `lights.wide_spot`

- **Title:** Spot angle is very wide
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** spot_angle of 120 degrees or more is far above the SpotLight3D default of 45. A wide cone behaves more like an omni for culling.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `SpotLight3D.spot_angle`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_light3d.html

### `lights.physical_units`

- **Title:** Physical light units are enabled
- **Severity:** info
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/lights_and_shadows/use_physical_light_units`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/lights_and_shadows.html

### `lights.projector_filter_aniso`

- **Title:** Light projector filter uses anisotropic samples
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/textures/light_projectors/filter`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `lights.negative`

- **Title:** Negative lights are in the scene
- **Severity:** info
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Light3D.light_negative`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_light3d.html

### `lights.no_lightmap_with_many_lights`

- **Title:** Many real-time lights and no LightmapGI
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Fires when the light count is at least 8 and the scan finds no LightmapGI. The optimizing-3D page recommends baked lighting; it does not define this count.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `LightmapGI`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/global_illumination/using_lightmap_gi.html

### `lights.editor_only_ignored`

- **Title:** Realtime lights are marked editor-only
- **Severity:** info
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Light3D.editor_only`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_light3d.html

### `lights.positional_light_dynamic_bake`

- **Title:** Omni or spot lights stay Dynamic in a lightmapped scene
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"all": [{"scene_gte": {"name": "check_positional_light_dynamic_bake", "value": 1}}, {"scene_gte": {"name": "lightmap_baked_count", "value": 1}}]}`
- **Evidence and limits:** A visible OmniLight3D or SpotLight3D keeps light_bake_mode Dynamic while the scene has a baked LightmapGI. Godot docs: "For best performance, you should set lights' bake mode to Static as opposed to the default Dynamic, as this will skip real-time lighting on meshes that have baked lighting."
- **Suggested action:** Set light_bake_mode to Static on omni and spot lights the lightmap covers and rebake; the same page suggests keeping Dynamic on the DirectionalLight3D.
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/performance/optimizing_3d_performance.html

### `lights.area_light_cost`

- **Title:** Area lights are in the scene
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_area_light_cost", "value": 1}}`
- **Evidence and limits:** A visible AreaLight3D with non-zero energy is in the scene. In Forward+, one visible area light adds cost to every rendered object; in Mobile and Compatibility only to the objects it reaches. Godot docs: "This type of light is the most expensive to render in real-time. It should be used sparingly, especially when shadows are enabled."
- **Suggested action:** Use area lights sparingly (the page suggests cinematics or high-end targets), turn off their shadows or set Size to 0.0 to drop the PCSS penumbra, and prefer omni or spot lights elsewhere.
- **Source:** https://docs.godotengine.org/en/4.7/tutorials/3d/lights_and_shadows.html

### `lights.light_volumetric_fog`

- **Title:** A light contributes to active volumetric fog
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_light_volumetric_fog", "value": 1}}`
- **Evidence and limits:** A visible non-editor-only Light3D has positive light and volumetric-fog energy and resolves to an Environment with volumetric fog enabled. Godot documents that zero fog energy skips fog computation for that light. Live current-camera environment overrides are honored; unresolved detached environments are excluded.
- **Suggested action:** Compare zero volumetric-fog energy on lights whose contribution is unnecessary, especially many short-lived effect lights.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/Light3D.xml

## gi

### `gi.sdfgi_enabled`

- **Title:** SDFGI is enabled
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Environment.sdfgi_enabled`
- **Try live:** `measure_change finding=gi.sdfgi_enabled` applies `[{"environment": true, "property": "sdfgi_enabled", "value": false}]`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/global_illumination/using_sdfgi.html

### `gi.sdfgi_cascades`

- **Title:** SDFGI cascade count is above the Environment default
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Environment.sdfgi_cascades`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/global_illumination/using_sdfgi.html

### `gi.sdfgi_occlusion`

- **Title:** SDFGI use-occlusion is on
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Environment.sdfgi_use_occlusion`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/global_illumination/using_sdfgi.html

### `gi.sdfgi_probe_rays`

- **Title:** SDFGI probe ray count is at the slow end
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/global_illumination/sdfgi/probe_ray_count`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/global_illumination/using_sdfgi.html

### `gi.sdfgi_frames_to_converge`

- **Title:** SDFGI frames-to-converge is the high-latency end
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/global_illumination/sdfgi/frames_to_converge`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/global_illumination/using_sdfgi.html

### `gi.sdfgi_light_update_slow`

- **Title:** SDFGI updates dynamic lights every frame
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/global_illumination/sdfgi/frames_to_update_lights`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/global_illumination/using_sdfgi.html

### `gi.half_resolution_off`

- **Title:** GI half-resolution buffer is off while GI is enabled
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/global_illumination/gi/use_half_resolution`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/global_illumination/using_sdfgi.html

### `gi.voxel_quality_high`

- **Title:** VoxelGI cone tracing is set to High
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/global_illumination/voxel_gi/quality`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/global_illumination/using_voxel_gi.html

### `gi.voxel_subdiv`

- **Title:** VoxelGI subdivision is above the default 128
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `VoxelGI.subdiv`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/global_illumination/using_voxel_gi.html

### `gi.voxel_count`

- **Title:** More than one VoxelGI is in the scene
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Two VoxelGI nodes means two baked volumes. The page does not forbid more than one; overlapping volumes still both store data.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `VoxelGI`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/global_illumination/using_voxel_gi.html

### `gi.probe_always`

- **Title:** A ReflectionProbe updates every frame
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `ReflectionProbe.update_mode`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/global_illumination/reflection_probes.html

### `gi.probe_shadows`

- **Title:** A ReflectionProbe renders real-time shadows
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `ReflectionProbe.enable_shadows`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/global_illumination/reflection_probes.html

### `gi.reflection_atlas_size`

- **Title:** Reflection atlas size is above the default
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** reflection_size defaults to 256. Above that stores a larger reflection atlas than the default.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/reflections/reflection_atlas/reflection_size`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/global_illumination/reflection_probes.html

### `gi.reflection_count`

- **Title:** Reflection atlas count is above the default
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** reflection_count defaults to 64. A higher count reserves more atlas slots than the default.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/reflections/reflection_atlas/reflection_count`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `gi.ggx_samples`

- **Title:** Sky GGX sample count is above the default
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/reflections/sky_reflections/ggx_samples`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_sky.html

### `gi.ssil_enabled`

- **Title:** Screen-space indirect lighting is enabled
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Environment.ssil_enabled`
- **Try live:** `measure_change finding=gi.ssil_enabled` applies `[{"environment": true, "property": "ssil_enabled", "value": false}]`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/environment_and_post_processing.html

### `gi.lightmap_bicubic_off`

- **Title:** Lightmap bicubic filter is off
- **Severity:** low
- **Kind:** quality_up
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/lightmapping/lightmap_gi/use_bicubic_filter`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/global_illumination/using_lightmap_gi.html

### `pass.ssil`

- **Title:** Process SSIL is in the capture
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** The trigger is a RenderingDevice timestamp label substring from Godot's clustered renderer. Labels are not a stable public API. The rule fires only when that pass has exclusive time above 0.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Try live:** `measure_change finding=pass.ssil` applies `[{"environment": true, "property": "ssil_enabled", "value": false}]`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/environment_and_post_processing.html

### `pass.sdfgi`

- **Title:** SDFGI is in the capture
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** The trigger is a RenderingDevice timestamp label substring from Godot's clustered renderer. Labels are not a stable public API. The rule fires only when that pass has exclusive time above 0.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Try live:** `measure_change finding=pass.sdfgi` applies `[{"environment": true, "property": "sdfgi_enabled", "value": false}]`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/global_illumination/using_sdfgi.html

### `gi.texture_array_reflections`

- **Title:** Reflections use texture arrays instead of mipmaps
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/reflections/sky_reflections/texture_array_reflections`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `gi.roughness_layers_high`

- **Title:** Radiance roughness layers are above 8
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/reflections/sky_reflections/roughness_layers`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `gi.fast_filter_high_quality`

- **Title:** Sky reflections use the high-quality fast filter
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/reflections/sky_reflections/fast_filter_high_quality`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `gi.reflection_mobile_size`

- **Title:** The mobile reflection atlas is above 128
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/reflections/reflection_atlas/reflection_size.mobile`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `gi.ggx_mobile_high`

- **Title:** Mobile GGX samples are above 16
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/reflections/sky_reflections/ggx_samples.mobile`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `gi.lightmap_ultra_rays`

- **Title:** Ultra lightmap bakes use more than 2048 rays
- **Severity:** info
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/lightmapping/bake_quality/ultra_quality_ray_count`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `gi.lightmap_high_rays`

- **Title:** High lightmap bakes use more than 512 rays
- **Severity:** info
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/lightmapping/bake_quality/high_quality_ray_count`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `gi.texture_array_reflections_mobile`

- **Title:** Mobile devices use texture-array sky reflections
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/reflections/sky_reflections/texture_array_reflections.mobile`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `gi.lightmap_unbaked`

- **Title:** A LightmapGI node has no baked data
- **Severity:** medium
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `LightmapGI.light_data`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_lightmapgi.html

### `gi.voxel_unbaked`

- **Title:** A VoxelGI node has no baked data
- **Severity:** medium
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `VoxelGI.data`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_voxelgi.html

### `gi.lightmap_data_embedded`

- **Title:** Lightmap data is embedded in a text scene
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_lightmap_data_embedded", "value": 1}}`
- **Evidence and limits:** A LightmapGI's light_data is built into a .tscn scene (or not saved to its own file), so the capture data is stored as Base64 text in the scene. Godot docs: "If you are using a scene in .tscn format, you should save this resource to an external binary .lmbake file to avoid bloating the .tscn scene with binary data encoded in Base64."
- **Suggested action:** Save light_data to an external .lmbake file (Godot's bake does this when given a path) and reference it from the LightmapGI.
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/global_illumination/using_lightmap_gi.html

### `gi.gi_dynamic`

- **Title:** Geometry uses dynamic GI with a VoxelGI in the scene
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"all": [{"scene_gte": {"name": "check_gi_dynamic", "value": 1}}, {"scene_gte": {"name": "voxel_gi_count", "value": 1}}]}`
- **Evidence and limits:** A visible GeometryInstance3D uses GI_MODE_DYNAMIC and the scan found a VoxelGI, the only GI that dynamic mode affects. Godot class reference: "but it has a higher performance impact than ."
- **Suggested action:** Use GI_MODE_STATIC for objects that do not move, and keep dynamic mode for moving objects that must contribute to VoxelGI.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/GeometryInstance3D.xml

### `gi.lightmap_directional`

- **Title:** Directional lightmaps add shader work
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_lightmap_directional", "value": 1}}`
- **Evidence and limits:** A baked LightmapGI has directional enabled. Godot class reference: "This has a small run-time performance cost as the shader has to perform more work to interpret the direction information from the lightmap."
- **Suggested action:** Rebake without directional where normal-mapped detail under baked light is not needed.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/LightmapGI.xml

### `gi.sdfgi_small_cells`

- **Title:** SDFGI cells are smaller than the default
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_sdfgi_small_cells", "value": 1}}`
- **Evidence and limits:** An assigned Environment enables SDFGI with sdfgi_min_cell_size below the 0.2 default. Smaller cells make updates more demanding and can increase stutter during camera movement. The default is a review threshold, not a minimum.
- **Suggested action:** Compare larger cells while repeating the same camera movement, checking both lighting detail and frame-time spikes.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/Environment.xml

### `gi.probe_lod_disabled`

- **Title:** A reflection probe disables automatic mesh LOD
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_probe_lod_disabled", "value": 1}}`
- **Evidence and limits:** A ReflectionProbe with a nonzero cull mask has mesh_lod_threshold set to zero, disabling automatic mesh LOD in its captures. A saving requires captured meshes with generated LODs; update-once probes pay during their capture rather than every frame.
- **Suggested action:** Compare a threshold of one pixel or higher and measure the reflection capture, especially for continuously updated probes.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/ReflectionProbe.xml

### `gi.probe_always_atlas`

- **Title:** An Always-updating ReflectionProbe resizes the reflection atlas to 256
- **Severity:** low
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/reflections/reflection_atlas/reflection_size`
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"all": [{"scene_gte": {"name": "reflection_probe_always_count", "value": 1}}, {"setting_neq": {"path": "rendering/reflections/reflection_atlas/reflection_size", "value": 256}}]}`
- **Evidence and limits:** Godot prints "ReflectionProbes set to UPDATE_ALWAYS must have an atlas size of 256." when a probe with update_mode Always renders into an atlas whose size is not 256, then resizes the atlas to 256 for every probe. The .mobile override (128 by default) also triggers it on mobile devices.
- **Suggested action:** Set rendering/reflections/reflection_atlas/reflection_size (and its .mobile override) to 256, or use update_mode Once.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/renderer_rd/storage_rd/light_storage.cpp

### `gi.lightmap_missing_nodes`

- **Title:** Baked lightmap data refers to nodes that no longer exist
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_lightmap_missing_nodes", "value": 1}}`
- **Evidence and limits:** Godot prints "LightmapGI couldn't find previously baked nodes and needs a rebake (missing nodes: ../Wall)." when a LightmapGI's baked data lists a mesh path that does not resolve; that mesh renders without its lightmap.
- **Suggested action:** Rebake the LightmapGI after moving, renaming or deleting baked meshes.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/scene/3d/lightmap_gi.cpp

## post

### `post.ssao_enabled`

- **Title:** SSAO is enabled
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Environment.ssao_enabled`
- **Try live:** `measure_change finding=post.ssao_enabled` applies `[{"environment": true, "property": "ssao_enabled", "value": false}]`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/environment_and_post_processing.html

### `post.ssao_quality_high`

- **Title:** SSAO quality is High or Ultra
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/environment/ssao/quality`
- **Try live:** `measure_change finding=post.ssao_quality_high` applies `[{"setting": "rendering/environment/ssao/quality", "value": 2}]`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `post.ssao_full_res`

- **Title:** SSAO half-size is off
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/environment/ssao/half_size`
- **Try live:** `measure_change finding=post.ssao_full_res` applies `[{"setting": "rendering/environment/ssao/half_size", "value": true}]`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `post.ssao_blur_passes`

- **Title:** SSAO blur passes are above the default
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** ssao/blur_passes defaults to 2 (range 0–6). More passes than the default is extra blur work.
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/environment/ssao/blur_passes`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `post.ssil_quality_high`

- **Title:** SSIL quality is High or Ultra
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/environment/ssil/quality`
- **Try live:** `measure_change finding=post.ssil_quality_high` applies `[{"setting": "rendering/environment/ssil/quality", "value": 2}]`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `post.ssil_full_res`

- **Title:** SSIL half-size is off
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/environment/ssil/half_size`
- **Try live:** `measure_change finding=post.ssil_full_res` applies `[{"setting": "rendering/environment/ssil/half_size", "value": true}]`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `post.ssr_enabled`

- **Title:** Screen-space reflections are enabled
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Environment.ssr_enabled`
- **Try live:** `measure_change finding=post.ssr_enabled` applies `[{"environment": true, "property": "ssr_enabled", "value": false}]`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/environment_and_post_processing.html

### `post.ssr_steps`

- **Title:** SSR max steps is above the Environment default
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Environment.ssr_max_steps defaults to 64 in Godot 4.4. Above 64 traces more steps than that default.
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Environment.ssr_max_steps`
- **Try live:** `measure_change finding=post.ssr_steps` applies `[{"environment": true, "property": "ssr_max_steps", "value": 64, "only_above": 64}]`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_environment.html

### `post.glow_enabled`

- **Title:** Glow is enabled
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Environment.glow_enabled`
- **Try live:** `measure_change finding=post.glow_enabled` applies `[{"environment": true, "property": "glow_enabled", "value": false}]`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/environment_and_post_processing.html

### `post.glow_bicubic`

- **Title:** Glow upscale is bicubic while glow is on
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/environment/glow/upscale_mode`
- **Try live:** `measure_change finding=post.glow_bicubic` applies `[{"setting": "rendering/environment/glow/upscale_mode", "value": 0}]`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `post.volumetric_fog`

- **Title:** Volumetric fog is enabled
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Environment.volumetric_fog_enabled`
- **Try live:** `measure_change finding=post.volumetric_fog` applies `[{"environment": true, "property": "volumetric_fog_enabled", "value": false}]`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/volumetric_fog.html

### `post.volumetric_fog_size`

- **Title:** Volumetric fog volume size or depth is above the default
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/environment/volumetric_fog/volume_size`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/volumetric_fog.html

### `post.fog_enabled`

- **Title:** Distance or height fog is enabled
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Environment.fog_enabled`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/environment_and_post_processing.html

### `post.adjustments`

- **Title:** Color adjustments are enabled
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Environment.adjustment_enabled`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/environment_and_post_processing.html

### `post.dof_enabled`

- **Title:** Depth-of-field blur is enabled
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `CameraAttributesPractical.dof_blur_far_enabled`
- **Try live:** `measure_change finding=post.dof_enabled` applies `[{"camera_attributes": true, "property": "dof_blur_far_enabled", "value": false}, {"camera_attributes": true, "property": "dof_blur_near_enabled", "value": false}]`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `post.dof_circle`

- **Title:** DOF bokeh shape is Circle
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/camera/depth_of_field/depth_of_field_bokeh_shape`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `post.dof_quality_high`

- **Title:** DOF bokeh quality is High
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/camera/depth_of_field/depth_of_field_bokeh_quality`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `post.sss_quality`

- **Title:** Subsurface scattering quality is Medium or High while materials use it
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/environment/subsurface_scattering/subsurface_scattering_quality`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `post.camera_far_default`

- **Title:** Camera far plane is still the default 4000
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Camera3D.far defaults to 4000, which is also the inspector maximum. Keeping the far plane that high retains more of the world in the frustum than a typical scene needs.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Camera3D.far`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_camera3d.html

### `pass.ssao`

- **Title:** Process SSAO is in the capture
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** The trigger is a RenderingDevice timestamp label substring from Godot's clustered renderer. Labels are not a stable public API. The rule fires only when that pass has exclusive time above 0.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Try live:** `measure_change finding=pass.ssao` applies `[{"environment": true, "property": "ssao_enabled", "value": false}]`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/environment_and_post_processing.html

### `pass.ssr`

- **Title:** Screen-space reflections are in the capture
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** The trigger is a RenderingDevice timestamp label substring from Godot's clustered renderer. Labels are not a stable public API. The rule fires only when that pass has exclusive time above 0.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Try live:** `measure_change finding=pass.ssr` applies `[{"environment": true, "property": "ssr_enabled", "value": false}]`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/environment_and_post_processing.html

### `pass.glow`

- **Title:** Glow is in the capture
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** The trigger is a RenderingDevice timestamp label substring from Godot's clustered renderer. Labels are not a stable public API. The rule fires only when that pass has exclusive time above 0.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Try live:** `measure_change finding=pass.glow` applies `[{"environment": true, "property": "glow_enabled", "value": false}]`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/environment_and_post_processing.html

### `pass.vfog`

- **Title:** Volumetric fog is in the capture
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** The trigger is a RenderingDevice timestamp label substring from Godot's clustered renderer. Labels are not a stable public API. The rule fires only when that pass has exclusive time above 0.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Try live:** `measure_change finding=pass.vfog` applies `[{"environment": true, "property": "volumetric_fog_enabled", "value": false}]`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/volumetric_fog.html

### `pass.sss`

- **Title:** Subsurface scattering is in the capture
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** The trigger is a RenderingDevice timestamp label substring from Godot's clustered renderer. Labels are not a stable public API. The rule fires only when that pass has exclusive time above 0.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Try live:** `measure_change finding=pass.sss` applies `[{"setting": "rendering/environment/subsurface_scattering/subsurface_scattering_quality", "value": 0}]`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `post.ssr_half_size_off`

- **Title:** Screen-space reflections are rendered at full size
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.6, 4.7
- **min_version:** 4.6
- **Setting:** `rendering/environment/screen_space_reflection/half_size`
- **Source:** https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html

### `post.ssr_roughness_quality`

- **Title:** SSR roughness quality is above the 4.4 default
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5
- **max_version:** 4.5
- **Setting:** `rendering/environment/screen_space_reflection/roughness_quality`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `post.glow_upscale_mobile`

- **Title:** Mobile devices use bicubic glow upscaling
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/environment/glow/upscale_mode.mobile`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `post.ssil_blur_passes`

- **Title:** SSIL blur passes are above the default
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/environment/ssil/blur_passes`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `post.auto_exposure`

- **Title:** Camera auto exposure is enabled
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_auto_exposure", "value": 1}}`
- **Evidence and limits:** A Camera3D or WorldEnvironment has CameraAttributes with auto_exposure_enabled. Godot docs: "Auto exposure needs to evaluate the scene's brightness every frame, which has a moderate performance cost."
- **Suggested action:** Leave auto exposure disabled if it doesn't make much of a difference in the scene, as the page recommends; set a fixed exposure instead.
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/environment_and_post_processing.html

### `post.color_correction_lut_large`

- **Title:** The color-correction LUT is larger than 65 per side
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_color_correction_lut_large", "value": 1}}`
- **Evidence and limits:** An Environment with adjustments enabled uses a 3D color-correction texture wider than 65 texels; the page lists 17 to 65 per side as typical sizes. The 65 cutoff is a review heuristic. Godot docs: "since color correction is low-frequency data, sticking to low resolutions is recommended for performance reasons."
- **Suggested action:** Resample the LUT to 33 or 65 per side.
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/environment_and_post_processing.html

### `post.fog_density_texture_large`

- **Title:** A FogVolume density texture is larger than 64 per side
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_fog_density_texture_large", "value": 1}}`
- **Evidence and limits:** A FogVolume's FogMaterial uses a 3D density texture wider, taller or deeper than 64 texels. Godot docs: "To improve performance, it's recommended to use low texture sizes (64×64×64 or lower), as high-frequency detail is difficult to notice in a FogVolume."
- **Suggested action:** Resample the density texture to 64×64×64 or lower.
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/volumetric_fog.html

### `post.compositor_msaa_resolve`

- **Title:** A custom compositor requests an intermediate MSAA resolve
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_compositor_msaa_resolve", "value": 1}}`
- **Evidence and limits:** The active camera/world compositor has an enabled pre-opaque, post-opaque or pre-transparent effect requesting resolved color or depth while its live viewport enables 3D MSAA. Forward+ tests those stage flags before resolving. Post-sky and post-transparent stages are excluded from this extra-resolve claim; shared resolves are not counted individually.
- **Suggested action:** Review the effect callback: remove a resolved-buffer request only when it does not read that buffer, or restructure compatible effects to share a rendering stage.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/servers/rendering/renderer_rd/forward_clustered/render_forward_clustered.cpp

### `post.compositor_motion`

- **Title:** A custom compositor requests motion-vector rendering
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_compositor_motion", "value": 1}}`
- **Evidence and limits:** An enabled effect in the active live compositor requests motion vectors, while viewport TAA is off and scaling is bilinear or FSR1. Forward+ enables its motion-vector path for this request. Debug views or other consumers may still need those vectors; no frame-time saving is assumed.
- **Suggested action:** Verify that the effect consumes motion vectors; remove the request only after adapting the callback to work without them.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/servers/rendering/renderer_rd/forward_clustered/render_forward_clustered.cpp

### `post.compositor_extra_buffers`

- **Title:** A custom compositor requests auxiliary lighting buffers
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_compositor_extra_buffers", "value": 1}}`
- **Evidence and limits:** An enabled effect in the active live compositor requests separate specular, or normal/roughness with a resolved Environment. Forward+ can select auxiliary render targets and a specular combine. Other rendering features may already require these buffers. Camera overrides, disabled viewport updates and disabled 3D are respected.
- **Suggested action:** Audit the callback's actual inputs and remove unused normal/roughness or separate-specular requirements, then profile the affected passes.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/servers/rendering/renderer_rd/forward_clustered/render_forward_clustered.cpp

### `post.fog_sdfgi_inject`

- **Title:** Volumetric fog enables SDFGI sampling
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_fog_sdfgi_inject", "value": 1}}`
- **Evidence and limits:** An assigned Environment enables volumetric fog and SDFGI with GI injection above the native 0.0001 threshold. The fog renderer selects its SDFGI shader path when the SDFGI buffers are available. This does not infer VoxelGI, LightmapGI or SSIL contributions.
- **Suggested action:** Compare zero fog GI injection where bounced lighting contributes little to the intended fog appearance.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/servers/rendering/renderer_rd/environment/fog.cpp

### `post.fog_ambient_inject`

- **Title:** Volumetric fog includes ambient-light injection
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_fog_ambient_inject", "value": 1}}`
- **Evidence and limits:** An assigned Environment enables volumetric fog with positive ambient injection. The fog shader evaluates the ambient branch and can sample sky radiance. The documented cost is small; the configured feature alone does not establish a bottleneck.
- **Suggested action:** Compare zero ambient injection if ambient lighting adds little to the intended fog appearance.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/servers/rendering/renderer_rd/shaders/environment/volumetric_fog_process.glsl

### `post.ssao_large_radius`

- **Title:** SSAO radius exceeds the default
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Renderer scope by version:** `{"4.4": ["forward_plus"], "4.6": ["forward_plus", "gl_compatibility"]}`
- **Observed condition:** `{"scene_gte": {"name": "check_ssao_large_radius", "value": 1}}`
- **Evidence and limits:** An assigned Environment enables SSAO with radius above its 1.0 default. Godot documents greater occlusion distance at a performance and quality cost. Compatibility supports this feature from 4.6 (the 4.5 GLES3 driver only stores the settings).
- **Suggested action:** Compare a smaller SSAO radius that still captures the intended contact shading.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/Environment.xml

### `post.fog_aerial`

- **Title:** Fog samples sky radiance for aerial perspective
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_fog_aerial", "value": 1}}`
- **Evidence and limits:** An assigned Environment enables regular fog with positive fog_aerial_perspective, a sky background and a sky material. The Forward+ and Mobile fog shaders sample sky radiance; the documentation describes a small performance cost.
- **Suggested action:** Compare a fixed fog color by setting aerial perspective to zero where the visual difference is acceptable.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/Environment.xml

### `post.camera_blur_amount`

- **Title:** Depth-of-field blur exceeds the documented default amount
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_camera_blur_amount", "value": 1}}`
- **Evidence and limits:** Assigned CameraAttributesPractical enables near or far depth of field with dof_blur_amount above its 0.1 default. Higher blur amounts can be more expensive; the default is a review threshold, not a quality limit. Physical camera attributes are excluded.
- **Suggested action:** Compare a lower blur amount and remeasure with the same camera and focus distances.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/CameraAttributesPractical.xml

### `post.compositor_pre_opaque_resolved`

- **Title:** A pre-opaque compositor effect asks for resolved buffers
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_compositor_pre_opaque_resolved", "value": 1}}`
- **Evidence and limits:** Godot prints "Pre opaque rendering effects can't access resolved color buffers." when a Pre-Opaque CompositorEffect sets access_resolved_color (or access_resolved_depth without a depth prepass) on a viewport with 3D MSAA; nothing has been rendered to resolve at that point.
- **Suggested action:** Move the effect to a later callback, or clear the access_resolved flags it cannot use.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/renderer_rd/forward_clustered/render_forward_clustered.cpp

### `post.compositor_mobile_unsupported`

- **Title:** A compositor effect uses a callback the Mobile renderer does not run
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_compositor_mobile_unsupported", "value": 1}}`
- **Evidence and limits:** Godot prints "Post opaque rendering effect callback is not supported in the mobile renderer" for a Post-Opaque CompositorEffect under the Mobile renderer, which renders opaque geometry and sky in subpasses; the renderer also prints that resolved depth access is unsupported when an effect asks for it with 3D MSAA.
- **Suggested action:** Use the Pre-Transparent or Post-Transparent callback on Mobile, or disable 3D MSAA for effects that read resolved depth.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/renderer_rd/forward_mobile/render_forward_mobile.cpp

## materials

### `materials.alpha_blend`

- **Title:** Materials use alpha blend transparency
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `BaseMaterial3D.transparency`
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/resources/material.cpp

### `materials.alpha_blend_depth_always`

- **Title:** Alpha-blend materials write depth every fragment
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `BaseMaterial3D.depth_draw_mode`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_basematerial3d.html

### `materials.depth_prepass_transparency`

- **Title:** Materials use the depth-prepass transparency mode
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `BaseMaterial3D.transparency`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_basematerial3d.html

### `materials.double_sided`

- **Title:** Materials disable backface culling
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `BaseMaterial3D.cull_mode`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_basematerial3d.html

### `materials.per_pixel_particles`

- **Title:** Particle materials are per-pixel shaded
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Counts BaseMaterial3D shading_mode Per-Pixel (index 1) used by GPUParticles3D or CPUParticles3D. The GPU optimization page says non-unshaded particles can force vertex shading to cut cost.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `BaseMaterial3D.shading_mode`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/performance/gpu_optimization.html

### `materials.shader_materials`

- **Title:** ShaderMaterials are in the scene
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Any ShaderMaterial is reported because the pipeline-compilations page says material changes create pipelines that are not covered until that variant is seen. The count is not a budget.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `ShaderMaterial`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/performance/pipeline_compilations.html

### `materials.subsurf`

- **Title:** Materials enable subsurface scattering
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `BaseMaterial3D.subsurf_scatter_enabled`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_basematerial3d.html

### `materials.refraction`

- **Title:** Materials enable refraction
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `BaseMaterial3D.refraction_enabled`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_basematerial3d.html

### `materials.heightmap`

- **Title:** Materials enable height mapping
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `BaseMaterial3D.heightmap_enabled`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_basematerial3d.html

### `materials.proximity_fade`

- **Title:** Materials enable proximity fade
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `BaseMaterial3D.proximity_fade_enabled`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_basematerial3d.html

### `materials.shader_material_copies`

- **Title:** Several ShaderMaterials repeat one shader and differ only in instance-uniform values
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Distinct ShaderMaterial resources in the scene that use the same shader and the same textures, matrices and uniform arrays, so they differ at most in scalars, vectors and colors, which per-instance uniforms can hold (shader_language.cpp rejects the instance qualifier on samplers, matrices and arrays). Any copy is reported; the count is not a budget.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `ShaderMaterial.set_shader_parameter`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_shadermaterial.html

### `materials.material_alpha_to_coverage`

- **Title:** Materials use alpha to coverage
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_material_alpha_to_coverage", "value": 1}}`
- **Evidence and limits:** A BaseMaterial3D with Alpha Scissor or Alpha Hash transparency has alpha_antialiasing_mode set (material.cpp emits alpha to coverage only for those two modes). Godot docs: "Alpha to coverage has a moderate performance cost, but it's effective at reducing aliasing on transparent materials without introducing any blurriness."
- **Suggested action:** Keep alpha antialiasing on foliage, fences and hair whose edges visibly alias, and turn it off elsewhere; it has no effect without MSAA.
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/3d_antialiasing.html

### `materials.shader_discard`

- **Title:** Custom spatial shaders use discard
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_shader_discard", "value": 1}}`
- **Evidence and limits:** A spatial ShaderMaterial's shader code contains a discard statement (comments ignored). Godot docs: "Beware that discard has a performance cost when used, as it will prevent the depth prepass from being effective on any surfaces using the shader."
- **Suggested action:** Use discard only where alpha testing is needed, and keep it out of shaders used on large opaque surfaces; BaseMaterial3D alpha scissor has the same cost.
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/shaders/shader_reference/shading_language.html

### `materials.parallax_layers`

- **Title:** Deep parallax uses more layers than the default
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_parallax_layers", "value": 1}}`
- **Evidence and limits:** An effective BaseMaterial3D uses deep parallax with heightmap_max_layers above 32 or heightmap_min_layers above 8 (the defaults). Godot class reference: "Higher values have a significant cost on the GPU, so it should only be increased on materials where it makes a significant visual difference."
- **Suggested action:** Return heightmap_max_layers/min_layers toward 32/8 unless steep height changes visibly need more.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/BaseMaterial3D.xml

### `materials.material_orm_pack`

- **Title:** Separate metallic and roughness maps can share a packed texture
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"all": [{"scene_gte": {"name": "check_material_orm_pack", "value": 1}}, {"setting_eq": {"path": "rendering/shading/overrides/force_vertex_shading", "value": false}}]}`
- **Evidence and limits:** An effective per-pixel StandardMaterial3D has metallic and roughness textures with nonzero multipliers. The generated shader samples them separately; ORMMaterial3D reads channels from one ORM sample. AO using UV2 is excluded because packed ORM uses UV1.
- **Suggested action:** Compare an ORMMaterial3D with correctly packed AO/roughness/metallic channels; preserve scalar multipliers in the packed data and verify texture import/color-space settings.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/resources/material.cpp

### `materials.material_next_pass`

- **Title:** Materials request additional geometry passes
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_material_next_pass", "value": 1}}`
- **Evidence and limits:** An effective spatial material has next_pass assigned; the surface is drawn again with that material.
- **Suggested action:** Remove a next pass only if its outline or other visual effect is unnecessary.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/Material.xml

### `materials.material_triplanar_uv1`

- **Title:** Albedo textures use UV1 triplanar sampling
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_material_triplanar_uv1", "value": 1}}`
- **Evidence and limits:** An effective BaseMaterial3D has UV1 triplanar enabled and an albedo texture assigned; triplanar sampling combines three projections per texture lookup.
- **Suggested action:** Compare imported mesh UVs with triplanar mapping on assets where UV authoring is practical.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/BaseMaterial3D.xml

### `materials.material_triplanar_uv2`

- **Title:** Detail albedo uses UV2 triplanar sampling
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_material_triplanar_uv2", "value": 1}}`
- **Evidence and limits:** Detail mapping is enabled with a detail albedo texture, UV2 selected and UV2 triplanar enabled.
- **Suggested action:** Use mesh UV2 for detail mapping where its appearance is acceptable.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/BaseMaterial3D.xml

### `materials.material_deep_parallax`

- **Title:** Height maps use deep parallax sampling
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_material_deep_parallax", "value": 1}}`
- **Evidence and limits:** Height mapping and deep parallax are enabled with a height texture and UV1 triplanar disabled.
- **Suggested action:** Compare simple parallax, fewer parallax layers or a normal map at the intended viewing distance.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/BaseMaterial3D.xml

### `materials.material_clearcoat`

- **Title:** Per-pixel materials enable clearcoat lighting
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"all": [{"scene_gte": {"name": "check_material_clearcoat", "value": 1}}, {"setting_eq": {"path": "rendering/shading/overrides/force_vertex_shading", "value": false}}]}`
- **Evidence and limits:** An effective per-pixel material enables clearcoat with a positive amount, adding the clearcoat lighting term.
- **Suggested action:** Compare clearcoat disabled on surfaces where the coating is hard to see.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/BaseMaterial3D.xml

### `materials.material_rim`

- **Title:** Per-pixel materials enable rim lighting
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"all": [{"scene_gte": {"name": "check_material_rim", "value": 1}}, {"setting_eq": {"path": "rendering/shading/overrides/force_vertex_shading", "value": false}}]}`
- **Evidence and limits:** An effective per-pixel material enables rim lighting with a positive amount.
- **Suggested action:** Compare rim lighting disabled on materials that do not need the stylized edge effect.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/BaseMaterial3D.xml

### `materials.material_anisotropy`

- **Title:** Per-pixel materials enable anisotropic lighting
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"all": [{"scene_gte": {"name": "check_material_anisotropy", "value": 1}}, {"setting_eq": {"path": "rendering/shading/overrides/force_vertex_shading", "value": false}}]}`
- **Evidence and limits:** An effective per-pixel material enables nonzero anisotropy, adding anisotropic lighting calculations.
- **Suggested action:** Compare isotropic lighting on surfaces whose directional highlights are not prominent.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/BaseMaterial3D.xml

### `materials.material_detail`

- **Title:** Materials sample a detail texture layer
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"all": [{"scene_gte": {"name": "check_material_detail", "value": 1}}, {"setting_eq": {"path": "rendering/shading/overrides/force_vertex_shading", "value": false}}]}`
- **Evidence and limits:** Detail mapping is enabled with detail albedo, or with detail normal on a per-pixel material.
- **Suggested action:** Compare a baked base texture or disabled detail layer where extra close-up detail is not visible.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/BaseMaterial3D.xml

### `materials.material_normal`

- **Title:** Per-pixel materials sample normal maps
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"all": [{"scene_gte": {"name": "check_material_normal", "value": 1}}, {"setting_eq": {"path": "rendering/shading/overrides/force_vertex_shading", "value": false}}]}`
- **Evidence and limits:** Normal mapping is enabled with a normal texture and nonzero normal scale on an effective per-pixel material.
- **Suggested action:** Compare disabling normal maps only on distant or visually flat surfaces.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/BaseMaterial3D.xml

### `materials.subsurf_renderer`

- **Title:** Subsurface scattering is enabled outside Forward+
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "subsurf_material_count", "value": 1}}`
- **Evidence and limits:** Godot prints "Subsurface scattering is only available when using the Forward+ renderer." when a material enables subsurface scattering under the Mobile or Compatibility renderer, which do not draw it.
- **Suggested action:** Turn subsurf_scatter_enabled off for this renderer, or fake the look in the albedo or a custom shader.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/renderer_rd/forward_mobile/scene_shader_forward_mobile.cpp

### `materials.transmittance_renderer`

- **Title:** Subsurface transmittance is enabled outside Forward+
- **Severity:** low
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_transmittance_material", "value": 1}}`
- **Evidence and limits:** Godot prints "Transmittance is only available when using the Forward+ renderer." when a material enables subsurface transmittance under the Mobile or Compatibility renderer, which do not draw it.
- **Suggested action:** Turn subsurf_scatter_transmittance_enabled off for this renderer.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/renderer_rd/forward_mobile/scene_shader_forward_mobile.cpp

### `materials.shader_param_old_names`

- **Title:** A ShaderMaterial is saved with pre-4.0 parameter names
- **Severity:** low
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_shader_param_old_names", "value": 1}}`
- **Evidence and limits:** Godot prints "This material (containing shader with path: 'res://water.gdshader') uses an old deprecated parameter names. Consider re-saving this resource (or scene which contains it) in order for it to continue working in future versions." when a saved ShaderMaterial (in a .tscn or .tres) stores parameters as shader_param/, param/ or shader_uniform/ instead of shader_parameter/; Godot renames them on every load.
- **Suggested action:** Open and re-save the resource or scene so the parameters are stored as shader_parameter/.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/scene/resources/material.cpp

## geometry

### `geometry.multimesh_candidate`

- **Title:** Many MeshInstance3D nodes share one mesh
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Four or more MeshInstance3D nodes sharing one mesh resource is the cut. The MultiMesh page is the tool for repeated instances. The optimizing-3D page also notes automatic instancing for identical opaque mesh-and-material pairs, which does not replace MultiMesh for large counts.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `MultiMeshInstance3D`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/using_multi_mesh_instance.html

### `geometry.high_surface_count`

- **Title:** A mesh has several surfaces
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Three or more surfaces on one mesh is the cut. Each surface is a separate draw with its own material. The optimizing-3D page says to split only the part that must be transparent.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Mesh.get_surface_count`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/performance/optimizing_3d_performance.html

### `geometry.no_visibility_range`

- **Title:** Many meshes have no visibility range
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Fires when at least 30 MeshInstance3D nodes leave visibility_range_begin and visibility_range_end at 0. The visibility-range page is aimed at large scenes; 30 is a review cut, not a Godot limit.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `GeometryInstance3D.visibility_range_end`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/visibility_ranges.html

### `geometry.lod_threshold_below_default`

- **Title:** Mesh LOD threshold is below the default 1 pixel
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/mesh_lod/lod_change/threshold_pixels`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/mesh_lod.html

### `geometry.lod_bias_high`

- **Title:** Mesh LOD bias is above 1
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `GeometryInstance3D.lod_bias`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/mesh_lod.html

### `geometry.occlusion_without_occluders`

- **Title:** Occlusion culling is on without occluder nodes
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/occlusion_culling/use_occlusion_culling`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/occlusion_culling.html

### `geometry.occlusion_bvh_high`

- **Title:** Occlusion BVH build quality is High
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/occlusion_culling/bvh_build_quality`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/occlusion_culling.html

### `geometry.occlusion_rays`

- **Title:** Occlusion rays per thread are above the default
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** occlusion_rays_per_thread defaults to 512. Above that is more rays than the default the occlusion page says you can lower.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/occlusion_culling/occlusion_rays_per_thread`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/occlusion_culling.html

### `geometry.ignore_occlusion`

- **Title:** Meshes opt out of occlusion culling
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `GeometryInstance3D.ignore_occlusion_culling`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/occlusion_culling.html

### `geometry.opaque_pass_share`

- **Title:** The opaque pass is a large share of measured GPU time
- **Severity:** high
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** 25% of the median timestamp-span frame is a review cut so the opaque pass is only flagged when it is a large measured slice. The percentage is not a Godot budget.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/performance/optimizing_3d_performance.html

### `geometry.transparent_pass_share`

- **Title:** The transparent pass is a large share of measured GPU time
- **Severity:** high
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** 15% of measured frame GPU time is a review cut for the transparent pass. It is not a documented budget.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/performance/gpu_optimization.html

### `geometry.multimesh_many_instances`

- **Title:** A MultiMesh permits at least 256 visible instances
- **Severity:** low
- **Kind:** info
- **Heuristic:** yes
- **Heuristic rationale:** The scan caps instance_count by visible_instance_count when set, excludes missing meshes, and covers 2D/3D MultiMesh nodes. 256 is a review prompt, not a Godot limit or a measured draw count.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `MultiMesh.visible_instance_count`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_multimesh.html

### `geometry.multimesh_custom_aabb`

- **Title:** A large MultiMesh has no custom AABB
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_multimesh_custom_aabb", "value": 1}}`
- **Evidence and limits:** A visible MultiMeshInstance3D holds at least 4096 instances and its MultiMesh has no custom_aabb, so every instance change recomputes the bounds. Whether instances change at runtime is not observed. Godot class reference: "Setting this manually prevents costly runtime AABB recalculations."
- **Suggested action:** Set MultiMesh.custom_aabb to bounds that cover all instances, especially when scripts update instance transforms.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/MultiMesh.xml

### `geometry.occluder_dense`

- **Title:** An occluder has many triangles or points
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_occluder_dense", "value": 1}}`
- **Evidence and limits:** An OccluderInstance3D uses an ArrayOccluder3D with more than 10,000 triangles or a PolygonOccluder3D with more than 64 points. Godot class reference: "The occluder geometry is rendered on the CPU, so it is important to keep its geometry as simple as possible."
- **Suggested action:** Rebake with a higher bake_simplification_distance, or use fewer, simpler occluder shapes.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/OccluderInstance3D.xml

### `geometry.gridmap_small_octants`

- **Title:** A populated GridMap uses very small rendering octants
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_gridmap_small_octants", "value": 1}}`
- **Evidence and limits:** A visible, unbaked GridMap sets cell_octant_size to 1 or 2 and more than 256 inspected cells refer to library items with recognized native meshes containing at least one surface. Custom mesh classes and empty meshes are skipped. Both native versions create a MultiMesh/render instance for each occupied item/octant combination. The cutoff is a review heuristic, not a measured batch count. Baked meshes use a different path and are excluded. At most 4096 cells across qualifying GridMaps are inspected; skipped cells are reported, and the public cell-list getter still returns its full list.
- **Suggested action:** Compare the default octant size of 8 or a size that fits the level, then measure draw calls and frame time along the same camera route.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/modules/gridmap/grid_map.cpp

### `geometry.primitive_density`

- **Title:** A procedural primitive requests dense geometry
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_primitive_density", "value": 1}}`
- **Evidence and limits:** A MeshInstance2D/3D uses a PlaneMesh, BoxMesh, SphereMesh, CylinderMesh, CapsuleMesh or TorusMesh whose native subdivision loops generate at least 8192 vertices. The estimate uses only stored segment counts; cylinder caps are omitted, making it a lower bound. No mesh generation or GPU buffer download is requested by this check. 8192 is a review cutoff, not an engine limit.
- **Suggested action:** Compare fewer subdivisions at the intended viewing distance, retaining enough vertices for displacement and deformation.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/resources/3d/primitive_meshes.cpp

### `geometry.textmesh_detail`

- **Title:** A TextMesh requests dense glyph geometry
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_textmesh_detail", "value": 1}}`
- **Evidence and limits:** A MeshInstance2D/3D assigns a nonblank TextMesh with curve_step below 0.5 or font_size above 63. Native curve subdivision uses curve_step divided by curve length; contours are obtained at font_size. Generated glyph geometry is cached and rebuilt on relevant changes, not automatically every frame. The cutoffs are review heuristics.
- **Suggested action:** Compare the default curve step and a smaller font size while preserving apparent size. For animated size changes, scale the node instead of regenerating mesh settings.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/resources/3d/primitive_meshes.cpp

### `geometry.skin_eight_weights`

- **Title:** A live skinned mesh uses eight bone influences
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_skin_eight_weights", "value": 1}}`
- **Evidence and limits:** An ArrayMesh surface with bone attributes uses the eight-weight format and resolves to a nonempty live Skeleton3D. The RD skinning shader loads and combines four additional influences in this format. Only stored surface metadata is read; weight buffers are not downloaded. Skinning updates can be cached when unchanged.
- **Suggested action:** For measured skinning bottlenecks, compare an asset limited to four normalized influences per vertex and inspect every animation.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/servers/rendering/renderer_rd/shaders/skeleton.glsl

### `geometry.mesh_cull_margin`

- **Title:** Mesh culling margin exceeds its largest stored bound dimension
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_mesh_cull_margin", "value": 1}}`
- **Evidence and limits:** An ArrayMesh instance has extra_cull_margin larger than the largest positive AABB dimension. Instance custom bounds take precedence over resource custom bounds and stored mesh bounds. The native culler grows bounds on every side by the margin; this scale-relative review threshold is heuristic.
- **Suggested action:** Inspect shader deformation and animation extents, then compare a tighter margin only if the expanded bound is unnecessary.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/servers/rendering/renderer_scene_cull.cpp

### `geometry.viewport_lod_disabled`

- **Title:** A SubViewport disables automatic mesh LOD
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_viewport_lod_disabled", "value": 1}}`
- **Evidence and limits:** A SubViewport with updates and 3D enabled has mesh_lod_threshold set to zero. This is its own threshold, independent of the root viewport's project setting. Meshes without generated LODs receive no benefit from changing it.
- **Suggested action:** Compare a threshold of one pixel or higher in this SubViewport with meshes that have generated LODs.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/Viewport.xml

### `geometry.geometry_fade_cost`

- **Title:** Visibility ranges enable alpha fading
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_geometry_fade_cost", "value": 1}}`
- **Evidence and limits:** A valid visibility range enables Self or Dependencies fading with a positive transition margin at a nonzero boundary. Geometry can enter the transparent path while fading; actual camera distance is not evaluated.
- **Suggested action:** Compare disabled fading with a nonzero hysteresis margin where popping is acceptable.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/GeometryInstance3D.xml

### `geometry.mesh_old_surface_format`

- **Title:** A saved mesh uses an old surface format that is upgraded on every load
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_mesh_old_surface_format", "value": 1}}`
- **Evidence and limits:** Godot prints "A surface of res://props/crate.tres uses an old surface format and needs to be upgraded." when an ArrayMesh saved in a .tscn or .tres has a surface format without the current format version (bits 35-42, ARRAY_FLAG_FORMAT_VERSION). Godot's message continues that the upgrade happens automatically at load time every time until the mesh is saved again or re-imported. Binary .res/.mesh files are not read.
- **Suggested action:** Re-save the scene or resource (or re-import the source model) in the current Godot version.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/rendering_server.cpp

## textures

### `textures.anisotropy_16x`

- **Title:** Anisotropic filtering is 16×
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/textures/default_filters/anisotropic_filtering_level`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `textures.anisotropy_off`

- **Title:** Anisotropic filtering is disabled
- **Severity:** low
- **Kind:** quality_up
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/textures/default_filters/anisotropic_filtering_level`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/assets_pipeline/importing_images.html

### `textures.nearest_mip_filter`

- **Title:** Nearest mipmap filter is forced
- **Severity:** info
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/textures/default_filters/use_nearest_mipmap_filter`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `textures.vram_uncompressed`

- **Title:** Imported textures use VRAM uncompressed
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `compress/mode`
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/editor/import/resource_importer_texture.h

### `textures.lossless_3d`

- **Title:** Textures used in 3D are imported lossless
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `compress/mode`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/assets_pipeline/importing_images.html

### `textures.no_mipmaps`

- **Title:** 3D textures have mipmaps disabled
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `mipmaps/generate`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/assets_pipeline/importing_images.html

### `textures.large_dimension`

- **Title:** A texture is larger than 2048 on a side
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** 2048 is not a Godot maximum. Textures wider or taller than 2048 are called out because they dominate VRAM relative to the 256 default reflection size and the 4096 shadow maps.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Texture2D.get_width`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/assets_pipeline/importing_images.html

### `textures.decal_filter_aniso`

- **Title:** Decal filter uses anisotropic samples
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/textures/decals/filter`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/using_decals.html

### `textures.webp_method_slow`

- **Title:** WebP compression method is above 4
- **Severity:** low
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/textures/webp_compression/compression_method`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `textures.gpu_compress_off`

- **Title:** GPU texture compression is disabled
- **Severity:** info
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/textures/vram_compression/compress_with_gpu`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `textures.noise_texture_startup`

- **Title:** A procedural noise texture has a large generation workload
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_noise_texture_startup", "value": 1}}`
- **Evidence and limits:** An observed NoiseTexture2D/3D with an assigned generator contains at least 1048576 configured texels. Native texture updates explicitly run the first update without a worker thread; later updates can use workers. Resource lifecycle determines whether that first update already had its generator. The scanner reads dimensions only and never generates or downloads the texture.
- **Suggested action:** For static noise, compare a pre-generated imported texture; otherwise prepare it during a loading phase and measure startup or regeneration spikes.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/modules/noise/noise_texture_2d.cpp

### `textures.noise_texture_octaves`

- **Title:** A noise texture samples more fractal layers than the default
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_noise_texture_octaves", "value": 1}}`
- **Evidence and limits:** An observed noise texture of at least 65536 texels uses FastNoiseLite with active ordinary fractal octaves above five, or enabled fractal domain warp above five. The wrapper forwards octave counts and the native implementation loops over them per sample. Disabled fractal/warp modes are excluded; these are generation costs, not continuous fragment-shader costs.
- **Suggested action:** Compare fewer noise or warp octaves while keeping the detail needed at the displayed scale; profile regeneration, especially during loading.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/modules/noise/fastnoise_lite.cpp

### `textures.gradient_hdr_size`

- **Title:** A large procedural gradient uses full-float pixels
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_gradient_hdr_size", "value": 1}}`
- **Evidence and limits:** A built-in Sprite2D, Sprite3D or TextureRect texture is a GradientTexture2D with HDR enabled and at least 512 by 512 pixels in total. Native generation selects RGBAF rather than RGBA8: four times the base pixel bytes. The size cutoff is heuristic and does not measure GPU residency or regeneration frequency.
- **Suggested action:** Compare a smaller gradient, or disable HDR only when overbright colors and float precision are unnecessary.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/resources/gradient_texture.cpp

### `textures.animated_texture`

- **Title:** A sprite or texture control uses an actively animated texture resource
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_animated_texture", "value": 1}}`
- **Evidence and limits:** Sprite2D, Sprite3D or TextureRect assigns an AnimatedTexture with multiple frames, nonzero speed and playback unpaused. Godot warns that this deprecated implementation is inefficient on modern renderers. Custom/parent canvas materials and 3D material overrides are excluded.
- **Suggested action:** For these node uses, compare AnimatedSprite2D/3D or explicit texture/frame animation while preserving playback timing and visual output.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/AnimatedTexture.xml

## particles

### `particles.gpu_amount`

- **Title:** A GPU particle amount is far above the default
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** GPUParticles2D and GPUParticles3D amount default to 8. 64 is eight times that default. The particles properties page says raising Amount spawns more particles at a performance cost and does not define this cut.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `GPUParticles2D/3D.amount`
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/GPUParticles3D.xml

### `particles.cpu_nodes`

- **Title:** CPU particle nodes are in the scene
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `CPUParticles2D/3D`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_cpuparticles3d.html

### `particles.trails`

- **Title:** GPU particle trails are enabled
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `GPUParticles2D/3D.trail_enabled`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/particles/trails.html

### `particles.collision`

- **Title:** Particle process materials enable collision
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `ParticleProcessMaterial.collision_mode`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/particles/properties.html

### `particles.fixed_fps_high`

- **Title:** Particle Fixed FPS is at or above 60
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** 60 matches a common display rate, not a particle constant. fixed_fps defaults to 30. The properties page says Fixed FPS limits how often the system is processed.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `GPUParticles2D/3D.fixed_fps`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/particles/properties.html

### `particles.draw_passes`

- **Title:** GPU particles use more than one draw pass
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `GPUParticles3D.draw_passes`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_gpuparticles3d.html

### `particles.heightfield_resolution`

- **Title:** Particle heightfield collision resolution is Slow or worse
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `GPUParticlesCollisionHeightField3D.resolution`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_gpuparticles3d.html

### `particles.many_systems`

- **Title:** Many particle nodes are in the scene
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Eight particle nodes is a review cut so a scene full of systems is surfaced. It is not an engine limit.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/particles/properties.html

### `particles.trail_mesh_detail`

- **Title:** A particle trail mesh uses more segments than the default
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_trail_mesh_detail", "value": 1}}`
- **Evidence and limits:** A trail-enabled GPUParticles3D draws a RibbonTrailMesh with section_segments above 3, or a TubeTrailMesh with radial_steps above 8 or section_rings above 3 (the defaults); every particle draws that geometry. Godot class reference: "Higher values result in a more detailed tube at the cost of performance."
- **Suggested action:** Return the trail mesh's segment counts toward the defaults unless the curve visibly needs them.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/TubeTrailMesh.xml

### `particles.particle_sdf2d_quality`

- **Title:** 2D particle collisions use an enlarged or high-resolution SDF
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_particle_sdf2d_quality", "value": 1}}`
- **Evidence and limits:** A live GPUParticles2D uses built-in collision and its owning viewport has SDF scale above 50 percent or oversize above 120 percent. These exceed viewport defaults and increase the SDF workload when collision rendering uses it. Custom process shaders and unresolved detached viewports are excluded.
- **Suggested action:** Compare the default SDF scale/oversize while moving the camera and testing particle collisions at viewport edges.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/Viewport.xml

### `particles.gpu_depth_sort`

- **Title:** 3D GPU particles request a depth-sort pass
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_gpu_depth_sort", "value": 1}}`
- **Evidence and limits:** GPUParticles3D uses DRAW_ORDER_VIEW_DEPTH with more than one particle. The RD backend allocates a sort buffer and runs SortEffects for this mode. Lifetime ordering does not take this GPU sorting branch.
- **Suggested action:** Compare index ordering for opaque or order-independent particle effects; retain depth sorting where transparency needs it.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/servers/rendering/renderer_rd/storage_rd/particles_storage.cpp

### `particles.heightfield_camera`

- **Title:** Particle height-field collision follows camera movement
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_heightfield_camera", "value": 1}}`
- **Evidence and limits:** The height-field collider follows the camera in UPDATE_MODE_WHEN_MOVED. Godot documents that camera movement forces height-map updates. UPDATE_MODE_ALWAYS is already covered by its own finding.
- **Suggested action:** Compare a fixed collider or lower resolution if the effect permits it; measure while moving the same camera path.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/GPUParticlesCollisionHeightField3D.xml

### `particles.particle_trail_segments`

- **Title:** 2D particle trails exceed the default mesh complexity
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_particle_trail_segments", "value": 1}}`
- **Evidence and limits:** GPUParticles2D enables trails with trail_sections times trail_section_subdivisions above the default 8 times 4. The native trail mesh uses this product as its segment count; 32 is a review heuristic, not a limit.
- **Suggested action:** Compare fewer trail sections or subdivisions while preserving the required curve smoothness.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/2d/gpu_particles_2d.cpp

### `particles.particle_warmup`

- **Title:** GPU particles request substantial startup preprocessing
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_particle_warmup", "value": 1}}`
- **Evidence and limits:** GPUParticles2D/3D.preprocess multiplied by fixed_fps (30 when zero) is at least 120 estimated simulation steps. The 120-step review threshold is heuristic, not a timeout limit.
- **Suggested action:** Reduce preprocessing for emitters that can start gradually, and measure the first frame or restart separately.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/GPUParticles3D.xml

### `particles.particle_sdf_large`

- **Title:** A particle collision SDF has a large texture dimension
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_particle_sdf_large", "value": 1}}`
- **Evidence and limits:** An assigned SDF Texture3D has a dimension of at least 256 voxels. This inspects the actual texture, not a resolution setting awaiting a bake. Shape, format and other dimensions determine memory cost.
- **Suggested action:** Test a lower-resolution rebake if collision precision allows it, then compare the assigned texture dimensions and VRAM.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/GPUParticlesCollisionSDF3D.xml

### `particles.particle_heightfield_always`

- **Title:** A particle height field updates every frame
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_particle_heightfield_always", "value": 1}}`
- **Evidence and limits:** GPUParticlesCollisionHeightField3D.update_mode is UPDATE_MODE_ALWAYS.
- **Suggested action:** Use UPDATE_MODE_WHEN_MOVED when the collision geometry does not change independently of the collider.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/GPUParticlesCollisionHeightField3D.xml

### `particles.particle_turbulence`

- **Title:** GPU particles enable turbulence noise
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_particle_turbulence", "value": 1}}`
- **Evidence and limits:** An effective ParticleProcessMaterial on GPUParticles2D/3D enables turbulence. Godot documents a high GPU cost; custom process shaders are not inferred.
- **Suggested action:** Compare disabled turbulence or a simpler motion pattern on distant effects, especially on mobile/web targets.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/ParticleProcessMaterial.xml

### `particles.particle_vector_resolution`

- **Title:** A particle vector field exceeds the documented low-resolution example
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_particle_vector_resolution", "value": 1}}`
- **Evidence and limits:** A vector-field attractor with nonzero strength and nonempty layer mask has more than 64*64*64 texture voxels. Godot describes 64-cubed as an example appropriate for low-frequency attraction data; it is not a hardware limit.
- **Suggested action:** Compare a lower-resolution field while preserving the attractor's world size.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/GPUParticlesAttractorVectorField3D.xml

## decals

### `decals.count`

- **Title:** Many decals are in the scene
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Sixteen decals is a review cut. The decal page says Forward+ clusters as many as performance allows, with a default limit of 512 clustered elements in view.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Decal.distance_fade_enabled`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/using_decals.html

### `decals.no_distance_fade`

- **Title:** Decals have no distance fade
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Decal.distance_fade_enabled`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/performance/optimizing_3d_performance.html

### `decals.compatibility_renderer`

- **Title:** Decals are present under the Compatibility renderer
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Decal`
- **Godot also warns:** in the editor (configuration warning)
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/using_decals.html

### `decals.large_size`

- **Title:** A decal is very large
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A decal size axis of 50 meters or more covers a large cluster region. The property range goes to 1024. 50 is a review cut.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Decal.size`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/using_decals.html

### `decals.decal_normal_fade`

- **Title:** A decal uses normal-angle fading
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_decal_normal_fade", "value": 1}}`
- **Evidence and limits:** A visible Decal with a nonzero cull_mask has normal_fade above 0. Godot class reference: "Setting to a value greater than 0.0 has a small performance cost due to the added normal angle computations."
- **Suggested action:** Set normal_fade to 0 where the decal does not need to fade on steep surfaces.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/Decal.xml

## sky

### `sky.quality_mode`

- **Title:** Sky process mode is Quality
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Sky.process_mode`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_sky.html

### `sky.radiance_size`

- **Title:** Sky radiance size is 1024 or 2048
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Sky.radiance_size`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_sky.html

### `sky.background_keep`

- **Title:** Environment background mode is Keep
- **Severity:** info
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Environment.background_mode`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/3d/environment_and_post_processing.html

### `sky.custom_fov`

- **Title:** Sky custom FOV is set
- **Severity:** info
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Environment.sky_custom_fov`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_environment.html

### `sky.realtime_radiance_size`

- **Title:** A real-time sky asks for a radiance size other than 256
- **Severity:** low
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_sky_realtime_radiance", "value": 1}}`
- **Evidence and limits:** Godot prints "Realtime Skies can only use a radiance size of 256. Radiance size will be set to 256 internally." when Sky.process_mode is Real-Time and radiance_size is not 256; the radiance map is set to 256 internally.
- **Suggested action:** Set Sky.radiance_size to 256 for real-time skies, or use another process mode if a different size is needed.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/renderer_rd/environment/sky.cpp

### `sky.realtime_roughness_layers`

- **Title:** A real-time sky runs with roughness layers other than 8
- **Severity:** low
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"all": [{"scene_gte": {"name": "check_sky_realtime", "value": 1}}, {"setting_neq": {"path": "rendering/reflections/sky_reflections/roughness_layers", "value": 8}}]}`
- **Evidence and limits:** Godot prints "When using the Real-Time sky update mode (or Automatic with a sky shader using "TIME"), "rendering/reflections/sky_reflections/roughness_layers" should be set to 8 in the project settings for best quality reflections." when Sky.process_mode is Real-Time and rendering/reflections/sky_reflections/roughness_layers is not 8 (Godot 4.4 and 4.5); real-time skies always use 8 layers.
- **Suggested action:** Set roughness_layers to 8, or use a non-real-time sky process mode.
- **Source:** https://github.com/godotengine/godot/blob/4.5.2-stable/servers/rendering/renderer_rd/environment/sky.cpp

## canvas

### `canvas.pcf13`

- **Title:** A 2D light uses PCF13 shadows
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Light2D.shadow_filter`
- **Try live:** `measure_change finding=canvas.pcf13` applies `[{"class": "Light2D", "property": "shadow_filter", "value": 1, "only_above": 1}]`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/2d/2d_lights_and_shadows.html

### `canvas.many_shadow_lights`

- **Title:** Several 2D lights cast shadows
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Four shadow-casting Light2D nodes is a review cut. The 2D lights page says even PCF13 should be limited to a few lights.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Light2D.shadow_enabled`
- **Try live:** `measure_change finding=canvas.many_shadow_lights` applies `[{"class": "Light2D", "property": "shadow_enabled", "value": false}]`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/2d/2d_lights_and_shadows.html

### `canvas.hdr_2d`

- **Title:** 2D HDR is enabled
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/viewport/hdr_2d`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `canvas.sdf_oversize`

- **Title:** 2D SDF oversize is above the default
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/2d/sdf/oversize`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `canvas.sdf_scale`

- **Title:** 2D SDF scale is at full resolution
- **Severity:** low
- **Kind:** quality_up
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/2d/sdf/scale`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `canvas.item_buffer`

- **Title:** 2D item buffer is above the default while canvas draws are high
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** item_buffer_size defaults to 16384. The rule flags it only when it is larger than that and canvas draw calls exceed 1000. 1000 is a review cut, not a batching budget.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/2d/batching/item_buffer_size`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `canvas.draw_calls`

- **Title:** Canvas draw calls are high
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** 2000 canvas draw calls is a review cut so a 2D frame with a large VIEWPORT_CANVAS_DRAW_CALLS count is surfaced. Godot does not publish that number as a limit.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/performance/gpu_optimization.html

### `canvas.tilemap_scene_tiles`

- **Title:** A TileMapLayer places many scene tiles
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_tilemap_scene_tiles", "value": 1}}`
- **Evidence and limits:** An enabled TileMapLayer places more than 256 cells from a TileSetScenesCollectionSource (bounded to 4096 inspected cells per scan). The 256 cutoff is a review heuristic shared with the other TileMap checks. Godot docs: "Scene tiles come with a greater performance overhead compared to atlases, as every scene is instanced individually for every placed tile."
- **Suggested action:** Use atlas tiles for static decoration and keep scene tiles for cells that need their own nodes (scripts, collision behaviour, lights).
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/2d/using_tilesets.html

### `canvas.tilemap_occluders`

- **Title:** A TileMapLayer creates many per-cell light occluders
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_tilemap_occluders", "value": 1}}`
- **Evidence and limits:** An enabled, locally visible TileMapLayer with occlusion_enabled has more than 256 inspected atlas-cell occluder polygons on layers with nonzero light masks or SDF collision enabled. Closed polygons require at least three points; open polygons require two. The native path creates a separate occluder for each cell/layer/polygon. This object-count cutoff is a review heuristic, not proof of active shadow or SDF cost. Runtime tile-data overrides and invalid references are skipped; cell and resource limits are reported.
- **Suggested action:** Compare consolidated static occluder outlines, or disable tile occlusion where neither 2D shadows nor SDF collision need it. Measure canvas CPU/GPU time while moving lights and editing tiles.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/2d/tile_map_layer.cpp

### `canvas.tilemap_animation_slices`

- **Title:** Animated tiles record many canvas animation slices
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_tilemap_animation_slices", "value": 1}}`
- **Evidence and limits:** An enabled, locally visible TileMapLayer has more than 4096 authored animation frames summed across inspected texture-assigned atlas cells with more than one frame. The native draw path records an animation slice and texture-region command for every authored frame, plus a reset slice. This counts configured command construction, not simultaneous GPU draws; inactive slices do not draw every frame. The threshold is a measurement heuristic. Runtime tile-data overrides and uninspected cells are not inferred.
- **Suggested action:** Compare fewer authored animation frames or fewer animated background cells, measuring both canvas frame time and tile-edit/rebuild spikes along the same camera route.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/2d/tile_map_layer.cpp

### `canvas.tilemap_small_quadrants`

- **Title:** A populated TileMapLayer uses small rendering quadrants
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_tilemap_small_quadrants", "value": 1}}`
- **Evidence and limits:** An enabled, locally visible TileMapLayer without Y sorting has rendering_quadrant_size at most 4 and more than 256 inspected atlas cells with assigned textures. Native rendering groups cells into quadrants, then canvas items. The cutoff is a measurement heuristic; tile count is not draw-call count. Scene-collection cells, invalid references and runtime tile-data overrides are skipped. At most 4096 cells per scene scan and 32 data layers and 32 collision/occlusion polygons per layer per tile are inspected; omissions are reported.
- **Suggested action:** Compare the default rendering quadrant size of 16, profiling canvas work along the same camera route and during tile edits.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/2d/tile_map_layer.cpp

### `canvas.tilemap_y_sort_groups`

- **Title:** A Y-sorted TileMapLayer creates many rendering groups
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_tilemap_y_sort_groups", "value": 1}}`
- **Evidence and limits:** An enabled, locally visible TileMapLayer uses Y sorting with more than 256 inspected texture-assigned atlas cells across more than 64 Y-position buckets. Buckets follow the checked native formula: int((map_to_local(cell).y + tile y_sort_origin + layer y_sort_origin) * 100). Y sorting uses these groups instead of rendering_quadrant_size. Group count does not prove visible draw calls or cost. Runtime tile-data overrides are skipped and scan omissions are reported.
- **Suggested action:** Compare separating flat floor/background tiles into a layer without Y sorting while keeping overlap-sensitive tiles on the sorted layer.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/2d/tile_map_layer.cpp

### `canvas.line_round_precision`

- **Title:** A rounded Line2D exceeds the default arc precision
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_line_round_precision", "value": 1}}`
- **Evidence and limits:** A visible Line2D has positive width, enough points for its rounded joints or enabled open caps, and round_precision above eight. LineBuilder uses this value to subdivide arcs into triangles. The threshold is the documented default, not a hardware budget.
- **Suggested action:** Compare the default precision on rounded lines, especially lines rebuilt frequently or displayed small.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/2d/line_builder.cpp

### `canvas.sprite_opaque_prepass`

- **Title:** A 3D sprite or label requests an opaque alpha prepass
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_sprite_opaque_prepass", "value": 1}}`
- **Evidence and limits:** SpriteBase3D or Label3D uses ALPHA_CUT_OPAQUE_PREPASS without a material override. Both class references describe this mode as slower than alpha blending or discard because it first draws fully opaque pixels in the depth prepass.
- **Suggested action:** Compare alpha discard where hard cutouts are acceptable, or alpha blending where overlap sorting remains correct.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/SpriteBase3D.xml

### `canvas.backbuffer_full`

- **Title:** A BackBufferCopy copies the entire viewport
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_backbuffer_full", "value": 1}}`
- **Evidence and limits:** A visible BackBufferCopy uses viewport mode or rectangle mode with an exactly empty Rect2, which the native renderer also treats as a full copy. The copied pixel count scales with viewport size.
- **Suggested action:** Compare a tight nonempty copy rectangle that contains all screen-texture samples needed by the following effects, or disable an unused copy.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/servers/rendering/renderer_canvas_cull.cpp

### `canvas.canvas_group_mipmaps`

- **Title:** A CanvasGroup generates backbuffer mipmaps
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_canvas_group_mipmaps", "value": 1}}`
- **Evidence and limits:** CanvasGroup.use_mipmaps is enabled, generating backbuffer mipmaps before the group is drawn.
- **Suggested action:** Disable mipmaps if the group's custom material does not sample them.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/CanvasGroup.xml

### `canvas.canvas_group_margins`

- **Title:** A CanvasGroup expands its backbuffer margins beyond the default
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_canvas_group_margins", "value": 1}}`
- **Evidence and limits:** CanvasGroup.clear_margin or fit_margin exceeds the documented 10-pixel default. This is a review threshold, not a GPU limit; actual cost depends on the resulting area.
- **Suggested action:** Reduce margins toward the smallest values that preserve shader effects and avoid mipmap edge artifacts.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/CanvasGroup.xml

### `canvas.sprite_shaded`

- **Title:** 3D sprites or labels enable lighting
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"all": [{"scene_gte": {"name": "check_sprite_shaded", "value": 1}}, {"setting_eq": {"path": "rendering/shading/overrides/force_vertex_shading", "value": false}}]}`
- **Evidence and limits:** SpriteBase3D or Label3D enables shaded with no material override. This activates the built-in lighting path; actual lighting cost depends on coverage and lights.
- **Suggested action:** Compare unshaded sprites or labels for UI-like elements that should not react to scene lights.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/SpriteBase3D.xml

### `canvas.hdr_output_forces_hdr_2d`

- **Title:** HDR output turns on HDR 2D
- **Severity:** low
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.7
- **Setting:** `display/window/hdr/request_hdr_output`
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"all": [{"setting_eq": {"path": "display/window/hdr/request_hdr_output", "value": true}}, {"setting_eq": {"path": "rendering/viewport/hdr_2d", "value": false}}]}`
- **Evidence and limits:** Godot prints "HDR 2D was automatically enabled because HDR output was requested in project settings." when display/window/hdr/request_hdr_output is on and rendering/viewport/hdr_2d is off. The root viewport then renders 2D in HDR anyway, with the memory and bandwidth of an HDR canvas buffer.
- **Suggested action:** Enable rendering/viewport/hdr_2d explicitly so the project settings match what runs, and budget for the HDR canvas buffer.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/scene/main/scene_tree.cpp

## cpu

### `cpu.process_time`

- **Title:** Process time beyond the GPU time exceeds half the frame budget
- **Severity:** high
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Half the budget is a review threshold. Godot's per-frame process time (the span Performance.TIME_PROCESS reports, passed to profilers in main.cpp) also covers RenderingServer sync and draw, so it includes the wait for the GPU: the median GPU time is subtracted, and the rule is skipped when frame timing finds the run GPU-bound. The median of frame_timing's samples is used instead of the once-per-second TIME_PROCESS peak, which also caught Render Lens's own work in the game; a few spike frames, which stutter_report covers, can also move a 95th percentile of 40 samples. It cannot name a script.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/performance/cpu_optimization.html

### `cpu.physics_time`

- **Title:** Physics time is a large share of the frame budget
- **Severity:** high
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** TIME_PHYSICS_PROCESS above a third of the frame budget is a review cut. The monitor is seconds, per the Performance class.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/performance/cpu_optimization.html

### `cpu.navigation_time`

- **Title:** Navigation time is a large share of the frame budget
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** TIME_NAVIGATION_PROCESS above a quarter of the frame budget is a review cut. The monitor is seconds.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_performance.html

### `cpu.physics_ticks`

- **Title:** Physics ticks per second are above 60
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `physics/common/physics_ticks_per_second`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/physics/physics_introduction.html

### `cpu.max_physics_steps`

- **Title:** Max physics steps per frame is above the default
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** max_physics_steps_per_frame defaults to 8. A higher value lets a slow frame run more catch-up physics steps.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `physics/common/max_physics_steps_per_frame`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `cpu.solver_iterations`

- **Title:** GodotPhysics solver iterations are above the default
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `physics/3d/solver/solver_iterations`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `cpu.jolt_kinematic_contacts`

- **Title:** Jolt generates all kinematic contacts
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `physics/jolt_physics_3d/simulation/generate_all_kinematic_contacts`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/physics/using_jolt_physics.html

### `cpu.jolt_face_index`

- **Title:** Jolt ray-cast face index is enabled
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `physics/jolt_physics_3d/queries/enable_ray_cast_face_index`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/physics/using_jolt_physics.html

### `cpu.orphan_nodes`

- **Title:** Orphan nodes exist
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_performance.html

### `cpu.collision_pairs`

- **Title:** 3D collision pair count is high
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** 500 is not a Godot physics limit (Jolt's max_body_pairs default is 65536). It flags PHYSICS_3D_COLLISION_PAIRS so a broadphase that is doing a lot of work is visible.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_performance.html

### `cpu.active_bodies`

- **Title:** Many 3D physics objects are active
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** 100 active 3D objects is a review cut. Jolt's max_bodies default is 10240, so this is not that cap.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_performance.html

### `cpu.separate_thread_off`

- **Title:** Physics is on the main thread while physics time is high
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Suggests the separate-thread setting only when TIME_PHYSICS_PROCESS already exceeds a third of the budget. The 4.4 Jolt page calls that threading support experimental.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `physics/3d/run_on_separate_thread`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/physics/using_jolt_physics.html

### `cpu.scene_bodies`

- **Title:** The edited scene contains many physics bodies
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** 80 physics bodies in the scanned scene is a review cut so a crowded collision scene is visible before play mode. It is not PHYSICS_3D_ACTIVE_OBJECTS.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/physics/physics_introduction.html

### `cpu.flush_stdout`

- **Title:** Stdout is flushed on every print
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `application/run/flush_stdout_on_print`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `cpu.low_processor_sleep_short`

- **Title:** Low-processor sleep is below the default
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `application/run/low_processor_mode_sleep_usec`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `cpu.interpolation_traversal`

- **Title:** 3D physics interpolation uses the slower Legacy or Debug traversal
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.5, 4.6, 4.7
- **min_version:** 4.5
- **Setting:** `physics/3d/physics_interpolation/scene_traversal`
- **Source:** https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html

### `cpu.animation_value_transforms`

- **Title:** Value tracks animate 3D position, rotation or scale
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_animation_value_transforms", "value": 1}}`
- **Evidence and limits:** An AnimationPlayer/AnimationTree library has a value track whose property is position, rotation, rotation_degrees, quaternion or scale on a node that resolves to Node3D. Unresolved targets are skipped. Godot class reference: "track types instead of is recommended for performance reasons."
- **Suggested action:** Use dedicated Position 3D, Rotation 3D and Scale 3D tracks for Node3D transforms.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/Animation.xml

### `cpu.animation_cubic_3d`

- **Title:** A complex 3D animation uses cubic transform interpolation
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_animation_cubic_3d", "value": 1}}`
- **Evidence and limits:** One animation has at least 16 position/rotation/scale 3D tracks with cubic or cubic-angle interpolation. The 16-track cutoff is a review heuristic for complex animations. Godot class reference: "Stick to for complex 3D animations imported from external software, even if it requires using a higher animation framerate in return."
- **Suggested action:** Switch imported 3D transform tracks to linear interpolation and raise the import animation FPS if motion needs it.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/Animation.xml

### `cpu.skeleton2d_zero_strength`

- **Title:** A zero-strength 2D skeleton stack still dispatches native modifiers
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_skeleton2d_zero_strength", "value": 1}}`
- **Evidence and limits:** An in-tree unscripted Skeleton2D can process and owns a setup, enabled, unscripted SkeletonModificationStack2D with strength exactly zero. One of the first 128 modifications is an enabled unscripted native TwoBoneIK, LookAt, Jiggle, CCDIK or FABRIK modification whose execution mode has the corresponding internal idle or physics tick enabled. Both checked stacks dispatch matching modifications without a strength early-out. All five reviewed native implementations use strength in pose-override writes after their configured work. Invalid cached targets or bones and empty chains may return early, so dispatch is not proof of a successful solve or measured CPU cost. Detached, disabled, paused, uninitialized, shared-with-another-skeleton, scripted and unrecognized native classes are excluded. Offenders identify the modification index and native class. The audit reads native getters and never executes a stack or solver. Bone-count queries are avoided because they can rebuild caches and emit bone_setup_changed.
- **Suggested action:** When these modifiers should remain unused, compare disabling the stack or unused modifications. Zero strength suppresses pose blending but is not a processing-off switch. Measure skeleton/animation CPU work during the intended zero-strength interval.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/resources/2d/skeleton/skeleton_modification_stack_2d.cpp

### `cpu.skeleton_zero_influence`

- **Title:** An active skeleton modifier has zero pose influence
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_skeleton_zero_influence", "value": 1}}`
- **Evidence and limits:** An in-tree unscripted SkeletonModifier3D is active with influence exactly zero. Its direct Skeleton3D parent has bones, can_process() is true and internal idle or physics processing is enabled. Both checked skeletons still enter the partial-influence modifier path; zero influence does not bypass the modifier dispatch. Godot 4.4 copies old/new bone poses and 4.7 iterates applied-pose state. A native modifier may have its own early-out, so this does not assert a particular IK/physics solve or measured CPU cost. Detached, empty, inactive, scripted and manually advanced/nonprocessing skeletons are excluded.
- **Suggested action:** If a modifier should remain unused, compare deactivating its processing body; for a permanently unused modifier, consider removing it after checking dependencies. Simply setting influence to zero is not a processing-off switch. Profile skeleton/animation CPU work during the intended zero-influence interval.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/skeleton_3d.cpp

### `cpu.viewport_pick_sort`

- **Title:** A SubViewport sorts 2D physics mouse picks
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_viewport_pick_sort", "value": 1}}`
- **Evidence and limits:** A SubViewport enables physics object picking and its sorting option, with input enabled. The native point-query path sorts up to 64 picked shapes by z order and tree order. Cost depends on input activity and overlapping pickable objects; it is not a GPU rendering cost.
- **Suggested action:** Compare unsorted picking if the application does not depend on topmost-object ordering.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/main/viewport.cpp

### `cpu.csg_composition`

- **Title:** A CSG hierarchy retains runtime construction work
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_csg_composition", "value": 1}}`
- **Evidence and limits:** A root CSGShape3D has a direct CSGShape3D child. Godot documents significant CPU construction cost for CSG and recommends baking final results. This identifies a runtime composition, not proof of rebuilding every frame; static results are cached until dirtied.
- **Suggested action:** For finished static geometry, compare a baked mesh and matching collision geometry; retain CSG when runtime boolean changes are required.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/modules/csg/doc_classes/CSGShape3D.xml

### `cpu.cpu_particle_sort`

- **Title:** CPU particles sort a nontrivial particle array
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_cpu_particle_sort", "value": 1}}`
- **Evidence and limits:** CPUParticles2D/3D uses lifetime ordering, or CPUParticles3D uses view-depth ordering, with amount at least 64. Native update code sorts the particle-index array; 64 is a review heuristic. Depth sorting additionally requires a current camera.
- **Suggested action:** Compare index ordering where the effect does not require a sorted blend order, and profile CPU frame time.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/cpu_particles_3d.cpp

### `cpu.skin_dynamic_bounds`

- **Title:** A skinned mesh uses automatically updated bounds
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_skin_dynamic_bounds", "value": 1}}`
- **Evidence and limits:** A live MeshInstance3D resolves to a nonempty Skeleton3D and uses an ArrayMesh with bone attributes, with neither instance nor mesh custom AABB. The RD backend can recalculate bone bounds when the skeleton version changes and caches unchanged skeletons. Pose-update frequency and the actual cost are not inferred.
- **Suggested action:** If CPU profiling identifies bounds updates, compare a carefully authored custom AABB that encloses every required animation pose.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/servers/rendering/renderer_rd/storage_rd/mesh_storage.cpp

### `cpu.rendering_server_sync_per_frame`

- **Title:** A script calls a waiting RenderingServer getter every frame on a separate render thread
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"all": [{"scene_gte": {"name": "check_frame_rendering_sync", "value": 1}}, {"setting_eq": {"path": "rendering/driver/threads/thread_model", "value": 2}}]}`
- **Evidence and limits:** Godot prints "Call to mesh_get_surface_count causing RenderingServer synchronizations on every frame. This significantly affects performance." when rendering/driver/threads/thread_model is Separate (2) and a script calls a RenderingServer method that returns a value (one of the FUNCnR/FUNCnRC wrappers, listed in server_sync_calls.gd) unconditionally in _process, _physics_process or _integrate_forces: the main thread waits for the render thread on every frame.
- **Suggested action:** Cache the value, call it less often, or keep the Safe thread model.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/rendering_server_default.h

### `cpu.physics_server_sync_per_frame`

- **Title:** A script calls a waiting PhysicsServer getter every frame with physics on its own thread
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"any": [{"all": [{"scene_gte": {"name": "check_frame_physics_3d_sync", "value": 1}}, {"setting_eq": {"path": "physics/3d/run_on_separate_thread", "value": true}}]}, {"all": [{"scene_gte": {"name": "check_frame_physics_2d_sync", "value": 1}}, {"setting_eq": {"path": "physics/2d/run_on_separate_thread", "value": true}}]}]}`
- **Evidence and limits:** Godot prints "Call to body_get_state causing PhysicsServer3D synchronizations on every frame. This significantly affects performance." (or the PhysicsServer2D form) when physics/3d (or 2d) run_on_separate_thread is on and a script calls a PhysicsServer3D (or PhysicsServer2D) method that returns a value unconditionally in a per-frame callback: the main thread waits for the physics thread every frame.
- **Suggested action:** Read state from the body or PhysicsDirectBodyState in _integrate_forces, cache values, or run physics on the main thread.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/servers/physics_3d/physics_server_3d_wrap_mt.h

## memory

### `memory.video_mem`

- **Title:** Video memory in use is above 512 MiB
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** 512 MiB is not a Godot limit and not the GPU's capacity. RENDER_VIDEO_MEM_USED is the engine's byte counter, and the class reference says it includes texture, buffer, and miscellaneous allocations.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_performance.html

### `memory.message_queue`

- **Title:** Message-queue peak is near its cap
- **Severity:** high
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** 0.9 is not an engine watermark. MEMORY_MESSAGE_BUFFER_MAX is the peak bytes, compared with memory/limits/message_queue/max_size_mb (default 32).
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `memory/limits/message_queue/max_size_mb`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_performance.html

### `memory.static_high`

- **Title:** Static memory is above 512 MiB
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** 512 MiB of MEMORY_STATIC is a review cut. The monitor is bytes of statically allocated memory, not a leak by itself. Compare it with MEMORY_STATIC_MAX.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_performance.html

### `memory.object_count`

- **Title:** Object count is very high
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** 20000 Object instances is a review cut. OBJECT_COUNT is the Performance monitor for live Objects. Godot does not define this threshold.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_performance.html

### `memory.resource_count`

- **Title:** Resource count is very high
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** 5000 resources is a review cut on OBJECT_RESOURCE_COUNT so a project that has loaded a large library is visible.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_performance.html

### `memory.buffer_mem`

- **Title:** Buffer memory is above 256 MiB
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** 256 MiB of RENDER_BUFFER_MEM_USED is a review cut. The class reference says this is buffer memory in bytes, separate from texture memory.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_performance.html

### `memory.staging_block_large`

- **Title:** Staging buffer blocks are above 256 KiB
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/rendering_device/staging_buffer/block_size_kb`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `memory.staging_cap_high`

- **Title:** The staging buffer cap is above 128 MiB
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/rendering_device/staging_buffer/max_size_mb`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `memory.gdscript_track_locals`

- **Title:** GDScript local variables are tracked in export builds
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.5, 4.6, 4.7
- **min_version:** 4.5
- **Setting:** `debug/settings/gdscript/always_track_local_variables`
- **Source:** https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html

### `memory.texture_mem`

- **Title:** Texture memory is above 256 MiB
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** 256 MiB is not a Godot limit. RENDER_TEXTURE_MEM_USED is the texture byte counter and the class says lower is better.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_performance.html

### `memory.node_count`

- **Title:** The scene tree has at least 1000 nodes
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** The CPU optimization page says node cost shows up from thousands of nodes. OBJECT_NODE_COUNT includes the root. 1000 is the low end of that range.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_performance.html

### `memory.vram_largest_share`

- **Title:** One resource is most of the Video RAM list
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** The debugger Video RAM tab lists bytes per resource. Half of that listed total and 64 MiB (a 4096x4096 RGBA8 texture with mipmaps is about 85 MiB) are review cuts, not GPU capacities; without the size floor a 6 MiB texture in a 12 MiB list was reported.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/scripting/debug/debugger_panel.html

### `memory.gdscript_track_call_stacks`

- **Title:** GDScript call stacks are tracked in release builds
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.5, 4.6, 4.7
- **Setting:** `debug/settings/gdscript/always_track_call_stacks`
- **Source:** https://docs.godotengine.org/en/4.5/tutorials/scripting/logging.html

### `memory.path_dense_cache`

- **Title:** A path requests a very fine baked-point cache
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_path_dense_cache", "value": 1}}`
- **Evidence and limits:** A Path2D/3D has at least two control points and a positive bake_interval below 1 pixel in 2D or 0.05 metres in 3D. Defaults are 5 pixels and 0.2 metres. Smaller intervals increase cached samples and rebuild work when the cache is used. The scanner reads the interval and control-point count without baking or measuring path length.
- **Suggested action:** Compare a coarser bake interval while moving followers along tight curves, then inspect cache memory and rebuild spikes after path edits.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/resources/curve.cpp

### `memory.viewport_hdr2d`

- **Title:** A SubViewport uses a wide HDR canvas buffer
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Renderer scope by version:** `{"4.4": ["forward_plus"], "4.6": ["forward_plus", "mobile"]}`
- **Observed condition:** `{"scene_gte": {"name": "check_viewport_hdr2d", "value": 1}}`
- **Evidence and limits:** An update-enabled SubViewport uses HDR 2D. The documented RGBA16 canvas target uses more bytes per pixel than an RGBA8 target. This applies to Forward+ in 4.4 and 4.5 and RD renderers from 4.6; Mobile's RGB10_A2 target in 4.4 and 4.5 is excluded from this wider-buffer claim.
- **Suggested action:** Compare disabling HDR 2D if this viewport needs neither HDR effects nor linear-space canvas compositing.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/Viewport.xml

## stutter

### `stutter.shader_cache_off`

- **Title:** Shader cache is disabled
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/shader_compiler/shader_cache/enabled`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/performance/pipeline_compilations.html

### `stutter.pipeline_cache_off`

- **Title:** Pipeline cache is disabled
- **Severity:** high
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Godot exposes the cache setting, not individual Vulkan pipeline creations or cache handles. Compare repeat runs; this is not proof that the upstream API condition fired.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `BestPractices-vkCreateGraphicsPipelines-multiple-pipelines-no-cache` (Godot adaptation, no layer required)
- **Observed condition:** `{"setting_eq": {"path": "rendering/rendering_device/pipeline_cache/enable", "value": false}}`
- **Mapping limits:** Godot exposes the cache setting, not individual Vulkan pipeline creations or cache handles. Compare repeat runs; this is not proof that the upstream API condition fired.
- **Setting:** `rendering/rendering_device/pipeline_cache/enable`
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/best_practices/bp_pipeline.cpp

### `stutter.compilations_canvas`

- **Title:** Canvas pipeline compilations have occurred
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/performance/pipeline_compilations.html

### `stutter.compilations_mesh`

- **Title:** Mesh pipeline compilations have occurred
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/performance/pipeline_compilations.html

### `stutter.compilations_surface`

- **Title:** Surface pipeline compilations have occurred
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/performance/pipeline_compilations.html

### `stutter.compilations_draw`

- **Title:** Draw-step pipeline compilations have occurred
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/performance/pipeline_compilations.html

### `stutter.compilations_specialization`

- **Title:** Specialization pipeline compilations are climbing
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/performance/pipeline_compilations.html

### `stutter.draw_calls_high`

- **Title:** Frame draw-call count is high
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** 300 is not a Godot draw-call budget. RENDER_TOTAL_DRAW_CALLS_IN_FRAME above that is a review cut so a CPU-bound scene with several hundred draws is listed. 1500 is not a Godot budget either. The GPU optimization page describes draw calls as CPU submission cost.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/performance/gpu_optimization.html

## pacing

### `pacing.vsync_off_uncapped`

- **Title:** VSync is off and the frame rate is uncapped
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `display/window/vsync/vsync_mode`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `pacing.vsync_off_with_cap`

- **Title:** VSync is off with a max_fps cap
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `display/window/vsync/vsync_mode`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `pacing.max_fps_below_target`

- **Title:** max_fps is below the advise target
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `application/run/max_fps`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `pacing.low_processor`

- **Title:** Low-processor mode is on
- **Severity:** info
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `application/run/low_processor_mode`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `pacing.frame_queue`

- **Title:** Rendering-device frame queue size is 3
- **Severity:** info
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/rendering_device/vsync/frame_queue_size`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `pacing.mailbox_vsync`

- **Title:** VSync mode is Mailbox
- **Severity:** info
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `display/window/vsync/vsync_mode`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `pacing.fps_below_target`

- **Title:** Measured FPS is below the target
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_performance.html

### `pacing.shadow_draws_dominate`

- **Title:** Shadow draw calls exceed visible draw calls
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_renderingserver.html

### `pacing.delta_smoothing_off`

- **Title:** Frame delta smoothing is off
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `application/run/delta_smoothing`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `pacing.swapchain_images`

- **Title:** The swapchain has more than 3 images
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/rendering_device/vsync/swapchain_image_count`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

## audio

### `audio.output_latency_low`

- **Title:** Preferred audio latency is below 15 ms
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `audio/driver/output_latency`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `audio.disable_threshold_strict`

- **Title:** Audio buses stay awake at quieter levels than the default
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `audio/buses/channel_disable_threshold_db`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `audio.disable_time_long`

- **Title:** Audio buses wait longer than 2 seconds before disabling
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `audio/buses/channel_disable_time`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `audio.tts_enabled`

- **Title:** Text-to-speech support is enabled
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `audio/general/text_to_speech`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `audio.polyphony`

- **Title:** An audio player allows more than one voice
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** The class says max_polyphony is how many sounds play at once and that extra sounds cut off the oldest. Above the default of 1 means more simultaneous mixes. No voice budget is documented.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `AudioStreamPlayer3D.max_polyphony`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_audiostreamplayer3d.html

### `audio.unbounded_3d`

- **Title:** An active or autoplay 3D sound has no distance cutoff
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** An assigned stream is playing or configured to autoplay. This does not prove it is currently distant, audible or expensive.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `AudioStreamPlayer3D.max_distance`
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/audio_stream_player_3d.cpp

### `audio.measured_latency`

- **Title:** Measured audio output latency is above 50 ms
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** The monitor is AudioServer output latency in seconds. 50 ms is above the 15 ms preferred default of audio/driver/output_latency. It is not a hardware measurement from this tool.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_performance.html

### `audio.reverb_dry_only`

- **Title:** A dry-only reverb still processes its filter network
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_reverb_dry_only", "value": 1}}`
- **Evidence and limits:** An enabled native AudioEffectReverb on a non-bypassed current audio bus has wet exactly 0 and dry exactly 1. Both checked versions call the reverb processor for each stereo channel, and its comb/all-pass loops run before the final wet/dry mix. There is no zero-wet bypass in that path. Bus activity is unknown; scripted/custom effects are skipped. This is a configured processing candidate, not measured CPU cost.
- **Suggested action:** Compare bypassing this effect if the wet mix stays zero and later automation does not need the reverb's warmed tail.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/servers/audio/effects/reverb_filter.cpp

### `audio.stereo_neutral`

- **Title:** A neutral stereo-enhancement effect still processes samples
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_stereo_neutral", "value": 1}}`
- **Evidence and limits:** An enabled native AudioEffectStereoEnhance on a non-bypassed current audio bus has pan_pullout exactly 1, time_pullout_ms exactly 0 and surround exactly 0. The source still computes center/side channels and writes and reads the delay ring for every sample. These settings request no stereo enhancement; this does not assert bit-identical floating-point output or prove that the bus is active. Scripted/custom effects are skipped.
- **Suggested action:** Compare bypassing this effect when these neutral settings stay fixed throughout the workload.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/servers/audio/effects/audio_effect_stereo_enhance.cpp

### `audio.eq_many_bands`

- **Title:** An audio equalizer processes more than ten bands
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_eq_many_bands", "value": 1}}`
- **Evidence and limits:** An enabled native AudioEffectEQ6/EQ10/EQ21 on a non-bypassed current audio bus reports more than ten bands. The native EQ loop processes every band for both channels on every sample, including bands whose gain is 0 dB. The cutoff distinguishes the 21-band resource from the 6/10-band alternatives; it is a review heuristic, not a device limit. Flat gains are not assumed to make the filter bank an identity operation. Bus activity and actual CPU cost are unknown; scripted/custom effects are skipped.
- **Suggested action:** Compare EQ6 or EQ10 where the mix does not need 21 separately adjustable bands, retuning the replacement by ear or against an audio reference.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/servers/audio/effects/audio_effect_eq.cpp

### `audio.spectrum_history`

- **Title:** A spectrum analyzer is configured with more than four seconds of history
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_spectrum_history", "value": 1}}`
- **Evidence and limits:** A native AudioEffectSpectrumAnalyzer on the current audio layout has a finite buffer_length above four seconds. AudioServer creates effect instances independently of bypass/enable state; disabling an effect or bypassing its bus does not release this history, so those states remain eligible. Instantiation allocates floor(buffer_length / (fft_size / mix_rate)) + 1 history arrays, each holding fft_size stereo AudioFrame values. This history grows roughly with duration and mix rate; a longer history does not by itself increase the FFT execution rate. Four seconds is a review cutoff matching the inspector range, not a native limit. Existing instances retain the history allocated at creation; this rule describes resource configuration. Scripted/custom effects are skipped.
- **Suggested action:** Compare the default two seconds or the shortest history that preserves the application's spectrum queries and audio/display latency tolerance, then recreate or reload the effect.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/servers/audio/effects/audio_effect_spectrum_analyzer.cpp

### `audio.pitch_shift_oversampling`

- **Title:** A pitch-shift effect increases FFT oversampling
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_pitch_shift_oversampling", "value": 1}}`
- **Evidence and limits:** An enabled native AudioEffectPitchShift on a non-bypassed current audio bus has a non-unity pitch scale and oversampling above its default of 4. The source shortens the FFT hop as oversampling increases; Godot documents the higher CPU demand. Unity pitch bypasses this work and is excluded. Zero-hop configurations receive a separate correctness finding. This is a configured processing path, not proof the bus is receiving audio or causing frame-time cost. Scripted/custom effects are skipped.
- **Suggested action:** Compare the default oversampling of 4 or the lowest value that preserves acceptable pitch-shift quality under the intended mix.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/servers/audio/effects/audio_effect_pitch_shift.cpp

### `audio.chorus_voices`

- **Title:** A chorus effect processes more than two voices
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_chorus_voices", "value": 1}}`
- **Evidence and limits:** An enabled native AudioEffectChorus on a non-bypassed current audio bus requests a nonzero wet mix and more than two voices with nonzero cutoff. Each such voice enters its own sample-processing loop. A zero cutoff skips that voice in both checked versions and is excluded. Two voices is the resource default, not a hardware limit; current configuration does not prove audible processing or measured cost.
- **Suggested action:** Compare two chorus voices or fewer on buses where the extra modulation is not audible in the complete mix.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/servers/audio/effects/audio_effect_chorus.cpp

### `audio.chorus_dry_only`

- **Title:** A dry-only chorus still has voice processing configured
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_chorus_dry_only", "value": 1}}`
- **Evidence and limits:** An enabled native AudioEffectChorus on a non-bypassed current audio bus has wet exactly 0, dry exactly 1 and at least one voice with nonzero cutoff. The native voice loop still runs when wet is zero, even though no wet contribution is requested. Bus activity is unknown; this is a measurement candidate. Scripted/custom effects are skipped.
- **Suggested action:** Compare bypassing this effect if the wet mix remains zero throughout the workload. Keep it active when upcoming automation needs its warmed delay/filter history.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/servers/audio/effects/audio_effect_chorus.cpp

### `audio.microphone_input_disabled`

- **Title:** A microphone stream is used while audio input is off
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"all": [{"scene_gte": {"name": "check_microphone_stream", "value": 1}}, {"setting_eq": {"path": "audio/driver/enable_input", "value": false}}]}`
- **Evidence and limits:** Godot prints "You must enable the project setting "audio/driver/enable_input" to use audio capture." when an AudioStreamMicrophone starts while audio/driver/enable_input is off; nothing is captured.
- **Suggested action:** Enable audio/driver/enable_input (export templates may also need microphone permissions on mobile and web).
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/servers/audio/audio_server.cpp

## platform

### `platform.windows_driver_vulkan`

- **Title:** Windows rendering driver is still Vulkan
- **Severity:** low
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.6, 4.7
- **min_version:** 4.6
- **Setting:** `rendering/rendering_device/driver.windows`
- **Source:** https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html

### `platform.per_pixel_transparency`

- **Title:** Per-pixel window transparency is allowed
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `display/window/per_pixel_transparency/allowed`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `platform.subwindows_not_embedded`

- **Title:** Subwindows are not embedded in the main window
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `display/window/subwindows/embed_subwindows`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `platform.etc2_astc_off_mobile`

- **Title:** ETC2 and ASTC import is off while the mobile renderer is selected
- **Severity:** low
- **Kind:** info
- **Heuristic:** no
- **Renderers:** mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/textures/vram_compression/import_etc2_astc`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `platform.s3tc_off_forward`

- **Title:** S3TC and BPTC import is off on Forward+
- **Severity:** low
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/textures/vram_compression/import_s3tc_bptc`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `platform.path_case_mismatch`

- **Title:** A res:// path differs in case from the file on disk
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_path_case_mismatch", "value": 1}}`
- **Evidence and limits:** Godot prints "Case mismatch opening requested file 'res://Art/hero.png', stored as 'res://art/hero.png' in the filesystem. This file will not open when exported to other case-sensitive platforms." in editor builds on Windows (and macOS) when a script, scene, resource or a path-bearing project setting (main scene, icon, boot splash, theme, autoloads, translations and their remaps) refers to a res:// path whose letter case differs from the file or folder on disk. The case-insensitive file system opens it during development; exported packs are case-sensitive. Text-resource references that also carry a uid:// are skipped, since Godot loads those by UID.
- **Suggested action:** Change the reference to the on-disk spelling, or rename the file to match.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/windows/file_access_windows.cpp

## ui

### `ui.default_font_msdf_off`

- **Title:** The default font is not an MSDF font
- **Severity:** low
- **Kind:** quality_up
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `gui/theme/default_font_multichannel_signed_distance_field`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `ui.font_mipmaps_on`

- **Title:** The default font generates mipmaps
- **Severity:** low
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `gui/theme/default_font_generate_mipmaps`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `ui.subviewport_always`

- **Title:** A SubViewport updates even when it is not visible
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `SubViewport.render_target_update_mode`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_subviewport.html

### `ui.subviewport_msaa`

- **Title:** A SubViewport has 3D MSAA enabled
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Viewport.msaa_3d`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_viewport.html

### `ui.clip_children`

- **Title:** A CanvasItem clips its children
- **Severity:** low
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `CanvasItem.clip_children`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_canvasitem.html

### `ui.subviewport_3d_unused`

- **Title:** A 2D-only SubViewport keeps 3D enabled
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_subviewport_3d_unused", "value": 1}}`
- **Evidence and limits:** A SubViewport has disable_3d off and no Node3D anywhere below it, so it renders only 2D. Godot docs: "Disabling 3D is slightly faster and uses less memory compared to enabled 3D."
- **Suggested action:** Turn on disable_3d for SubViewports that only show 2D content.
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/rendering/viewports.html

### `ui.label3d_font_size`

- **Title:** A Label3D renders a large dynamic font size
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_label3d_font_size", "value": 1}}`
- **Evidence and limits:** A visible Label3D with text uses font_size above 64 with a non-MSDF font, so each new glyph is rasterized at that size. Godot class reference: "Higher font sizes require more time to render new characters, which can cause stuttering during gameplay."
- **Suggested action:** Lower font_size and raise pixel_size, or use an MSDF font for large 3D text.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/Label3D.xml

### `ui.hidden_video`

- **Title:** A hidden video player can keep decoding frames
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_hidden_video", "value": 1}}`
- **Evidence and limits:** A hidden in-tree VideoStreamPlayer has a recognized, unscripted native Theora stream and a nonempty video texture. It is unpaused and can_process() is true, including inherited process and tree-pause state. In a running game, playback and internal processing must both be active; in the editor, autoplay is a configuration candidate only. Both verified native players update playback independently of visibility, and Theora decodes, converts and uploads new frames. Stopped runtime playback, detached nodes, custom streams and zero playback speed/time scale where the player supports scaling are excluded. This does not measure decoder cost or prove the texture is unused elsewhere.
- **Suggested action:** If this hidden video is not needed for audio, timing or another consumer of get_video_texture(), pause playback while it is hidden and compare CPU/frame timing during that interval.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/gui/video_stream_player.cpp

### `ui.font_msdf_size`

- **Title:** A text node uses an enlarged MSDF glyph cache
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_font_msdf_size", "value": 1}}`
- **Evidence and limits:** A Label, Button or explicitly font-assigned Label3D uses a FontFile with source data, MSDF enabled and msdf_size above its default 48. Native glyph caches use this source size; larger values increase generation work and memory. Up to eight explicit FontVariation base links are followed; fallback glyph fonts are not inferred.
- **Suggested action:** Compare the default MSDF source size where glyph detail remains adequate; measure first-use text generation and font memory as well as appearance.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/FontFile.xml

### `ui.font_subpixel_large`

- **Title:** Large text forces subpixel glyph variants
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_font_subpixel_large", "value": 1}}`
- **Evidence and limits:** An observed dynamic non-MSDF FontFile forces half- or quarter-pixel positioning and the text node requests a font size above 20. In both checked versions AUTO stops subpixel variants above 20 pixels; 4.7 stores that size in 1/64 units internally. Actual raster size can also depend on scaling, so this is a review candidate.
- **Suggested action:** Compare AUTO subpixel positioning at the actual viewport scale, checking text sharpness and first-use cache generation.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/modules/text_server_adv/text_server_adv.cpp

### `ui.font_local_mipmaps`

- **Title:** An observed font resource generates mipmaps
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_font_local_mipmaps", "value": 1}}`
- **Evidence and limits:** A Label, Button or explicitly font-assigned Label3D resolves to a FontFile with source data and generate_mipmaps enabled. Native atlas upload generates the mip chain when dirty. This inspects the actual font override, independently of the project's default-font setting.
- **Suggested action:** Compare disabling mipmaps for fonts displayed at a stable native size with no minification; retain them for shrinking or distant text.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/modules/text_server_adv/text_server_adv.cpp

### `ui.font_oversampling`

- **Title:** A canvas text font overrides oversampling above 2
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_font_oversampling", "value": 1}}`
- **Evidence and limits:** A nonempty Label or Button resolves through at most eight native FontVariation links to an unscripted FontFile with source data, MSDF disabled, fixed_size zero and a finite oversampling override above 2. Godot 4.4 scales the glyph raster size inside its cache; 4.7 requests a larger size cache during canvas drawing. Larger outline glyphs can increase first-use raster work and atlas memory; embedded color bitmap strikes can behave differently. The threshold is a review heuristic, not a measured cost. Label3D, system/fallback glyph selection, scripted fonts and automatic viewport oversampling are not inferred.
- **Suggested action:** Compare a smaller explicit font oversampling override at the intended display scale. Measure first-use text rendering and font memory, and inspect small text and outlines before keeping the change. Zero restores automatic oversampling and does not necessarily reduce it.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/modules/text_server_adv/text_server_adv.cpp

### `ui.panel_corner_detail`

- **Title:** A rounded panel uses high corner geometry detail
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_panel_corner_detail", "value": 1}}`
- **Evidence and limits:** A visible Panel or PanelContainer uses an effective native, unscripted StyleBoxFlat with corner_detail above the default 8, nonnegative border/radius settings with at least one positive corner radius, and an enabled nontransparent fill, border or shadow. The expanded rectangle must be finite, not approximately zero-sized, and larger in both dimensions than twice its largest border width, excluding degenerate or border-filled cases where native radius adaptation can remove rounding. Both versions build more vertices per rounded fill/ring as corner_detail increases; borders, shadows and antialiasing can add rings. The threshold is a review heuristic, not evidence of a frame-time bottleneck. Canvas geometry is cached between redraws; no per-frame CPU rebuild is claimed.
- **Suggested action:** Compare corner_detail 8 or a lower visually acceptable value on these panels, checking corner smoothness at the actual UI scale and measuring canvas cost and redraw-heavy UI updates.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/resources/style_box_flat.cpp

### `ui.label_effect_passes`

- **Title:** A long Label draws both outline and shadow passes
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_label_effect_passes", "value": 1}}`
- **Evidence and limits:** A Label with at least 128 text characters and visible_characters not zero enables both a visible outline and visible shadow. Native drawing processes separate shadow, outline and fill steps; a shadow outline can add more work. LabelSettings overrides take precedence. Character count is not a visible-glyph or draw-call count.
- **Suggested action:** Compare using only the outline or only the shadow for long UI text, and measure canvas rendering while checking readability.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/gui/label.cpp

### `ui.richtext_sync`

- **Title:** A large RichTextLabel processes text synchronously
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_richtext_sync", "value": 1}}`
- **Evidence and limits:** RichTextLabel has over 32768 current characters according to get_total_character_count() with threaded disabled. The getter walks the native item list without triggering shaping or custom effects; it counts text, newlines and image placeholders, excluding markup and stale stored text after programmatic edits. Its cache-validation path processes invalid lines synchronously; unchanged valid text is cached. The character cutoff is heuristic, not a rendered-glyph or millisecond estimate. Counting cost scales with the number of native rich-text items.
- **Suggested action:** Compare threaded text processing if long text updates stall the UI, and wait for finished before relying on completed layout dimensions.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/gui/rich_text_label.cpp

### `ui.aspect_ratio_proportional_texture`

- **Title:** A proportional TextureRect is inside an AspectRatioContainer
- **Severity:** low
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_aspect_ratio_texture_rect", "value": 1}}`
- **Evidence and limits:** Godot prints "Proportional TextureRect is currently not supported inside AspectRatioContainer" when a direct TextureRect child of AspectRatioContainer uses expand mode Fit Width Proportional or Fit Height Proportional; the container ignores that child's proportional sizing.
- **Suggested action:** Use expand mode Ignore Size or Keep Size inside the container and let the container keep the ratio.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/scene/gui/aspect_ratio_container.cpp

### `ui.flow_fit_texture_rect`

- **Title:** A fit-mode TextureRect is inside a wrapping FlowContainer
- **Severity:** low
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_flow_fit_texture_rect", "value": 1}}`
- **Evidence and limits:** Godot prints "TextureRects with Fit Expand Modes are currently not supported inside FlowContainers with multiple lines" when a direct TextureRect child of a FlowContainer that has wrapped to more than one line uses a Fit Width or Fit Height expand mode; Godot stops sizing it to avoid a layout loop. Line count is known only for laid-out containers (running scenes).
- **Suggested action:** Use Ignore Size or Keep Size for TextureRects inside FlowContainers, or wrap them in a fixed-size container.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/scene/gui/flow_container.cpp

## navigation

### `navigation.path_threads_high`

- **Title:** Pathfinding may use more than 4 threads
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `navigation/pathfinding/max_threads`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `navigation.path_threads_unlimited`

- **Title:** Pathfinding threads are unlimited
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `navigation/pathfinding/max_threads`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `navigation.sync_on_main_thread`

- **Title:** Navigation map sync runs on the main thread
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `navigation/world/map_use_async_iterations`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `navigation.avoidance_single_thread`

- **Title:** Avoidance is not using multiple threads
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `navigation/avoidance/thread_model/avoidance_use_multiple_threads`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `navigation.avoidance`

- **Title:** A NavigationAgent2D/3D has avoidance enabled
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `NavigationAgent2D/3D.avoidance_enabled`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_navigationagent3d.html

### `navigation.agents_44`

- **Title:** Navigation agents are processing avoidance
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** In Godot 4.4 this monitor counts 3D agents processing avoidance. Eight is a review prompt. Godot 4.7 renamed it to NAVIGATION_3D_AGENT_COUNT.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4
- **max_version:** 4.4
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_performance.html

### `navigation.agents_3d`

- **Title:** 3D navigation agents are processing avoidance
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** From Godot 4.5 this monitor counts 3D agents processing avoidance. Eight is a review prompt.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.5, 4.6, 4.7
- **min_version:** 4.5
- **Source:** https://docs.godotengine.org/en/4.7/classes/class_performance.html

### `navigation.agents_2d`

- **Title:** 2D navigation agents are processing avoidance
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** From Godot 4.5 this monitor counts 2D agents processing avoidance. Eight is a review prompt.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.5, 4.6, 4.7
- **min_version:** 4.5
- **Source:** https://docs.godotengine.org/en/4.7/classes/class_performance.html

### `navigation.region_sync_on_main_thread`

- **Title:** Navigation regions synchronize on the main thread
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.5, 4.6, 4.7
- **Setting:** `navigation/world/region_use_async_iterations`
- **Source:** https://docs.godotengine.org/en/4.5/tutorials/migrating/upgrading_to_godot_4.5.html

### `navigation.obstacle_static_and_dynamic`

- **Title:** A navigation obstacle is both static and dynamic
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_obstacle_static_and_dynamic", "value": 1}}`
- **Evidence and limits:** A NavigationObstacle2D/3D with avoidance enabled has both a radius (dynamic) and an outline of three or more vertices (static). Godot docs: "While both static and dynamic properties can be active at the same time on the same obstacle this is not recommended for performance."
- **Suggested action:** Use the radius while the obstacle moves and the vertices once it rests, as the page describes, instead of both at once.
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/navigation/navigation_using_navigationobstacles.html

### `navigation.tilemap_navigation_regions`

- **Title:** A TileMapLayer creates many per-cell navigation regions
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_tilemap_navigation_regions", "value": 1}}`
- **Evidence and limits:** An enabled TileMapLayer with navigation_enabled has more than 256 inspected cell/layer navigation polygons containing baked polygons or outlines and nonzero navigation layers. Both native versions create a region per qualifying cell and navigation layer. This is an object-count review cutoff, not a measured pathfinding or map-synchronization cost. Runtime tile-data overrides and scene-collection sources are skipped; resource/cell inspection limits are reported.
- **Suggested action:** For a mostly static level, compare a consolidated NavigationRegion2D bake and disable per-cell navigation only after the replacement preserves valid paths.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/2d/tile_map_layer.cpp

### `navigation.gridmap_navigation_regions`

- **Title:** A GridMap creates many per-cell navigation regions
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_gridmap_navigation_regions", "value": 1}}`
- **Evidence and limits:** A GridMap with bake_navigation enabled has more than 256 inspected cells referencing nonempty item navigation meshes with nonzero navigation layers. Native octant updates create a NavigationServer3D region per qualifying cell. The cutoff is a review heuristic; map synchronization and path cost are not measured. At most 4096 cells across qualifying GridMaps are inspected and omitted cells are reported.
- **Suggested action:** For static levels, compare baking a consolidated NavigationRegion3D from the level geometry, then disable per-cell GridMap navigation only after the replacement works.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/modules/gridmap/grid_map.cpp

### `navigation.navigation_polygons`

- **Title:** A navigation region contains a large polygon graph
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_navigation_polygons", "value": 1}}`
- **Evidence and limits:** An enabled NavigationRegion3D with nonzero navigation layers has more than 8192 baked navigation polygons. Native path queries search polygon connections; polygon count bounds graph size but is not the number visited by each query. This reads stored polygon count without rebaking the mesh. The cutoff is heuristic.
- **Suggested action:** Profile long and unreachable path requests, then simplify unnecessary navigation geometry on flat areas while preserving routes and agent clearance.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/modules/navigation/3d/nav_mesh_queries_3d.cpp

### `navigation.navigation_neighbors`

- **Title:** Avoidance agents allow more neighbours than the default
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_navigation_neighbors", "value": 1}}`
- **Evidence and limits:** An avoidance-enabled NavigationAgent2D/3D searches a positive distance and allows more than ten neighbours. Godot's RVO code retains up to max_neighbors candidates and builds a constraint for each retained neighbour. Ten is the default-based review cutoff; actual nearby agents determine work.
- **Suggested action:** Compare a smaller neighbour limit in representative dense crowds and profile CPU avoidance time.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/thirdparty/rvo2/rvo2_3d/Agent3d.cpp

### `navigation.mesh_cell_size_mismatch`

- **Title:** A navigation mesh cell is smaller than its map's
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_navmesh_cell_size_mismatch", "value": 1}}`
- **Evidence and limits:** Godot prints "A navigation mesh that uses a `cell_size` of 0.1 was assigned to a navigation map set to a larger `cell_size` of 0.25." when a NavigationRegion's mesh uses a cell_size or cell_height below the map's (the navigation/2d or 3d default_cell_size and default_cell_height settings for default maps). The message says the mismatch can cause rasterization errors with navigation mesh edges on the map.
- **Suggested action:** Bake the navigation mesh with the map's cell size and height, or change the map defaults to match.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/modules/navigation_3d/nav_region_3d.cpp

### `navigation.obstacle_vertex_height`

- **Title:** Static obstacle vertices have Y values that avoidance ignores
- **Severity:** low
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_obstacle_vertex_height", "value": 1}}`
- **Evidence and limits:** Godot prints "Y coordinates of static obstacle vertices are ignored. Please use obstacle position Y to change elevation of obstacle." in editor builds when a NavigationObstacle3D's vertices have a nonzero Y; avoidance ignores the Y in every build.
- **Suggested action:** Keep obstacle vertices at Y 0 and move the obstacle node to set its elevation.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/modules/navigation_3d/nav_map_3d.cpp

### `navigation.runtime_bake_visual_meshes`

- **Title:** Navigation is baked at runtime from visual meshes
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"all": [{"scene_gte": {"name": "check_navigation_runtime_bake", "value": 1}}, {"scene_gte": {"name": "check_navmesh_parses_meshes", "value": 1}}]}`
- **Evidence and limits:** Godot prints "Source geometry parsing for navigation mesh baking had to parse RenderingServer meshes at runtime." in a running game when a NavigationMesh parses mesh instances (parsed geometry type Mesh Instances, the default, or Both) and a script bakes or parses source geometry (bake_navigation_mesh or parse_source_geometry_data). Godot's message continues that visual meshes store their geometry on the GPU, so reading it back is slow.
- **Suggested action:** Parse static colliders instead (parsed geometry type Static Colliders), or bake in the editor and load the result.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/scene/resources/3d/navigation_mesh_source_geometry_data_3d.cpp

## physics

### `physics.solver_iterations_2d`

- **Title:** 2D solver iterations are above 16
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `physics/2d/solver/solver_iterations`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `physics.jolt_position_steps`

- **Title:** Jolt position steps are above 2
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `physics/jolt_physics_3d/simulation/position_steps`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `physics.jolt_velocity_steps`

- **Title:** Jolt velocity steps are above 10
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `physics/jolt_physics_3d/simulation/velocity_steps`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `physics.jolt_sleep_disabled`

- **Title:** Jolt rigid bodies are not allowed to sleep
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `physics/jolt_physics_3d/simulation/allow_sleep`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `physics.jolt_temp_buffer`

- **Title:** Jolt's temporary memory buffer is above 32 MiB
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `physics/jolt_physics_3d/limits/temporary_memory_buffer_size`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `physics.areas_detect_static`

- **Title:** Jolt areas detect static bodies
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4
- **max_version:** 4.4
- **Setting:** `physics/jolt_physics_3d/simulation/areas_detect_static_bodies`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `physics.continuous_cd`

- **Title:** Continuous collision detection is enabled on a 3D body
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `RigidBody3D.continuous_cd`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_rigidbody3d.html

### `physics.continuous_cd_2d`

- **Title:** Continuous collision detection is enabled on a 2D body
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `RigidBody2D.continuous_cd`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_rigidbody2d.html

### `physics.concave_shape`

- **Title:** A concave collision shape is in the scene
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `ConcavePolygonShape3D`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/performance/cpu_optimization.html

### `physics.heightmap_shape`

- **Title:** A heightmap collision shape is in the scene
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `HeightMapShape3D`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/performance/cpu_optimization.html

### `physics.soft_body`

- **Title:** A SoftBody3D is in the scene
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `SoftBody3D.simulation_precision`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_softbody3d.html

### `physics.many_character_bodies`

- **Title:** Several CharacterBody3D nodes are in the scene
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** The CPU optimization page says physics becomes a bottleneck with large numbers of physics objects, from the scene rather than a fixed cap. Eight is only a prompt to look.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `CharacterBody3D`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/performance/cpu_optimization.html

### `physics.active_bodies_2d`

- **Title:** Many 2D rigid bodies are active
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** The monitor counts active RigidBody2D nodes and says lower is better. 32 is a review prompt, not a Godot limit.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_performance.html

### `physics.pairs_2d`

- **Title:** Many 2D collision pairs
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** The monitor counts 2D collision pairs and says lower is better. 64 is a review prompt, not a Godot limit.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_performance.html

### `physics.islands_3d`

- **Title:** Many 3D physics islands
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** The monitor counts 3D physics islands and says lower is better. 32 is a review prompt, not a Godot limit.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_performance.html

### `physics.separate_thread_2d_off`

- **Title:** The 2D physics server runs on the main thread while physics takes a third of the frame
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `physics/2d/run_on_separate_thread`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `physics.jolt_contact_cache_off`

- **Title:** The Jolt body pair contact cache is disabled
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `physics/jolt_physics_3d/simulation/body_pair_contact_cache_enabled`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `physics.body_many_shapes`

- **Title:** A physics body has more than 16 collision shapes
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_body_many_shapes", "value": 1}}`
- **Evidence and limits:** A CollisionObject2D or CollisionObject3D owns more than 16 enabled shapes (for example from automatic convex decomposition). The 16 cutoff is a review heuristic. Godot docs: "Convex collision shapes should use a number of shapes as low as possible for performance reasons."
- **Suggested action:** Replace generated shape sets with a few primitive shapes (box, sphere, capsule), or a single concave shape on static level geometry.
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/physics/troubleshooting_physics_issues.html

### `physics.tilemap_kinematic`

- **Title:** A TileMap syncs its collisions as kinematic bodies
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_tilemap_kinematic", "value": 1}}`
- **Evidence and limits:** A TileMap enables collision_animatable. Godot class reference: "Enabling may have a small performance impact, only do it if the TileMap is moving and has colliding tiles."
- **Suggested action:** Disable collision_animatable unless the TileMap moves and other bodies collide with it.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/TileMap.xml

### `physics.tilemap_physics_chunking`

- **Title:** A populated TileMapLayer disables physics chunking
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_tilemap_physics_chunking", "value": 1}}`
- **Evidence and limits:** On verified Godot 4.7, an enabled TileMapLayer with collision_enabled uses physics_quadrant_size 1 and more than 256 inspected atlas cells have collision polygons with at least three points on layers with nonzero collision layer/mask bits. Native quadrant updates merge polygons with matching physics properties; size 1 disables cross-cell chunking. Godot 4.4 has no such public property and is excluded. Runtime tile-data overrides and inspection omissions are not guessed.
- **Suggested action:** If exact per-cell body identification is unnecessary, compare the default physics quadrant size of 16 and measure physics processing and tile-edit spikes.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/scene/2d/tile_map_layer.cpp

### `physics.character_slide_budget`

- **Title:** A character body permits extra slide iterations
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_character_slide_budget", "value": 1}}`
- **Evidence and limits:** A CharacterBody2D/3D with an enabled collision shape, nonzero collision mask and a process mode other than disabled raises max_slides above its default of 4 in 2D or 6 in 3D. Native grounded and floating movement repeat move_and_collide up to this limit. Actual work depends on calling move_and_slide and on the contacts encountered; a raised limit alone does not consume all iterations.
- **Suggested action:** Profile move_and_slide in collision-heavy movement and compare the default limit where gameplay permits.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/physics/character_body_3d.cpp

### `physics.softbody_precision`

- **Title:** A soft body requests additional solver iterations
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_softbody_precision", "value": 1}}`
- **Evidence and limits:** A SoftBody3D with a mesh surface requests simulation_precision above its default 5 and is not explicitly disabled with remove mode. Godot Physics repeats its link solver iteration_count times; Jolt maps the same setting to its iteration count. Mesh complexity and activity determine actual cost, and the scanner does not claim the two backends have identical work per iteration.
- **Suggested action:** Compare a lower simulation precision while profiling physics with this soft body active.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/modules/godot_physics_3d/godot_soft_body_3d.cpp

### `physics.shape_cast_results`

- **Title:** A ShapeCast permits more contact queries per update
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_shape_cast_results", "value": 1}}`
- **Evidence and limits:** An enabled ShapeCast2D/3D with a shape, a nonzero collision mask and an enabled collision target permits more than the default 32 results. Native shape casts repeatedly call rest_info, excluding each hit, until no further hit is found or max_results is reached. The limit permits extra work; it does not prove that enough objects are hit to use it. Unsupported concave 3D shapes are excluded.
- **Suggested action:** Profile shape-cast updates in dense collision scenes and compare a smaller result limit if gameplay needs only a few contacts.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/physics/shape_cast_3d.cpp

### `physics.spring_bone_collision_pairs`

- **Title:** A spring-bone simulator declares many joint/collider pairs
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_spring_bone_collision_pairs", "value": 1}}`
- **Evidence and limits:** A live active unscripted SpringBoneSimulator3D has a direct unscripted Skeleton3D parent with bones, can_process() true and an enabled internal idle/physics tick. Across the first 128 settings, configured joint counts times verified eligible unscripted direct SpringBoneCollision3D children exceed 128. Only the first 128 children and collision paths are inspected. Allow lists deduplicate verified direct references; full child lists remove resolved exclusions. Settings with more than 128 exclusions are skipped. Both native versions loop over colliders for every initialized joint. This is a configured workload indicator: joints without Verlet state and other initialization/processing early-outs can reduce actual calls, so it is not a measured collision count or CPU cost. The 128-pair threshold is heuristic; inactive, paused, detached, scripted and empty cases are excluded. The audit never initializes joints, rebuilds native collision caches, clears paths or runs collision callbacks.
- **Suggested action:** Compare restricting each chain's collision list to relevant nearby colliders, reducing decorative joints/colliders, or deactivating unused simulation. Profile skeleton/physics CPU work during the same animation, then verify contact and motion.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/spring_bone_simulator_3d.cpp

### `physics.skeleton2d_jiggle_colliders`

- **Title:** A native 2D Jiggle chain requests many collision rays
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_skeleton2d_jiggle_colliders", "value": 1}}`
- **Evidence and limits:** One of the first 128 modifications in a live, setup, owned, enabled, unscripted Skeleton2D stack is an enabled unscripted native SkeletonModification2DJiggle with use_colliders true, nonzero collision_mask, physics execution mode, an enabled internal physics tick and more than 16 configured joints. Each joint that reaches the reviewed native collision branch performs a PhysicsDirectSpaceState2D intersect_ray query. The 16-joint threshold is a review heuristic, not a Godot budget. Invalid targets or joint caches can return early, so the configured joint count is not a measured ray count or CPU cost. Strength zero does not bypass this work. Paused, detached, disabled, scripted and unrecognized native cases are excluded; the audit does not run physics queries or modifiers.
- **Suggested action:** For decorative chains, compare disabling collision where contact is unnecessary, reducing the joint chain while preserving its motion, or narrowing collision_mask. Measure physics CPU work during the same animation and camera route.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/resources/2d/skeleton/skeleton_modification_2d_jiggle.cpp

### `physics.rigid_sleep_disabled`

- **Title:** A dynamic rigid body cannot automatically sleep
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_rigid_sleep_disabled", "value": 1}}`
- **Evidence and limits:** An unfrozen RigidBody2D or RigidBody3D disables can_sleep. Sleeping bodies skip motion and force calculations until woken; disabling automatic sleep removes that opportunity when a body settles. This does not claim that a moving body could already be sleeping.
- **Suggested action:** Enable automatic sleeping where settled bodies need no continuous simulation, then compare the same settling scene and physics CPU time.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/RigidBody3D.xml

### `physics.rigid_contact_budget`

- **Title:** A rigid body allows a large contact-report list
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_rigid_contact_budget", "value": 1}}`
- **Evidence and limits:** An unfrozen RigidBody2D or RigidBody3D enables contact monitoring with max_contacts_reported above 32, a heuristic review cutoff. Native monitoring builds temporary lists and walks actual reported contacts during state callbacks. The configured cap permits work but does not establish the actual contact count or cost; multiple contacts can belong to one collision.
- **Suggested action:** Profile crowded contact cases and compare a smaller report cap only if gameplay still receives every contact it needs.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/physics/rigid_body_3d.cpp

### `physics.jolt_joint_ignored`

- **Title:** A joint sets parameters that Jolt Physics ignores
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"all": [{"scene_gte": {"name": "check_jolt_joint_ignored", "value": 1}}, {"setting_eq": {"path": "physics/3d/physics_engine", "value": "Jolt Physics"}}]}`
- **Evidence and limits:** Godot prints "Hinge joint softness is not supported when using Jolt Physics. Any such value will be ignored." for each Hinge, Pin, ConeTwist, Slider or Generic6DOF joint parameter (bias, softness, relaxation, damping, restitution, ERP, force limit and slider angular limits) and solver priority that differs from Godot's default while physics/3d/physics_engine is Jolt Physics. PhysicalBone3D joints are not inspected.
- **Suggested action:** Reset the parameters Jolt ignores, or tune the joint with the settings Jolt implements (limits, motors and springs).
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/modules/jolt_physics/joints/jolt_hinge_joint_3d.cpp

### `physics.jolt_area_wind_ignored`

- **Title:** An Area3D sets wind that Jolt Physics ignores
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"all": [{"scene_gte": {"name": "check_jolt_area_wind_ignored", "value": 1}}, {"setting_eq": {"path": "physics/3d/physics_engine", "value": "Jolt Physics"}}]}`
- **Evidence and limits:** Godot prints "Area wind force magnitude is not supported when using Jolt Physics. Any such value will be ignored." when an Area3D's wind force magnitude, attenuation or source differs from the default while physics/3d/physics_engine is Jolt Physics (Godot 4.4 to 4.6; 4.7 implements area wind).
- **Suggested action:** Apply the force from a script, or remove the wind settings.
- **Source:** https://github.com/godotengine/godot/blob/4.6.3-stable/modules/jolt_physics/objects/jolt_area_3d.cpp

### `physics.jolt_shape_bias_ignored`

- **Title:** A collision shape sets a solver bias that Jolt Physics ignores
- **Severity:** low
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"all": [{"scene_gte": {"name": "check_jolt_shape_bias_ignored", "value": 1}}, {"setting_eq": {"path": "physics/3d/physics_engine", "value": "Jolt Physics"}}]}`
- **Evidence and limits:** Godot prints "Custom solver bias for shapes is not supported when using Jolt Physics. Any such value will be ignored." when a CollisionShape3D's shape has a nonzero custom_solver_bias while physics/3d/physics_engine is Jolt Physics.
- **Suggested action:** Set custom_solver_bias back to 0.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/modules/jolt_physics/shapes/jolt_shape_3d.cpp

### `physics.convex_polygon_2d_concave`

- **Title:** A ConvexPolygonShape2D has concave points
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_convex_polygon_concave", "value": 1}}`
- **Evidence and limits:** Godot prints "Concave polygon is assigned to ConvexPolygonShape2D." in debug builds when a CollisionShape2D's ConvexPolygonShape2D points fail Godot's convexity test; the shape still collides as a convex solver shape, so contacts do not follow the drawn outline.
- **Suggested action:** Use a CollisionPolygon2D with build mode Solids (it decomposes concave outlines), or a ConcavePolygonShape2D for static geometry.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/scene/resources/2d/convex_polygon_shape_2d.cpp

### `physics.jolt_singular_basis`

- **Title:** A physics node has a zero-scale axis under Jolt Physics
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"all": [{"scene_gte": {"name": "check_jolt_singular_basis", "value": 1}}, {"setting_eq": {"path": "physics/3d/physics_engine", "value": "Jolt Physics"}}]}`
- **Evidence and limits:** Godot prints "<object>: The basis of the transform was singular, which is not supported by Jolt Physics. This is likely caused by one or more axes having a scale of zero. The basis (and thus its scale) will be treated as identity." when a CollisionObject3D or CollisionShape3D in the tree has a global transform with a zero scale on some axis while physics/3d/physics_engine is Jolt Physics; Jolt replaces the basis.
- **Suggested action:** Give physics nodes a nonzero scale; hide or disable them instead of scaling them to zero.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/modules/jolt_physics/shapes/jolt_shape_3d.h

### `physics.jolt_server_call_ignored`

- **Title:** A script sets PhysicsServer3D parameters that Jolt Physics ignores
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"all": [{"scene_gte": {"name": "check_script_jolt_server_call", "value": 1}}, {"setting_eq": {"path": "physics/3d/physics_engine", "value": "Jolt Physics"}}]}`
- **Evidence and limits:** Godot prints "Space-specific solver iterations is not supported when using Jolt Physics. Any such value will be ignored." when physics/3d/physics_engine is Jolt Physics and a script calls PhysicsServer3D.space_set_param() (every space parameter: contact recycle radius, max separation, max penetration, default bias, sleep thresholds, sleep time, solver iterations), body_set_user_flags() or body_set_contacts_reported_depth_threshold() with a non-default value.
- **Suggested action:** Use the physics/jolt_physics_3d project settings for the equivalent tuning, or drop the calls under Jolt.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/modules/jolt_physics/spaces/jolt_space_3d.cpp

## xr

### `xr.foveation_ignored`

- **Title:** Foveation is set but the renderer is Forward+
- **Severity:** info
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4
- **max_version:** 4.4
- **Setting:** `xr/openxr/foveation_level`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `xr.subsample_off`

- **Title:** Foveation is not using subsampled images
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** gl_compatibility
- **Godot versions:** 4.7
- **min_version:** 4.7
- **Setting:** `xr/openxr/foveation_with_subsampled_images`
- **Source:** https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html

### `xr.screen_texture`

- **Title:** An XR project reads the screen texture
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"all": [{"scene_gte": {"name": "check_screen_texture", "value": 1}}, {"setting_eq": {"path": "xr/openxr/enabled", "value": true}}]}`
- **Evidence and limits:** xr/openxr/enabled is on and a spatial ShaderMaterial declares a hint_screen_texture uniform, or a BaseMaterial3D enables refraction (which samples the screen texture); comments are ignored. The page adds that Godot then makes a full copy of the render buffer. Godot docs: "Full screen effects that require reading from the screen texture effectively disable all rendering performance optimizations in XR."
- **Suggested action:** Write XR full-screen effects as per-pixel shaders that do not sample the screen (the page's vignette example), and avoid refraction on XR-visible materials.
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/xr/xr_full_screen_effects.html

### `xr.composition_layer_sort_zero`

- **Title:** An OpenXR composition layer has sort order 0
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_openxr_layer_sort_zero", "value": 1}}`
- **Evidence and limits:** Godot prints "Composition layer returned sort order 0, it may be overwritten by projection layer." when an OpenXRCompositionLayer's sort_order is 0, the order of the main projection layer, so the runtime may draw the scene over it.
- **Suggested action:** Use a positive sort_order to draw the layer in front of the scene, or a negative one to draw it behind.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/modules/openxr/openxr_api.cpp

### `xr.frame_synthesis_renderer`

- **Title:** OpenXR frame synthesis is requested under Forward+
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.6, 4.7
- **Setting:** `xr/openxr/extensions/frame_synthesis`
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"all": [{"setting_eq": {"path": "xr/openxr/enabled", "value": true}}, {"setting_eq": {"path": "xr/openxr/extensions/frame_synthesis", "value": true}}]}`
- **Evidence and limits:** Godot prints "OpenXR: Frame synthesis not supported for this rendering method!" when xr/openxr/extensions/frame_synthesis is on and the project renders with Forward+ on Vulkan; Godot unregisters the extension, so no frames are synthesized. Mobile on Vulkan and Compatibility support it; Direct3D 12 and Metal reject it as a driver instead.
- **Suggested action:** Use the Mobile renderer for XR projects that rely on frame synthesis, or turn the setting off.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/modules/openxr/extensions/openxr_frame_synthesis_extension.cpp

### `xr.object_picking_stereo`

- **Title:** Physics object picking is expected in a stereo XR viewport
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"any": [{"scene_gte": {"name": "check_xr_viewport_picking", "value": 1}}, {"all": [{"scene_gte": {"name": "check_xr_pickable_listener", "value": 1}}, {"setting_eq": {"path": "xr/openxr/enabled", "value": true}}, {"setting_eq": {"path": "physics/common/enable_object_picking", "value": true}}]}]}`
- **Evidence and limits:** Godot prints "Object picking can't be used when stereo rendering, this will be turned off!" once a stereo XR interface renders a viewport that has physics object picking on: a SubViewport with use_xr and physics_object_picking, or an OpenXR project whose root viewport picks (physics/common/enable_object_picking) while scene objects listen for input_event. Godot then turns picking off, so those listeners get no mouse or pointer events.
- **Suggested action:** Use XR pointer raycasts (RayCast3D or a pointer tool) for interaction, and turn object picking off for XR viewports.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/scene/main/viewport.cpp

### `xr.canvas_background_multiview`

- **Title:** An XR project uses a canvas environment background on Mobile
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"all": [{"scene_gte": {"name": "check_env_bg_canvas", "value": 1}}, {"setting_eq": {"path": "xr/openxr/enabled", "value": true}}]}`
- **Evidence and limits:** Godot prints "Canvas background is not supported in multiview!" when an Environment uses background mode Canvas in an OpenXR project under the Mobile renderer; stereo (multiview) rendering cannot show the canvas behind the scene.
- **Suggested action:** Use a sky, color or passthrough background in XR.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/renderer_rd/forward_mobile/render_forward_mobile.cpp

### `xr.foveation_subsampled_disabled`

- **Title:** Subsampled foveation is disabled by post-processing on Mobile
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** mobile
- **Godot versions:** 4.7
- **Setting:** `xr/openxr/foveation_with_subsampled_images`
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"all": [{"setting_eq": {"path": "xr/openxr/enabled", "value": true}}, {"setting_eq": {"path": "xr/openxr/foveation_with_subsampled_images", "value": true}}, {"any": [{"scene_gte": {"name": "env_glow", "value": 1}}, {"scene_gte": {"name": "dof_blur_enabled", "value": 1}}, {"scene_gte": {"name": "check_auto_exposure", "value": 1}}, {"scene_gte": {"name": "check_env_bg_canvas", "value": 1}}, {"scene_gte": {"name": "check_shader_screen_read", "value": 1}}, {"scene_gte": {"name": "check_compositor_transparent_callback", "value": 1}}, {"setting_neq": {"path": "rendering/anti_aliasing/quality/screen_space_aa", "value": 0}}, {"setting_neq": {"path": "rendering/scaling_3d/scale", "value": 1.0}}]}]}`
- **Evidence and limits:** Godot prints "Foveation with subsampled images was enabled, but rendering features are in use that have forced it to be disabled." on headsets with the FB foveation extension when xr/openxr/foveation_with_subsampled_images is on (the default) and the Mobile renderer cannot finish post-processing in a subpass: glow, depth of field, auto-exposure, a canvas background, screen or depth texture reads (shaders, refraction, proximity fade), transparent-stage compositor effects, screen-space AA or a 3D scale other than 1 (render_forward_mobile.cpp).
- **Suggested action:** Remove those features from the XR view to keep subsampled foveation, or turn the setting off.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/modules/openxr/openxr_api.cpp

## renderer

### `renderer.burley_mobile`

- **Title:** Mobile devices use Burley instead of Lambert diffuse
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/shading/overrides/force_lambert_over_burley.mobile`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `renderer.gl_item_buffer_raised`

- **Title:** The Compatibility canvas item buffer is above its default
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Setting:** `rendering/gl_compatibility/item_buffer_size`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

### `renderer.nvidia_gl_threaded`

- **Title:** NVIDIA threaded optimization stays enabled under OpenGL
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **GPU families:** nvidia
- **Setting:** `rendering/gl_compatibility/nvidia_disable_threaded_optimization`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_projectsettings.html

## animation

### `animation.physics_callback`

- **Title:** An AnimationPlayer updates during the physics frame
- **Severity:** low
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `AnimationMixer.callback_mode_process`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_animationmixer.html

## scripts

### `scripts.many_process`

- **Title:** Several nodes run _process
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** The CPU optimization page says _process propagates through the tree and each node has a cost, with the visible range starting at thousands of nodes. Eight is only a prompt to look.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Node._process`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/performance/cpu_optimization.html

### `scripts.many_physics_process`

- **Title:** Several nodes run _physics_process
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** The CPU optimization page groups _physics_process with _process as tree propagation cost. Eight is only a prompt to look, below the documented thousands of nodes.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Node._physics_process`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/performance/cpu_optimization.html

### `scripts.node_count_high`

- **Title:** The project has many autoloads
- **Severity:** low
- **Kind:** info
- **Heuristic:** yes
- **Heuristic rationale:** Autoloads are nodes that stay for the whole run. The CPU optimization page says every node has a cost. Sixteen autoloads is a review prompt, not a Godot limit.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Node`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/performance/cpu_optimization.html

### `scripts.frame_texture_readback`

- **Title:** A texture is read back from the GPU every frame
- **Severity:** high
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Texture2D.get_image`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_texture2d.html

### `scripts.frame_mesh_bake`

- **Title:** A skinned or blend-shape mesh is baked from the GPU every frame
- **Severity:** high
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `MeshInstance3D.bake_mesh_from_current_skeleton_pose`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_meshinstance3d.html

### `scripts.frame_multimesh_buffer`

- **Title:** A MultiMesh buffer is read back every frame
- **Severity:** high
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `RenderingServer.multimesh_get_buffer`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_renderingserver.html

### `scripts.frame_global_shader_get`

- **Title:** A global shader parameter is read from the rendering server every frame
- **Severity:** high
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `RenderingServer.global_shader_parameter_get`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_renderingserver.html

### `scripts.frame_force_sync`

- **Title:** The rendering server is force-synchronized every frame
- **Severity:** high
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `RenderingServer.force_sync`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_renderingserver.html

### `scripts.frame_find_nodes`

- **Title:** The scene tree is searched by name every frame
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Node.find_child`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_node.html

### `scripts.frame_group_calls`

- **Title:** A whole node group is called or notified every frame
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `SceneTree.call_group`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_scenetree.html

### `scripts.frame_output_latency`

- **Title:** Audio output latency is queried every frame
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `AudioServer.get_output_latency`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_audioserver.html

### `scripts.frame_window_title`

- **Title:** The window title is changed every frame
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `DisplayServer.window_set_title`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_displayserver.html

### `scripts.frame_capture_rect`

- **Title:** GPU particle bounds are captured every frame
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `GPUParticles2D.capture_rect`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_gpuparticles2d.html

### `scripts.frame_tile_update`

- **Title:** Runtime tile data is invalidated every frame
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `TileMapLayer.notify_runtime_tile_data_update`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_tilemaplayer.html

### `scripts.frame_bone_global_pose`

- **Title:** Global bone poses are written every frame
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Skeleton3D.set_bone_global_pose`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_skeleton3d.html

### `scripts.frame_navigation_parse`

- **Title:** Navigation source geometry is parsed every frame
- **Severity:** high
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `NavigationServer3D.parse_source_geometry_data`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_navigationserver3d.html

### `scripts.frame_navigation_force_update`

- **Title:** A navigation map is force-updated every frame
- **Severity:** high
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `NavigationServer3D.map_force_update`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_navigationserver3d.html

### `scripts.frame_navigation_bake`

- **Title:** A navigation mesh is baked every frame
- **Severity:** high
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `NavigationRegion3D.bake_navigation_mesh`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_navigationregion3d.html

### `scripts.frame_image_texture_set`

- **Title:** An ImageTexture is recreated every frame
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `ImageTexture.set_image`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_imagetexture.html

### `scripts.frame_file_flush`

- **Title:** A file is flushed to disk every frame
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `FileAccess.flush`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_fileaccess.html

### `scripts.frame_impulse`

- **Title:** An impulse not scaled by the frame time is applied every frame
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** yes
- **Heuristic rationale:** Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces (nothing after the first return is reported; nested branches and loops are skipped). Methods match by name, so a script method with the same name can match; get_image, set_image and flush must be called on an object.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `RigidBody3D.apply_impulse`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_rigidbody3d.html

### `scripts.tile_runtime_update_all`

- **Title:** Every tile is marked for runtime tile-data updates
- **Severity:** high
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Text scan: the first statement of a _use_tile_data_runtime_update override is `return true`, so every tile of the layer is processed at runtime.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `TileMapLayer._use_tile_data_runtime_update`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_tilemaplayer.html

### `scripts.draw_line_loop`

- **Title:** Lines are drawn one draw_line call at a time inside a loop
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Text scan of _draw: draw_line calls inside for or while loops, including one-line loops. Loop counts are not known, so a short fixed loop is reported too.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `CanvasItem.draw_multiline`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_canvasitem.html

### `scripts.profile_top_self`

- **Title:** One script function uses a large share of the frame
- **Severity:** high
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** The CPU optimization page says to focus on the function that takes much more time than the others. One fifth of the frame budget is the cutoff used here.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/performance/cpu_optimization.html

### `scripts.frame_navigation_reachable`

- **Title:** Path reachability is checked every frame
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** A configured feature is a measurement candidate, not proof that it is currently visible, costly or unnecessary. Numeric review thresholds are Render Lens heuristics, not Godot limits.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_frame_navigation_reachable", "value": 1}}`
- **Evidence and limits:** Text scan of unconditional top-level statements in _process, _physics_process and _integrate_forces finds is_target_reachable(). Methods match by name. Godot docs: "Do not check beforehand if a target position is reachable every frame. What looks like an innocent check is the equivalent of an expensive path query behind the scene."
- **Suggested action:** Request the path directly and compare its last point with the target, as the page suggests, instead of checking reachability every frame.
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/navigation/navigation_optimizing_performance.html

### `scripts.deprecated_engine_call`

- **Title:** A script calls a deprecated Godot API that does nothing
- **Severity:** low
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_script_deprecated_call", "value": 1}}`
- **Evidence and limits:** Godot prints "Deprecated. Barriers are automatically inserted by RenderingDevice." when a script calls RenderingDevice.barrier() or full_barrier(), or draw_command_insert_label(); Godot also warns that RenderingServer.reflection_probe_set_resolution() is not available in Godot 4, that environment_set_ssr_roughness_quality() no longer does anything (4.6+), and that NavigationServer3D.region_bake_navigation_mesh() and NavigationMeshGenerator.bake() are deprecated. Calls in comments and strings are ignored.
- **Suggested action:** Remove the no-op calls; for navigation, parse source geometry and bake with NavigationServer3D.bake_from_source_geometry_data(); set reflection-probe size in the project settings.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/rendering_device.cpp

### `scripts.draw_argument_ignored`

- **Title:** A draw call passes an argument Godot ignores
- **Severity:** low
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_script_draw_ignored", "value": 1}}`
- **Evidence and limits:** Godot prints "The draw_rect() "width" argument has no effect when "filled" is "true"." when a script calls draw_rect() or draw_circle() with filled set to true and a literal width other than -1, or draw_polyline()/draw_multiline() with a literal negative width and antialiased set to true (thin line strips cannot be antialiased). Only literal arguments are judged.
- **Suggested action:** Drop the width for filled shapes, or draw an outline separately; use a positive width when antialiasing lines.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/scene/main/canvas_item.cpp

### `scripts.theme_in_init`

- **Title:** A script reads theme items in _init
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_script_theme_in_init", "value": 1}}`
- **Evidence and limits:** Godot prints "Attempting to access theme items too early in Control; prefer NOTIFICATION_POSTINITIALIZE and NOTIFICATION_THEME_CHANGED" when a script's _init calls get_theme_* or has_theme_*; the Control (or Window) is not initialized yet, so the theme lookup has no owner theme or overrides.
- **Suggested action:** Read theme items in _notification for NOTIFICATION_THEME_CHANGED (or NOTIFICATION_POSTINITIALIZE), or in _ready.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/scene/gui/control.cpp

## import

### `import.mesh_lods_off`

- **Title:** A 3D scene import disabled mesh LOD generation
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Mesh`
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/editor/import/3d/resource_importer_scene.cpp

### `import.mesh_shadow_off`

- **Title:** A 3D scene import disabled shadow meshes
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Mesh`
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/editor/import/3d/resource_importer_scene.cpp

### `import.mesh_uncompressed`

- **Title:** A 3D scene import disables mesh compression
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Mesh`
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/editor/import/3d/resource_importer_scene.cpp

### `import.audio_pcm`

- **Title:** A WAV import uses PCM instead of a compressed mode
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `AudioStreamWAV`
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/editor/import/resource_importer_wav.cpp

### `import.texture_lossless`

- **Title:** A layered texture import (cubemap, array or 3D texture) uses lossless compression
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Texture2D`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/assets_pipeline/importing_images.html

### `import.texture_no_mipmaps`

- **Title:** A layered texture import (cubemap, array or 3D texture) does not generate mipmaps
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Texture2D`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/assets_pipeline/importing_images.html

### `import.texture_uncompressed`

- **Title:** A texture import is VRAM-uncompressed
- **Severity:** high
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `Texture2D`
- **Source:** https://docs.godotengine.org/en/4.4/tutorials/assets_pipeline/importing_images.html

### `import.texture_high_quality`

- **Title:** VRAM-compressed textures use high-quality BPTC/ASTC compression
- **Severity:** low
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** The .import file does not record whether the image is opaque; for transparent images both modes use 8 bits per pixel, so only opaque textures lose memory.
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `ResourceImporterTexture.compress/high_quality`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_resourceimportertexture.html

### `import.texture_hdr_uncompressed`

- **Title:** HDR textures are imported without VRAM compression
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `ResourceImporterTexture.compress/hdr_compression`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_resourceimportertexture.html

### `import.gltf_embedded_uncompressed`

- **Title:** A glTF import embeds its images uncompressed
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_gltfstate.html

### `import.obj_lods_off`

- **Title:** An OBJ import disables mesh LOD generation
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `ResourceImporterOBJ.generate_lods`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_resourceimporterobj.html

### `import.obj_shadow_off`

- **Title:** An OBJ import disables shadow mesh generation
- **Severity:** low
- **Kind:** performance
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Node:** `ResourceImporterOBJ.generate_shadow_mesh`
- **Source:** https://docs.godotengine.org/en/4.4/classes/class_resourceimporterobj.html

## scene_validation

### `scene_validation.shader_cooperative_outer_interpretation`

- **Title:** A cooperative outer product declares an invalid accumulation interpretation
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/core_checks/cc_spirv_cooperative.cpp

### `scene_validation.shader_cooperative_reduce_type`

- **Title:** A cooperative reduction uses an invalid vector component type
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/core_checks/cc_spirv_cooperative.cpp

### `scene_validation.shader_cooperative_training_storage`

- **Title:** A cooperative accumulation targets an invalid pointer storage class
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/core_checks/cc_spirv_cooperative.cpp

### `scene_validation.shader_cooperative_fp8_layout`

- **Title:** An FP8 cooperative matrix multiplication uses an invalid memory layout
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/core_checks/cc_spirv_cooperative.cpp

### `scene_validation.shader_graph_capability`

- **Title:** An imported shader module declares a data-graph-only capability
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/stateless/sl_spirv.cpp

### `scene_validation.shader_tensor_declaration`

- **Title:** An imported shader declares a tensor with a shape or without a rank
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/stateless/sl_spirv.cpp

### `scene_validation.shader_subgroup_repack`

- **Title:** A subgroup-uniform-control-flow shader includes an invocation-repack instruction
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/stateless/sl_spirv.cpp

### `scene_validation.shader_cooperative_alignment`

- **Title:** A cooperative-vector operation uses a misaligned constant offset or stride
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://registry.khronos.org/vulkan/specs/latest/html/vkspec.html#spirvenv-module-validation-runtime

### `scene_validation.shader_cooperative_offset_width`

- **Title:** A cooperative-vector offset is a 64-bit integer
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://registry.khronos.org/vulkan/specs/latest/html/vkspec.html#spirvenv-module-validation-runtime

### `scene_validation.shader_matrix_muladd`

- **Title:** A cooperative-matrix multiply-add combines incompatible matrices
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Source:** https://github.com/KhronosGroup/SPIRV-Tools/blob/main/source/val/validate_arithmetics.cpp

### `scene_validation.shader_cooperative_outer_type`

- **Title:** A cooperative outer product uses non-float16 input components
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `VUID-RuntimeSpirv-OpCooperativeVectorOuterProductAccumulateNV-10093; ValidateCooperativeVector` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_shader_cooperative_outer_type", "value": 1}}`
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/core_checks/cc_spirv_cooperative.cpp

### `scene_validation.shader_cooperative_outer_layout`

- **Title:** A cooperative outer product declares the wrong matrix layout
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `VUID-RuntimeSpirv-OpCooperativeVectorOuterProductAccumulateNV-10093; ValidateCooperativeVector` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_shader_cooperative_outer_layout", "value": 1}}`
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/core_checks/cc_spirv_cooperative.cpp

### `scene_validation.shader_extension_namespace`

- **Title:** An imported shader uses a non-SPIR-V extension declaration
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `VUID-VkShaderModuleCreateInfo-pCode-08741; ValidateShaderCapabilitiesAndExtensions` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_shader_extension_namespace", "value": 1}}`
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/vulkan/generated/spirv_validation_helper.cpp

### `scene_validation.shader_vulkan_capability`

- **Title:** An imported shader declares a capability forbidden by Vulkan
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `VUID-VkShaderModuleCreateInfo-pCode-08739; GetSpirvCapabilites; ValidateShaderCapabilitiesAndExtensions` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_shader_vulkan_capability", "value": 1}}`
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/vulkan/generated/spirv_validation_helper.cpp

### `scene_validation.shader_interface_8bit`

- **Title:** An imported shader declares an 8-bit input or output
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `VUID-RuntimeSpirv-None-10980; Validate8And16BitStorage` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_shader_interface_8bit", "value": 1}}`
- **Evidence and limits:** An imported RDShaderFile version with no stored base or stage compilation errors contains a typed OpVariable in Input or Output storage with an 8-bit integer or floating-point element. Vulkan forbids these objects unconditionally. Both checked Godot compilers accept scalar int8_t vertex/fragment inputs and outputs and retain the 8-bit declarations in SPIR-V, so compiler-error reporting alone does not cover this case. Every inspected public shader stage is considered. Numeric scalar/vector/matrix/array/struct type chains are inspected within 16 levels with cached visits; nested pointers, untyped variables, unknown types and deeper branches are skipped. This does not classify 8-bit buffers, push constants, workgroup data or 16-bit interfaces as invalid. Imported presence does not prove linking or execution; no shader or pipeline is created by the audit.
- **Suggested action:** Use a permitted interface representation, normally 32-bit integers for these values, and convert to or from 8-bit data within the shader. Update both sides of a stage interface and vertex attribute formats or render-target outputs as appropriate, then reimport.
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/stateless/sl_spirv.cpp

### `scene_validation.shader_storage_format`

- **Title:** An imported storage-image format is unsupported on this Vulkan device
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `VUID-VkImageViewCreateInfo-usage-02275; CompatibleSpirvImageFormat` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_shader_storage_format", "value": 1}}`
- **Evidence and limits:** An imported RDShaderFile version with no stored base or stage compilation errors declares a UniformConstant storage image with a known explicit SPIR-V ImageFormat and descriptor set/binding. The corresponding Godot DataFormat does not support TEXTURE_USAGE_STORAGE_BIT for either optimal or linear tiling on the current Vulkan RenderingDevice. The exact SPIR-V/Vulkan format mapping and both native Godot driver tables are checked. Direct and fixed-array 1D/2D/3D/cube images are inspected within existing scan budgets; buffer/subpass images, formatless or unmapped formats and unknown array lengths are skipped. Native support queries are cached per format. This reads declarations and format support without creating an image, shader or pipeline; project presence does not prove binding or execution. Other device features, usage combinations and dimensions are not validated.
- **Suggested action:** Choose a storage-image format supported on each target device, then update both the shader format qualifier and its matching RenderingDevice texture/view format. Retain a fallback if devices require different formats; merely removing the format qualifier does not establish formatless access support.
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/core_checks/cc_image.cpp

### `scene_validation.shader_invalid_spirv`

- **Title:** An imported shader contains an invalid SPIR-V header
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `VUID-VkShaderModuleCreateInfo-codeSize-08735; VUID-VkShaderModuleCreateInfo-pCode-08738; SPIR-V five-word module header` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_shader_invalid_spirv", "value": 1}}`
- **Evidence and limits:** While using Vulkan, a nonempty imported RDShaderFile stage within the scan budget is shorter than the five-word SPIR-V header, has a byte length not divisible by four, or starts with the wrong SPIR-V magic word. Its version has no stored base or stage compilation error. Oversized modules, empty absent stages, byte-swapped modules, unsupported execution models and other skipped reflection cases are not called corrupt. This reads stored bytes without creating a shader or pipeline; project presence does not prove execution. Header success does not validate the rest of the module.
- **Suggested action:** Reimport the source shader and inspect the reported resource/version/stage. If another tool writes RDShaderSPIRV bytecode, fix that output and restore a correctly compiled resource; do not submit the malformed bytes to a RenderingDevice.
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/core_checks/cc_spirv.cpp

### `scene_validation.shader_interface`

- **Title:** Imported vertex and fragment interfaces do not match
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `VUID-RuntimeSpirv-OpEntryPoint-07754; VUID-RuntimeSpirv-OpEntryPoint-08743` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_shader_interface", "value": 1}}`
- **Evidence and limits:** A successfully compiled imported RDShaderFile version contains only vertex and fragment bytecode. At an explicit Location/Component slot, its vertex output and fragment input disagree on numeric kind or bit width, or a known fragment input has no matching vertex output. Missing-output findings require complete supported vertex reflection; unknown or truncated declarations suppress them. Godot compiles the stages separately. If linked together these declarations violate Vulkan's interface type requirement; file presence does not prove pipeline creation or execution. Numeric 16/32/64-bit scalars, vectors, matrices, fixed arrays and structs with explicit variable/member locations are inspected within 16 type levels and 1024 component slots per stage. Integer signedness is ignored, matching upstream. A PerVertexKHR fragment input ignores exactly its outer per-vertex array wrapper for interface matching. Unknown lengths/types, grouped decorations, overlaps and excess slots are skipped. Array lengths require known unsigned 32-bit constants. Unused outputs, built-ins, tessellation and maintenance4-dependent vector-size rules are not inferred.
- **Suggested action:** Provide the intended vertex output at the reported fragment-input location/component and make both numeric kind and bit width agree, then reimport. Check all variants and callers that use the paired stages.
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/core_checks/cc_shader_interface.cpp

### `scene_validation.compute_pow_domain`

- **Title:** An imported shader stage has a known out-of-domain power operand
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `SPIRV-Sanitizer-Pow` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_compute_pow_domain", "value": 1}}`
- **Evidence and limits:** A known float32 component of GLSL.std.450 Pow has x below zero, or x equal to zero and a known y at most zero. Even an integer-valued exponent does not make a negative GLSL Pow base defined. On the Vulkan path, imported public shader stages are inspected individually: vertex, fragment, tessellation and compute, plus ray-tracing stages in Godot 4.7. Only the first stage entry block and the exact GLSL.std.450 import are inspected. Scalar32 literals, constant-null vectors, 2-4 component vectors constructed directly from scalar operands, and literal uint32-to-float32 bitcasts are supported. Unknown components remain unknown; helpers, later blocks, specialization, other widths and computed expressions are skipped. Compiler-folded operations may leave no instruction to inspect. File presence does not prove execution or measured cost.
- **Suggested action:** Correct the domain or explicitly implement the intended signed/integer-power behavior. Clamp only if that preserves the algorithm.
- **Source:** https://registry.khronos.org/SPIR-V/specs/unified1/GLSL.std.450.html

### `scene_validation.compute_atan2_zero`

- **Title:** An imported shader stage has known zero/zero atan2 operands
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `SPIRV-Sanitizer-Atan2` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_compute_atan2_zero", "value": 1}}`
- **Evidence and limits:** A corresponding float32 component pair of GLSL.std.450 Atan2 has both x and y equal to zero, including either sign of zero. The result for that component is undefined/poison if executed. On the Vulkan path, imported public shader stages are inspected individually: vertex, fragment, tessellation and compute, plus ray-tracing stages in Godot 4.7. Only the first stage entry block and the exact GLSL.std.450 import are inspected. Scalar32 literals, constant-null vectors, 2-4 component vectors constructed directly from scalar operands, and literal uint32-to-float32 bitcasts are supported. Unknown components remain unknown; helpers, later blocks, specialization, other widths and computed expressions are skipped. Compiler-folded operations may leave no instruction to inspect. File presence does not prove execution or measured cost.
- **Suggested action:** Define and guard the zero-vector case before computing its angle; choose a fallback that preserves the intended orientation.
- **Source:** https://registry.khronos.org/SPIR-V/specs/unified1/GLSL.std.450.html

### `scene_validation.compute_minmax_nan`

- **Title:** An imported shader stage has a literal NaN in min/max
- **Severity:** medium
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `SPIRV-Sanitizer-Fminmax` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_compute_minmax_nan", "value": 1}}`
- **Evidence and limits:** A float32 component of GLSL.std.450 FMin/FMax has a known NaN operand. The current Khronos specification makes the choice of operand implementation-dependent when NaN is involved, and special-value behavior also depends on floating-point controls. This is portability guidance, not an invalid-instruction claim; it deliberately differs from the pinned GPUAV diagnostic's undefined-result wording. On the Vulkan path, imported public shader stages are inspected individually: vertex, fragment, tessellation and compute, plus ray-tracing stages in Godot 4.7. Only the first stage entry block and the exact GLSL.std.450 import are inspected. Scalar32 literals, constant-null vectors, 2-4 component vectors constructed directly from scalar operands, and literal uint32-to-float32 bitcasts are supported. Unknown components remain unknown; helpers, later blocks, specialization, other widths and computed expressions are skipped. Compiler-folded operations may leave no instruction to inspect. File presence does not prove execution or measured cost.
- **Suggested action:** If deterministic NaN handling matters, test for NaN explicitly and choose the intended fallback instead of relying on min/max to sanitize it.
- **Source:** https://registry.khronos.org/SPIR-V/specs/unified1/GLSL.std.450.html

### `scene_validation.compute_zero_divisor`

- **Title:** An imported shader stage has a literal zero divisor
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `SPIRV-Sanitizer-Divide-By-Zero` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_compute_zero_divisor", "value": 1}}`
- **Evidence and limits:** In the first block of the single stage entry function, an integer division/remainder/modulo or floating remainder/modulo uses a known zero component in a scalar or 2-4 component vector of 32-bit divisors. Positive and negative float zero, direct scalar-component vector construction, literal uint32-to-float32 bitcasts and OpConstantNull are recognized. Floating division is deliberately excluded, matching upstream. Helper functions, later blocks, other widths, specialization and unknown dynamic components are skipped. This Vulkan-path static finding describes an invalid/undefined operation if executed, not a captured runtime failure; the imported file may be unused.
- **Suggested action:** Correct the divisor or guard the operation, and define the intended output for a zero input. Reimport and verify the actual workload on representative inputs.
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/gpuav/spirv/sanitizer_pass.cpp

### `scene_validation.compute_ray_query_flags`

- **Title:** An imported shader stage has conflicting literal ray-query flags
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `VUID-RuntimeSpirv-OpRayQueryInitializeKHR-06889; VUID-RuntimeSpirv-OpRayQueryInitializeKHR-06890; VUID-RuntimeSpirv-OpRayQueryInitializeKHR-06891` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_compute_ray_query_flags", "value": 1}}`
- **Evidence and limits:** A direct uint32 OpConstant flag operand selects both SkipTriangles and SkipAABBs; more than one of SkipTriangles/CullBackFacingTriangles/CullFrontFacingTriangles; or more than one of Opaque/NoOpaque/CullOpaque/CullNoOpaque. Only OpRayQueryInitializeKHR before the first control-flow terminator in the single stage entry function is inspected, on the Vulkan path. Helper functions, later blocks, specialization constants and dynamic operands are skipped. File presence does not prove execution or device support; this is a static operand finding, not a captured validation error or measured performance cost.
- **Suggested action:** Choose compatible ray-query flags for the intended geometry and opacity policy; retain at most one flag from each mutually exclusive group.
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/gpuav/shaders/instrumentation/trace_ray.comp

### `scene_validation.compute_ray_query_distance`

- **Title:** An imported shader stage has invalid literal ray-query distances
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `VUID-RuntimeSpirv-OpRayQueryInitializeKHR-06349; VUID-RuntimeSpirv-OpRayQueryInitializeKHR-06350; VUID-RuntimeSpirv-OpRayQueryInitializeKHR-06351` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_compute_ray_query_distance", "value": 1}}`
- **Evidence and limits:** A known float32 literal, zero OpConstantNull or literal uint32-to-float32 bitcast Tmin/Tmax is NaN or negative, or two known constants have Tmax below Tmin. Positive infinity is not rejected merely for being infinite; it must satisfy the same order test. Only OpRayQueryInitializeKHR before the first control-flow terminator in the single stage entry function is inspected, on the Vulkan path. Helper functions, later blocks, specialization constants and dynamic operands are skipped. File presence does not prove execution or device support; this is a static operand finding, not a captured validation error or measured performance cost.
- **Suggested action:** Supply nonnegative, non-NaN distances with Tmax at least Tmin, using the intended ray length and coordinate scale.
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/gpuav/shaders/instrumentation/trace_ray.comp

### `scene_validation.compute_push_constant_limit`

- **Title:** An imported shader stage exceeds this GPU's push-constant size
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `VUID-VkPushConstantRange-size-00298` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_compute_push_constant_limit", "value": 1}}`
- **Evidence and limits:** The maximum known push-constant member offset plus its fixed scalar/vector/matrix/array payload exceeds maxPushConstantsSize. Padding is omitted and nested structs or unknown sizes contribute nothing, so the byte count is a lower bound. Godot reflects the block and creates a push-constant range starting at zero. Read from the actual Vulkan device through RenderingDevice.LIMIT_MAX_PUSH_CONSTANT_SIZE. Descriptor totals span distinct set/binding pairs in each inspected stage, despite Godot's PER_UNIFORM_SET enum name. Fixed image/sampler arrays are counted; buffer arrays, buffer/subpass images and unresolved lengths are omitted. Unknown limits and non-Vulkan drivers are skipped. File presence does not prove execution, and this is not a captured validation message.
- **Suggested action:** Reduce the shader's declared resources or push-constant payload, or select a variant compatible with the target GPU. Update RDUniform bindings and push-constant callers together.
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/stateless/sl_pipeline.cpp

### `scene_validation.compute_samplers_limit`

- **Title:** An imported shader stage exceeds this GPU's sampler descriptor count
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `VUID-VkPipelineLayoutCreateInfo-descriptorType-03028; VUID-VkPipelineLayoutCreateInfo-descriptorType-03016` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_compute_samplers_limit", "value": 1}}`
- **Evidence and limits:** Separate and combined image-sampler declarations exceed a positive maxDescriptorSetSamplers or maxPerStageDescriptorSamplers limit. Read from the actual Vulkan device through RenderingDevice.LIMIT_MAX_SAMPLERS_PER_UNIFORM_SET and LIMIT_MAX_SAMPLERS_PER_SHADER_STAGE. Descriptor totals span distinct set/binding pairs in each inspected stage, despite Godot's PER_UNIFORM_SET enum name. Fixed image/sampler arrays are counted; buffer arrays, buffer/subpass images and unresolved lengths are omitted. Unknown limits and non-Vulkan drivers are skipped. File presence does not prove execution, and this is not a captured validation message.
- **Suggested action:** Reduce the shader's declared resources or push-constant payload, or select a variant compatible with the target GPU. Update RDUniform bindings and push-constant callers together.
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/core_checks/cc_descriptor.cpp

### `scene_validation.compute_sampled_images_limit`

- **Title:** An imported shader stage exceeds this GPU's sampled-image descriptor count
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `VUID-VkPipelineLayoutCreateInfo-descriptorType-03033; VUID-VkPipelineLayoutCreateInfo-descriptorType-06939` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_compute_sampled_images_limit", "value": 1}}`
- **Evidence and limits:** Sampled images, including combined image samplers, exceed a positive maxDescriptorSetSampledImages or maxPerStageDescriptorSampledImages limit. Read from the actual Vulkan device through RenderingDevice.LIMIT_MAX_TEXTURES_PER_UNIFORM_SET and LIMIT_MAX_TEXTURES_PER_SHADER_STAGE. Descriptor totals span distinct set/binding pairs in each inspected stage, despite Godot's PER_UNIFORM_SET enum name. Fixed image/sampler arrays are counted; buffer arrays, buffer/subpass images and unresolved lengths are omitted. Unknown limits and non-Vulkan drivers are skipped. File presence does not prove execution, and this is not a captured validation message.
- **Suggested action:** Reduce the shader's declared resources or push-constant payload, or select a variant compatible with the target GPU. Update RDUniform bindings and push-constant callers together.
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/core_checks/cc_descriptor.cpp

### `scene_validation.compute_storage_images_limit`

- **Title:** An imported shader stage exceeds this GPU's storage-image descriptor count
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `VUID-VkPipelineLayoutCreateInfo-descriptorType-03034; VUID-VkPipelineLayoutCreateInfo-descriptorType-03020` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_compute_storage_images_limit", "value": 1}}`
- **Evidence and limits:** Storage-image declarations exceed a positive maxDescriptorSetStorageImages or maxPerStageDescriptorStorageImages limit. Read from the actual Vulkan device through RenderingDevice.LIMIT_MAX_STORAGE_IMAGES_PER_UNIFORM_SET and LIMIT_MAX_STORAGE_IMAGES_PER_SHADER_STAGE. Descriptor totals span distinct set/binding pairs in each inspected stage, despite Godot's PER_UNIFORM_SET enum name. Fixed image/sampler arrays are counted; buffer arrays, buffer/subpass images and unresolved lengths are omitted. Unknown limits and non-Vulkan drivers are skipped. File presence does not prove execution, and this is not a captured validation message.
- **Suggested action:** Reduce the shader's declared resources or push-constant payload, or select a variant compatible with the target GPU. Update RDUniform bindings and push-constant callers together.
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/core_checks/cc_descriptor.cpp

### `scene_validation.compute_uniform_buffers_limit`

- **Title:** An imported shader stage exceeds this GPU's per-stage uniform-buffer descriptor count
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `VUID-VkPipelineLayoutCreateInfo-descriptorType-03017` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_compute_uniform_buffers_limit", "value": 1}}`
- **Evidence and limits:** Distinct non-array Uniform/Block buffer bindings exceed maxPerStageDescriptorUniformBuffers. This stage limit includes static and dynamic buffers; their separate pipeline-layout limits are not conflated. Read from the actual Vulkan device through RenderingDevice.LIMIT_MAX_UNIFORM_BUFFERS_PER_SHADER_STAGE. Descriptor totals span distinct set/binding pairs in each inspected stage, despite Godot's PER_UNIFORM_SET enum name. Fixed image/sampler arrays are counted; buffer arrays, buffer/subpass images and unresolved lengths are omitted. Unknown limits and non-Vulkan drivers are skipped. File presence does not prove execution, and this is not a captured validation message.
- **Suggested action:** Reduce the shader's declared resources or push-constant payload, or select a variant compatible with the target GPU. Update RDUniform bindings and push-constant callers together.
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/core_checks/cc_descriptor.cpp

### `scene_validation.compute_storage_buffers_limit`

- **Title:** An imported shader stage exceeds this GPU's per-stage storage-buffer descriptor count
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `VUID-VkPipelineLayoutCreateInfo-descriptorType-03018` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_compute_storage_buffers_limit", "value": 1}}`
- **Evidence and limits:** Distinct non-array StorageBuffer/Block or legacy Uniform/BufferBlock bindings exceed maxPerStageDescriptorStorageBuffers. This stage limit includes static and dynamic buffers. Read from the actual Vulkan device through RenderingDevice.LIMIT_MAX_STORAGE_BUFFERS_PER_SHADER_STAGE. Descriptor totals span distinct set/binding pairs in each inspected stage, despite Godot's PER_UNIFORM_SET enum name. Fixed image/sampler arrays are counted; buffer arrays, buffer/subpass images and unresolved lengths are omitted. Unknown limits and non-Vulkan drivers are skipped. File presence does not prove execution, and this is not a captured validation message.
- **Suggested action:** Reduce the shader's declared resources or push-constant payload, or select a variant compatible with the target GPU. Update RDUniform bindings and push-constant callers together.
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/core_checks/cc_descriptor.cpp

### `scene_validation.compute_bound_sets_limit`

- **Title:** An imported shader stage exceeds this GPU's descriptor-set layout count
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `VUID-VkPipelineLayoutCreateInfo-setLayoutCount-00286` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_compute_bound_sets_limit", "value": 1}}`
- **Evidence and limits:** The highest known resource descriptor-set index plus one exceeds maxBoundDescriptorSets. Godot sizes its reflected uniform-set vector to set+1, including gaps. Only recognized resource declarations with explicit set/binding decorations contribute; Godot may impose a stricter engine limit as well. Read from the actual Vulkan device through RenderingDevice.LIMIT_MAX_BOUND_UNIFORM_SETS. Descriptor totals span distinct set/binding pairs in each inspected stage, despite Godot's PER_UNIFORM_SET enum name. Fixed image/sampler arrays are counted; buffer arrays, buffer/subpass images and unresolved lengths are omitted. Unknown limits and non-Vulkan drivers are skipped. File presence does not prove execution, and this is not a captured validation message.
- **Suggested action:** Reduce the shader's declared resources or push-constant payload, or select a variant compatible with the target GPU. Update RDUniform bindings and push-constant callers together.
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/stateless/sl_pipeline.cpp

### `scene_validation.compute_uniform_buffer_size_limit`

- **Title:** An imported shader stage exceeds this GPU's uniform-buffer range
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `VUID-VkWriteDescriptorSet-descriptorType-00332` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_compute_uniform_buffer_size_limit", "value": 1}}`
- **Evidence and limits:** A known Uniform/Block member offset plus fixed payload exceeds maxUniformBufferRange. Godot requires a supplied uniform buffer at least as large as the reflected block; the native descriptor range uses the buffer size. Padding and unsupported members are omitted, giving a lower bound on the required range, not an observation of a runtime descriptor write. Read from the actual Vulkan device through RenderingDevice.LIMIT_MAX_UNIFORM_BUFFER_SIZE. Descriptor totals span distinct set/binding pairs in each inspected stage, despite Godot's PER_UNIFORM_SET enum name. Fixed image/sampler arrays are counted; buffer arrays, buffer/subpass images and unresolved lengths are omitted. Unknown limits and non-Vulkan drivers are skipped. File presence does not prove execution, and this is not a captured validation message.
- **Suggested action:** Reduce the shader's declared resources or push-constant payload, or select a variant compatible with the target GPU. Update RDUniform bindings and push-constant callers together.
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/core_checks/cc_descriptor.cpp

### `scene_validation.compute_buffer_device_address`

- **Title:** An imported shader stage requires unsupported buffer device addresses
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `VUID-VkShaderModuleCreateInfo-pCode-08740` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_compute_buffer_device_address", "value": 1}}`
- **Evidence and limits:** Imported stage SPIR-V declares OpCapability PhysicalStorageBufferAddresses, but the current Vulkan RenderingDevice explicitly reports the corresponding Godot feature unsupported. Unknown feature support is skipped; Godot 4.4 has no public ray-query query. This is a device compatibility check, not a captured layer message or proof that the shader is executed.
- **Suggested action:** Select a shader variant supported by the target GPU and engine, or keep this shader restricted to devices reporting the required feature.
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/vulkan/generated/spirv_validation_helper.cpp

### `scene_validation.compute_ray_query`

- **Title:** An imported shader stage requires unsupported ray queries
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.7
- **Upstream idea:** `VUID-VkShaderModuleCreateInfo-pCode-08740` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_compute_ray_query", "value": 1}}`
- **Evidence and limits:** Imported stage SPIR-V declares OpCapability RayQueryKHR, but the current Vulkan RenderingDevice explicitly reports the corresponding Godot feature unsupported. Unknown feature support is skipped; Godot 4.4 has no public ray-query query. This is a device compatibility check, not a captured layer message or proof that the shader is executed.
- **Suggested action:** Select a shader variant supported by the target GPU and engine, or keep this shader restricted to devices reporting the required feature.
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/vulkan/generated/spirv_validation_helper.cpp

### `scene_validation.compute_raytracing_pipeline`

- **Title:** An imported shader stage requires unsupported ray tracing pipelines
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.7
- **Upstream idea:** `VUID-VkShaderModuleCreateInfo-pCode-08740` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_compute_raytracing_pipeline", "value": 1}}`
- **Evidence and limits:** Imported stage SPIR-V declares OpCapability RayTracingKHR, but the current Vulkan RenderingDevice explicitly reports the corresponding Godot feature unsupported. Unknown feature support is skipped; Godot 4.4 has no public ray-tracing pipeline support query. This is a device compatibility check, not a captured layer message or proof that the shader is executed.
- **Suggested action:** Select a shader variant supported by the target GPU and engine, or keep this shader restricted to devices reporting the required feature.
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/vulkan/generated/spirv_validation_helper.cpp

### `scene_validation.compute_invocation_limit`

- **Title:** An imported compute shader exceeds this GPU's invocation limit
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `VUID-RuntimeSpirv-x-06432` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_compute_invocation_limit", "value": 1}}`
- **Evidence and limits:** The fixed local_size x*y*z exceeds RenderingDevice.LIMIT_MAX_COMPUTE_WORKGROUP_INVOCATIONS on the current rendering device. Only imported compute entry points are inspected; specialization-dependent sizes and unavailable device limits are skipped. File presence does not prove dispatch, and these are not captured validation messages.
- **Suggested action:** Choose a compatible workgroup size and adjust dispatch group counts and shader bounds checks together; test on each target GPU.
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/core_checks/cc_spirv.cpp

### `scene_validation.compute_dimension_limit`

- **Title:** An imported compute shader exceeds this GPU's workgroup dimensions
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `VUID-RuntimeSpirv-x-06429; VUID-RuntimeSpirv-y-06430; VUID-RuntimeSpirv-z-06431` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_compute_dimension_limit", "value": 1}}`
- **Evidence and limits:** At least one fixed local_size dimension exceeds its corresponding RenderingDevice.LIMIT_MAX_COMPUTE_WORKGROUP_SIZE_X/Y/Z limit on the current rendering device. Only imported compute entry points are inspected; specialization-dependent sizes and unavailable device limits are skipped. File presence does not prove dispatch, and these are not captured validation messages.
- **Suggested action:** Choose a compatible workgroup size and adjust dispatch group counts and shader bounds checks together; test on each target GPU.
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/core_checks/cc_spirv.cpp

### `scene_validation.compute_shared_memory_limit`

- **Title:** An imported compute shader exceeds this GPU's shared-memory limit
- **Severity:** high
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.5, 4.6, 4.7
- **Upstream idea:** `VUID-RuntimeSpirv-Workgroup-06530` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_compute_shared_memory_limit", "value": 1}}`
- **Evidence and limits:** On the Vulkan path from Godot 4.5, a conservative byte-size lower bound for fixed Workgroup variables exceeds RenderingDevice.LIMIT_MAX_COMPUTE_SHARED_MEMORY_SIZE. Godot 4.4 exposes the enum but has no Vulkan getter implementation (4.5 added it), so 4.4 and other drivers are skipped. Scalar/vector/matrix/fixed-array declarations are supported; structs, explicit layouts, aliasing and unresolved array lengths are skipped. Padding can increase the actual requirement. Counts saturate at one GiB to prevent overflow. Only imported compute entry points are inspected; specialization-dependent sizes and unavailable device limits are skipped. File presence does not prove dispatch, and these are not captured validation messages.
- **Suggested action:** Reduce or restructure the fixed shared-memory arrays, or select a shader variant compatible with the target device. Review barriers and indexing together.
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/core_checks/cc_spirv.cpp

### `scene_validation.shader_compile_error`

- **Title:** An imported RenderingDevice shader records a compilation error
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_shader_compile_error", "value": 1}}`
- **Evidence and limits:** The imported RDShaderFile base error or an RDShaderSPIRV stage error is nonempty. Unimported files are reported as unavailable scan coverage, not as successful shaders. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Inspect the shader's import errors in Godot, fix the source and reimport.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/RDShaderFile.xml

### `scene_validation.gpu_process_missing`

- **Title:** GPU particles have no process material
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_gpu_process_missing", "value": 1}}`
- **Evidence and limits:** A GPUParticles2D or GPUParticles3D has no process material. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Assign a process material if particle simulation is intended.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/gpu_particles_3d.cpp

### `scene_validation.gpu_mesh_missing`

- **Title:** 3D GPU particles have no draw mesh
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_gpu_mesh_missing", "value": 1}}`
- **Evidence and limits:** None of the configured draw passes has a mesh. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Assign a mesh to an active draw pass.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/gpu_particles_3d.cpp

### `scene_validation.cpu_mesh_missing`

- **Title:** 3D CPU particles have no mesh
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_cpu_mesh_missing", "value": 1}}`
- **Evidence and limits:** The CPUParticles3D mesh is absent. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Assign a particle mesh if visible particles are intended.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/cpu_particles_3d.cpp

### `scene_validation.particles_animation_2d`

- **Title:** 2D particle animation lacks an enabled animation material
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_particles_animation_2d", "value": 1}}`
- **Evidence and limits:** GPU ParticleProcessMaterial or CPUParticles2D has animation speed/offset or curves, but the drawing material is absent or CanvasItemMaterial.particles_anim is off. Custom shaders are excluded. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Enable particle animation on a CanvasItemMaterial and configure its frame grid.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/2d/gpu_particles_2d.cpp

### `scene_validation.particles_animation_3d`

- **Title:** 3D particle animation lacks a particle billboard material
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_particles_animation_3d", "value": 1}}`
- **Evidence and limits:** GPU or CPU 3D particle animation is configured, but no effective draw material supports particle billboards. Custom ShaderMaterials are treated as unknown and excluded. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Set the intended BaseMaterial3D billboard mode to Particle Billboard and configure the frame grid.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/gpu_particles_3d.cpp

### `scene_validation.trails_skin`

- **Title:** Particle Skin overrides built-in trail poses
- **Severity:** medium
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_trails_skin", "value": 1}}`
- **Evidence and limits:** Trails use both a trail mesh and a Skin. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Remove the Skin if the built-in trail poses were intended, or confirm the override is deliberate.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/gpu_particles_3d.cpp

### `scene_validation.trails_no_pose`

- **Title:** Particle trails lack a trail mesh or Skin
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_trails_no_pose", "value": 1}}`
- **Evidence and limits:** Trails are enabled with neither built-in trail poses nor a Skin. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use RibbonTrailMesh/TubeTrailMesh or supply an appropriate Skin.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/gpu_particles_3d.cpp

### `scene_validation.trails_multiple`

- **Title:** Multiple built-in trail meshes lack a Skin
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_trails_multiple", "value": 1}}`
- **Evidence and limits:** More than one draw pass has built-in trail poses and no Skin is assigned. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use a single trail mesh, or provide a Skin for the multiple-mesh arrangement.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/gpu_particles_3d.cpp

### `scene_validation.trails_material`

- **Title:** Particle trail material is missing or not trail-enabled
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_trails_material", "value": 1}}`
- **Evidence and limits:** Trail poses exist, but an effective surface material is absent or a BaseMaterial3D has particle trails disabled. Overridden surface materials and custom shaders are excluded. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Enable particle trails on the effective BaseMaterial3D, or assign a suitable material.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/gpu_particles_3d.cpp

### `scene_validation.trails_renderer`

- **Title:** Particle trails are unsupported in Compatibility
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_trails_renderer", "value": 1}}`
- **Evidence and limits:** 2D or 3D GPU particle trails are enabled under Compatibility. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use Forward+ or Mobile, or provide a separate trail effect.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/gpu_particles_3d.cpp

### `scene_validation.subemitter_renderer`

- **Title:** Particle sub-emitters are unsupported in Compatibility
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_subemitter_renderer", "value": 1}}`
- **Evidence and limits:** A GPU particle sub-emitter path is set under Compatibility. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use Forward+ or Mobile, or spawn the secondary effect through game logic.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/gpu_particles_3d.cpp

### `scene_validation.decal_textures`

- **Title:** A decal has no textures
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_decal_textures", "value": 1}}`
- **Evidence and limits:** All four decal texture slots are empty. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Assign a texture to the intended decal channel.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/decal.cpp

### `scene_validation.decal_albedo`

- **Title:** A normal/ORM decal lacks its albedo blend mask
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_decal_albedo", "value": 1}}`
- **Evidence and limits:** A normal or ORM texture is assigned without an albedo texture. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Assign an albedo texture with alpha; set Albedo Mix to zero if its color should remain invisible.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/decal.cpp

### `scene_validation.decal_mask`

- **Title:** A decal cannot affect any visual layer
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_decal_mask", "value": 1}}`
- **Evidence and limits:** The decal cull mask is zero. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Enable the target objects' visual layers in the decal cull mask.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/decal.cpp

### `scene_validation.light_scale`

- **Title:** Scaling a light does not resize its illumination
- **Severity:** medium
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_light_scale", "value": 1}}`
- **Evidence and limits:** A Light3D has a non-unit local scale. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Adjust the light's range or size properties if illumination size should change.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/light_3d.cpp

### `scene_validation.projector_shadows`

- **Title:** A light projector needs shadows enabled
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_projector_shadows", "value": 1}}`
- **Evidence and limits:** An OmniLight3D or SpotLight3D has a projector texture with shadows disabled. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Enable shadows if the projector is needed; measure the added shadow cost.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/light_3d.cpp

### `scene_validation.projector_renderer`

- **Title:** Light projectors are unsupported in Compatibility
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_projector_renderer", "value": 1}}`
- **Evidence and limits:** An OmniLight3D or SpotLight3D has a projector texture under Compatibility. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use Forward+ or Mobile, or replace the projection effect.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/light_3d.cpp

### `scene_validation.spot_shadows`

- **Title:** A spotlight at 90 degrees cannot cast shadows
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_spot_shadows", "value": 1}}`
- **Evidence and limits:** Shadows are enabled with a spot angle of at least 90 degrees; the engine's predicate includes exactly 90. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Reduce the angle below 90 degrees if shadows are required.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/light_3d.cpp

### `scene_validation.area_projector`

- **Title:** Area lights do not use the projector slot
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_area_projector", "value": 1}}`
- **Evidence and limits:** An AreaLight3D has a light_projector texture. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Move the intended texture to area_texture.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/scene/3d/light_3d.cpp

### `scene_validation.area_texture`

- **Title:** Textured area lights are unsupported in Compatibility
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** gl_compatibility
- **Godot versions:** 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_area_texture", "value": 1}}`
- **Evidence and limits:** An AreaLight3D has area_texture under Compatibility. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use Forward+ or Mobile, or use an untextured light.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/scene/3d/light_3d.cpp

### `scene_validation.area_shadows`

- **Title:** Area-light shadows are unsupported in Compatibility
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** gl_compatibility
- **Godot versions:** 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_area_shadows", "value": 1}}`
- **Evidence and limits:** An AreaLight3D enables shadows under Compatibility. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use a supported renderer or a different shadow-casting light.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/scene/3d/light_3d.cpp

### `scene_validation.fog_renderer`

- **Title:** FogVolume needs Forward+
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_fog_renderer", "value": 1}}`
- **Evidence and limits:** A FogVolume is present under Mobile or Compatibility. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use Forward+ for volumetric fog, or use ordinary depth/height fog.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/fog_volume.cpp

### `scene_validation.fog_environment`

- **Title:** FogVolume has volumetric fog disabled in its world
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_fog_environment", "value": 1}}`
- **Evidence and limits:** A live FogVolume's effective camera/world Environment has volumetric fog disabled. Camera overrides and fallback environments are respected; detached scenes and absent environments are skipped. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Enable volumetric fog in the effective Environment if the volume is needed, then measure its cost.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/fog_volume.cpp

### `scene_validation.voxel_renderer`

- **Title:** VoxelGI is unsupported by this renderer
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_voxel_renderer", "value": 1}}`
- **Evidence and limits:** A VoxelGI node is present under Mobile or Compatibility. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use Forward+ or choose a GI solution supported by the target renderer.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/VoxelGI.xml

### `scene_validation.occluder_missing`

- **Title:** An occluder has no occluder resource
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_occluder_missing", "value": 1}}`
- **Evidence and limits:** OccluderInstance3D.occluder is absent. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Bake occluders or assign a suitable primitive occluder.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/occluder_instance_3d.cpp

### `scene_validation.occluder_empty`

- **Title:** An occluder has insufficient geometry
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_occluder_empty", "value": 1}}`
- **Evidence and limits:** An ArrayOccluder3D has fewer than three indices, or a PolygonOccluder3D has fewer than three points. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Bake valid occluder geometry or supply a valid polygon.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/occluder_instance_3d.cpp

### `scene_validation.occluder_bake_mask`

- **Title:** An occluder's bake mask selects no layers
- **Severity:** medium
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_occluder_bake_mask", "value": 1}}`
- **Evidence and limits:** The bake mask is zero. An already assigned occluder can still work; this only concerns a future bake. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Select layers before baking if automatic occluder generation is intended.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/occluder_instance_3d.cpp

### `scene_validation.collision_parent`

- **Title:** A collision shape has the wrong direct parent
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_collision_parent", "value": 1}}`
- **Evidence and limits:** A CollisionShape2D/3D is not directly beneath a CollisionObject of the matching dimension. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Parent the shape directly beneath the intended Area or physics body.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/physics/collision_shape_3d.cpp

### `scene_validation.collision_resource`

- **Title:** A collision shape has no Shape resource
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_collision_resource", "value": 1}}`
- **Evidence and limits:** CollisionShape2D/3D.shape is absent. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Assign the intended Shape resource.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/physics/collision_shape_3d.cpp

### `scene_validation.collision_polygon_parent`

- **Title:** A collision polygon has the wrong direct parent
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_collision_polygon_parent", "value": 1}}`
- **Evidence and limits:** A CollisionPolygon2D/3D is not directly beneath a CollisionObject of the matching dimension. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Parent the polygon directly beneath the intended Area or physics body.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/2d/physics/collision_polygon_2d.cpp

### `scene_validation.collision_polygon_empty`

- **Title:** A collision polygon has no points
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_collision_polygon_empty", "value": 1}}`
- **Evidence and limits:** A CollisionPolygon2D/3D has an empty polygon. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Define the collision outline.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/2d/physics/collision_polygon_2d.cpp

### `scene_validation.collision_polygon_points`

- **Title:** A 2D collision polygon has too few points
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_collision_polygon_points", "value": 1}}`
- **Evidence and limits:** A nonempty polygon has fewer than three points in Solids mode, or fewer than two in Segments mode. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Add enough points for the selected build mode.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/2d/physics/collision_polygon_2d.cpp

### `scene_validation.one_way_area`

- **Title:** Area2D ignores one-way collision
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_one_way_area", "value": 1}}`
- **Evidence and limits:** A CollisionShape2D or CollisionPolygon2D under Area2D enables one-way collision. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use a physics body for one-way blocking, or handle directional detection in game logic.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/2d/physics/collision_shape_2d.cpp

### `scene_validation.collision_nonuniform`

- **Title:** A 3D collision node has nonuniform scale
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_collision_nonuniform", "value": 1}}`
- **Evidence and limits:** A CollisionObject3D, CollisionShape3D or CollisionPolygon3D has unequal local scale axes, using Godot's approximate-zero comparison. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Keep scale uniform and resize the shape resource or polygon vertices instead.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/physics/collision_shape_3d.cpp

### `scene_validation.rigid_scale`

- **Title:** Physics can override a rigid body's scale
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_rigid_scale", "value": 1}}`
- **Evidence and limits:** A RigidBody2D/3D local scale differs from unit scale by more than the engine's 0.05 tolerance. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Keep the body scale at one and resize its child shapes and visuals.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/physics/rigid_body_3d.cpp

### `scene_validation.concave_dynamic`

- **Title:** A moving 3D body uses a concave collision shape
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_concave_dynamic", "value": 1}}`
- **Evidence and limits:** A concave shape belongs to CharacterBody3D or a RigidBody3D that is not frozen in static mode. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use convex shapes or convex decomposition for moving bodies; keep concave geometry on static bodies.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/physics/collision_shape_3d.cpp

### `scene_validation.boundary_dynamic`

- **Title:** A moving rigid body uses an infinite world-boundary shape
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_boundary_dynamic", "value": 1}}`
- **Evidence and limits:** WorldBoundaryShape3D belongs to a RigidBody3D not frozen in static mode. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Keep the world boundary on a static body and use a finite shape for moving objects.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/physics/collision_shape_3d.cpp

### `scene_validation.mesh_missing`

- **Title:** A mesh instance has no mesh resource
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_mesh_missing", "value": 1}}`
- **Evidence and limits:** The MeshInstance2D/3D mesh resource is absent. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Assign a mesh if this node should render geometry.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/MeshInstance3D.xml

### `scene_validation.worldenv_empty`

- **Title:** A WorldEnvironment has no resources
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_worldenv_empty", "value": 1}}`
- **Evidence and limits:** Environment, camera attributes and compositor are all absent. Compositor-only nodes are deliberately excluded. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Assign the intended resource or remove the unused node.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/world_environment.cpp

### `scene_validation.worldenv_conflict`

- **Title:** A WorldEnvironment resource is overridden in its world
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_worldenv_conflict", "value": 1}}`
- **Evidence and limits:** In a live tree, an assigned Environment, camera attributes or compositor differs from the resource selected by that node's viewport world. Detached scenes are skipped. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Keep one intended provider per world; use separate viewport worlds where separate environments are needed.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/world_environment.cpp

### `scene_validation.visibility_range_invalid`

- **Title:** A visibility range cannot display its geometry
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_visibility_range_invalid", "value": 1}}`
- **Evidence and limits:** The nonzero visibility range end is less than or equal to its begin. An end of zero disables the upper limit and is excluded. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Set the end beyond the begin, or set end to zero to remove the upper limit.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/visual_instance_3d.cpp

### `scene_validation.visibility_fade_begin`

- **Title:** A visibility fade has no begin transition margin
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_visibility_fade_begin", "value": 1}}`
- **Evidence and limits:** Visibility fading is enabled, the begin distance is nonzero and its margin is approximately zero. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Give the begin margin a positive width if a smooth transition is intended.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/visual_instance_3d.cpp

### `scene_validation.visibility_fade_end`

- **Title:** A visibility fade has no end transition margin
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_visibility_fade_end", "value": 1}}`
- **Evidence and limits:** Visibility fading is enabled, the end distance is nonzero and its margin is approximately zero. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Give the end margin a positive width if a smooth transition is intended.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/visual_instance_3d.cpp

### `scene_validation.geometry_transparency`

- **Title:** Geometry-instance transparency needs Forward+
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_geometry_transparency", "value": 1}}`
- **Evidence and limits:** GeometryInstance3D.transparency is greater than zero under Mobile or Compatibility. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use a material transparency mode supported by the renderer, or select Forward+.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/visual_instance_3d.cpp

### `scene_validation.geometry_fade`

- **Title:** Visibility-range fading needs Forward+
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_geometry_fade", "value": 1}}`
- **Evidence and limits:** A GeometryInstance3D enables Self or Dependencies visibility fading under an unsupported renderer. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use disabled fading with hysteresis, or select Forward+.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/visual_instance_3d.cpp

### `scene_validation.point_light_texture`

- **Title:** A PointLight2D has no light texture
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_point_light_texture", "value": 1}}`
- **Evidence and limits:** PointLight2D.texture is absent. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Assign a light texture if this light should illuminate the canvas.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/2d/light_2d.cpp

### `scene_validation.light_occluder_missing`

- **Title:** A 2D light occluder has no polygon resource
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_light_occluder_missing", "value": 1}}`
- **Evidence and limits:** LightOccluder2D.occluder is absent. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Create an occluder polygon that follows the intended shadow-casting outline.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/2d/light_occluder_2d.cpp

### `scene_validation.light_occluder_empty`

- **Title:** A 2D light occluder has an empty polygon
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_light_occluder_empty", "value": 1}}`
- **Evidence and limits:** An assigned OccluderPolygon2D contains no points. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Create an occluder polygon that follows the intended shadow-casting outline.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/2d/light_occluder_2d.cpp

### `scene_validation.particle_sdf_bake_mask`

- **Title:** A particle SDF bake mask selects no geometry
- **Severity:** medium
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_particle_sdf_bake_mask", "value": 1}}`
- **Evidence and limits:** GPUParticlesCollisionSDF3D.bake_mask is zero. This concerns the next bake, not whether an existing texture works. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Select the visual layers to include before baking the collision SDF.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/gpu_particles_collision_3d.cpp

### `scene_validation.particle_sdf_texture`

- **Title:** A particle SDF collider has no baked field texture
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_particle_sdf_texture", "value": 1}}`
- **Evidence and limits:** GPUParticlesCollisionSDF3D.texture is absent; the node has no assigned signed-distance field. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Bake the collider or assign the intended Texture3D before relying on SDF collisions.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/GPUParticlesCollisionSDF3D.xml

### `scene_validation.particle_collision_scale`

- **Title:** A particle collider has unsupported nonuniform world scale
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_particle_collision_scale", "value": 1}}`
- **Evidence and limits:** The absolute world scale of a live GPUParticlesCollision3D differs between axes. Detached nodes are skipped; a compensating parent scale is respected. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use uniform world scale and edit the collider's size or radius instead.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/GPUParticlesCollision3D.xml

### `scene_validation.viewport_container_child`

- **Title:** A SubViewportContainer has no direct SubViewport child
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_viewport_container_child", "value": 1}}`
- **Evidence and limits:** None of the container's direct children is a SubViewport. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Add the intended SubViewport as a direct child.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/gui/subviewport_container.cpp

### `scene_validation.viewport_ssr_transparent`

- **Title:** A transparent SubViewport cannot use SSR
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_viewport_ssr_transparent", "value": 1}}`
- **Evidence and limits:** A live SubViewport has transparent_bg enabled and SSR enabled in its effective camera/world Environment. Detached scenes are excluded. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use an opaque viewport background if SSR is required, or use reflection probes for this view.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/doc/classes/Environment.xml

### `scene_validation.sprite_frames_missing`

- **Title:** An animated sprite has no SpriteFrames resource
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_sprite_frames_missing", "value": 1}}`
- **Evidence and limits:** An AnimatedSprite2D or AnimatedSprite3D has no SpriteFrames resource. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Assign the animation's SpriteFrames resource.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/2d/animated_sprite_2d.cpp

### `scene_validation.path_follow_parent`

- **Title:** A PathFollow node is outside its matching Path
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_path_follow_parent", "value": 1}}`
- **Evidence and limits:** PathFollow2D does not have a direct Path2D parent, or PathFollow3D does not have a direct Path3D parent. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Make the matching Path node the direct parent before using its curve.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/path_3d.cpp

### `scene_validation.path_follow_up_vector`

- **Title:** Oriented path following needs curve up vectors
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_path_follow_up_vector", "value": 1}}`
- **Evidence and limits:** A PathFollow3D uses ROTATION_ORIENTED but its parent Path3D's assigned Curve3D has up_vector_enabled disabled. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Enable up vectors on the curve, or use a rotation mode that does not require them.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/path_3d.cpp

### `scene_validation.remote_transform_target`

- **Title:** A RemoteTransform cannot use its target
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_remote_transform_target", "value": 1}}`
- **Evidence and limits:** A live RemoteTransform2D/3D cannot resolve its remote_path to a matching Node2D/3D, or targets itself, an ancestor or a descendant. Godot's cache rejects those hierarchy relationships. Detached scenes are skipped. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Point remote_path at a node of the matching dimension outside the remote transform's own ancestor/descendant chain.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/remote_transform_3d.cpp

### `scene_validation.navigation_agent_parent`

- **Title:** A navigation agent has the wrong parent dimension
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_navigation_agent_parent", "value": 1}}`
- **Evidence and limits:** NavigationAgent2D requires a Node2D-derived direct parent; NavigationAgent3D requires a Node3D-derived direct parent. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Place the agent directly under the matching moving Node2D/Node3D.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/navigation_agent_3d.cpp

### `scene_validation.navigation_region_missing`

- **Title:** An enabled navigation region has no navigation resource
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_navigation_region_missing", "value": 1}}`
- **Evidence and limits:** An enabled NavigationRegion3D has no NavigationMesh, or an enabled NavigationRegion2D has no NavigationPolygon. Disabled regions are excluded. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Assign and bake the intended navigation resource, or disable this region until it is ready.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/navigation_region_3d.cpp

### `scene_validation.navigation_obstacle_rotation`

- **Title:** A navigation obstacle ignores its world X/Z rotation
- **Severity:** medium
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_navigation_obstacle_rotation", "value": 1}}`
- **Evidence and limits:** A live NavigationObstacle3D has nonzero world X or Z rotation; navigation uses its Y rotation only. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Keep the obstacle upright, or author vertices matching its intended horizontal footprint.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/navigation_obstacle_3d.cpp

### `scene_validation.navigation_obstacle_scale`

- **Title:** A navigation obstacle has unsupported world scale
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_navigation_obstacle_scale", "value": 1}}`
- **Evidence and limits:** A live NavigationObstacle2D/3D has a world scale component below 0.001, using the engine warning's threshold. Negative and zero components are included. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use positive world scale on the obstacle and its parents; resize its radius or vertices as needed.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/navigation_obstacle_3d.cpp

### `scene_validation.navigation_obstacle_nonuniform`

- **Title:** A navigation obstacle's radius cannot follow its nonuniform transform
- **Severity:** medium
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_navigation_obstacle_nonuniform", "value": 1}}`
- **Evidence and limits:** A live obstacle has positive radius and a nonconformal world transform. Godot scales the radius using the largest axis instead. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use uniform scaling for the radius or author a vertex-based obstacle for the intended outline.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/navigation_obstacle_3d.cpp

### `scene_validation.navigation_obstacle_skew`

- **Title:** A navigation obstacle's radius ignores world skew
- **Severity:** medium
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_navigation_obstacle_skew", "value": 1}}`
- **Evidence and limits:** A live NavigationObstacle2D has positive radius and nonzero world skew. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use vertices for a skewed outline or remove skew when relying on the radius.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/2d/navigation_obstacle_2d.cpp

### `scene_validation.bone_attachment_parent`

- **Title:** A bone attachment has no parent Skeleton3D
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_bone_attachment_parent", "value": 1}}`
- **Evidence and limits:** BoneAttachment3D does not use an external skeleton and its direct parent is not Skeleton3D. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Parent the attachment to Skeleton3D or configure its external skeleton.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/bone_attachment_3d.cpp

### `scene_validation.bone_attachment_external`

- **Title:** A bone attachment cannot resolve its external skeleton
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_bone_attachment_external", "value": 1}}`
- **Evidence and limits:** A live BoneAttachment3D enables an external skeleton, but the configured path does not resolve to Skeleton3D. Detached paths are skipped. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Set the external skeleton path to the intended Skeleton3D.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/bone_attachment_3d.cpp

### `scene_validation.bone_attachment_bone`

- **Title:** A bone attachment has no selected bone
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_bone_attachment_bone", "value": 1}}`
- **Evidence and limits:** BoneAttachment3D.bone_idx is negative. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Select a bone from the resolved skeleton.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/bone_attachment_3d.cpp

### `scene_validation.bone2d_hierarchy`

- **Title:** A Bone2D chain does not end at a Skeleton2D
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_bone2d_hierarchy", "value": 1}}`
- **Evidence and limits:** Following direct Bone2D parents reaches a node that is not Skeleton2D, or reaches no parent. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Place each Bone2D directly under Skeleton2D or another Bone2D in that skeleton's chain.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/2d/skeleton_2d.cpp

### `scene_validation.bone2d_rest`

- **Title:** A Bone2D has no rest pose
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_bone2d_rest", "value": 1}}`
- **Evidence and limits:** Bone2D.rest is the all-zero transform used by Godot to mark an unset rest pose. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Set the intended rest pose using the Skeleton2D tools before animating the rig.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/2d/skeleton_2d.cpp

### `scene_validation.animation_tree_root`

- **Title:** An AnimationTree has no root graph
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_animation_tree_root", "value": 1}}`
- **Evidence and limits:** AnimationTree.tree_root is absent. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Assign the intended AnimationNode graph.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/animation/animation_tree.cpp

### `scene_validation.animation_mixer_root`

- **Title:** An active animation mixer cannot resolve its root node
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_animation_mixer_root", "value": 1}}`
- **Evidence and limits:** A live, active AnimationMixer (including AnimationPlayer/AnimationTree) cannot resolve root_node. Detached and inactive mixers are excluded. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Point root_node at the node from which the animation's track paths should resolve.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/animation/animation_mixer.cpp

### `scene_validation.canvas_group_clip`

- **Title:** A CanvasGroup child also requests child clipping
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_canvas_group_clip", "value": 1}}`
- **Evidence and limits:** A clipping CanvasItem has CanvasGroup in its actual CanvasItem parent chain. Godot documents that both features use the backbuffer and conflict. Top-level items, CanvasLayer, Viewport and non-CanvasItem hierarchy breaks are respected. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Move clipping outside the CanvasGroup or restructure the group to avoid competing backbuffer operations.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/CanvasGroup.xml

### `scene_validation.shape_cast_resource`

- **Title:** A ShapeCast has no shape resource
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_shape_cast_resource", "value": 1}}`
- **Evidence and limits:** ShapeCast2D.shape or ShapeCast3D.shape is absent. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Assign the convex shape that the query should sweep.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/physics/shape_cast_3d.cpp

### `scene_validation.shape_cast_concave`

- **Title:** A ShapeCast3D uses an unsupported concave shape
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_shape_cast_concave", "value": 1}}`
- **Evidence and limits:** ShapeCast3D.shape is ConcavePolygonShape3D; Godot explicitly warns that collisions will not be reported. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use a convex shape for the sweep, or split the query into several convex sweeps.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/physics/shape_cast_3d.cpp

### `scene_validation.vehicle_wheel_parent`

- **Title:** A vehicle wheel is outside a VehicleBody3D
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_vehicle_wheel_parent", "value": 1}}`
- **Evidence and limits:** VehicleWheel3D does not have a direct VehicleBody3D parent. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Parent the wheel directly to its VehicleBody3D.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/physics/vehicle_body_3d.cpp

### `scene_validation.joint_targets`

- **Title:** A physics joint has invalid body connections
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_joint_targets", "value": 1}}`
- **Evidence and limits:** A live joint resolves a non-body node, connects a body to itself, or lacks the required bodies. Joint2D needs two PhysicsBody2D nodes; Joint3D permits one PhysicsBody3D connected to the world. Detached paths are skipped. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Connect distinct bodies with the matching dimension. For a 3D world anchor, keep one body assigned and leave the other endpoint empty.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/physics/joints/joint_3d.cpp

### `scene_validation.lightmap_shadowmask`

- **Title:** Lightmap shadowmasking lacks a baked shadowmask atlas
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_lightmap_shadowmask", "value": 1}}`
- **Evidence and limits:** LightmapGI requests a non-None shadowmask mode, has LightmapGIData assigned, but its stored shadowmask_textures array is empty. The separate missing-lightmap rule covers absent light_data. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Rebake with shadowmasking enabled if directional shadows beyond the realtime shadow distance are required.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/lightmap_gi.cpp

### `scene_validation.camera_cull_mask`

- **Title:** A camera selects no geometry visibility layers
- **Severity:** medium
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_camera_cull_mask", "value": 1}}`
- **Evidence and limits:** Camera3D.cull_mask is exactly zero, including all internal layers. This does not disable the sky, canvas UI or GI contributions. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Enable the intended visibility layers if this camera should draw 3D geometry.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/Camera3D.xml

### `scene_validation.geometry_layers`

- **Title:** Geometry belongs to no camera visibility layer
- **Severity:** medium
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_geometry_layers", "value": 1}}`
- **Evidence and limits:** GeometryInstance3D.layers is exactly zero. GI participation is separate and is not inferred from this mask. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Assign the intended visibility layers if cameras should draw this geometry.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/VisualInstance3D.xml

### `scene_validation.light_cull_mask`

- **Title:** A 3D light selects no object layers
- **Severity:** medium
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_light_cull_mask", "value": 1}}`
- **Evidence and limits:** Light3D.light_cull_mask is zero. The check concerns the object-layer selection, not whether the light contributes to baked or global illumination. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Select the object layers that should receive the light.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/Light3D.xml

### `scene_validation.navigation_layers`

- **Title:** Navigation selects no pathfinding layers
- **Severity:** medium
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_navigation_layers", "value": 1}}`
- **Evidence and limits:** A navigation agent, or an enabled region/link, has navigation_layers set to zero. Disabled regions and links are excluded. Avoidance layers are independent. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Select matching navigation layers for agents and regions/links if pathfinding should use them.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/NavigationAgent3D.xml

### `scene_validation.particle_collider_mask`

- **Title:** A particle collider selects no particle layers
- **Severity:** medium
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_particle_collider_mask", "value": 1}}`
- **Evidence and limits:** GPUParticlesCollision3D.cull_mask is zero. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Select the rendering layers of the GPU particles that should collide with this shape.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/GPUParticlesCollision3D.xml

### `scene_validation.particle_attractor_mask`

- **Title:** A particle attractor selects no particle layers
- **Severity:** medium
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_particle_attractor_mask", "value": 1}}`
- **Evidence and limits:** GPUParticlesAttractor3D.cull_mask is zero. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Select the rendering layers of the GPU particles this attractor should affect.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/GPUParticlesAttractor3D.xml

### `scene_validation.particle_vector_texture`

- **Title:** A particle vector-field attractor has no field texture
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_particle_vector_texture", "value": 1}}`
- **Evidence and limits:** GPUParticlesAttractorVectorField3D.texture is absent; no authored vector field is assigned. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Assign the intended Texture3D, such as NoiseTexture3D, before relying on this field.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/gpu_particles_collision_3d.cpp

### `scene_validation.range_exp_min`

- **Title:** An exponential UI range has an invalid minimum
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_range_exp_min", "value": 1}}`
- **Evidence and limits:** Range.exp_edit is enabled with min_value <= 0 in Godot 4.4, or min_value < 0 in Godot 4.7. The inspector uses the running engine's version; 4.7 permits exactly zero. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use a positive minimum on 4.4, or a nonnegative minimum on 4.7; alternatively use a linear range.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/gui/range.cpp

### `scene_validation.tooltip_mouse_filter`

- **Title:** A Control tooltip is suppressed by its mouse filter
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_tooltip_mouse_filter", "value": 1}}`
- **Evidence and limits:** Control.tooltip_text is nonempty while mouse_filter is MOUSE_FILTER_IGNORE. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use Stop or Pass if this control should receive pointer input and show its tooltip; check input propagation after changing the filter.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/gui/control.cpp

### `scene_validation.particle_points_data`

- **Title:** Point-based particle emission has incomplete data
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_particle_points_data", "value": 1}}`
- **Evidence and limits:** A GPU particle system's ParticleProcessMaterial uses Points/Directed Points but lacks the point texture, has a nonpositive point count, or uses Directed Points without a normal texture. Other shapes and custom process shaders are excluded. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Generate emission points from the intended mesh/node or supply the matching point count, point texture and directed normal texture.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/resources/particle_process_material.cpp

### `scene_validation.particle_subemitter_target`

- **Title:** A GPU particle sub-emitter path cannot attach its target
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_particle_subemitter_target", "value": 1}}`
- **Evidence and limits:** A live GPUParticles2D/3D has a nonempty sub_emitter path that resolves to itself, no node, or a node other than GPUParticles2D/3D of the matching dimension. Detached paths are skipped. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Point sub_emitter at a different GPU particle node of the same dimension.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/gpu_particles_3d.cpp

### `scene_validation.path_curve_data`

- **Title:** A path follower has no usable curve segment
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_path_curve_data", "value": 1}}`
- **Evidence and limits:** A PathFollow2D/3D has the correct direct Path parent, but that parent's curve is absent or contains fewer than two points. Coincident multi-point curves are not evaluated or baked by the audit. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Assign a curve with at least two distinct points if the follower should move along a path.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/path_3d.cpp

### `scene_validation.camera_dof_renderer`

- **Title:** Practical camera depth of field is unsupported in Compatibility
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_camera_dof_renderer", "value": 1}}`
- **Evidence and limits:** A Camera3D or WorldEnvironment has CameraAttributesPractical with near or far blur enabled. Assigned resources are inspected, not only the currently selected camera. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use Forward+ or Mobile for this depth-of-field effect, or disable the unused blur settings.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/CameraAttributesPractical.xml

### `scene_validation.camera_autoexposure_renderer`

- **Title:** Camera auto-exposure is unsupported by this renderer
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Renderer scope by version:** `{"4.4": ["gl_compatibility"], "4.6": ["mobile", "gl_compatibility"]}`
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_camera_autoexposure_renderer", "value": 1}}`
- **Evidence and limits:** A Camera3D or WorldEnvironment has assigned CameraAttributes with auto_exposure_enabled under a renderer without auto-exposure. Godot 4.4 and 4.5 warn under Compatibility; 4.6 and later also under Mobile. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use manual exposure on this renderer, or choose Forward+ for automatic exposure.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/servers/rendering/storage/camera_attributes_storage.cpp

### `scene_validation.viewport_dof_transparent`

- **Title:** A transparent SubViewport cannot use practical depth of field
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_viewport_dof_transparent", "value": 1}}`
- **Evidence and limits:** A live transparent SubViewport has near/far blur enabled in its effective CameraAttributesPractical. Current-camera overrides take precedence over world attributes. Detached scenes and physical lens calculations are excluded. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use an opaque viewport background if depth of field is required, or remove the unused blur settings.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/doc/classes/CameraAttributesPractical.xml

### `scene_validation.spring_bone_exclude_order`

- **Title:** A spring-bone exclude list is out of child order
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_spring_bone_exclude_order", "value": 1}}`
- **Evidence and limits:** A SpringBoneSimulator3D setting with all child collisions enabled lists excluded collisions whose child indices are not strictly increasing (out of order or repeated). SpringBoneSimulator3D::_find_collisions merges the exclude list into the child list assuming ascending order, so some excluded collisions stay active; reproduced on Godot 4.4 and 4.7.2, where exclude list [1, 0] still applied child 0 and [0, 0, 1] still applied child 1 (tests/test_source_rules.gd checks this engine behaviour on every version). This describes the scanned state; scripts may configure it later.
- **Suggested action:** List excluded collisions in their child order, without duplicates, or reorder the collision children to match.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/spring_bone_simulator_3d.cpp

### `scene_validation.skeleton_modifier_parent`

- **Title:** An active skeleton modifier has no direct Skeleton3D parent
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_skeleton_modifier_parent", "value": 1}}`
- **Evidence and limits:** An active SkeletonModifier3D is not directly parented to Skeleton3D. Inactive modifiers are excluded. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Place the modifier directly under the skeleton it should modify.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/skeleton_modifier_3d.cpp

### `scene_validation.viewport_shrink_ignored`

- **Title:** SubViewportContainer shrink is ignored without stretch
- **Severity:** medium
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_viewport_shrink_ignored", "value": 1}}`
- **Evidence and limits:** SubViewportContainer.stretch_shrink is greater than one while stretch is disabled. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Enable stretch if the container should control and reduce the child viewport's render resolution.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/SubViewportContainer.xml

### `scene_validation.canvas_nested_clip`

- **Title:** CanvasItem child clipping is nested inside another clipping item
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_canvas_nested_clip", "value": 1}}`
- **Evidence and limits:** An enabled clip_children node has another enabled clip_children item in its actual CanvasItem parent chain. CanvasItem clipping cannot be nested; this is distinct from Control.clip_contents. Separate canvas/root-item boundaries are excluded. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Keep one CanvasItem clipping level or restructure the effect using separate rendering surfaces.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/CanvasItem.xml

### `scene_validation.collision_object_empty`

- **Title:** A live physics object has no registered shape owners
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_collision_object_empty", "value": 1}}`
- **Evidence and limits:** A live CollisionObject2D/3D has an empty get_shape_owners() array, matching the native shapes-map warning. Detached bodies are excluded because their child shapes may not be registered yet. An existing empty owner is not treated as an absent owner. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Add an appropriate CollisionShape or CollisionPolygon child if the object should participate in collision or area queries.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/physics/collision_object_3d.cpp

### `scene_validation.navigation_link_endpoints`

- **Title:** Navigation link start and end positions coincide
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_navigation_link_endpoints", "value": 1}}`
- **Evidence and limits:** An enabled NavigationLink2D/3D has approximately equal local start_position and end_position, matching both native configuration warnings. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Place the endpoints at the distinct navigation positions the link should connect, or disable the unused link.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/navigation_link_3d.cpp

### `scene_validation.scroll_container_children`

- **Title:** ScrollContainer does not have one layout child
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_scroll_container_children", "value": 1}}`
- **Evidence and limits:** A ScrollContainer has zero or multiple visible, non-top-level direct Control children. Internal scrollbars and 4.7 decoration nodes are excluded; hidden or top-level controls do not participate in its layout. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use one direct layout container for scrollable content and put its controls beneath it.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/gui/scroll_container.cpp

### `scene_validation.texture_rect_atlas_tile`

- **Title:** Tiled TextureRect uses atlas margins
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_texture_rect_atlas_tile", "value": 1}}`
- **Evidence and limits:** A TextureRect uses STRETCH_TILE and an AtlasTexture in its chain has a nonzero margin. Godot 4.7 warns that this combination is unsupported. Inspection is bounded to 16 distinct atlas resources; deeper unresolved chains are not inferred. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use a margin-free texture for tiling, or choose a non-tiled stretch mode.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/scene/gui/texture_rect.cpp

### `scene_validation.fog_aerial`

- **Title:** Aerial-perspective fog is unavailable in Compatibility
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_fog_aerial", "value": 1}}`
- **Evidence and limits:** An assigned Environment enables regular fog with positive fog_aerial_perspective, a sky background and a sky material. The aerial-perspective sampling block is commented out in the 4.4 and 4.7.2 Compatibility shaders. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use a fixed fog color or a supported renderer if sky-colored aerial perspective is required.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/drivers/gles3/shaders/scene.glsl

### `scene_validation.look_at_axes`

- **Title:** Look-at forward and rotation axes are parallel
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_look_at_axes", "value": 1}}`
- **Evidence and limits:** An active LookAtModifier3D uses the same unsigned axis for forward_axis and primary_rotation_axis, including either forward-axis sign. This reproduces the native configuration warning. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Choose a primary rotation axis perpendicular to the bone's forward axis.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/look_at_modifier_3d.cpp

### `scene_validation.look_at_bone`

- **Title:** Look-at modifier has no valid skeleton bone
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_look_at_bone", "value": 1}}`
- **Evidence and limits:** A live active LookAtModifier3D directly under Skeleton3D has a negative or out-of-range bone index. The native modification returns before applying a pose. Detached nodes are excluded because bone names resolve on tree entry. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Select an existing bone from the parent skeleton and verify the binding after skeleton changes.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/look_at_modifier_3d.cpp

### `scene_validation.look_at_target`

- **Title:** Assigned look-at target does not resolve to Node3D
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_look_at_target", "value": 1}}`
- **Evidence and limits:** A live active LookAtModifier3D has a nonempty target_node path that is missing or resolves to another node type. The native modifier preserves the current bone rotation when no Node3D target resolves. Empty target paths are excluded because they may intentionally suspend aiming. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Repair the target path or clear it if aiming is intentionally suspended.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/look_at_modifier_3d.cpp

### `scene_validation.retarget_children`

- **Title:** Retarget modifier has no direct destination skeleton
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_retarget_children", "value": 1}}`
- **Evidence and limits:** An active RetargetModifier3D has no direct Skeleton3D child. The native destination cache considers direct children only; a skeleton beneath an intermediary Node is not a destination. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Place the intended destination Skeleton3D directly under the modifier.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/retarget_modifier_3d.cpp

### `scene_validation.retarget_profile`

- **Title:** Retarget modifier has no skeleton profile
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_retarget_profile", "value": 1}}`
- **Evidence and limits:** An active RetargetModifier3D has no SkeletonProfile. The native cache_rests method clears the source bone IDs and returns without a profile, leaving no bone mappings to retarget. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Assign the SkeletonProfile that describes the matching source and destination bone names.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/retarget_modifier_3d.cpp

### `scene_validation.skeleton_ik_bones`

- **Title:** An IK modifier has invalid root or tip bone selections
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_skeleton_ik_bones", "value": 1}}`
- **Evidence and limits:** An active, unscripted native SkeletonIK3D has a direct Skeleton3D parent, but a selected root/tip bone name is missing or the root bone index is at least the tip index. Both checked native task builders reject these selections. This checks current resource configuration; a task created before bone renaming may retain earlier indices. No IK task is created and no solve is invoked by the audit. An ancestry requirement is not invented: the native builder's explicit index checks are the predicate. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Choose existing root and tip bones for the intended chain, with the root index below the tip index, and reload/reinitialize the IK chain after correcting the configuration. Confirm the selected root is the intended ancestor.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/skeleton_ik_3d.cpp

### `scene_validation.material_height_triplanar`

- **Title:** Height mapping is ignored with UV1 triplanar mapping
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_material_height_triplanar", "value": 1}}`
- **Evidence and limits:** An effective BaseMaterial3D enables both height mapping and UV1 triplanar mapping. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use mesh UVs for height mapping, or disable the unused height-map feature.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/resources/material.cpp

### `scene_validation.material_msdf_triplanar`

- **Title:** MSDF albedo is ignored with UV1 triplanar mapping
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_material_msdf_triplanar", "value": 1}}`
- **Evidence and limits:** An effective BaseMaterial3D enables both MSDF albedo and UV1 triplanar mapping. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use mesh UVs when sampling an MSDF albedo texture.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/resources/material.cpp

### `scene_validation.material_unshaded_features`

- **Title:** Unshaded materials ignore clearcoat and rim lighting
- **Severity:** medium
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_material_unshaded_features", "value": 1}}`
- **Evidence and limits:** An unshaded BaseMaterial3D enables clearcoat or rim lighting. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Select a lit shading mode if those lighting effects are needed, or disable the unused features.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/resources/material.cpp

### `scene_validation.material_particle_trails`

- **Title:** A particle-trail material is used on ordinary mesh geometry
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_material_particle_trails", "value": 1}}`
- **Evidence and limits:** An effective BaseMaterial3D enables use_particle_trails outside a GPUParticles3D draw pass. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use a separate material with particle trails disabled for ordinary mesh geometry.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/resources/material.cpp

### `scene_validation.material_anisotropy_tangents`

- **Title:** An anisotropic material's ArrayMesh surface lacks tangents
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"all": [{"scene_gte": {"name": "check_material_anisotropy_tangents", "value": 1}}, {"setting_eq": {"path": "rendering/shading/overrides/force_vertex_shading", "value": false}}]}`
- **Evidence and limits:** An effective per-pixel BaseMaterial3D enables nonzero anisotropy on an ArrayMesh surface without ARRAY_FORMAT_TANGENT. Triplanar modes generate tangent space in the shader and are excluded, as are other mesh types and unknown custom shader semantics. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Generate tangents during mesh import, or disable anisotropy where it is unnecessary.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/doc/classes/BaseMaterial3D.xml

### `scene_validation.missing_node`

- **Title:** A scene node's class or instanced scene is missing
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_missing_node", "value": 1}}`
- **Evidence and limits:** A MissingNode placeholder stands in for a node whose class or instanced scene was unavailable when the scene loaded. The offender lists the original class and scene. Godot keeps the stored properties only while the placeholder is saved unchanged. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Restore the missing class (plugin, GDExtension or script class) or scene file, or replace the node deliberately before saving the scene.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/main/missing_node.cpp

### `scene_validation.canvas_modulate_multiple`

- **Title:** More than one visible CanvasModulate shares a canvas
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_canvas_modulate_multiple", "value": 1}}`
- **Evidence and limits:** Two or more visible CanvasModulate nodes are registered for the same canvas. Godot applies only one of them, and which one is undefined. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Keep one visible CanvasModulate per canvas; hide or remove the others, or move them to separate CanvasLayers.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/2d/canvas_modulate.cpp

### `scene_validation.timer_short_wait`

- **Title:** A Timer waits less than 0.05 seconds
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_timer_short_wait", "value": 1}}`
- **Evidence and limits:** Timer.wait_time is below 0.05 s. Godot warns that such timers behave differently depending on the rendered or physics frame rate, because a Timer can fire at most once per processed frame. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use a process loop for very short periodic work, or accept and document the frame-rate-dependent firing.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/main/timer.cpp

### `scene_validation.shader_globals_inactive`

- **Title:** A ShaderGlobalsOverride is inactive because another one exists
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_shader_globals_inactive", "value": 1}}`
- **Evidence and limits:** A ShaderGlobalsOverride inside the tree is not in the active override group: another override node is already active, so this node's values are ignored. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Keep a single ShaderGlobalsOverride per scene tree and merge the overridden parameters into it.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/main/shader_globals_override.cpp

### `scene_validation.container_plain`

- **Title:** A plain Container has no layout script
- **Severity:** medium
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_container_plain", "value": 1}}`
- **Evidence and limits:** A node of exact class Container has no script, so nothing positions its children. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use a concrete container (VBoxContainer, HBoxContainer, MarginContainer ...) or a plain Control.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/gui/container.cpp

### `scene_validation.button_group_toggle`

- **Title:** A ButtonGroup member is not in toggle mode
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_button_group_toggle", "value": 1}}`
- **Evidence and limits:** A BaseButton has a ButtonGroup but toggle_mode is false, so the group cannot keep a single pressed button. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Enable toggle_mode on group members, or remove the ButtonGroup.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/gui/base_button.cpp

### `scene_validation.label_autowrap_width`

- **Title:** An autowrapping Label has no width constraint
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_label_autowrap_width", "value": 1}}`
- **Evidence and limits:** Godot 4.7: an in-tree Label wraps text but its custom minimum width and combined maximum width are both zero. Godot 4.4: a wrapping Label inside a Container has no custom minimum size. Godot warns the label cannot size correctly, typically collapsing to one character per line. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Set a positive custom minimum (or 4.7 maximum) width, or let a container with a fixed width size the label.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/gui/label.cpp

### `scene_validation.label_missing_glyphs`

- **Title:** A Label's font cannot render some of its characters
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_label_missing_glyphs", "value": 1}}`
- **Evidence and limits:** Shaping the Label's text (uppercase applied, up to 4096 characters, untranslated) with its effective font and fallbacks leaves glyphs without a font, which render as boxes or nothing. Godot 4.7 ignores zero-index control glyphs; 4.4 reports any unfonted glyph. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Add a fallback font that covers the characters, or change the text. Check translated strings too.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/gui/label.cpp

### `scene_validation.label_msdf_pixel_range`

- **Title:** An MSDF Label outline exceeds the font's pixel range
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_label_msdf_pixel_range", "value": 1}}`
- **Evidence and limits:** The Label uses an MSDF FontFile whose msdf_pixel_range is too small for the combined outline and stacked outline/shadow sizes at this font size, so part of the outline or shadow is not drawn. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Raise msdf_pixel_range on the font import (Godot reports the required minimum), or reduce the outline sizes.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/scene/gui/label.cpp

### `scene_validation.popup_transparency`

- **Title:** Rounded or shadowed popups lack window transparency
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_popup_transparency", "value": 1}}`
- **Evidence and limits:** A PopupPanel or PopupMenu (including the popup of a MenuButton or OptionButton) uses a StyleBoxFlat panel with shadows or rounded corners, subwindows are not embedded, and the display server reports no window transparency, so the corners and shadow render opaque. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Enable display/window/per_pixel_transparency/allowed on platforms that support it, embed subwindows, or use a square shadowless popup style.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/gui/popup.cpp

### `scene_validation.subviewport_cursor`

- **Title:** A SubViewportContainer sets a default cursor shape
- **Severity:** medium
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_subviewport_cursor", "value": 1}}`
- **Evidence and limits:** SubViewportContainer.mouse_default_cursor_shape is not CURSOR_ARROW; Godot ignores it for this node. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Set the cursor on the Controls inside the SubViewport instead, and leave the container at CURSOR_ARROW.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/gui/subviewport_container.cpp

### `scene_validation.parallax_layer_parent`

- **Title:** A ParallaxLayer is not a child of ParallaxBackground
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_parallax_layer_parent", "value": 1}}`
- **Evidence and limits:** A ParallaxLayer's parent is not a ParallaxBackground, so it does not scroll with the parallax camera. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Move the layer under a ParallaxBackground, or use Parallax2D.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/2d/parallax_layer.cpp

### `scene_validation.voxel_gi_data`

- **Title:** A VoxelGI node has no baked data
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_voxel_gi_data", "value": 1}}`
- **Evidence and limits:** VoxelGI.data is empty, so the node is disabled and contributes no global illumination. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Bake the VoxelGI, or remove the node if it is unused.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/voxel_gi.cpp

### `scene_validation.occluder_culling_disabled`

- **Title:** Occluders exist but occlusion culling is disabled
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_occluder_culling_disabled", "value": 1}}`
- **Evidence and limits:** An OccluderInstance3D exists while rendering/occlusion_culling/use_occlusion_culling is false, so the root viewport performs no occlusion culling with it. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Enable occlusion culling in the project settings, or remove unused occluders.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/occluder_instance_3d.cpp

### `scene_validation.tilemap_deprecated`

- **Title:** A deprecated TileMap node is used
- **Severity:** medium
- **Kind:** info
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_tilemap_deprecated", "value": 1}}`
- **Evidence and limits:** The scene uses TileMap, which Godot deprecates in favor of separate TileMapLayer nodes. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use the TileMap bottom panel's Extract TileMap layers command to convert it to TileMapLayer nodes.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/2d/tile_map.cpp

### `scene_validation.tilemap_ysort_z`

- **Title:** A Y-sorted TileMap layer shares a Z index with an unsorted layer
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_tilemap_ysort_z", "value": 1}}`
- **Evidence and limits:** A TileMap has a layer without Y-sort at the same Z index as a Y-sorted layer, so the unsorted layer is Y-sorted as a whole together with the sorted tiles. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Give unsorted layers a different Z index, or enable Y-sort on them.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/2d/tile_map.cpp

### `scene_validation.tilemap_layer_ysort`

- **Title:** A TileMap layer is Y-sorted but the TileMap node is not
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_tilemap_layer_ysort", "value": 1}}`
- **Evidence and limits:** At least one TileMap layer enables Y-sort while the TileMap node itself does not. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Enable Y-sort on the TileMap node as well.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/2d/tile_map.cpp

### `scene_validation.tilemap_node_ysort`

- **Title:** A Y-sorted TileMap has no Y-sorted layers
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_tilemap_node_ysort", "value": 1}}`
- **Evidence and limits:** The TileMap node enables Y-sort but none of its layers do, so each layer is Y-sorted as a whole. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Enable Y-sort on the layers that need per-tile sorting.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/2d/tile_map.cpp

### `scene_validation.tilemap_isometric_ysort`

- **Title:** An isometric TileMap is not fully Y-sorted
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_tilemap_isometric_ysort", "value": 1}}`
- **Evidence and limits:** The TileSet uses isometric tiles while Y-sort is off on the TileMap or on at least one layer, which Godot warns will likely not draw as intended. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Enable Y-sort on the TileMap and all of its layers.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/2d/tile_map.cpp

### `scene_validation.physical_bone2d_parent`

- **Title:** A PhysicalBone2D has no Skeleton2D ancestor
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_physical_bone2d_parent", "value": 1}}`
- **Evidence and limits:** Walking up through parent PhysicalBone2D nodes does not reach a Skeleton2D, so the bone cannot follow or drive a skeleton. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Place PhysicalBone2D nodes under a Skeleton2D, directly or through other PhysicalBone2D nodes.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/2d/physics/physical_bone_2d.cpp

### `scene_validation.physical_bone2d_bone`

- **Title:** A PhysicalBone2D is not assigned to a Bone2D
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_physical_bone2d_bone", "value": 1}}`
- **Evidence and limits:** The PhysicalBone2D has a Skeleton2D but bone2d_index is -1. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Set bone2d_nodepath (or bone2d_index) to the Bone2D it should simulate.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/2d/physics/physical_bone_2d.cpp

### `scene_validation.physical_bone2d_joint`

- **Title:** A child PhysicalBone2D has no Joint2D
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_physical_bone2d_joint", "value": 1}}`
- **Evidence and limits:** A PhysicalBone2D whose parent is another PhysicalBone2D has no Joint2D child, so nothing keeps the two bones connected. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Add a PinJoint2D (or another Joint2D) as a child of the bone.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/2d/physics/physical_bone_2d.cpp

### `scene_validation.physics_body_interpolation`

- **Title:** A physics body sits on a non-interpolated branch
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_physics_body_interpolation", "value": 1}}`
- **Evidence and limits:** Physics interpolation is enabled for the project, but this PhysicsBody2D/3D resolves to physics_interpolation_mode OFF through its own or an inherited mode. Godot warns it will not work correctly there. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Set the body (and its ancestors) to Inherit or On, and keep non-interpolated visuals on separate branches.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/scene/3d/physics/physics_body_3d.cpp

### `scene_validation.canvas_group_ancestor`

- **Title:** A CanvasGroup has a clipping or CanvasGroup ancestor
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_canvas_group_ancestor", "value": 1}}`
- **Evidence and limits:** An in-tree CanvasGroup has an ancestor CanvasGroup or an ancestor CanvasItem that clips its children, so Godot warns the group will not function properly. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Move the CanvasGroup out of the clipping ancestor or the outer CanvasGroup.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/scene/2d/canvas_group.cpp

### `scene_validation.xr_camera_parent`

- **Title:** An XRCamera3D is not a child of XROrigin3D
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_xr_camera_parent", "value": 1}}`
- **Evidence and limits:** A visible in-tree XRCamera3D has a parent that is not an XROrigin3D, so its tracking space is undefined. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Make the XRCamera3D a direct child of the XROrigin3D.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/xr/xr_nodes.cpp

### `scene_validation.xr_node_parent`

- **Title:** An XR controller or anchor is not a child of XROrigin3D
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_xr_node_parent", "value": 1}}`
- **Evidence and limits:** A visible in-tree XRNode3D (XRController3D, XRAnchor3D ...) has a parent that is not an XROrigin3D. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Make tracked XR nodes direct children of the XROrigin3D.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/xr/xr_nodes.cpp

### `scene_validation.xr_node_tracker`

- **Title:** An XR tracked node has no tracker name
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_xr_node_tracker", "value": 1}}`
- **Evidence and limits:** A visible in-tree XRNode3D has an empty tracker name, so it follows nothing. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Set the tracker (for example left_hand or right_hand).
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/xr/xr_nodes.cpp

### `scene_validation.xr_node_pose`

- **Title:** An XR tracked node has no pose name
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_xr_node_pose", "value": 1}}`
- **Evidence and limits:** A visible in-tree XRNode3D has an empty pose name. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Set the pose (default, aim or grip).
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/xr/xr_nodes.cpp

### `scene_validation.xr_interpolation`

- **Title:** An XR camera or tracked node is physics-interpolated
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_xr_interpolation", "value": 1}}`
- **Evidence and limits:** Physics interpolation is enabled and a visible XRCamera3D or XRNode3D is interpolated; Godot warns this causes jitter because tracking updates every rendered frame. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Set physics_interpolation_mode to Off on XR cameras and tracked nodes.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/scene/3d/xr/xr_nodes.cpp

### `scene_validation.xr_origin_camera`

- **Title:** An XROrigin3D has no XRCamera3D child
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_xr_origin_camera", "value": 1}}`
- **Evidence and limits:** A visible in-tree XROrigin3D has no XRCamera3D child, so nothing renders from the headset pose. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Add an XRCamera3D as a child of the XROrigin3D.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/xr/xr_nodes.cpp

### `scene_validation.xr_origin_scale`

- **Title:** An XROrigin3D is scaled
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_xr_origin_scale", "value": 1}}`
- **Evidence and limits:** The XROrigin3D's scale is not (1, 1, 1); Godot does not support scaling it. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Reset the scale and change XRServer world scale instead.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/scene/3d/xr/xr_nodes.cpp

### `scene_validation.xr_shaders_disabled`

- **Title:** An XR scene runs without XR shaders
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_xr_shaders_disabled", "value": 1}}`
- **Evidence and limits:** An XROrigin3D exists while xr/shaders/enabled is false, so stereoscopic output is not supported. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Enable xr/shaders/enabled in the project settings.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/xr/xr_nodes.cpp

### `scene_validation.xr_hand_tracking`

- **Title:** Hand skeleton modifiers lack the OpenXR hand-tracking extension
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_xr_hand_tracking", "value": 1}}`
- **Evidence and limits:** An XRHandModifier3D exists while OpenXR is enabled but xr/openxr/extensions/hand_tracking is off, so no hand data arrives. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Enable the OpenXR hand-tracking extension in the project settings.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/xr/xr_hand_modifier_3d.cpp

### `scene_validation.openxr_layer_transform`

- **Title:** An OpenXR composition layer has scale or shear
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_openxr_layer_transform", "value": 1}}`
- **Evidence and limits:** The OpenXRCompositionLayer's local basis is not orthonormal; OpenXR composition layers support rotation and translation only. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Size the layer through its shape properties and keep the node's scale at 1.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/modules/openxr/scene/openxr_composition_layer.cpp

### `scene_validation.openxr_layer_hole_punch`

- **Title:** A hole-punching OpenXR layer is sorted in front
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_openxr_layer_hole_punch", "value": 1}}`
- **Evidence and limits:** enable_hole_punch is on while sort_order is zero or positive; hole punching only works for layers sorted behind the projection layer. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use a negative sort_order for hole-punched layers.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/modules/openxr/scene/openxr_composition_layer.cpp

### `scene_validation.openxr_layer_parent`

- **Title:** An OpenXR composition layer is not under XROrigin3D
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_openxr_layer_parent", "value": 1}}`
- **Evidence and limits:** Godot 4.4: a visible in-tree OpenXRCompositionLayer's parent is not an XROrigin3D. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Make the layer a child of the XROrigin3D.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/modules/openxr/scene/openxr_composition_layer.cpp

### `scene_validation.openxr_visibility_mask_parent`

- **Title:** An OpenXR visibility mask is not under XRCamera3D
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_openxr_visibility_mask_parent", "value": 1}}`
- **Evidence and limits:** A visible in-tree OpenXRVisibilityMask's parent is not an XRCamera3D. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Make the visibility mask a child of the XRCamera3D.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/modules/openxr/scene/openxr_visibility_mask.cpp

### `scene_validation.openxr_render_model_parent`

- **Title:** An OpenXR render model is outside its XR origin
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_openxr_render_model_parent", "value": 1}}`
- **Evidence and limits:** An OpenXRRenderModel's parent is neither an XROrigin3D nor an OpenXRRenderModelManager, or an OpenXRRenderModelManager has no XROrigin3D parent (or, for a specific tracker, no XROrigin3D ancestor). This describes the scanned state; scripts may configure it later.
- **Suggested action:** Place render models under an OpenXRRenderModelManager that is under the XROrigin3D.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/modules/openxr/scene/openxr_render_model_manager.cpp

### `scene_validation.openxr_render_model_extension`

- **Title:** OpenXR render models lack their extension
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_openxr_render_model_extension", "value": 1}}`
- **Evidence and limits:** An OpenXRRenderModel or OpenXRRenderModelManager exists while xr/openxr/extensions/render_model is off. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Enable the OpenXR render-model extension in the project settings.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/modules/openxr/scene/openxr_render_model.cpp

### `scene_validation.openxr_render_model_pose`

- **Title:** An OpenXR render-model manager needs a tracker for its pose
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_openxr_render_model_pose", "value": 1}}`
- **Evidence and limits:** An OpenXRRenderModelManager tracks any or no device while make_local_to_pose is set; a pose needs a specific tracker. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Select a hand tracker, or clear make_local_to_pose.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/modules/openxr/scene/openxr_render_model_manager.cpp

### `scene_validation.multiplayer_spawner_path`

- **Title:** A MultiplayerSpawner's spawn path is invalid
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_multiplayer_spawner_path", "value": 1}}`
- **Evidence and limits:** MultiplayerSpawner.spawn_path is empty or does not resolve, so it cannot spawn nodes. Absolute paths are skipped outside a running tree. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Point spawn_path at the node that receives spawned scenes.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/modules/multiplayer/multiplayer_spawner.cpp

### `scene_validation.multiplayer_synchronizer_root`

- **Title:** A MultiplayerSynchronizer's root path is invalid
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_multiplayer_synchronizer_root", "value": 1}}`
- **Evidence and limits:** MultiplayerSynchronizer.root_path is empty or does not resolve, so it cannot synchronize properties. Absolute paths are skipped outside a running tree. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Point root_path at the node whose properties are replicated.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/modules/multiplayer/multiplayer_synchronizer.cpp

### `scene_validation.csg_empty_shape`

- **Title:** A CSG shape produces no geometry
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_csg_empty_shape", "value": 1}}`
- **Evidence and limits:** The in-tree root CSG result for this shape has no surfaces, which Godot reports as an empty shape; it usually means a non-manifold mesh. Only root results are exposed, so an empty child brush under a non-empty root is not detected. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Use closed, manifold meshes (every edge shared by exactly two faces) in CSGMesh3D, or check the CSG operations.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/modules/csg/csg_shape.cpp

### `scene_validation.spring_bone_collision_parent`

- **Title:** A spring-bone collider is not under SpringBoneSimulator3D
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_spring_bone_collision_parent", "value": 1}}`
- **Evidence and limits:** A SpringBoneCollision3D's parent is not a SpringBoneSimulator3D, so no simulator uses it. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Move the collider under the SpringBoneSimulator3D that should collide with it.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/3d/spring_bone_collision_3d.cpp

### `scene_validation.aim_modifier_axes`

- **Title:** An AimModifier3D setting has parallel forward and rotation axes
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.5, 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_aim_modifier_axes", "value": 1}}`
- **Evidence and limits:** A setting using Euler rotation has a forward axis parallel to its primary rotation axis, which cannot aim. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Choose a primary rotation axis perpendicular to the forward axis.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/scene/3d/aim_modifier_3d.cpp

### `scene_validation.iterate_ik_target`

- **Title:** An iterative IK chain has no valid target
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_iterate_ik_target", "value": 1}}`
- **Evidence and limits:** An in-tree IterateIK3D (FABRIK3D, CCDIK3D, JacobianIK3D) has a setting whose target is empty or does not resolve to a Node3D. _process_ik skips that setting every frame. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Assign a Node3D target to every setting, or remove unused settings.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/scene/3d/iterate_ik_3d.cpp

### `scene_validation.spline_ik_path`

- **Title:** A SplineIK3D setting has no usable Path3D
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_spline_ik_path", "value": 1}}`
- **Evidence and limits:** An in-tree SplineIK3D has a setting whose Path3D is missing or does not resolve, or whose curve has no points. _process_ik skips that setting every frame. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Assign a Path3D with a curve to every setting.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/scene/3d/spline_ik_3d.cpp

### `scene_validation.two_bone_ik_targets`

- **Title:** A TwoBoneIK3D setting lacks a target or pole node
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.6, 4.7
- **Godot also warns:** in the editor (configuration warning)
- **Observed condition:** `{"scene_gte": {"name": "check_two_bone_ik_targets", "value": 1}}`
- **Evidence and limits:** An in-tree TwoBoneIK3D has a setting whose target or pole does not resolve to a Node3D. _process_ik aborts that setting each frame. (Godot 4.7.2's pole warning re-tests the target path; the processing code requires both.) This describes the scanned state; scripts may configure it later.
- **Suggested action:** Assign Node3D target and pole nodes to every setting.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/scene/3d/two_bone_ik_3d.cpp

### `scene_validation.audio_pitch_zero_hop`

- **Title:** A pitch-shift effect is configured with a zero FFT hop
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Observed condition:** `{"scene_gte": {"name": "check_audio_pitch_zero_hop", "value": 1}}`
- **Evidence and limits:** An enabled native AudioEffectPitchShift on a non-bypassed current audio bus has non-unity pitch and oversampling greater than its configured FFT frame size (256/512/1024/2048/4096). Native instantiation captures that size; integer frame_size/oversampling then yields a zero hop, so the output FIFO fill loop has no iterations. This describes the resource configuration when instantiated; existing instances may retain an earlier FFT size, and inactive buses may not process audio. Scripted/custom effects are skipped.
- **Suggested action:** Use oversampling no greater than the selected FFT frame size, normally starting with the default 4. Recreate/reload the effect after changing FFT size and test the intended pitch shift.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/servers/audio/effects/audio_effect_pitch_shift.cpp

### `scene_validation.skeleton2d_jiggle_collision_mode`

- **Title:** A native 2D Jiggle modifier requests collision in idle mode
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_skeleton2d_jiggle_collision_mode", "value": 1}}`
- **Evidence and limits:** One of the first 128 modifications in a live, setup, owned, enabled, unscripted Skeleton2D stack is an enabled unscripted native SkeletonModification2DJiggle with at least one configured joint, use_colliders true, idle execution mode and an enabled internal idle tick. Both checked native implementations skip intersect_ray and issue a once-only warning when such a joint reaches the collider branch. Invalid targets or joint caches may return early; this reports the configured mode conflict, not a captured warning. Detached, paused, disabled, empty-chain and scripted cases are excluded. The audit never executes a modifier or physics query. This describes the scanned state; scripts may configure it later.
- **Suggested action:** Set the modification to physics_process if collisions are intended, or disable use_colliders when collision is unnecessary. Verify skeletal motion after changing the update clock.
- **Source:** https://github.com/godotengine/godot/blob/4.4-stable/scene/resources/2d/skeleton/skeleton_modification_2d_jiggle.cpp

### `scene_validation.env_ssao_renderer`

- **Title:** SSAO is unsupported by this renderer
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Renderer scope by version:** `{"4.6": ["mobile"]}`
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "env_ssao", "value": 1}}`
- **Evidence and limits:** SSAO is enabled on a scanned Environment under an unsupported renderer. SSAO is supported by Compatibility from 4.6 and is excluded there. No performance saving is asserted.
- **Suggested action:** Use Forward+ or a supported alternative effect for the target hardware.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/doc/classes/Environment.xml

### `scene_validation.env_ssil_renderer`

- **Title:** SSIL is unsupported by this renderer
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "env_ssil", "value": 1}}`
- **Evidence and limits:** SSIL is enabled on a scanned Environment under an unsupported renderer. No performance saving is asserted.
- **Suggested action:** Use Forward+ or a supported alternative effect for the target hardware.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/doc/classes/Environment.xml

### `scene_validation.env_ssr_renderer`

- **Title:** SSR is unsupported by this renderer
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "env_ssr", "value": 1}}`
- **Evidence and limits:** SSR is enabled on a scanned Environment under an unsupported renderer. No performance saving is asserted.
- **Suggested action:** Use Forward+ or a supported alternative effect for the target hardware.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/doc/classes/Environment.xml

### `scene_validation.env_sdfgi_renderer`

- **Title:** SDFGI is unsupported by this renderer
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "env_sdfgi", "value": 1}}`
- **Evidence and limits:** SDFGI is enabled on a scanned Environment under an unsupported renderer. No performance saving is asserted.
- **Suggested action:** Use Forward+ or a supported alternative effect for the target hardware.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/doc/classes/Environment.xml

### `scene_validation.env_volumetric_fog_renderer`

- **Title:** Volumetric fog is unsupported by this renderer
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "env_volumetric_fog", "value": 1}}`
- **Evidence and limits:** Volumetric fog is enabled on a scanned Environment under an unsupported renderer. No performance saving is asserted.
- **Suggested action:** Use Forward+ or a supported alternative effect for the target hardware.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/doc/classes/Environment.xml

### `scene_validation.particle_attractor_renderer`

- **Title:** A vector-field particle attractor is used under Compatibility
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_particle_vector_attractor", "value": 1}}`
- **Evidence and limits:** Godot prints "Vector field particle attractors are not available in the Compatibility renderer." when the scene has a GPUParticlesAttractorVectorField3D and the renderer is Compatibility, which skips it.
- **Suggested action:** Use a box or sphere attractor, or switch to Forward+ or Mobile.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/storage/particles_storage.cpp

### `scene_validation.particle_sdf_renderer`

- **Title:** An SDF particle collider is used under Compatibility
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_particle_sdf_collider", "value": 1}}`
- **Evidence and limits:** Godot prints "SDF Particle Colliders are not available in the Compatibility renderer." when the scene has a GPUParticlesCollisionSDF3D and the renderer is Compatibility, which skips it.
- **Suggested action:** Use box, sphere or height-field colliders, or switch to Forward+ or Mobile.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/storage/particles_storage.cpp

### `scene_validation.texture_type_unsampled`

- **Title:** A decal, projector or 2D light uses a texture type it cannot sample
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_texture_type_unsampled", "value": 1}}`
- **Evidence and limits:** Godot prints "ViewportTexture cannot be used as a Decal texture (Decal path). As a workaround, assign the value returned by ViewportTexture's `get_image()` instead." when a Decal texture, a Light3D projector (or 4.7 area-light texture) or a PointLight2D texture is an AnimatedTexture, AtlasTexture, CameraTexture, CanvasTexture, MeshTexture, Texture2DRD or ViewportTexture. Godot's message suggests assigning the image from get_image() instead.
- **Suggested action:** Assign an ImageTexture or imported texture (for example from the texture's get_image()).
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/scene/3d/decal.cpp

### `scene_validation.viewport_sss_transparent`

- **Title:** Subsurface scattering is drawn in a transparent viewport
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus
- **Godot versions:** 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"any": [{"scene_gte": {"name": "check_viewport_sss_transparent", "value": 1}}, {"all": [{"setting_eq": {"path": "rendering/viewport/transparent_background", "value": true}}, {"scene_gte": {"name": "subsurf_material_count", "value": 1}}, {"setting_neq": {"path": "rendering/environment/subsurface_scattering/subsurface_scattering_quality", "value": 0}}]}]}`
- **Evidence and limits:** Godot prints "Sub-surface scattering is not supported in viewports with a transparent background. Disabling SSS in transparent viewport." when a SubViewport with transparent_bg draws a material with subsurface scattering, or rendering/viewport/transparent_background is on and the scene uses such a material, while subsurface scattering quality is not Disabled.
- **Suggested action:** Use an opaque background for viewports that need subsurface scattering, or turn subsurface scattering off on those materials.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/renderer_rd/forward_clustered/render_forward_clustered.cpp

### `scene_validation.modifier_node_missing`

- **Title:** A skeleton modifier's center or reference node does not resolve
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_modifier_node_missing", "value": 1}}`
- **Evidence and limits:** Godot prints "Setting: 0: Reference node 'Missing' not found." when a SpringBoneSimulator3D center node or a BoneConstraint3D reference node path does not resolve to a Node3D; the setting then has no valid center or reference.
- **Suggested action:** Point the path at the intended Node3D, or clear it and use a bone reference.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/scene/3d/bone_constraint_3d.cpp

### `scene_validation.material_normal_tangents`

- **Title:** A normal- or height-mapped material is drawn on a mesh without tangents
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_material_normal_tangents", "value": 1}}`
- **Evidence and limits:** Godot prints "Attempting to use a shader that requires tangents with a mesh that doesn't contain tangents. Ensure that meshes are imported with the 'ensure_tangents' option. If creating your own meshes, add an `ARRAY_TANGENT` array (when using ArrayMesh) or call `generate_tangents()` (when using SurfaceTool)." when a per-pixel BaseMaterial3D with normal mapping or height mapping is drawn on an ArrayMesh surface without ARRAY_FORMAT_TANGENT. Normal mapping writes NORMAL_MAP and height mapping reads TANGENT and BINORMAL, so the lighting uses a missing tangent basis. Triplanar materials build their own tangents and are excluded; anisotropy is reported by scene_validation.material_anisotropy_tangents.
- **Suggested action:** Enable ensure_tangents when importing the mesh, add an ARRAY_TANGENT array, or call SurfaceTool.generate_tangents().
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/renderer_rd/forward_clustered/render_forward_clustered.cpp

### `scene_validation.shader_normal_roughness_renderer`

- **Title:** A spatial shader reads the normal-roughness buffer under Compatibility
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_shader_normal_roughness", "value": 1}}`
- **Evidence and limits:** Godot prints "Reading from the normal-roughness texture is only available when using the Forward+ or Mobile renderer." when a ShaderMaterial's spatial shader declares a hint_normal_roughness_texture uniform (comments ignored) under the Compatibility renderer, which has no normal-roughness buffer.
- **Suggested action:** Remove the normal-roughness read for Compatibility, or use Forward+ or Mobile.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/storage/material_storage.cpp

### `scene_validation.modifier_axis_colinear`

- **Title:** A joint rotation axis or pole direction is parallel to the bone
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_modifier_axis_colinear", "value": 1}}`
- **Evidence and limits:** Godot prints "Setting: 0 Joint: 0: Rotation axis and forward vector are colinear. This is not advised as it may cause unwanted rotation." when a SpringBoneSimulator3D or IterateIK3D joint's rotation axis is parallel to the direction to its child bone in the rest pose, or (4.6+) a TwoBoneIK3D pole direction is parallel to the middle bone's forward vector. Godot's message warns that it may cause unwanted rotation. Joints whose forward comes from an extended end bone are not inspected.
- **Suggested action:** Choose a rotation axis or pole direction perpendicular to the bone.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/scene/3d/spring_bone_simulator_3d.cpp

### `scene_validation.instance_uniform_conflict`

- **Title:** Materials on one instance declare the same instance uniform differently
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_instance_uniform_conflict", "value": 1}}`
- **Evidence and limits:** Godot prints "More than one material in instance export the same instance shader uniform 'tint', but they do it with different data types. Only the first one (in order) will display correctly." (or "... with different indices ...") when the material override (or the surface materials) and the overlay of a GeometryInstance3D declare an instance uniform with the same name but a different type or instance index; only the first declaration displays correctly. Shader #include files are not followed.
- **Suggested action:** Give the uniform the same type and instance_index in every shader on the instance, or rename one.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/instance_uniforms.cpp

### `scene_validation.emit_particle_compatibility`

- **Title:** A script emits particles manually under Compatibility
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_script_emit_particle", "value": 1}}`
- **Evidence and limits:** Godot prints "The Compatibility renderer does not support manually emitting particles." when a script calls emit_particle() (GPUParticles2D/3D) and the renderer is Compatibility, which ignores manual emission.
- **Suggested action:** Use CPUParticles for script-driven emission under Compatibility, or a renderer with GPU particle emission.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/storage/particles_storage.cpp

### `scene_validation.ext_resource_uid_invalid`

- **Title:** A text resource references a UID that no longer resolves
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_ext_resource_uid_invalid", "value": 1}}`
- **Evidence and limits:** Godot prints "res://level.tscn:3 - ext_resource, invalid UID: uid://b1example - using text path instead: res://art/hero.png" when a .tscn or .tres ext_resource carries a uid:// that is not in the UID cache and does not belong to the file at its path (the editor-build test in resource_format_text.cpp); a UID matching the path's .uid sidecar counts as valid, so C# scripts are not reported by an editor without .NET. Godot falls back to the text path, which breaks when the file is moved again or exported without it.
- **Suggested action:** Open and re-save the scene or resource in the editor so the ext_resource gets the file's current UID.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/scene/resources/resource_format_text.cpp

### `scene_validation.animation_expression_base`

- **Title:** State-machine transition expressions have no base node
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_animation_expression_base", "value": 1}}`
- **Evidence and limits:** Godot prints "Animation transition has a valid expression, but no expression base node was set on its AnimationTree." when an AnimationTree's advance_expression_base_node does not resolve and its state machine (or a nested one, four levels deep) has a transition with an advance expression; the expression is never evaluated, so the transition never fires by expression.
- **Suggested action:** Point advance_expression_base_node at the node whose properties the expressions read (the default "." is the AnimationTree).
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/scene/animation/animation_node_state_machine.cpp

### `scene_validation.modifier_bone_missing`

- **Title:** A skeleton modifier names a bone its skeleton does not have
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_modifier_bone_missing", "value": 1}}`
- **Evidence and limits:** Godot prints "Setting: 0: Root bone index '-1' is out of range!" (4.4 to 4.6: "Root bone index out of range!") when a SkeletonModifier3D setting stores a bone name the parent Skeleton3D lacks, or a bone index past its bone count. Godot re-resolves stored bones whenever the modifier enters the skeleton; the setting then skips that bone. Covers spring bones, IK, bone constraints, twist dispersers, angular-velocity limits, bone targets and look-at origins.
- **Suggested action:** Pick an existing bone in the inspector, or update the bone names after renaming bones or replacing the skeleton.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/scene/3d/spring_bone_simulator_3d.cpp

### `scene_validation.animation_track_unresolved`

- **Title:** An animation track's node path does not resolve
- **Severity:** medium
- **Kind:** correctness
- **Heuristic:** no
- **Renderers:** forward_plus, mobile, gl_compatibility
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Godot also warns:** at run time (printed warning)
- **Observed condition:** `{"scene_gte": {"name": "check_animation_track_unresolved", "value": 1}}`
- **Evidence and limits:** Godot prints "AnimationPlayer: 'walk', couldn't resolve track:  'Renamed:visible'. This warning can be disabled in Project Settings." for every enabled track whose node path does not resolve from the AnimationPlayer or AnimationTree root_node, when animation/warnings/check_invalid_track_paths is on (the default). The track animates nothing.
- **Suggested action:** Retarget the track to the renamed or moved node, delete the stale track, or disable it.
- **Source:** https://github.com/godotengine/godot/blob/4.7.2-stable/scene/animation/animation_mixer.cpp

## gpu_best_practices

### `gpu_best_practices.compute_arm_spatial`

- **Title:** A one-dimensional compute workgroup accesses multidimensional images on Arm
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Adapted from an upstream API-level check using Godot-visible evidence. It does not prove the Vulkan condition fired or predict saved milliseconds. On the actual Vulkan driver, exactly one fixed local-size dimension exceeds one and the compute entry-point body directly samples, fetches, gathers, reads or writes a 2D/3D/cube/rectangle image. Image declarations alone do not qualify. Helper-only operations, unresolved image values and specialized sizes are skipped. Addressing and tiling are unknown; a one-dimensional group can still have good locality.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `BestPractices-Arm-vkCreateComputePipelines-compute-spatial-locality` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_compute_arm_spatial", "value": 1}}`
- **Mapping limits:** Adapted from an upstream API-level check using Godot-visible evidence. It does not prove the Vulkan condition fired or predict saved milliseconds. On the actual Vulkan driver, exactly one fixed local-size dimension exceeds one and the compute entry-point body directly samples, fetches, gathers, reads or writes a 2D/3D/cube/rectangle image. Image declarations alone do not qualify. Helper-only operations, unresolved image values and specialized sizes are skipped. Addressing and tiling are unknown; a one-dimensional group can still have good locality.
- **GPU families:** arm
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/best_practices/bp_pipeline.cpp

### `gpu_best_practices.compute_amd_layout`

- **Title:** An imported shader stage exceeds AMD's small-layout guideline
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Adapted from an upstream API-level check using Godot-visible evidence. It does not prove the Vulkan condition fired or predict saved milliseconds. On the actual Vulkan driver, fixed push-constant members plus the known descriptor-set layout count exceed upstream's 13-DWORD guideline. Push data costs one DWORD per four bytes and each set costs one DWORD; Godot includes gaps through the highest set index. Padding, dynamic-buffer costs and unsupported types are omitted. This is an AMD guideline, not a Vulkan limit, a measured bottleneck or proof that the shader is executed.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `BestPractices-AMD-CreatePipelinesLayout-KeepLayoutSmall` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_compute_amd_layout", "value": 1}}`
- **Mapping limits:** Adapted from an upstream API-level check using Godot-visible evidence. It does not prove the Vulkan condition fired or predict saved milliseconds. On the actual Vulkan driver, fixed push-constant members plus the known descriptor-set layout count exceed upstream's 13-DWORD guideline. Push data costs one DWORD per four bytes and each set costs one DWORD; Godot includes gaps through the highest set index. Padding, dynamic-buffer costs and unsupported types are omitted. This is an AMD guideline, not a Vulkan limit, a measured bottleneck or proof that the shader is executed.
- **GPU families:** amd
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/best_practices/bp_pipeline.cpp

### `gpu_best_practices.compute_nvidia_descriptor_space`

- **Title:** An imported shader stage exceeds NVIDIA's descriptor-space guideline
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Adapted from an upstream API-level check using Godot-visible evidence. It does not prove the Vulkan condition fired or predict saved milliseconds. On the actual Vulkan driver, known descriptors in one imported stage exceed upstream's 256-byte fast-space guideline: image/sampler descriptors cost four bytes, non-array uniform buffers eight and non-array storage buffers sixteen. Distinct set/binding pairs are counted once. Buffer arrays, unsupported and runtime-sized arrays are omitted, so this is a lower bound, not a complete pipeline layout size. Godot's checked Vulkan implementations create these descriptor set layouts without update-after-bind flags. This is a vendor guideline, not a Vulkan limit or measured cost.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `BestPractices-NVIDIA-CreatePipelineLayout-LargePipelineLayout` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_compute_nvidia_descriptor_space", "value": 1}}`
- **Mapping limits:** Adapted from an upstream API-level check using Godot-visible evidence. It does not prove the Vulkan condition fired or predict saved milliseconds. On the actual Vulkan driver, known descriptors in one imported stage exceed upstream's 256-byte fast-space guideline: image/sampler descriptors cost four bytes, non-array uniform buffers eight and non-array storage buffers sixteen. Distinct set/binding pairs are counted once. Buffer arrays, unsupported and runtime-sized arrays are omitted, so this is a lower bound, not a complete pipeline layout size. Godot's checked Vulkan implementations create these descriptor set layouts without update-after-bind flags. This is a vendor guideline, not a Vulkan limit or measured cost.
- **GPU families:** nvidia
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/best_practices/bp_pipeline.cpp

### `gpu_best_practices.compute_nvidia_separate_sampler`

- **Title:** An imported shader stage declares separate samplers on Vulkan/NVIDIA
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Adapted from an upstream API-level check using Godot-visible evidence. It does not prove the Vulkan condition fired or predict saved milliseconds. An imported shader stage has a UniformConstant variable whose type is a sampler or a fixed array of samplers. Godot reflects this as a separate sampler descriptor. The scanner requires the actual Vulkan rendering driver; D3D12, Metal and unknown drivers are excluded. A declaration does not prove the shader is executed or expensive, and upstream describes the potential benefit as marginal.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `BestPractices-NVIDIA-CreatePipelineLayout-SeparateSampler` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_compute_nvidia_separate_sampler", "value": 1}}`
- **Mapping limits:** Adapted from an upstream API-level check using Godot-visible evidence. It does not prove the Vulkan condition fired or predict saved milliseconds. An imported shader stage has a UniformConstant variable whose type is a sampler or a fixed array of samplers. Godot reflects this as a separate sampler descriptor. The scanner requires the actual Vulkan rendering driver; D3D12, Metal and unknown drivers are excluded. A declaration does not prove the shader is executed or expensive, and upstream describes the potential benefit as marginal.
- **GPU families:** nvidia
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/best_practices/bp_pipeline.cpp

### `gpu_best_practices.compute_arm_large`

- **Title:** Compute workgroups exceed Arm's 64-thread guideline
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Adapted from an upstream API-level check using Godot-visible evidence. It does not prove the Vulkan condition fired or predict saved milliseconds. Fixed local sizes are read from imported RDShaderFile compute SPIR-V. The exact upstream size predicate is used. Runtime-specialized sizes are skipped. A shader file can be unused; no dispatch or measured cost is asserted. GPU generations differ.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `BestPractices-Arm-vkCreateComputePipelines-compute-work-group-size` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_compute_arm_large", "value": 1}}`
- **Mapping limits:** Adapted from an upstream API-level check using Godot-visible evidence. It does not prove the Vulkan condition fired or predict saved milliseconds. Fixed local sizes are read from imported RDShaderFile compute SPIR-V. The exact upstream size predicate is used. Runtime-specialized sizes are skipped. A shader file can be unused; no dispatch or measured cost is asserted. GPU generations differ.
- **GPU families:** arm
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/best_practices/bp_pipeline.cpp

### `gpu_best_practices.compute_arm_alignment`

- **Title:** Compute workgroup dimensions miss Arm's four-thread alignment
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Adapted from an upstream API-level check using Godot-visible evidence. It does not prove the Vulkan condition fired or predict saved milliseconds. Fixed local sizes are read from imported RDShaderFile compute SPIR-V. The exact upstream size predicate is used. Runtime-specialized sizes are skipped. A shader file can be unused; no dispatch or measured cost is asserted. GPU generations differ.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `BestPractices-Arm-vkCreateComputePipelines-compute-thread-group-alignment` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_compute_arm_alignment", "value": 1}}`
- **Mapping limits:** Adapted from an upstream API-level check using Godot-visible evidence. It does not prove the Vulkan condition fired or predict saved milliseconds. Fixed local sizes are read from imported RDShaderFile compute SPIR-V. The exact upstream size predicate is used. Runtime-specialized sizes are skipped. A shader file can be unused; no dispatch or measured cost is asserted. GPU generations differ.
- **GPU families:** arm
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/best_practices/bp_pipeline.cpp

### `gpu_best_practices.compute_amd_alignment`

- **Title:** Compute workgroups are not multiples of 64 on AMD
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Adapted from an upstream API-level check using Godot-visible evidence. It does not prove the Vulkan condition fired or predict saved milliseconds. Fixed local sizes are read from imported RDShaderFile compute SPIR-V. The exact upstream size predicate is used. Runtime-specialized sizes are skipped. A shader file can be unused; no dispatch or measured cost is asserted. GPU generations differ.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `BestPractices-AMD-LocalWorkgroup-Multiple64` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "check_compute_amd_alignment", "value": 1}}`
- **Mapping limits:** Adapted from an upstream API-level check using Godot-visible evidence. It does not prove the Vulkan condition fired or predict saved milliseconds. Fixed local sizes are read from imported RDShaderFile compute SPIR-V. The exact upstream size predicate is used. Runtime-specialized sizes are skipped. A shader file can be unused; no dispatch or measured cost is asserted. GPU generations differ.
- **GPU families:** amd
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/best_practices/bp_pipeline.cpp

### `gpu_best_practices.double_buffer_vsync`

- **Title:** Double buffering with VSync deserves a pacing comparison
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Adapted from an upstream API-level check using Godot-visible evidence. It does not prove the Vulkan condition fired or predict saved milliseconds. Two swapchain images and enabled VSync are configured. The actual present mode and driver-selected image count are not observed.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `BestPractices-vkCreateSwapchainKHR-suboptimal-swapchain-image-count` (Godot adaptation, no layer required)
- **Observed condition:** `{"all": [{"setting_eq": {"path": "rendering/rendering_device/vsync/swapchain_image_count", "value": 2}}, {"setting_gt": {"path": "display/window/vsync/vsync_mode", "value": 0}}]}`
- **Mapping limits:** Adapted from an upstream API-level check using Godot-visible evidence. It does not prove the Vulkan condition fired or predict saved milliseconds. Two swapchain images and enabled VSync are configured. The actual present mode and driver-selected image count are not observed.
- **Setting:** `rendering/rendering_device/vsync/swapchain_image_count`
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/best_practices/bp_wsi.cpp

### `gpu_best_practices.arm_msaa8`

- **Title:** 8x MSAA on a GPU family with a 4x efficiency guideline
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Adapted from an upstream API-level check using Godot-visible evidence. It does not prove the Vulkan condition fired or predict saved milliseconds. The main viewport setting or a SubViewport uses 8x MSAA. Upstream's family-specific efficiency threshold is 4 samples; hardware revisions vary.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `BestPractices-Arm-vkCreateImage-too-large-sample-count` (Godot adaptation, no layer required)
- **Observed condition:** `{"any": [{"setting_eq": {"path": "rendering/anti_aliasing/quality/msaa_3d", "value": 3}}, {"scene_gte": {"name": "subviewport_msaa8_count", "value": 1}}]}`
- **Mapping limits:** Adapted from an upstream API-level check using Godot-visible evidence. It does not prove the Vulkan condition fired or predict saved milliseconds. The main viewport setting or a SubViewport uses 8x MSAA. Upstream's family-specific efficiency threshold is 4 samples; hardware revisions vary.
- **GPU families:** arm
- **Setting:** `rendering/anti_aliasing/quality/msaa_3d`
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/best_practices/bp_image.cpp

### `gpu_best_practices.imagination_msaa8`

- **Title:** 8x MSAA on a GPU family with a 4x efficiency guideline
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Adapted from an upstream API-level check using Godot-visible evidence. It does not prove the Vulkan condition fired or predict saved milliseconds. The main viewport setting or a SubViewport uses 8x MSAA. Upstream's family-specific efficiency threshold is 4 samples; hardware revisions vary.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `BestPractices-IMG-vkCreateImage-too-large-sample-count` (Godot adaptation, no layer required)
- **Observed condition:** `{"any": [{"setting_eq": {"path": "rendering/anti_aliasing/quality/msaa_3d", "value": 3}}, {"scene_gte": {"name": "subviewport_msaa8_count", "value": 1}}]}`
- **Mapping limits:** Adapted from an upstream API-level check using Godot-visible evidence. It does not prove the Vulkan condition fired or predict saved milliseconds. The main viewport setting or a SubViewport uses 8x MSAA. Upstream's family-specific efficiency threshold is 4 samples; hardware revisions vary.
- **GPU families:** imagination
- **Setting:** `rendering/anti_aliasing/quality/msaa_3d`
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/best_practices/bp_image.cpp

### `gpu_best_practices.arm_anisotropic_materials`

- **Title:** Anisotropic material samplers on Arm
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Adapted from an upstream API-level check using Godot-visible evidence. It does not prove the Vulkan condition fired or predict saved milliseconds. A BaseMaterial3D requests anisotropic filtering and the project level enables it. ShaderMaterial samplers are not inspected.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `BestPractices-Arm-vkCreateSampler-anisotropy` (Godot adaptation, no layer required)
- **Observed condition:** `{"all": [{"scene_gte": {"name": "anisotropic_material_count", "value": 1}}, {"setting_gt": {"path": "rendering/textures/default_filters/anisotropic_filtering_level", "value": 0}}]}`
- **Mapping limits:** Adapted from an upstream API-level check using Godot-visible evidence. It does not prove the Vulkan condition fired or predict saved milliseconds. A BaseMaterial3D requests anisotropic filtering and the project level enables it. ShaderMaterial samplers are not inspected.
- **GPU families:** arm
- **Node:** `BaseMaterial3D.texture_filter`
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/best_practices/bp_descriptor.cpp

### `gpu_best_practices.arm_mip_bias`

- **Title:** Manual mipmap bias on Arm
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Adapted from an upstream API-level check using Godot-visible evidence. It does not prove the Vulkan condition fired or predict saved milliseconds. The manual mipmap bias is nonzero. Godot may add automatic scaling/AA bias, so the final sampler bias is not known.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `BestPractices-Arm-vkCreateSampler-lod-bias` (Godot adaptation, no layer required)
- **Observed condition:** `{"setting_neq": {"path": "rendering/textures/default_filters/texture_mipmap_bias", "value": 0.0}}`
- **Mapping limits:** Adapted from an upstream API-level check using Godot-visible evidence. It does not prove the Vulkan condition fired or predict saved milliseconds. The manual mipmap bias is nonzero. Godot may add automatic scaling/AA bias, so the final sampler bias is not known.
- **GPU families:** arm
- **Setting:** `rendering/textures/default_filters/texture_mipmap_bias`
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/best_practices/bp_descriptor.cpp

### `gpu_best_practices.arm_msaa_blending`

- **Title:** Measure transparency together with MSAA on Arm
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Adapted from an upstream API-level check using Godot-visible evidence. It does not prove the Vulkan condition fired or predict saved milliseconds. MSAA and alpha-blended materials coexist in the scene. The actual attachment format, sample shading and per-pass render state are not exposed; this is a candidate for measurement only.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `BestPractices-Arm-vkCreatePipelines-multisampled-blending` (Godot adaptation, no layer required)
- **Observed condition:** `{"all": [{"setting_gt": {"path": "rendering/anti_aliasing/quality/msaa_3d", "value": 0}}, {"scene_gte": {"name": "transparent_alpha_blend_count", "value": 1}}]}`
- **Mapping limits:** Adapted from an upstream API-level check using Godot-visible evidence. It does not prove the Vulkan condition fired or predict saved milliseconds. MSAA and alpha-blended materials coexist in the scene. The actual attachment format, sample shading and per-pass render state are not exposed; this is a candidate for measurement only.
- **GPU families:** arm
- **Setting:** `rendering/anti_aliasing/quality/msaa_3d`
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/best_practices/bp_pipeline.cpp

### `gpu_best_practices.tile_keep_viewport`

- **Title:** A SubViewport retains its previous color contents
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Adapted from an upstream API-level check using Godot-visible evidence. It does not prove the Vulkan condition fired or predict saved milliseconds. A SubViewport uses CLEAR_MODE_NEVER. Preserving pixels can require attachment reads on tile GPUs; Render Lens does not see the generated load operations.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `BestPractices-vkCmdBeginRenderPass-attachment-needs-readback` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "subviewport_keep_count", "value": 1}}`
- **Mapping limits:** Adapted from an upstream API-level check using Godot-visible evidence. It does not prove the Vulkan condition fired or predict saved milliseconds. A SubViewport uses CLEAR_MODE_NEVER. Preserving pixels can require attachment reads on tile GPUs; Render Lens does not see the generated load operations.
- **GPU families:** arm, imagination
- **Node:** `SubViewport.render_target_clear_mode`
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/best_practices/bp_render_pass.cpp

### `gpu_best_practices.tile_small_meshes`

- **Title:** Many tiny indexed mesh surfaces on a tile GPU
- **Severity:** medium
- **Kind:** performance
- **Heuristic:** yes
- **Heuristic rationale:** Adapted from an upstream API-level check using Godot-visible evidence. It does not prove the Vulkan condition fired or predict saved milliseconds. At least ten visible MeshInstance3D surfaces have 1-10 indices each. This mirrors upstream's size/count thresholds but does not establish culling, instancing or command-buffer membership.
- **Renderers:** forward_plus, mobile
- **Godot versions:** 4.4, 4.5, 4.6, 4.7
- **Upstream idea:** `BestPractices-vkCmdDrawIndexed-many-small-indexed-drawcalls` (Godot adaptation, no layer required)
- **Observed condition:** `{"scene_gte": {"name": "small_indexed_surface_count", "value": 10}}`
- **Mapping limits:** Adapted from an upstream API-level check using Godot-visible evidence. It does not prove the Vulkan condition fired or predict saved milliseconds. At least ten visible MeshInstance3D surfaces have 1-10 indices each. This mirrors upstream's size/count thresholds but does not establish culling, instancing or command-buffer membership.
- **GPU families:** arm, imagination
- **Node:** `ArrayMesh surfaces / MeshInstance3D`
- **Source:** https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/99fd2cb5761410c0e8cd82395861abd75c9d1f06/layers/best_practices/bp_drawdispatch.cpp
