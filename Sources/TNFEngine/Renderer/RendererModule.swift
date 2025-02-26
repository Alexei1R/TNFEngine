// Copyright (c) 2025 The Noughy Fox
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import MetalKit
import Utilities
import simd

struct Uniforms {
    var modelViewProjectionMatrix: mat4f
    var modelMatrix: mat4f
    var lightDirection: vec3f
    var lightColor: vec3f
}

public final class Renderer: Module {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private let depthStencilState: MTLDepthStencilState
    private let vertexBuffer: MTLBuffer
    private let indexBuffer: MTLBuffer
    private let indexCount: Int
    private var camera: Camera
    private var modelMatrix: mat4f

    public init() {
        // NOTE: Initialize Metal device and setup basic components
        guard let device = Device.shared?.device,
            let queue = device.makeCommandQueue()
        else { fatalError() }
        self.device = device
        self.commandQueue = queue

        let depthDesc = MTLDepthStencilDescriptor()
        depthDesc.depthCompareFunction = .lessEqual
        depthDesc.isDepthWriteEnabled = true
        guard let depthState = device.makeDepthStencilState(descriptor: depthDesc)
        else { fatalError() }
        self.depthStencilState = depthState

        camera = Camera.createDefaultCamera()
        modelMatrix = mat4f.identity
            .rotateDegrees(-90, axis: .x)
            .scale(0.01)
            .translate(-vec3f.up)

        // Setup mesh data - initialize these properties directly
        let meshData = Self.createMeshData(device: device)
        self.vertexBuffer = meshData.0
        self.indexBuffer = meshData.1
        self.indexCount = meshData.2

        // Create render pipeline - initialize this property directly
        self.pipelineState = Self.createRenderPipeline(device: device)
    }

    // NOTE: Setup 3D model and create GPU buffers - changed to static method
    private static func createMeshData(device: MTLDevice) -> (MTLBuffer, MTLBuffer, Int) {
        guard let path = Bundle.main.path(forResource: "model", ofType: "usdc")
        else { fatalError() }
        let url = URL(fileURLWithPath: path)
        let model3D = Model3D()
        try! model3D.load(from: url)
        guard let mesh = model3D.meshes.first,
            let meshData = model3D.extractMeshData(from: mesh)
        else { fatalError() }

        guard
            let vBuffer = device.makeBuffer(
                bytes: meshData.vertices,
                length: MemoryLayout<StaticModelVertex>.stride * meshData.vertices.count,
                options: []),
            let iBuffer = device.makeBuffer(
                bytes: meshData.indices,
                length: MemoryLayout<UInt32>.stride * meshData.indices.count,
                options: [])
        else { fatalError() }

        return (vBuffer, iBuffer, meshData.indices.count)
    }

    // NOTE: Configure render pipeline with shaders and vertex layout - changed to static method
    private static func createRenderPipeline(device: MTLDevice) -> MTLRenderPipelineState {
        let pipelineDesc = MTLRenderPipelineDescriptor()

        let staticModelShaderLayout = ShaderLayout(elements: [
            ShaderElement(type: .vertex, data: "vertex_main"),
            ShaderElement(type: .fragment, data: "fragment_main"),
        ])

        do {
            let shaderHandle = try ShaderManager.shared.loadShader(layout: staticModelShaderLayout)
            if let shaderHandle = ShaderManager.shared.getShader(shaderHandle) {
                pipelineDesc.vertexFunction = shaderHandle.function(of: .vertex)
                pipelineDesc.fragmentFunction = shaderHandle.function(of: .fragment)
                Log.info("Setting up the shaders")
            }
        } catch {
            Log.error(
                "Can't load shader 🤓, make sure the shader exists in bundle, ERROR \n [\(error)]")
        }

        let staticModelVertexLayout = BufferLayout(elements: [
            BufferElement(type: .float3, name: "position"),
            BufferElement(type: .float3, name: "normal"),
            BufferElement(type: .float2, name: "texCoord"),
            BufferElement(type: .float3, name: "tangent"),
            BufferElement(type: .float3, name: "bitangent"),
        ])

        pipelineDesc.vertexDescriptor = staticModelVertexLayout.metalVertexDescriptor(
            bufferIndex: 0)
        pipelineDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDesc.depthAttachmentPixelFormat = .depth32Float

        return try! device.makeRenderPipelineState(descriptor: pipelineDesc)
    }

    // NOTE: Handle render pass setup
    @MainActor
    private func createRenderPass(for view: MTKView) -> RenderPassDescriptor {
        // Create a color attachment descriptor for the drawable's texture
        let colorAttachment = ColorAttachmentDescriptor(
            texture: view.currentDrawable?.texture,
            loadAction: .clear,
            storeAction: .store,
            clearColor: MTLClearColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        )

        // Create a depth attachment descriptor for the depth buffer
        let depthAttachment = DepthAttachmentDescriptor(
            texture: view.depthStencilTexture,
            loadAction: .clear,
            storeAction: .dontCare,
            clearDepth: 1.0
        )

        // Build the render pass configuration
        let config = RenderPassBuilder()
            .addColorAttachment(colorAttachment)
            .setDepthAttachment(depthAttachment)
            .setSampleCount(view.sampleCount)
            .build()

        return RenderPassDescriptor(config: config)
    }

    // NOTE: Handle drawing
    @MainActor
    public func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
            let commandBuffer = commandQueue.makeCommandBuffer()
        else { return }
        let renderPass = createRenderPass(for: view)
        let mtlRenderPassDescriptor = renderPass.getMTLRenderPassDescriptor()

        guard
            let encoder = commandBuffer.makeRenderCommandEncoder(
                descriptor: mtlRenderPassDescriptor)
        else { return }

        // Prepare uniforms
        let viewProj = camera.getViewProjectionMatrix()
        var uniforms = Uniforms(
            modelViewProjectionMatrix: viewProj * modelMatrix,
            modelMatrix: modelMatrix,
            lightDirection: vec3f(10, 10, 10),
            lightColor: vec3f(1, 1, 1)
        )

        // Set render state and draw
        encoder.setRenderPipelineState(pipelineState)
        encoder.setDepthStencilState(depthStencilState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        encoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: indexCount,
            indexType: .uint32,
            indexBuffer: indexBuffer,
            indexBufferOffset: 0)

        // Finalize rendering
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    public func resize(to size: CGSize) {
        camera.setAspectRatio(Float(size.width / size.height))
    }

    public func update(dt: Float) {}

    public func handle(_ event: EventType) async {
        guard let touchEvent = event as? TouchEvent else { return }
        switch touchEvent.type {
        case .tap: break
        case .drag:
            camera.orbit(
                deltaTheta: touchEvent.delta.x * 0.015,
                deltaPhi: touchEvent.delta.y * 0.015)
        case .scale:
            camera.zoom(delta: touchEvent.scale)
        case .rotate: break
        case .resize: break
        case .translate:
            camera.moveInPlane(
                deltaX: touchEvent.delta.x * 0.008,
                deltaY: touchEvent.delta.y * 0.008)
        }
    }
}
