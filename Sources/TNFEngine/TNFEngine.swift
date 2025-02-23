// Copyright (c) 2025 The Noughy Fox
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT



import MetalKit
import Utilities

public final class TNFEngine {
    private let device: MTLDevice
    private let moduleStack: ModuleStack
    public let eventDispatcher: EventDispatcher

    public init?() {
        guard let engineDevice = Device.shared?.device,
              engineDevice.makeCommandQueue() != nil
        else { return nil }

        self.device = engineDevice
        self.eventDispatcher = EventDispatcher()
        self.moduleStack = ModuleStack()
        
        // Add default modules
        let input = InputModule()
        moduleStack.addModule(input)
        eventDispatcher.subscribe(input)


    }

    public func start() {
        Log.info("TNFEngine started")
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
        moduleStack.updateAll(dt: 1.0/60.0)
    }
    
    public func getMetalDevice() -> MTLDevice {
        return device
    }
    
    // MARK: - Touch Event Handling
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
                TouchPoint(position: vec2f(Float(end.x), Float(end.y)))
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





