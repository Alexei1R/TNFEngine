//
//  ViewportView.swift
//  Forge
//
//  Created by rusu alexei on 20.02.2025.
//


import SwiftUI

// Tools Panel and Tool Button components
struct ToolsPanelView: View {
    @ObservedObject var viewModel: ForgeViewModel

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(viewModel.tools) { tool in
                        ToolButton(
                            icon: tool.icon,
                            isSelected: viewModel.selectedTool?.id == tool.id,
                            size: 30
                        ) {
                            viewModel.selectedTool = tool
                        }
                    }
                }
            }
            Spacer()
            // Button to toggle the layers panel.
            Button(action: {
                withAnimation {
                    viewModel.showLayers.toggle()
                }
            }) {
                Image(systemName: "sidebar.left")
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.blue.opacity(0.3))
                    .cornerRadius(8)
            }
        }
        .padding(.vertical)
        .background(Color.black.opacity(0.8))
    }
}

struct QuickButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .padding(6)
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
        }
    }
}

struct ToolButton: View {
    let icon: String
    let isSelected: Bool
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .foregroundColor(isSelected ? .blue : .white)
                .frame(width: size, height: size)
                .background(isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3))
                .cornerRadius(8)
        }
    }
}
