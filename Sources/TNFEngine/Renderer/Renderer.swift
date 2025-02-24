//
// Copyright (c) 2025 The Noughy Fox
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import MetalKit
import Utilities
import simd

struct Uniforms {
    var modelViewProjectionMatrix: matrix_float4x4
    var modelMatrix: matrix_float4x4
    var normalMatrix: matrix_float3x3
    var lightDirection: SIMD3<Float>
    var lightColor: SIMD3<Float>
}

public final class Renderer: Module {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private let outlinePipelineState: MTLRenderPipelineState
    private let depthStencilNormalState: MTLDepthStencilState
    private let depthStencilOutlineState: MTLDepthStencilState
    private let vertexBuffer: MTLBuffer
    private let indexBuffer: MTLBuffer
    private let indexCount: Int
    private var camera: Camera
    private var modelMatrix: mat4f

    public init() {
        guard let device = Device.shared?.device,
            let queue = device.makeCommandQueue()
        else { fatalError() }
        self.device = device
        self.commandQueue = queue

        // Make sure the MTKView is configured with:
        // view.colorPixelFormat = .bgra8Unorm
        // view.depthStencilPixelFormat = .depth32Float_stencil8
        let colorPixelFormat: MTLPixelFormat = .bgra8Unorm
        let depthStencilPixelFormat: MTLPixelFormat = .depth32Float_stencil8

        // --- Normal Pass Depth/Stencil State ---
        // In the normal pass we want every drawn fragment to write a stencil value of 1.
        let normalDepthStencilDesc = MTLDepthStencilDescriptor()
        normalDepthStencilDesc.depthCompareFunction = .lessEqual
        normalDepthStencilDesc.isDepthWriteEnabled = true
        let normalStencilDesc = MTLStencilDescriptor()
        normalStencilDesc.stencilCompareFunction = .always
        // On a successful depth & stencil test, replace the stencil buffer value with the reference value (1)
        normalStencilDesc.stencilFailureOperation = .keep
        normalStencilDesc.depthFailureOperation = .keep
        normalStencilDesc.depthStencilPassOperation = .replace
        normalStencilDesc.readMask = 0xFF
        normalStencilDesc.writeMask = 0xFF
        normalDepthStencilDesc.frontFaceStencil = normalStencilDesc
        normalDepthStencilDesc.backFaceStencil = normalStencilDesc
        guard let normalState = device.makeDepthStencilState(descriptor: normalDepthStencilDesc)
        else { fatalError() }
        self.depthStencilNormalState = normalState

        // --- Outline Pass Depth/Stencil State ---
        // In the outline pass we only want to render pixels where the stencil is not equal to 1.
        // This will render the scaled-up object only at the border (where the normal model was not drawn).
        let outlineDepthStencilDesc = MTLDepthStencilDescriptor()
        outlineDepthStencilDesc.depthCompareFunction = .lessEqual
        outlineDepthStencilDesc.isDepthWriteEnabled = false
        let outlineStencilDesc = MTLStencilDescriptor()
        outlineStencilDesc.stencilCompareFunction = .notEqual
        outlineStencilDesc.stencilFailureOperation = .keep
        outlineStencilDesc.depthFailureOperation = .keep
        outlineStencilDesc.depthStencilPassOperation = .keep
        outlineStencilDesc.readMask = 0xFF
        outlineStencilDesc.writeMask = 0x00
        outlineDepthStencilDesc.frontFaceStencil = outlineStencilDesc
        outlineDepthStencilDesc.backFaceStencil = outlineStencilDesc
        guard let outlineState = device.makeDepthStencilState(descriptor: outlineDepthStencilDesc)
        else { fatalError() }
        self.depthStencilOutlineState = outlineState

        // Setup camera and model transform.
        camera = Camera(
            position: vec3f(0, 0, -3),
            target: vec3f(0, 0, 0),
            up: vec3f(0, 1, 0),
            fieldOfView: Float.pi / 3,
            aspectRatio: 1.0,
            nearPlane: 0.1,
            farPlane: 1000.0
        )
        // Build the model matrix (rotate, scale, then translate).
        modelMatrix = mat4f.identity
            .rotateDegrees(-90, axis: .x)
            .scale(0.01)

        // Load the model from file.
        guard let path = Bundle.main.path(forResource: "model", ofType: "usdc") else {
            fatalError()
        }
        let url = URL(fileURLWithPath: path)
        let model3D = Model3D()
        try! model3D.load(from: url)
        guard let mesh = model3D.meshes.first,
            let meshData = model3D.extractMeshData(from: mesh)
        else { fatalError() }
        indexCount = meshData.indices.count

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
        vertexBuffer = vBuffer
        indexBuffer = iBuffer

        // --- Setup Shader Library ---
        let shaderSource = """
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
                                         uint vid [[vertex_id]])
            {
                VertexOut out;
                float4 pos = float4(vertices[vid].position, 1.0);
                out.position = uniforms.modelViewProjectionMatrix * pos;
                out.normal = uniforms.normalMatrix * vertices[vid].normal;
                return out;
            }

            fragment float4 fragment_main(VertexOut in [[stage_in]],
                                          constant Uniforms &uniforms [[buffer(1)]])
            {
                float3 N = normalize(in.normal);
                float3 L = normalize(uniforms.lightDirection);
                float diff = max(dot(N, L), 0.0);
                float3 ambient = 0.2 * uniforms.lightColor;
                float3 diffuse = diff * uniforms.lightColor;
                return float4(ambient + diffuse, 1.0);
            }

            fragment float4 fragment_outline_main(VertexOut in [[stage_in]])
            {
                // Render a solid orange color for the outline.
                return float4(1.0, 0.5, 0.0, 1.0);
            }
            """
        let library = try! device.makeLibrary(source: shaderSource, options: nil)
        let vertexFunction = library.makeFunction(name: "vertex_main")!
        let fragmentFunction = library.makeFunction(name: "fragment_main")!
        let outlineFragmentFunction = library.makeFunction(name: "fragment_outline_main")!

        // --- Setup Vertex Descriptor ---
        let vertexDesc = MTLVertexDescriptor()
        vertexDesc.attributes[0].format = .float3
        vertexDesc.attributes[0].offset = 0
        vertexDesc.attributes[0].bufferIndex = 0
        vertexDesc.attributes[1].format = .float3
        vertexDesc.attributes[1].offset = MemoryLayout<SIMD3<Float>>.stride
        vertexDesc.attributes[1].bufferIndex = 0
        vertexDesc.attributes[2].format = .float2
        vertexDesc.attributes[2].offset = MemoryLayout<SIMD3<Float>>.stride * 2
        vertexDesc.attributes[2].bufferIndex = 0
        vertexDesc.attributes[3].format = .float3
        vertexDesc.attributes[3].offset =
            MemoryLayout<SIMD3<Float>>.stride * 2 + MemoryLayout<SIMD2<Float>>.stride
        vertexDesc.attributes[3].bufferIndex = 0
        vertexDesc.attributes[4].format = .float3
        vertexDesc.attributes[4].offset =
            MemoryLayout<SIMD3<Float>>.stride * 3 + MemoryLayout<SIMD2<Float>>.stride
        vertexDesc.attributes[4].bufferIndex = 0
        vertexDesc.layouts[0].stride = MemoryLayout<StaticModelVertex>.stride

        // --- Create Render Pipeline for Normal Object ---
        let pipelineDesc = MTLRenderPipelineDescriptor()
        pipelineDesc.vertexFunction = vertexFunction
        pipelineDesc.fragmentFunction = fragmentFunction
        pipelineDesc.vertexDescriptor = vertexDesc
        pipelineDesc.colorAttachments[0].pixelFormat = colorPixelFormat
        pipelineDesc.depthAttachmentPixelFormat = depthStencilPixelFormat
        pipelineDesc.stencilAttachmentPixelFormat = depthStencilPixelFormat
        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDesc)

        // --- Create Render Pipeline for Outline ---
        let outlinePipelineDesc = MTLRenderPipelineDescriptor()
        outlinePipelineDesc.vertexFunction = vertexFunction
        outlinePipelineDesc.fragmentFunction = outlineFragmentFunction
        outlinePipelineDesc.vertexDescriptor = vertexDesc
        outlinePipelineDesc.colorAttachments[0].pixelFormat = colorPixelFormat
        outlinePipelineDesc.depthAttachmentPixelFormat = depthStencilPixelFormat
        outlinePipelineDesc.stencilAttachmentPixelFormat = depthStencilPixelFormat
        outlinePipelineState = try! device.makeRenderPipelineState(descriptor: outlinePipelineDesc)
    }

    @MainActor
    public func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
            let descriptor = view.currentRenderPassDescriptor,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else { return }

        // Clear background and depth/stencil values.
        descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.1, 0.1, 0.1, 1.0)
        descriptor.depthAttachment.clearDepth = 1.0
        if let stencilAttachment = descriptor.stencilAttachment {
            stencilAttachment.clearStencil = 0
        }

        let viewProj = camera.getViewProjectionMatrix()

        // --- First Pass: Render the Normal Model ---
        // This pass writes to the stencil buffer (replacing stencil values with 1).
        var upperLeft = simd_float3x3(
            SIMD3<Float>(modelMatrix.columns.0.x, modelMatrix.columns.0.y, modelMatrix.columns.0.z),
            SIMD3<Float>(modelMatrix.columns.1.x, modelMatrix.columns.1.y, modelMatrix.columns.1.z),
            SIMD3<Float>(modelMatrix.columns.2.x, modelMatrix.columns.2.y, modelMatrix.columns.2.z)
        )
        let normalMatrix = simd_transpose(simd_inverse(upperLeft))
        var uniforms = Uniforms(
            modelViewProjectionMatrix: viewProj * modelMatrix,
            modelMatrix: modelMatrix,
            normalMatrix: normalMatrix,
            lightDirection: SIMD3<Float>(10, 10, 10),
            lightColor: SIMD3<Float>(1, 1, 1)
        )

        encoder.setRenderPipelineState(pipelineState)
        encoder.setDepthStencilState(depthStencilNormalState)
        // Set the stencil reference so that the normal pass writes a value (1) into the stencil.
        encoder.setStencilReferenceValue(1)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        encoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: indexCount,
            indexType: .uint32,
            indexBuffer: indexBuffer,
            indexBufferOffset: 0)

        // --- Second Pass: Render the Outline ---
        // The outline pass draws a slightly enlarged version of the model.
        // It uses a stencil test so that it only colors fragments where the normal model was not rendered.
        let outlineScale: Float = 1.05
        // let outlineMatrix = modelMatrix.scale(outlineScale)

        let outlineMatrix = modelMatrix.scale(
            vec3f(outlineScale * 0.98, outlineScale, outlineScale * 0.955))

        var upperLeftOutline = simd_float3x3(
            SIMD3<Float>(
                outlineMatrix.columns.0.x, outlineMatrix.columns.0.y, outlineMatrix.columns.0.z),
            SIMD3<Float>(
                outlineMatrix.columns.1.x, outlineMatrix.columns.1.y, outlineMatrix.columns.1.z),
            SIMD3<Float>(
                outlineMatrix.columns.2.x, outlineMatrix.columns.2.y, outlineMatrix.columns.2.z)
        )
        let normalMatrixOutline = simd_transpose(simd_inverse(upperLeftOutline))
        var outlineUniforms = Uniforms(
            modelViewProjectionMatrix: viewProj * outlineMatrix,
            modelMatrix: outlineMatrix,
            normalMatrix: normalMatrixOutline,
            lightDirection: SIMD3<Float>(10, 10, 10),
            lightColor: SIMD3<Float>(1, 1, 1)
        )

        // Optionally, add a slight depth bias to ensure proper layering.
        encoder.setDepthBias(0.015, slopeScale: 1.0, clamp: 0.0)
        encoder.setRenderPipelineState(outlinePipelineState)
        encoder.setDepthStencilState(depthStencilOutlineState)
        // This stencil test makes sure the outline only renders where the normal model was not drawn.
        encoder.setStencilReferenceValue(1)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBytes(&outlineUniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        encoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: indexCount,
            indexType: .uint32,
            indexBuffer: indexBuffer,
            indexBufferOffset: 0)

        // Clear depth bias after outline pass.
        encoder.setDepthBias(0, slopeScale: 0, clamp: 0)

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    public func resize(to size: CGSize) {
        camera.setAspectRatio(Float(size.width / size.height))
    }

    public func update(dt: Float) {
        // Update logic (such as animations) here.
    }

    public func handle(_ event: EventType) async {
        guard let touchEvent = event as? TouchEvent else { return }
        switch touchEvent.type {
        case .tap:
            break
        case .drag:
            camera.orbit(
                deltaTheta: touchEvent.delta.x * 0.015,
                deltaPhi: touchEvent.delta.y * 0.015)
        case .scale:
            camera.zoom(delta: touchEvent.scale)
        case .rotate:
            break
        case .resize:
            break
        case .translate:
            camera.moveInPlane(
                deltaX: touchEvent.delta.x * 0.008,
                deltaY: touchEvent.delta.y * 0.008)
        }
    }
}
