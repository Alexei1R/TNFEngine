// Copyright (c) 2025 The Noughy Fox
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import Foundation
import Metal

protocol RendererAPIProtocol: AnyObject {
    var device: MTLDevice { get }
    var commandQueue: MTLCommandQueue { get }

    func createCommandBuffer() -> CommandBuffer
    func createRenderPass(renderPassConfig: RenderPassConfig) -> RenderPassDescriptor

}

class RendererAPI: RendererAPIProtocol {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue

    init?() {
        guard let device = Device.shared?.device,
            let commandQueue = device.makeCommandQueue()
        else {
            return nil
        }
        self.device = device
        self.commandQueue = commandQueue
    }

    func createCommandBuffer() -> CommandBuffer {
        CommandBuffer(commandQueue: commandQueue)
    }

    func createRenderPass(renderPassConfig: RenderPassConfig) -> RenderPassDescriptor {

        RenderPassDescriptor(config: renderPassConfig)
    }

}
