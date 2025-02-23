//
//  ViewportView.swift
//  Forge
//
//  Created by rusu alexei on 20.02.2025.
//



import SwiftUI
import TNFEngine

struct ContentView: View {
    @StateObject var viewModel = ForgeViewModel()
    @State private var leftPanelWidth: CGFloat = 60
    @State private var rightPanelWidth: CGFloat = 180
    @State private var currentOperation: String = "No tool selected"
    private let screenMargin: CGFloat = 40
    private let engine = TNFEngine()
    
    
    var body: some View {
        GeometryReader { geometry in
            let viewportWidth = geometry.size.width - leftPanelWidth - (viewModel.showLayers ? rightPanelWidth : 0)
            HStack(spacing: 0) {
                // Left Panel
                ToolsPanelView(viewModel: viewModel)
                    .padding(.vertical, 8)
                    .frame(width: leftPanelWidth)
                
                ZStack(alignment: .topLeading) {
                    // Background
                    Color.gray
                    
                    // Add Button
                    Button(action: {
                        viewModel.addLayer(name: "New Layer")
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                            Text("Add")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.7))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(16)
                    .transition(.scale.combined(with: .opacity))
                    
                    
                    // Center content
                    VStack(spacing: 12) {
                        if let engine = engine {
                            ViewportView(engine: engine)
                                .ignoresSafeArea(.all)
                                .onAppear {
                                    engine.start()
                                }
                        } else {
                            Text("Metal is not supported on this device.")
                                .foregroundColor(.red)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: viewportWidth, height: geometry.size.height)
                
                // Right Panel
                if viewModel.showLayers {
                    ComponentView(viewModel: viewModel, rightPanelWidth: $rightPanelWidth, geometry: geometry)
                        .transition(.move(edge: .trailing))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
        .onAppear {
            //            setupToolCallback()
        }
    }
    
    //    private func setupToolCallback() {
    //        viewModel.onToolSelection { tool in
    //            if let tool = tool {
    //                switch tool.group {
    //                case .selection:
    //                    currentOperation = "Selection Mode: Click to select objects"
    //                case .manipulation:
    //                    switch tool.name {
    //                    case "Move":
    //                        currentOperation = "Move Mode: Drag to move objects"
    //                    case "Scale":
    //                        currentOperation = "Scale Mode: Drag to scale objects"
    //                    case "Rotate":
    //                        currentOperation = "Rotate Mode: Drag to rotate objects"
    //                    default:
    //                        currentOperation = "Manipulation Mode"
    //                    }
    //                case .creation:
    //                    switch tool.name {
    //                    case "Add Cube":
    //                        currentOperation = "Creation Mode: Click to place a cube"
    //                    case "Add Sphere":
    //                        currentOperation = "Creation Mode: Click to place a sphere"
    //                    default:
    //                        currentOperation = "Creation Mode"
    //                    }
    //                case .view:
    //                    currentOperation = "View Mode: Adjusting viewport"
    //                }
    //            } else {
    //                currentOperation = "No tool selected"
    //            }
    //        }
    //    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

