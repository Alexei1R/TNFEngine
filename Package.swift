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
            targets: ["TNFEngine", "Engine", "Utilities"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "TNFEngine",
            dependencies: ["Engine", "Utilities"],
            path: "Sources/TNFEngine"
        ),

        .target(
            name: "Engine",
            dependencies: [],
            path: "Sources/Engine",
            resources: [
                .process("Shaders")
            ]
        ),

        .target(
            name: "Utilities",
            dependencies: [],
            path: "Sources/Utilities"
        ),

        .testTarget(
            name: "TNFEngineTests",
            dependencies: ["TNFEngine"]
        ),
    ]
)
