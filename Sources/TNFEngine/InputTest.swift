// Copyright (c) 2025 The Noughy Fox
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

public final class InputModule: Module {
    public func handle(_ event: EventType) async {
        guard let touchEvent = event as? TouchEvent else { return }

        switch touchEvent.type {
        case .tap:
            print("Tap at: \(touchEvent.touches.first?.position ?? .zero)")
        case .drag:
            print("Drag delta: \(touchEvent.delta)")
        case .scale:
            print("Scale factor: \(touchEvent.scale)")
        case .rotate:
            print("Rotation angle: \(touchEvent.rotation)")
        case .translate:
            print("Translation delta: \(touchEvent.delta)")
        case .resize:
            print("Resize to: \(touchEvent.touches.first?.position ?? .zero)")
        }
    }
}
