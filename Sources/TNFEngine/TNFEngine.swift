// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import MetalKit
import Utilities

struct Position: Component {
    var x, y: Float
}

public final class TNFEngine {
    public let eventDispatcher: EventDispatcher
    public let renderer: Renderer
    public let scene: Scene

    private let device: MTLDevice
    private let moduleStack: ModuleStack
    private let materials: MaterialManager = MaterialManager()

    public init?() {
        guard let engineDevice = Device.shared?.device,
            engineDevice.makeCommandQueue() != nil
        else { return nil }

        self.device = engineDevice
        self.eventDispatcher = EventDispatcher()
        self.moduleStack = ModuleStack()

        // Add default modules
        self.renderer = Renderer()
        moduleStack.addModule(renderer)
        eventDispatcher.subscribe(renderer)

        self.scene = Scene()

    }

    public func start() {
        Log.info("TNFEngine started")

        // NOTE: Testing ecs
        let modelEntity = scene.create(named: "Model")
        scene.add(Position(x: 0, y: 0), to: modelEntity)

        let girlEntity = scene.create(named: "Girl")
        scene.add(Position(x: 1, y: 1), to: girlEntity)

        let meshEntity = scene.create(named: "Mesh")
        scene.add(MeshComponent(name: "model"), to: meshEntity)

        let materialHandle = materials.createMaterial(name: "matalic")

        scene.add(MaterialComponent(handle: materialHandle), to: meshEntity)

        // if let assetURL = Bundle.module.url(
        //     forResource: "staticDefaultMesh", withExtension: "metal")
        // {
        //     Log.info("Found asset at: \(assetURL)")
        // } else {
        //     Log.error("dont found assest")
        // }

        //FIXME: Remove this code
        // if let bundlePath = Bundle.module.resourceURL {
        //     do {
        //         let contents = try FileManager.default.contentsOfDirectory(
        //             at: bundlePath, includingPropertiesForKeys: nil)
        //         Log.info("Bundle contains: \(contents)")
        //     } catch {
        //         Log.error("Failed to read bundle contents: \(error)")
        //     }
        // }
        //
        // if let metallibURL = Bundle.module.url(forResource: "default", withExtension: "metallib") {
        //     Log.info("Found metallib at: \(metallibURL)")
        // } else {
        //     Log.error("Metallib not found")
        // }

    }

    public func resize(to size: CGSize) {
        renderer.resize(to: size)
    }

    public func addModule(_ module: Module) {
        moduleStack.addModule(module)
        eventDispatcher.subscribe(module)
    }

    public func removeModule(_ module: Module) {
        moduleStack.removeModule(module)
        eventDispatcher.unsubscribe(module)
    }

    @MainActor
    public func update(view: MTKView) {
        moduleStack.updateAll(dt: 1.0 / 60.0)

        renderer.draw(in: view)

        // var meshView = scene.view(of: MeshComponent.self)
        // meshView.forEach { entity in
        //     //     if let position: Position = scene.get(for: entity) {
        //     //         Log.error("Entity position: \(position.x), \(position.y)")
        //     //     }
        //
        //     if let mesh: MeshComponent = scene.get(for: entity) {
        //
        //         // Log.warning("Indices Count \(mesh.meshData?.indices.count ?? -1 )")
        //     }
        //
        // }
        //

        //FIXME: REMOVE
        // var view = scene.view(MeshComponent.self, MaterialComponent.self)
        //
        // view.forEach { entity in
        //     if let meshComponent: MeshComponent = scene.get(for: entity),
        //         let materialComponent: MaterialComponent = scene.get(for: entity)
        //     {
        //
        //         //Bind material , a
        //     }
        // }

    }

    public func getMetalDevice() -> MTLDevice {
        return device
    }

}

//NOTE: Callbacks for events
extension TNFEngine {

    public func handleTouch(at point: CGPoint) async {
        let event = TouchEvent(
            type: .tap,
            touches: [TouchPoint(position: vec2f(Float(point.x), Float(point.y)))]
        )
        await eventDispatcher.dispatch(event)
    }

    public func handleDrag(from start: CGPoint, to end: CGPoint) async {
        let event = TouchEvent(
            type: .drag,
            touches: [
                TouchPoint(position: vec2f(Float(start.x), Float(start.y))),
                TouchPoint(position: vec2f(Float(end.x), Float(end.y))),
            ],
            delta: vec2f(Float(end.x - start.x), Float(end.y - start.y))
        )
        await eventDispatcher.dispatch(event)
    }

    public func handleTranslate(touches: [CGPoint], delta: CGPoint) async {
        let touchPoints = touches.map {
            TouchPoint(position: vec2f(Float($0.x), Float($0.y)))
        }
        let event = TouchEvent(
            type: .translate,
            touches: touchPoints,
            delta: vec2f(Float(delta.x), Float(delta.y))
        )
        await eventDispatcher.dispatch(event)
    }

    public func handleScale(_ scale: Float, at point: CGPoint) async {
        let event = TouchEvent(
            type: .scale,
            touches: [TouchPoint(position: vec2f(Float(point.x), Float(point.y)))],
            scale: scale
        )
        await eventDispatcher.dispatch(event)
    }

    public func handleRotate(_ angle: Float, at point: CGPoint) async {
        let event = TouchEvent(
            type: .rotate,
            touches: [TouchPoint(position: vec2f(Float(point.x), Float(point.y)))],
            rotation: angle
        )
        await eventDispatcher.dispatch(event)
    }
}
