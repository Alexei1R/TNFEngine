//
//  ViewportView.swift
//  Forge
//
//  Created by rusu alexei on 20.02.2025.
//


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
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        engine.update(view: uiView)
    }

    func makeCoordinator() -> ViewportCoordinator {
        return ViewportCoordinator(engine: engine)
    }
}

class ViewportCoordinator: NSObject, MTKViewDelegate {
    private let engine: TNFEngine

    init(engine: TNFEngine) {
        self.engine = engine
    }

    func draw(in view: MTKView) {
        engine.update(view: view)
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        engine.resize(to: size)
    }
}
