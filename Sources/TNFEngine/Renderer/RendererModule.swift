import MetalKit
import Utilities
import simd

struct Uniforms {
    var modelViewProjectionMatrix: matrix_float4x4
    var modelMatrix: matrix_float4x4
    var lightDirection: SIMD3<Float>
    var lightColor: SIMD3<Float>
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

        camera = Camera(
            position: vec3f(0, 0, -3),
            target: vec3f(0, 0, 0),
            up: vec3f(0, 1, 0),
            fieldOfView: Float.pi / 3,
            aspectRatio: 1.0,
            nearPlane: 0.1,
            farPlane: 1000.0
        )

        modelMatrix = mat4f.identity
            .rotateDegrees(-90, axis: .x)
            .scale(0.01)
            .translate(-vec3f.up)

        guard let path = Bundle.main.path(forResource: "model", ofType: "usdc")
        else { fatalError() }
        let url = URL(fileURLWithPath: path)
        let model3D = Model3D()
        try! model3D.load(from: url)
        guard let mesh = model3D.meshes.first,
              let meshData = model3D.extractMeshData(from: mesh)
        else { fatalError() }
        indexCount = meshData.indices.count

        guard let vBuffer = device.makeBuffer(
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

        let shaderSource = """
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
            };

            vertex VertexOut vertex_main(const device Vertex *vertices [[buffer(0)]],
                                         constant Uniforms &uniforms [[buffer(1)]],
                                         uint vid [[vertex_id]])
            {
                VertexOut out;
                float4 pos = float4(vertices[vid].position, 1.0);
                out.position = uniforms.modelViewProjectionMatrix * pos;
                float3x3 normalMatrix = float3x3(uniforms.modelMatrix[0].xyz,
                                                 uniforms.modelMatrix[1].xyz,
                                                 uniforms.modelMatrix[2].xyz);
                normalMatrix = transpose(inverse3x3(normalMatrix));
                out.normal = normalMatrix * vertices[vid].normal;
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
            """
        let library = try! device.makeLibrary(source: shaderSource, options: nil)
        let vertexFunction = library.makeFunction(name: "vertex_main")!
        let fragmentFunction = library.makeFunction(name: "fragment_main")!

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
        vertexDesc.attributes[3].offset = MemoryLayout<SIMD3<Float>>.stride * 2 + MemoryLayout<SIMD2<Float>>.stride
        vertexDesc.attributes[3].bufferIndex = 0
        vertexDesc.attributes[4].format = .float3
        vertexDesc.attributes[4].offset = MemoryLayout<SIMD3<Float>>.stride * 3 + MemoryLayout<SIMD2<Float>>.stride
        vertexDesc.attributes[4].bufferIndex = 0
        vertexDesc.layouts[0].stride = MemoryLayout<StaticModelVertex>.stride

        let pipelineDesc = MTLRenderPipelineDescriptor()
        pipelineDesc.vertexFunction = vertexFunction
        pipelineDesc.fragmentFunction = fragmentFunction
        pipelineDesc.vertexDescriptor = vertexDesc
        pipelineDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDesc.depthAttachmentPixelFormat = .depth32Float

        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDesc)
    }

    @MainActor
    public func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else { return }

        descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.1, 0.1, 0.1, 1.0)
        descriptor.depthAttachment.clearDepth = 1.0

        let viewProj = camera.getViewProjectionMatrix()
        var uniforms = Uniforms(
            modelViewProjectionMatrix: viewProj * modelMatrix,
            modelMatrix: modelMatrix,
            lightDirection: SIMD3<Float>(10, 10, 10),
            lightColor: SIMD3<Float>(1, 1, 1)
        )

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
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    public func resize(to size: CGSize) {
        camera.setAspectRatio(Float(size.width / size.height))
    }

    public func update(dt: Float) { }

    public func handle(_ event: EventType) async {
        guard let touchEvent = event as? TouchEvent else { return }
        switch touchEvent.type {
        case .tap: break
        case .drag:
            camera.orbit(deltaTheta: touchEvent.delta.x * 0.015,
                         deltaPhi: touchEvent.delta.y * 0.015)
        case .scale:
            camera.zoom(delta: touchEvent.scale)
        case .rotate: break
        case .resize: break
        case .translate:
            camera.moveInPlane(deltaX: touchEvent.delta.x * 0.008,
                               deltaY: touchEvent.delta.y * 0.008)
        }
    }
}
