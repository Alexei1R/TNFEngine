// Copyright (c) 2025 The Noughy Fox
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

struct MeshComponent: Component {
    public let path: String
    public let transform: mat4f

    public init(path: String, transform: mat4f = mat4f.identity) {
        self.path = path
        self.transform = transform
    }

}
