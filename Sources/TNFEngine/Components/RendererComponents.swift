// Copyright (c) 2025 The Noughy Fox
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import Metal
import Utilities

//NOTE: Contain the draw data

struct MeshComponent: Component {
    public let name: String
    public let transform: mat4f
    public private(set) var meshData: MeshData?
    public let fileExtension: String

    public init(name: String, fileExtension: String = "usdc", transform: mat4f = mat4f.identity) {
        self.name = name
        self.transform = transform
        self.meshData = nil
        self.fileExtension = fileExtension

        load(named: name, fileExtension: fileExtension)
    }

    private mutating func load(named name: String, fileExtension: String) {
        guard let path = Bundle.main.path(forResource: name, ofType: fileExtension) else {
            Log.error("Failed to find model: \(name).\(fileExtension)")
            return
        }

        let url = URL(fileURLWithPath: path)
        loadModel(from: url)
    }

    private mutating func loadModel(from url: URL) {
        do {
            let model3D = Model3D()
            try model3D.load(from: url)

            guard let mesh = model3D.meshes.first,
                let data = model3D.extractMeshData(from: mesh)
            else {
                Log.error("Failed to extract mesh data from model: \(url.lastPathComponent)")
                return
            }

            self.meshData = data
            Log.info("Successfully loaded model: \(url.lastPathComponent)")

        } catch {
            Log.error(
                "Failed to load model: \(url.lastPathComponent), error: \(error.localizedDescription)"
            )
        }
    }
}

//NOTE:  Handle to a material
struct MaterialComponent: Component {

    public let materialHandle: Handle

    public init(handle: Handle) {
        self.materialHandle = handle
    }

}
