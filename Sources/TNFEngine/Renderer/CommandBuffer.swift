// Copyright (c) 2025 The Noughy Fox
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import Foundation
import Metal

class CommandBuffer {
    private let commandBuffer: MTLCommandBuffer
    private var renderCommandEncoder: MTLRenderCommandEncoder?

    init(commandQueue: MTLCommandQueue) {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            fatalError("Could not create command buffer")
        }
        self.commandBuffer = commandBuffer
    }

    func begin() {
    }

    func setRenderPass(descriptor: MTLRenderPassDescriptor) {
        renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
    }

    func end() {
        renderCommandEncoder?.endEncoding()
        commandBuffer.commit()
    }
}
