//
//  ViewportView.swift
//  Forge
//
//  Created by rusu alexei on 20.02.2025.
//

import SwiftUI
import Foundation


struct Tool: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let group: ToolGroup
}

enum ToolGroup {
    case selection, manipulation, creation, view
}

class ForgeViewModel: ObservableObject {
    // Callback type definition
    typealias ToolSelectionCallback = (Tool?) -> Void
    
    // Private array to store callbacks
    private var toolSelectionCallbacks: [ToolSelectionCallback] = []
    
    
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
}
