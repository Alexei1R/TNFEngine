//
//  ViewportView.swift
//  Forge
//
//  Created by rusu alexei on 20.02.2025.
//


import SwiftUI

struct ComponentView: View {
    @ObservedObject var viewModel: ForgeViewModel
    @Binding var rightPanelWidth: CGFloat
    var geometry: GeometryProxy

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Layers")
                    .foregroundColor(.white)
                    .font(.headline)
                Spacer()
                // Button to close the layers panel
                Button(action: {
                    withAnimation {
                        viewModel.showLayers = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                }
            }
            .padding(8)
            
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(viewModel.layers) { layer in
                        LayerRow(
                            layer: layer,
                            isSelected: viewModel.selectedLayer == layer.id,
                            onSelect: { viewModel.selectLayer(id: layer.id) },
                            onToggleVisibility: { viewModel.toggleLayerVisibility(id: layer.id) },
                            onRemove: { viewModel.removeLayer(id: layer.id) }
                        )
                    }
                }
                .padding(8)
            }
            Spacer()
        }
        .frame(width: rightPanelWidth, height: geometry.size.height)
        .background(Color.black.opacity(0.85))
        .cornerRadius(12)
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 4)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let newWidth = rightPanelWidth - value.translation.width
                            rightPanelWidth = max(180, min(newWidth, geometry.size.width * 0.35))
                        }
                ),
            alignment: .leading
        )
    }
}

struct LayerRow: View {
    let layer: Layer
    let isSelected: Bool
    let onSelect: () -> Void
    let onToggleVisibility: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            // Eye button to toggle visibility
            Button(action: onToggleVisibility) {
                Image(systemName: layer.isVisible ? "eye.fill" : "eye.slash.fill")
                    .foregroundColor(layer.isVisible ? .green : .red)
                    .font(.system(size: 12))  // Reduced size
            }
            
            // Remove button
            Button(action: onRemove) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.system(size: 12))  // Reduced size
            }
            
            Button(action: onSelect) {
                HStack {
                    Image(systemName: layerIcon(for: layer.type))
                        .foregroundColor(.white)
                    Text(layer.name)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .padding(8)
                .background(isSelected ? Color.blue.opacity(0.3) : Color.clear)
                .cornerRadius(4)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private func layerIcon(for type: String) -> String {
        switch type {
        case "Mesh": return "cube.fill"
        case "Light": return "lightbulb.fill"
        case "Camera": return "camera.fill"
        default: return "questionmark"
        }
    }
}
