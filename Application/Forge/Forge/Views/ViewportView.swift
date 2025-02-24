
import SwiftUI
import MetalKit
import TNFEngine

struct ViewportView: UIViewRepresentable {
    private let engine: TNFEngine
    
    init(engine: TNFEngine) {
        self.engine = engine
    }
    
    func makeUIView(context: Context) -> MTKView {
                let view = MTKView()
                view.device = engine.getMetalDevice()
                view.preferredFramesPerSecond = 60
                view.isPaused = false
                view.enableSetNeedsDisplay = false
                view.colorPixelFormat = .bgra8Unorm
                view.depthStencilPixelFormat = .depth32Float_stencil8
                view.clearColor = MTLClearColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
                view.delegate = context.coordinator
                view.isMultipleTouchEnabled = true
                setupGestureRecognizers(for: view, with: context.coordinator)
                return view
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {}
    
    func makeCoordinator() -> ViewportCoordinator {
        return ViewportCoordinator(engine: engine)
    }
    
    private func setupGestureRecognizers(for view: MTKView, with coordinator: ViewportCoordinator) {
        let tapGesture = UITapGestureRecognizer(target: coordinator, action: #selector(ViewportCoordinator.handleTap(_:)))
        tapGesture.numberOfTouchesRequired = 1
        
        let singleFingerPanGesture = UIPanGestureRecognizer(target: coordinator, action: #selector(ViewportCoordinator.handleSingleFingerPan(_:)))
        singleFingerPanGesture.minimumNumberOfTouches = 1
        singleFingerPanGesture.maximumNumberOfTouches = 1
        
        let twoFingerPanGesture = UIPanGestureRecognizer(target: coordinator, action: #selector(ViewportCoordinator.handleTwoFingerPan(_:)))
        twoFingerPanGesture.minimumNumberOfTouches = 2
        twoFingerPanGesture.maximumNumberOfTouches = 2
        
        let pinchGesture = UIPinchGestureRecognizer(target: coordinator, action: #selector(ViewportCoordinator.handlePinch(_:)))
        let rotationGesture = UIRotationGestureRecognizer(target: coordinator, action: #selector(ViewportCoordinator.handleRotation(_:)))
        
        [twoFingerPanGesture, pinchGesture, rotationGesture].forEach { $0.delegate = coordinator }
        [tapGesture, singleFingerPanGesture, twoFingerPanGesture, pinchGesture, rotationGesture].forEach { view.addGestureRecognizer($0) }
    }
}


class ViewportCoordinator: NSObject, MTKViewDelegate, UIGestureRecognizerDelegate {
    private let engine: TNFEngine
    
    init(engine: TNFEngine) {
        self.engine = engine
        super.init()
    }
    
    func draw(in view: MTKView) {
        engine.update(view: view)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        engine.resize(to: size)
        Task {
            await engine.handleTouch(at: CGPoint(x: size.width, y: size.height))
        }
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let metalView = gesture.view as? MTKView else { return }
        let location = gesture.location(in: metalView)
        
        Task {
            await engine.handleTouch(at: location)
        }
    }
    
    @objc func handleSingleFingerPan(_ gesture: UIPanGestureRecognizer) {
        guard let metalView = gesture.view as? MTKView else { return }
        let location = gesture.location(in: metalView)
        let translation = gesture.translation(in: metalView)
        let startPoint = CGPoint(x: location.x - translation.x, y: location.y - translation.y)
        
        Task {
            await engine.handleDrag(from: startPoint, to: location)
        }
        
        gesture.setTranslation(.zero, in: metalView)
    }
    
    @objc func handleTwoFingerPan(_ gesture: UIPanGestureRecognizer) {
        guard let metalView = gesture.view as? MTKView,
              gesture.numberOfTouches == 2 else { return }
        
        let touchPoints = (0..<gesture.numberOfTouches).map {
            gesture.location(ofTouch: $0, in: metalView)
        }
        
        let translation = gesture.translation(in: metalView)
        
        Task {
            await engine.handleTranslate(touches: touchPoints, delta: translation)
        }
        
        gesture.setTranslation(.zero, in: metalView)
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let metalView = gesture.view as? MTKView else { return }
        let location = gesture.location(in: metalView)
        if gesture.state == .changed {
            let delta = 1.0 - Float(gesture.scale) // 0 when no pinch, positive for pinch-in, negative for pinch-out
            Task {
                await engine.handleScale(delta, at: location)
            }
            gesture.scale = 1.0
        }
    }
    
    
    
    @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let metalView = gesture.view as? MTKView else { return }
        let location = gesture.location(in: metalView)
        
        Task {
            await engine.handleRotate(Float(gesture.rotation), at: location)
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow simultaneous recognition for two-finger gestures
        if gestureRecognizer is UIPinchGestureRecognizer && otherGestureRecognizer is UIRotationGestureRecognizer {
            return true
        }
        if gestureRecognizer is UIRotationGestureRecognizer && otherGestureRecognizer is UIPinchGestureRecognizer {
            return true
        }
        return false
    }
}
