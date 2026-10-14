`video_checks.ogv` is a 32x32, six-frame synthetic test pattern generated for these tests. It contains no audio or external media. Regeneration requires FFmpeg; running the tests does not:

```
ffmpeg -f lavfi -i testsrc2=size=32x32:rate=6:duration=1 -an -c:v libtheora -q:v 2 video_checks.ogv
```

`cooperative_outer_float32_row.spv` and `cooperative_outer_float16_training.spv` are unmodified compute-stage output from Godot 4.7.2 official `ed1daf0bf`, compiled with `RenderingDevice.shader_compile_spirv_from_source`. Tests only parse/import these bytes; they never create shaders or pipelines from them. The first intentionally violates the float16-input and training-optimal-layout requirements; passing the second's intrinsic checks does not establish device support or complete memory/pipeline validity. Godot 4.4 rejects the ordinary GLSL extension, so the saved bytes provide compiler-produced parser/import fixtures for both versions.

Regenerate each with this source, substituting `TYPE=float`, `LAYOUT=0` for the invalid fixture and `TYPE=float16_t`, `LAYOUT=3` for the intrinsic control. Save `RDShaderSPIRV.bytecode_compute` as bytes.

```glsl
#version 460
#extension GL_NV_cooperative_vector : require
#extension GL_EXT_shader_explicit_arithmetic_types_float16 : require
#extension GL_EXT_shader_16bit_storage : require
layout(local_size_x=1) in;
layout(set=0,binding=0,std430) buffer Output { TYPE data[]; };
void main() {
    coopvecNV<TYPE,4> a = coopvecNV<TYPE,4>(TYPE(1));
    coopvecNV<TYPE,4> b = a;
    coopVecOuterProductAccumulateNV(a,b,data,0u,16u,LAYOUT,gl_ComponentTypeFloat16NV);
}
```

- Float32/row-major fixture: 1068 bytes, SHA-256 `f135b8315888f113b50fc60fb573a5a47ba7eb0cdb7760bc472776f334148d2d`.
- Float16/training-optimal fixture: 1100 bytes, SHA-256 `7b5a8644280fa36fe5b4b7726099603aaab140207968f11241716c25b6faad25`.

## Intrinsic cooperative accumulation and tensor declarations (1.24)

These modules were compiled by Godot 4.7.2 `ed1daf0bf` through `RenderingDevice.shader_compile_spirv_from_source`; no shader or pipeline was created. Companion `.source.txt` files reproduce the cooperative semantics. Their whitespace can differ from the original probe, so byte-for-byte recompilation is not promised. Godot 4.4 rejects ordinary cooperative-vector and tensor GLSL; both versions inspect the original saved bytecode.

| Fixture | Bytes | SHA-256 |
| --- | ---: | --- |
| `cooperative_reduce_int32.spv` | 952 | `057a102394a4047b55063b09407ef4ccd6f534d36263414e19aaf4a8af63e3d4` |
| `cooperative_reduce_float32.spv` | 964 | `9dcf1dd8d59080d49bbab52395b3e86d993465a33c208f019a1bf38a2af1c746` |
| `cooperative_outer_interpretation5.spv` | 1060 | `2ef77851d49679d2086110ea2ce821c39884b8bd0a638ba7d7486e32fe93fc0b` |
| `cooperative_outer_workgroup.spv` | 880 | `1d9cec8c9ba57a36f752571e4732edf180141455e934ea2c8e22c7ae49c13b6a` |
| `cooperative_reduce_private.spv` | 800 | `6e329a7573620f146912d761f099d12077c8447f6a1c708a2929dbeedc1f49ea` |
| `cooperative_matmul_fp8_row.spv` | 1180 | `5e96de6fc47169471c80e98d1584dbd0978f3662a152932de8ab971477d52724` |
| `cooperative_matmul_fp8_training.spv` | 1196 | `e75d4ade0d405b07c751b10c2c34a8dfb6040b0a54a8558cdef330f025e662b7` |
| `tensor_ranked.spv` | 932 | `8fdf46221dca59bbcea88e18a2b4ae363513ecd14081d87bc0c6eba18c444bc8` |

The reduction float32 and FP8 training-layout modules are controls for these intrinsic restrictions; they do not establish device support. The other cooperative modules isolate non-float reduction components, accumulation interpretation 5, Workgroup/Private destinations and FP8 row-major storage. `tensor_ranked.spv` is a compiled `tensorARM<int,1>` read into an SSBO using `GL_ARM_tensors`. Tests derive the missing-rank and explicit-shape declaration forms in memory; these are fixture mutations, not a claim that the ordinary compiler emits them. Native tensors, feature/property tables, memory alignment/safety and full Vulkan validity are not established. Never submit the invalid fixtures to a shader or pipeline.
