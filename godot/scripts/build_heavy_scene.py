#!/usr/bin/env python3
"""Write sample_project/heavy_test.tscn and a 3072px lossless albedo.

The scene is a Forward+ stress case: cube-shadow omnis, shadowed spots,
a PSSM directional, a MultiMesh of a high-segment sphere, many MeshInstance3D
nodes with no visibility range, stacked alpha-blend quads, SSAO, SSIL, SSR,
volumetric fog, SDFGI, DOF, GPU and CPU particles, and a large lossless texture.
"""

import os
import struct
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJECT = os.path.join(ROOT, "sample_project")
PNG_NAME = "heavy_albedo.png"
TEX_SIZE = 3072


def png_bytes(width, height):
    raw = bytearray()
    for y in range(height):
        raw.append(0)
        g = (y * 255) // (height - 1)
        for x in range(width):
            raw.append((x * 255) // (width - 1))
            raw.append(g)
            raw.append(160)
    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")


def xf(x, y, z):
    return "Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s, %s, %s)" % (x, y, z)


def main():
    png_path = os.path.join(PROJECT, PNG_NAME)
    with open(png_path, "wb") as handle:
        handle.write(png_bytes(TEX_SIZE, TEX_SIZE))

    subs = []
    nodes = []

    def sub(type_name, body, sid):
        subs.append('[sub_resource type="%s" id="%s"]\n%s' % (type_name, sid, body.rstrip()))
        return sid

    sub("Environment", """
background_mode = 1
background_color = Color(0.08, 0.09, 0.12, 1)
ambient_light_source = 2
ambient_light_color = Color(0.25, 0.27, 0.32, 1)
tonemap_mode = 2
ssao_enabled = true
ssil_enabled = true
ssr_enabled = true
ssr_max_steps = 96
glow_enabled = true
volumetric_fog_enabled = true
volumetric_fog_density = 0.05
sdfgi_enabled = true
""", "Environment_heavy")
    sub("CameraAttributesPractical", """
dof_blur_far_enabled = true
dof_blur_far_distance = 12.0
dof_blur_far_transition = 4.0
""", "CameraAttributes_heavy")
    sub("SphereMesh", """
radius = 0.45
height = 0.9
radial_segments = 48
rings = 24
""", "SphereMesh_dense")
    sub("SphereMesh", """
radius = 0.08
height = 0.16
radial_segments = 8
rings = 4
""", "SphereMesh_particle")
    sub("BoxMesh", "size = Vector3(28, 0.2, 28)\n", "BoxMesh_ground")
    sub("StandardMaterial3D", """
transparency = 1
albedo_color = Color(0.55, 0.75, 1, 0.35)
cull_mode = 2
""", "Material_alpha")
    sub("QuadMesh", """
material = SubResource("Material_alpha")
size = Vector2(8, 5)
""", "QuadMesh_alpha")
    sub("StandardMaterial3D", 'albedo_texture = ExtResource("1_albedo")\n', "Material_albedo")
    sub("BoxMesh", """
material = SubResource("Material_albedo")
size = Vector3(2, 2, 2)
""", "BoxMesh_albedo")
    sub("BoxShape3D", "size = Vector3(1, 1, 1)\n", "BoxShape_1")

    buffer = []
    for i in range(64):
        x = -7.0 + (i % 8) * 2.0
        z = -7.0 + (i // 8) * 2.0
        buffer.extend([1, 0, 0, 0, 1, 0, 0, 0, 1, x, 0.45, z])
    sub("MultiMesh", """
transform_format = 1
instance_count = 64
mesh = SubResource("SphereMesh_dense")
buffer = PackedFloat32Array(%s)
""" % ", ".join(str(v) for v in buffer), "MultiMesh_dense")

    nodes.append('[node name="HeavyTest" type="Node3D"]')
    nodes.append("""
[node name="WorldEnvironment" type="WorldEnvironment" parent="."]
environment = SubResource("Environment_heavy")
""")
    nodes.append("""
[node name="Camera3D" type="Camera3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 0.866025, 0.5, 0, -0.5, 0.866025, 0, 7, 16)
current = true
far = 4000.0
attributes = SubResource("CameraAttributes_heavy")
""")
    nodes.append("""
[node name="DirectionalLight3D" type="DirectionalLight3D" parent="."]
transform = Transform3D(0.866025, -0.353553, 0.353553, 0, 0.707107, 0.707107, -0.5, -0.612372, 0.612372, 0, 8, 0)
shadow_enabled = true
directional_shadow_mode = 2
directional_shadow_max_distance = 180.0
""")
    nodes.append('[node name="OmniLights" type="Node3D" parent="."]')
    for i in range(8):
        angle = i * 45.0
        import math
        x = round(math.cos(math.radians(angle)) * 6.0, 3)
        z = round(math.sin(math.radians(angle)) * 6.0, 3)
        nodes.append("""
[node name="Omni%s" type="OmniLight3D" parent="OmniLights"]
transform = %s
light_energy = 1.4
shadow_enabled = true
omni_range = 14.0
omni_shadow_mode = 1
""" % (i + 1, xf(x, 2.2, z)))
    nodes.append('[node name="SpotLights" type="Node3D" parent="."]')
    for i in range(6):
        x = -5.0 + i * 2.0
        nodes.append("""
[node name="Spot%s" type="SpotLight3D" parent="SpotLights"]
transform = Transform3D(1, 0, 0, 0, -0.5, 0.866025, 0, -0.866025, -0.5, %s, 6, 0)
light_energy = 2.0
shadow_enabled = true
spot_range = 16.0
spot_angle = 50.0
""" % (i + 1, x))
    nodes.append("""
[node name="Ground" type="MeshInstance3D" parent="."]
mesh = SubResource("BoxMesh_ground")
""")
    nodes.append("""
[node name="AlbedoBox" type="MeshInstance3D" parent="."]
transform = %s
mesh = SubResource("BoxMesh_albedo")
lod_bias = 2.0
""" % xf(0, 1.2, -2))
    nodes.append('[node name="DenseMeshes" type="Node3D" parent="."]')
    for i in range(36):
        x = -5.0 + (i % 6) * 2.0
        z = -5.0 + (i // 6) * 2.0
        nodes.append("""
[node name="Mesh%s" type="MeshInstance3D" parent="DenseMeshes"]
transform = %s
mesh = SubResource("SphereMesh_dense")
lod_bias = 2.0
""" % (i + 1, xf(x, 1.6, z)))
    nodes.append("""
[node name="DenseMultiMesh" type="MultiMeshInstance3D" parent="."]
multimesh = SubResource("MultiMesh_dense")
""")
    nodes.append('[node name="Overdraw" type="Node3D" parent="."]')
    for i in range(10):
        nodes.append("""
[node name="Quad%s" type="MeshInstance3D" parent="Overdraw"]
transform = %s
mesh = SubResource("QuadMesh_alpha")
""" % (i + 1, xf(0, 2.0 + i * 0.05, 3.0 - i * 0.15)))
    nodes.append('[node name="Particles" type="Node3D" parent="."]')
    for i in range(4):
        extra = "trail_enabled = true\n" if i == 0 else ""
        amount = 1024 if i == 0 else 2048
        nodes.append("""
[node name="GPU%s" type="GPUParticles3D" parent="Particles"]
transform = %s
amount = %s
lifetime = 1.2
%sdraw_pass_1 = SubResource("SphereMesh_particle")
""" % (i + 1, xf(-3.0 + i * 2.0, 2.0, 1.0), amount, extra))
    nodes.append("""
[node name="CPUSparks" type="CPUParticles3D" parent="Particles"]
transform = %s
amount = 256
mesh = SubResource("SphereMesh_particle")
""" % xf(0, 1.5, 2))
    nodes.append("""
[node name="ReflectionProbe" type="ReflectionProbe" parent="."]
transform = %s
update_mode = 1
size = Vector3(24, 10, 24)
""" % xf(0, 2, 0))
    nodes.append('[node name="Decals" type="Node3D" parent="."]')
    for i in range(4):
        nodes.append("""
[node name="Decal%s" type="Decal" parent="Decals"]
transform = %s
size = Vector3(2, 2, 2)
""" % (i + 1, xf(-3.0 + i * 2.0, 0.3, 4)))
    nodes.append('[node name="Physics" type="Node3D" parent="."]')
    for i in range(4):
        nodes.append("""
[node name="Body%s" type="StaticBody3D" parent="Physics"]
transform = %s

[node name="Shape" type="CollisionShape3D" parent="Physics/Body%s"]
shape = SubResource("BoxShape_1")
""" % (i + 1, xf(-2.0 + i * 1.5, 0.5, -6), i + 1))
    nodes.append("""
[node name="Canvas" type="CanvasLayer" parent="."]

[node name="Fill" type="PointLight2D" parent="Canvas"]
shadow_enabled = true
shadow_filter = 2
""")

    ext = 1
    load_steps = ext + len(subs) + 1
    text = ['[gd_scene load_steps=%d format=3]' % load_steps, ""]
    text.append('[ext_resource type="Texture2D" path="res://%s" id="1_albedo"]' % PNG_NAME)
    text.append("")
    text.append("\n\n".join(subs))
    text.append("")
    text.append("\n".join(nodes))
    text.append("")
    out = os.path.join(PROJECT, "heavy_test.tscn")
    with open(out, "w", encoding="utf-8") as handle:
        handle.write("\n".join(text))
    print("wrote", out, "subs", len(subs), "png", os.path.getsize(png_path))


if __name__ == "__main__":
    main()
