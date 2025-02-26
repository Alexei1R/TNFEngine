// Copyright (c) 2025 The Noughy Fox
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import Foundation
import Metal
import Utilities
import simd

protocol ConfigEntry {
    var name: String { get }
    var value: Any { get }
}

enum MaterialParamValue {
    case float(Float)
    case vector2(SIMD2<Float>)
    case vector3(SIMD3<Float>)
    case vector4(SIMD4<Float>)
    case integer(Int)
    case boolean(Bool)

    var size: Int {
        switch self {
        case .float: return MemoryLayout<Float>.size
        case .vector2: return MemoryLayout<SIMD2<Float>>.size
        case .vector3: return MemoryLayout<SIMD3<Float>>.size
        case .vector4: return MemoryLayout<SIMD4<Float>>.size
        case .integer: return MemoryLayout<Int>.size
        case .boolean: return MemoryLayout<Bool>.size
        }
    }
}

//NOTE:  Main Material class
class Material {
    var name: String = "UnnamedMaterial"
    var parameters: [String: MaterialParamValue]
    var parameterOrder: [String] = []
    private var isChanged: Bool = true

    init(name: String = "UnnamedMaterial") {
        self.name = name
        self.parameters = [:]
    }

    func setParameter(_ name: String, _ value: MaterialParamValue) {
        // Add to order list if it's a new parameter
        if parameters[name] == nil {
            parameterOrder.append(name)
        }
        parameters[name] = value
        isChanged = true
    }

    func getParameter(_ name: String) -> MaterialParamValue? {
        return parameters[name]
    }

    func removeParameter(_ name: String) {
        if parameters.removeValue(forKey: name) != nil {
            if let index = parameterOrder.firstIndex(of: name) {
                parameterOrder.remove(at: index)
            }
            isChanged = true
        }
    }

    func getSizeBytes() -> Int {
        var size = 0
        // Use parameterOrder to ensure consistent sizing
        for name in parameterOrder {
            guard let value = parameters[name] else { continue }
            size += value.size
        }
        return size
    }
}

// MARK: - Material Manager
class MaterialManager {
    private var materials: [Handle: Material] = [:]

    func createMaterial(name: String = "UnnamedMaterial") -> Handle {
        let material = Material(name: name)
        let handle = Handle()

        self.materials[handle] = material

        return handle
    }

    func getMaterial(_ handle: Handle) -> Material? {
        return materials[handle]
    }

    func updateMaterial(_ handle: Handle, update: @escaping (Material) -> Void) {
        guard let material = self.materials[handle] else { return }
        update(material)
    }

    func destroyMaterial(_ handle: Handle) {
        self.materials.removeValue(forKey: handle)
    }
}

extension MaterialManager {
    func printMaterialDetails(_ handle: Handle) {
        if let material = getMaterial(handle) {
            print("\n=== Material Details [\(material.name)] ===")

            // Print all parameters
            print("\nParameters:")
            for name in material.parameterOrder {
                guard let value = material.parameters[name] else { continue }
                switch value {
                case .float(let v):
                    print("- \(name): Float = \(v)")
                case .vector2(let v):
                    print("- \(name): Float2 = \(v)")
                case .vector3(let v):
                    print("- \(name): Float3 = \(v)")
                case .vector4(let v):
                    print("- \(name): Float4 = \(v)")
                case .integer(let v):
                    print("- \(name): Int = \(v)")
                case .boolean(let v):
                    print("- \(name): Bool = \(v)")
                }
            }
            print("===================================")
        } else {
            print("No material found for the given handle")
        }
    }
}

//Default material
extension Material {
    static func createDefault() -> Material {
        let material = Material(name: "DefaultMaterial")
        material.setParameter("roughness", .float(0.5))
        material.setParameter("metallic", .float(0.0))
        material.setParameter("normalScale", .vector2(SIMD2<Float>(1.0, 1.0)))
        return material
    }
}

extension Material {
    func createUniformBuffer(device: MTLDevice) -> MTLBuffer? {
        let bufferSize = getSizeBytes()
        if bufferSize == 0 {
            return nil
        }

        guard let buffer = device.makeBuffer(length: bufferSize, options: []) else {
            return nil
        }

        updateBufferContents(buffer)

        Log.info("Material buffer created with size: \(bufferSize)")

        return buffer
    }

    func updateUniformBuffer(buffer: MTLBuffer) -> Bool {
        if !isChanged {
            return false
        }

        updateBufferContents(buffer)

        Log.info("Material buffer updated")
        return true
    }

    private func updateBufferContents(_ buffer: MTLBuffer) {
        let contents = buffer.contents()
        var offset = 0

        // Use the consistent parameter order to write values
        for name in parameterOrder {
            guard let value = parameters[name] else { continue }

            switch value {
            case .float(let v):
                memcpy(
                    contents + offset,
                    [v].withUnsafeBytes { $0.baseAddress! },
                    MemoryLayout<Float>.size)
                offset += MemoryLayout<Float>.size

            case .vector2(let v):
                memcpy(
                    contents + offset,
                    [v].withUnsafeBytes { $0.baseAddress! },
                    MemoryLayout<SIMD2<Float>>.size)
                offset += MemoryLayout<SIMD2<Float>>.size

            case .vector3(let v):
                memcpy(
                    contents + offset,
                    [v].withUnsafeBytes { $0.baseAddress! },
                    MemoryLayout<SIMD3<Float>>.size)
                offset += MemoryLayout<SIMD3<Float>>.size

            case .vector4(let v):
                memcpy(
                    contents + offset,
                    [v].withUnsafeBytes { $0.baseAddress! },
                    MemoryLayout<SIMD4<Float>>.size)
                offset += MemoryLayout<SIMD4<Float>>.size

            case .integer(let v):
                memcpy(
                    contents + offset,
                    [v].withUnsafeBytes { $0.baseAddress! },
                    MemoryLayout<Int>.size)
                offset += MemoryLayout<Int>.size

            case .boolean(let v):
                memcpy(
                    contents + offset,
                    [v].withUnsafeBytes { $0.baseAddress! },
                    MemoryLayout<Bool>.size)
                offset += MemoryLayout<Bool>.size
            }
        }

        isChanged = false
    }
}

