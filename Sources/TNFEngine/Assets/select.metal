//
// Created by toor on 2025-02-26.
//

#include <metal_stdlib>
using namespace metal;

// Simple vertex shader for 2D selection rendering
vertex float4 selectionVertexShader(uint vertex_id [[vertex_id]],
                                    const device float2 *vertices
                                    [[buffer(0)]]) {
  // Simply pass through the vertex position in NDC space
  return float4(vertices[vertex_id], 0.0, 1.0);
}

// Simple fragment shader for selection rendering
fragment float4 selectionFragmentShader(constant float4 &color [[buffer(0)]]) {
  // Output the specified color (either fill or outline)
  return color;
}
