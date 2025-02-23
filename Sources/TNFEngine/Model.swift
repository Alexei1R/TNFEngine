// // copyright (c) 2025 the noughy fox
// //
// // this software is released under the mit license.
// // https://opensource.org/licenses/mit
//
// import foundation
// import metalkit
// import modelio
// import utilities
// import simd
//
// // error enum for model loader errors.
// public enum modelloadererror: error {
//     case failedtoloadasset(string)
//     case invalidmesh
//     case missingvertexdata
// }
//
// public struct staticmodelvertex {
//     var position: simd3<float>
//     var normal: simd3<float>
//     var texturecoordinate: simd2<float>
//     var tangent: simd3<float>
//     var bitangent: simd3<float>
// }
//
// public struct meshdata {
//     var vertices: [staticmodelvertex]
//     var indices: [uint32]
// }
//
// public class model3d {
//     private(set) var asset: mdlasset?
//     private(set) var meshes: [mdlmesh] = []
//
//     private(set) var changecoordinatesystem: bool = true
//
//     let blendertometalmatrix: simd_float4x4 = simd_float4x4(
//         columns: (
//             simd4<float>(1, 0, 0, 0),
//             simd4<float>(0, 0, 1, 0),
//             simd4<float>(0, -1, 0, 0),
//             simd4<float>(0, 0, 0, 1)
//         ))
//
//     private let vertexdescriptor: mdlvertexdescriptor = {
//         let descriptor = mdlvertexdescriptor()
//         var offset = 0
//
//         descriptor.attributes[0] = mdlvertexattribute(
//             name: mdlvertexattributeposition,
//             format: .float3,
//             offset: offset,
//             bufferindex: 0)
//         offset += memorylayout<simd3<float>>.stride
//
//         descriptor.attributes[1] = mdlvertexattribute(
//             name: mdlvertexattributenormal,
//             format: .float3,
//             offset: offset,
//             bufferindex: 0)
//         offset += memorylayout<simd3<float>>.stride
//
//         descriptor.attributes[2] = mdlvertexattribute(
//             name: mdlvertexattributetexturecoordinate,
//             format: .float2,
//             offset: offset,
//             bufferindex: 0)
//         offset += memorylayout<simd2<float>>.stride
//
//         descriptor.attributes[3] = mdlvertexattribute(
//             name: mdlvertexattributetangent,
//             format: .float3,
//             offset: offset,
//             bufferindex: 0)
//         offset += memorylayout<simd3<float>>.stride
//
//         descriptor.attributes[4] = mdlvertexattribute(
//             name: mdlvertexattributebitangent,
//             format: .float3,
//             offset: offset,
//             bufferindex: 0)
//         offset += memorylayout<simd3<float>>.stride
//
//         descriptor.layouts[0] = mdlvertexbufferlayout(stride: offset)
//         return descriptor
//     }()
//
//     public init() {}
//
//     public func load(from url: url) throws {
//         guard let device = mtlcreatesystemdefaultdevice() else {
//             throw modelloadererror.failedtoloadasset("no metal device available")
//         }
//         let allocator = mtkmeshbufferallocator(device: device)
//         asset = mdlasset(url: url, vertexdescriptor: vertexdescriptor, bufferallocator: allocator)
//         guard let asset = asset else {
//             throw modelloadererror.failedtoloadasset("failed to load asset")
//         }
//         if #available(ios 11.0, macos 10.13, *) {
//             asset.upaxis = simd3<float>(0, 1, 0)
//         }
//         try loadmeshes()
//         log.info("model loaded")
//     }
//
//     private func loadmeshes() throws {
//         guard let foundmeshes = asset?.childobjects(of: mdlmesh.self) as? [mdlmesh],
//             !foundmeshes.isempty
//         else {
//             throw modelloadererror.invalidmesh
//         }
//         meshes = foundmeshes
//         for mesh in meshes {
//             mesh.transform = mdltransform()
//             if let attributes = mesh.vertexdescriptor.attributes as? [mdlvertexattribute] {
//                 if !attributes.contains(where: { $0.name == mdlvertexattributenormal }) {
//                     mesh.addnormals(
//                         withattributenamed: mdlvertexattributenormal, creasethreshold: 0.5)
//                 }
//                 if !attributes.contains(where: { $0.name == mdlvertexattributetangent }) {
//                     mesh.addtangentbasis(
//                         fortexturecoordinateattributenamed: mdlvertexattributetexturecoordinate,
//                         tangentattributenamed: mdlvertexattributetangent,
//                         bitangentattributenamed: mdlvertexattributebitangent)
//                 }
//             }
//         }
//     }
//
//     public func extractmeshdata(from mesh: mdlmesh) -> meshdata? {
//         guard let vertexbuffer = mesh.vertexbuffers.first as? mdlmeshbuffer,
//             let layout = mesh.vertexdescriptor.layouts[0] as? mdlvertexbufferlayout
//         else { return nil }
//         let vertexmap = vertexbuffer.map()
//         let vertexdata = vertexmap.bytes
//         let stride = int(layout.stride)
//         var vertices = [staticmodelvertex]()
//         vertices.reservecapacity(mesh.vertexcount)
//         var attributemap = [string: (offset: int, format: mdlvertexformat)]()
//         for attribute in mesh.vertexdescriptor.attributes as? [mdlvertexattribute] ?? [] {
//             attributemap[attribute.name] = (int(attribute.offset), attribute.format)
//         }
//         for i in 0..<mesh.vertexcount {
//             let baseaddress = vertexdata.advanced(by: i * stride)
//             var vertex = staticmodelvertex(
//                 position: simd3<float>(0, 0, 0),
//                 normal: simd3<float>(0, 0, 0),
//                 texturecoordinate: simd2<float>(0, 0),
//                 tangent: simd3<float>(0, 0, 0),
//                 bitangent: simd3<float>(0, 0, 0))
//             if let (offset, _) = attributemap[mdlvertexattributeposition] {
//                 let pos = baseaddress.advanced(by: offset).assumingmemorybound(
//                     to: simd3<float>.self
//                 ).pointee
//                 if changecoordinatesystem {
//                     let t = blendertometalmatrix * simd4<float>(pos.x, pos.y, pos.z, 1)
//                     vertex.position = simd3<float>(t.x, t.y, t.z) / t.w
//                 } else {
//                     vertex.position = pos
//                 }
//             }
//             if let (offset, _) = attributemap[mdlvertexattributenormal] {
//                 let n = baseaddress.advanced(by: offset).assumingmemorybound(to: simd3<float>.self)
//                     .pointee
//                 if changecoordinatesystem {
//                     let t = blendertometalmatrix * simd4<float>(n.x, n.y, n.z, 0)
//                     vertex.normal = normalize(simd3<float>(t.x, t.y, t.z))
//                 } else {
//                     vertex.normal = normalize(n)
//                 }
//             }
//             if let (offset, _) = attributemap[mdlvertexattributetexturecoordinate] {
//                 vertex.texturecoordinate =
//                     baseaddress.advanced(by: offset).assumingmemorybound(to: simd2<float>.self)
//                     .pointee
//             }
//             if let (offset, _) = attributemap[mdlvertexattributetangent] {
//                 let tan = baseaddress.advanced(by: offset).assumingmemorybound(
//                     to: simd3<float>.self
//                 ).pointee
//                 if changecoordinatesystem {
//                     let t = blendertometalmatrix * simd4<float>(tan.x, tan.y, tan.z, 0)
//                     vertex.tangent = normalize(simd3<float>(t.x, t.y, t.z))
//                 } else {
//                     vertex.tangent = normalize(tan)
//                 }
//             }
//             if let (offset, _) = attributemap[mdlvertexattributebitangent] {
//                 let bitan = baseaddress.advanced(by: offset).assumingmemorybound(
//                     to: simd3<float>.self
//                 ).pointee
//                 if changecoordinatesystem {
//                     let t = blendertometalmatrix * simd4<float>(bitan.x, bitan.y, bitan.z, 0)
//                     vertex.bitangent = normalize(simd3<float>(t.x, t.y, t.z))
//                 } else {
//                     vertex.bitangent = normalize(bitan)
//                 }
//             }
//             vertices.append(vertex)
//         }
//         var indices = [uint32]()
//         if let submeshes = mesh.submeshes as? [mdlsubmesh] {
//             for submesh in submeshes {
//                 guard let indexbuffer = submesh.indexbuffer as? mdlmeshbuffer else { continue }
//                 let indexmap = indexbuffer.map()
//                 let indexdata = indexmap.bytes
//                 let indexcount = submesh.indexcount
//                 switch submesh.indextype {
//                 case .uint32:
//                     let ptr = indexdata.assumingmemorybound(to: uint32.self)
//                     indices.append(contentsof: unsafebufferpointer(start: ptr, count: indexcount))
//                 case .uint16:
//                     let ptr = indexdata.assumingmemorybound(to: uint16.self)
//                     indices.append(
//                         contentsof: unsafebufferpointer(start: ptr, count: indexcount).map {
//                             uint32($0)
//                         })
//                 case .uint8:
//                     let ptr = indexdata.assumingmemorybound(to: uint8.self)
//                     indices.append(
//                         contentsof: unsafebufferpointer(start: ptr, count: indexcount).map {
//                             uint32($0)
//                         })
//                 default:
//                     log.error("model3d invalid index type")
//                     continue
//                 }
//             }
//         }
//         guard !vertices.isempty, !indices.isempty else { return nil }
//         return meshdata(vertices: vertices, indices: indices)
//     }
//
//     public func printmodelinfo() {
//         log.info("\n=== model information ===")
//         log.info("number of meshes: \(meshes.count)")
//         for (index, mesh) in meshes.enumerated() {
//             log.info("\nmesh \(index + 1):")
//             log.info("- vertex count: \(mesh.vertexcount)")
//             log.info("- submesh count: \(mesh.submeshes?.count ?? 0)")
//         }
//     }
// }
