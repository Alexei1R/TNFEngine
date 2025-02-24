//
// Created by toor on 2025-02-24.
//

#include <metal_stdlib>
using namespace metal;

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
  float3x3 normalMatrix;
  float3 lightDirection;
  float3 lightColor;
};

vertex VertexOut vertex_main(const device Vertex *vertices [[buffer(0)]],
                             constant Uniforms &uniforms [[buffer(1)]],
                             uint vid [[vertex_id]]) {
  VertexOut out;
  float4 pos = float4(vertices[vid].position, 1.0);
  out.position = uniforms.modelViewProjectionMatrix * pos;
  out.normal = uniforms.normalMatrix * vertices[vid].normal;
  return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              constant Uniforms &uniforms [[buffer(1)]]) {
  float3 N = normalize(in.normal);
  float3 L = normalize(uniforms.lightDirection);
  float diff = max(dot(N, L), 0.0);
  float3 ambient = 0.2 * uniforms.lightColor;
  float3 diffuse = diff * uniforms.lightColor;
  return float4(ambient + diffuse, 1.0);
}

fragment float4 fragment_outline_main(VertexOut in [[stage_in]]) {
  // Render a solid orange color for the outline.
  return float4(1.0, 0.5, 0.0, 1.0);
}
