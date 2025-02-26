//
// Created by toor on 2025-02-25.
//

#include <metal_stdlib>
using namespace metal;

float3x3 inverse3x3(float3x3 m) {
  float3 a = m[0];
  float3 b = m[1];
  float3 c = m[2];
  float3 r0 = cross(b, c);
  float3 r1 = cross(c, a);
  float3 r2 = cross(a, b);
  float det = dot(a, r0);
  return float3x3(r0 / det, r1 / det, r2 / det);
}

struct Vertex {
  float3 position [[attribute(0)]];
  float3 normal [[attribute(1)]];
  float2 texCoord [[attribute(2)]];
  float3 tangent [[attribute(3)]];
  float3 bitangent [[attribute(4)]];
};

struct VertexOut {
  float4 position [[position]];
  float3 normal;
};

struct Uniforms {
  float4x4 modelViewProjectionMatrix;
  float4x4 modelMatrix;
  float3 lightDirection;
  float3 lightColor;
  float3 cameraPosition;
};

struct Material {
  float4 albedo;            // 16 bytes
  float4 emission;          // 16 bytes
  float metallic;           // 4 bytes
  float roughness;          // 4 bytes
  float clearCoat;          // 4 bytes
  float clearCoatRoughness; // 4 bytes
  float transmission;       // 4 bytes
  float ior;                // 4 bytes
} __attribute__((packed));

vertex VertexOut vertex_main(const device Vertex *vertices [[buffer(0)]],
                             constant Uniforms &uniforms [[buffer(1)]],
                             uint vid [[vertex_id]]) {
  VertexOut out;
  float4 pos = float4(vertices[vid].position, 1.0);
  out.position = uniforms.modelViewProjectionMatrix * pos;
  float3x3 normalMatrix =
      float3x3(uniforms.modelMatrix[0].xyz, uniforms.modelMatrix[1].xyz,
               uniforms.modelMatrix[2].xyz);
  normalMatrix = transpose(inverse3x3(normalMatrix));
  out.normal = normalMatrix * vertices[vid].normal;
  return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              constant Uniforms &uniforms [[buffer(1)]],
                              constant Material &material [[buffer(2)]]

) {

  float3 N = normalize(in.normal);
  float3 L = normalize(uniforms.lightDirection);
  float diff = max(dot(N, L), 0.0);
  float3 ambient = 0.2 * uniforms.lightColor;
  float3 diffuse = diff * uniforms.lightColor;
  return float4(ambient + diffuse, 1.0) * material.albedo;
}
