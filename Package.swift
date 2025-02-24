// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "TNFEngine",
    platforms: [
        .macOS(.v13),
        .iOS(.v15),
    ],
    products: [
        .library(
            name: "TNFEngine",
            targets: ["TNFEngine", "Utilities"])
    ],
    dependencies: [],
    targets: [

        .target(
            name: "TNFEngine",
            dependencies: ["Utilities"],
            path: "Sources/TNFEngine",
            resources: [
                .process("Assets")
            ]
        ),

        .target(
            name: "Utilities",
            dependencies: [],
            path: "Sources/Utilities"
        ),

        // .testTarget(
        //     name: "TNFEngineTests",
        //     dependencies: ["TNFEngine"]
        // ),
    ]
)
