//
//  ContentView.swift
//  Forge
//
//  Created by rusu alexei on 20.02.2025.
//

import SwiftUI
import TNFEngine

struct ContentView: View {
    private let engine = TNFEngine()

    var body: some View {
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
}
