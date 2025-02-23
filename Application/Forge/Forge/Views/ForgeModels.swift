//
//  ViewportView.swift
//  Forge
//
//  Created by rusu alexei on 20.02.2025.
//

import SwiftUI
import Foundation

// Main Data Models remain the same
struct Layer: Identifiable {
    let id = UUID()
    var name: String
    var isVisible: Bool = true
    var isLocked: Bool = false
    var opacity: Double = 1.0
    var type: String = "Mesh"
}

struct Tool: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let group: ToolGroup
}

enum ToolGroup {
    case selection, manipulation, creation, view
}

// Updated ViewModel with tool selection callback
class ForgeViewModel: ObservableObject {
    // Callback type definition
    typealias ToolSelectionCallback = (Tool?) -> Void
    
    // Private array to store callbacks
    private var toolSelectionCallbacks: [ToolSelectionCallback] = []
    
    @Published var layers: [Layer] = [
        Layer(name: "Cube", type: "Mesh"),
        Layer(name: "Light", type: "Light"),
        Layer(name: "Camera", type: "Camera")
    ]
    
    @Published var selectedLayer: Layer.ID?
    @Published var selectedTool: Tool? {
        didSet {
            notifyToolSelectionCallbacks()
        }
    }
    
    @Published var showLayers: Bool = false
    
    let tools: [Tool] = [
        Tool(name: "Select", icon: "cursorarrow", group: .selection),
        Tool(name: "Move", icon: "move.3d", group: .manipulation),
        Tool(name: "Scale", icon: "scale.3d", group: .manipulation),
        Tool(name: "Rotate", icon: "rotate.3d", group: .manipulation),
//        Tool(name: "Add Cube", icon: "cube.fill", group: .creation),
//        Tool(name: "Add Sphere", icon: "circle.fill", group: .creation)
    ]
    
    // Method to register a callback
    func onToolSelection(_ callback: @escaping ToolSelectionCallback) {
        toolSelectionCallbacks.append(callback)
    }
    
    // Method to remove a callback (if needed)
    func removeToolSelectionCallback(_ callback: @escaping ToolSelectionCallback) {
        toolSelectionCallbacks.removeAll(where: { $0 as AnyObject === callback as AnyObject })
    }
    
    // Private method to notify all callbacks
    private func notifyToolSelectionCallbacks() {
        toolSelectionCallbacks.forEach { callback in
            callback(selectedTool)
        }
    }
    
    // Existing Layer API functions remain the same
    func addLayer(name: String, type: String = "Mesh") {
        let newLayer = Layer(name: name, type: type)
        layers.append(newLayer)
        print("Layer added: \(newLayer.name)")
    }
    
    func removeLayer(id: Layer.ID) {
        layers.removeAll { $0.id == id }
        print("Layer removed with ID: \(id)")
    }
    
    func selectLayer(id: Layer.ID) {
        selectedLayer = id
        print("Layer selected with ID: \(id)")
    }
    
    func toggleLayerVisibility(id: Layer.ID) {
        if let index = layers.firstIndex(where: { $0.id == id }) {
            layers[index].isVisible.toggle()
            print("Layer \(layers[index].name) visibility: \(layers[index].isVisible)")
        }
    }
}
