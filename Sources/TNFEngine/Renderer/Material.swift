// Copyright (c) 2025 The Noughy Fox
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import Foundation
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
}

//NOTE:  Main Material class
class Material {
    var name: String = "UnnamedMaterial"
    var additionalParameters: [String: MaterialParamValue]

    init(name: String = "UnnamedMaterial") {
        self.name = name
        self.additionalParameters = [:]
    }

    func setParameter(_ name: String, _ value: MaterialParamValue) {
        additionalParameters[name] = value
    }

    func getParameter(_ name: String) -> MaterialParamValue? {
        return additionalParameters[name]
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
            for (name, value) in material.additionalParameters {
                switch value {
                case .float(let v):
                    print("- \(name): Float = \(v)")
                case .vector2(let v):
                    print("- \(name): SIMD2<Float> = \(v)")
                case .vector3(let v):
                    print("- \(name): SIMD3<Float> = \(v)")
                case .vector4(let v):
                    print("- \(name): SIMD4<Float> = \(v)")
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
