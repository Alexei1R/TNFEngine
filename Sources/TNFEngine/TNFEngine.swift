// Copyright (c) 2025 The Noughy Fox
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import MetalKit
import Support

public final class TNFEngine {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue

    public init?() {
        guard let device = MTLCreateSystemDefaultDevice(),
            let commandQueue = device.makeCommandQueue()
        else {
            return nil
        }
        self.device = device
        self.commandQueue = commandQueue
    }

    public func start() {
        Log.info("TNFEngine started")
    }

    public func resize(to size: CGSize) {
        Log.info("Viewport resized to: \(size)")
    }

    public func getMetalDevice() -> MTLDevice {
        return device
    }

    @MainActor
    public func update(view: MTKView) {

        guard let drawable = view.currentDrawable,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderPassDescriptor = view.currentRenderPassDescriptor
        else {
            return
        }

        let commandEncoder = commandBuffer.makeRenderCommandEncoder(
            descriptor: renderPassDescriptor)
        commandEncoder?.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()

    }

}
