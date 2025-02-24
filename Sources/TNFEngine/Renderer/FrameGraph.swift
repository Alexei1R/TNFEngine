// Copyright (c) 2025 The Noughy Fox
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import Foundation
import Metal

class FrameGraph {
    private var renderPasses: [(CommandBuffer) -> Void] = []
    private let rendererAPI: RendererAPI

    init(rendererAPI: RendererAPI) {
        self.rendererAPI = rendererAPI
    }

    func addPass(renderPass: @escaping (CommandBuffer) -> Void) {
        renderPasses.append(renderPass)
    }

    func execute() {
        let commandBuffer = rendererAPI.createCommandBuffer()

        for pass in renderPasses {
            pass(commandBuffer)
        }
    }
}
