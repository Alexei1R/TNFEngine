// Copyright (c) 2025 The Noughy Fox
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import Foundation
import MetalKit
import simd

public enum TouchEventType {
    case tap
    case drag
    case scale
    case rotate
    case translate
    case resize
}

public struct TouchPoint {
    public let position: vec2f
    public let timestamp: TimeInterval
    
    public init(position: vec2f, timestamp: TimeInterval = CACurrentMediaTime()) {
        self.position = position
        self.timestamp = timestamp
    }
}

public protocol EventType {
    var timestamp: TimeInterval { get }
    var isHandled: Bool { get set }
}

public struct Event: EventType {
    public let timestamp: TimeInterval
    public var isHandled: Bool
    
    public init(timestamp: TimeInterval = CACurrentMediaTime()) {
        self.timestamp = timestamp
        self.isHandled = false
    }
}

public struct TouchEvent: EventType {
    public let timestamp: TimeInterval
    public var isHandled: Bool
    
    public let type: TouchEventType
    public let touches: [TouchPoint]
    public let delta: vec2f
    public let scale: Float
    public let rotation: Float
    
    public init(
        type: TouchEventType,
        touches: [TouchPoint],
        delta: vec2f = .zero,
        scale: Float = 1.0,
        rotation: Float = 0.0,
        timestamp: TimeInterval = CACurrentMediaTime()
    ) {
        self.type = type
        self.touches = touches
        self.delta = delta
        self.scale = scale
        self.rotation = rotation
        self.timestamp = timestamp
        self.isHandled = false
    }
}

public protocol EventHandler: AnyObject {
    func handle(_ event: EventType) async
}

private class WeakEventHandler {
    weak var handler: EventHandler?
    
    init(_ handler: EventHandler) {
        self.handler = handler
    }
}

public final class EventDispatcher {
    private var handlers: [ObjectIdentifier: [WeakEventHandler]] = [:]
    
    public init() {}
    
    public func subscribe(_ handler: EventHandler) {
        let id = ObjectIdentifier(type(of: handler))
        let weakHandler = WeakEventHandler(handler)
        
        if handlers[id] != nil {
            handlers[id]?.append(weakHandler)
        } else {
            handlers[id] = [weakHandler]
        }
    }
    
    public func unsubscribe(_ handler: EventHandler) {
        let id = ObjectIdentifier(type(of: handler))
        handlers[id]?.removeAll { $0.handler === handler }
        
        if handlers[id]?.isEmpty == true {
            handlers.removeValue(forKey: id)
        }
    }
    
    public func dispatch(_ event: EventType) async {
        let currentHandlers = handlers
        
        for (_, handlers) in currentHandlers {
            for handler in handlers {
                guard let handler = handler.handler else { continue }
                if event.isHandled { return }
                await handler.handle(event)
            }
        }
    }
}
