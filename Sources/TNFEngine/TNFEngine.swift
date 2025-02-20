// Copyright (c) 2025 The Noughy Fox
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import Engine
import MetalKit
import Utilities

struct Vertex {
    var position: vector_float4
    var color: vector_float4
}

public final class TNFEngine {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private let vertexBuffer: MTLBuffer
    private let indexBuffer: MTLBuffer
    private let indexCount: Int

    public init?() {
        // Use the shared Device instance from Engine module
        guard let engineDevice = Device.shared?.device,
            let commandQueue = engineDevice.makeCommandQueue()
        else { return nil }

        self.device = engineDevice
        self.commandQueue = commandQueue

        let vertices: [Vertex] = [
            Vertex(position: [0.0, 0.5, 0, 1.0], color: [1, 0, 0, 1]),
            Vertex(position: [-0.5, -0.5, 0, 1.0], color: [0, 1, 0, 1]),
            Vertex(position: [0.5, -0.5, 0, 1.0], color: [1, 0, 1, 1]),
        ]
        let indices: [UInt16] = [0, 1, 2]
        indexCount = indices.count

        guard
            let vBuffer = device.makeBuffer(
                bytes: vertices,
                length: MemoryLayout<Vertex>.stride * vertices.count,
                options: []),
            let iBuffer = device.makeBuffer(
                bytes: indices,
                length: MemoryLayout<UInt16>.stride * indices.count,
                options: [])
        else { return nil }
        vertexBuffer = vBuffer
        indexBuffer = iBuffer

        let shaderSource = """
            #include <metal_stdlib>
            using namespace metal;
            struct Vertex {
                float4 position [[attribute(0)]];
                float4 color [[attribute(1)]];
            };
            struct VOut {
                float4 position [[position]];
                float4 color;
            };
            vertex VOut vertex_main(const device Vertex *vertices [[buffer(0)]], uint vid [[vertex_id]]) {
                VOut out;
                out.position = vertices[vid].position;
                out.color = vertices[vid].color;
                return out;
            }
            fragment float4 fragment_main(VOut in [[stage_in]]) {
                return in.color;
            }
            """
        do {

            let library = try device.makeLibrary(source: shaderSource, options: nil)
            let vertexFunction = library.makeFunction(name: "vertex_main")
            let fragmentFunction = library.makeFunction(name: "fragment_main")
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            return nil
        }
    }

    public func start() {
        Log.info("TNFEngine started")
    }

    public func resize(to size: CGSize) {
        Log.info("Viewport resized to: \(size)")
    }

    public func getMetalDevice() -> MTLDevice {
        return device
    }

    @MainActor
    public func update(view: MTKView) {
        guard let drawable = view.currentDrawable,
            let renderPassDescriptor = view.currentRenderPassDescriptor,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let commandEncoder = commandBuffer.makeRenderCommandEncoder(
                descriptor: renderPassDescriptor)
        else { return }
        commandEncoder.setRenderPipelineState(pipelineState)
        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder.drawIndexedPrimitives(
            type: .triangle, indexCount: indexCount, indexType: .uint16, indexBuffer: indexBuffer,
            indexBufferOffset: 0)
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
