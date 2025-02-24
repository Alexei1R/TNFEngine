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
                
            }
            .frame(width: rightPanelWidth, height: geometry.size.height)
            .background(Color.black.opacity(0.85))
            .cornerRadius(12)
            .overlay(
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 8)
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
    
}
