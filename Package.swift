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
            targets: ["TNFEngine", "Engine", "Support"])
    ],
    dependencies: [],
    targets: [
        // Main target that exports the other components
        .target(
            name: "TNFEngine",
            dependencies: ["Engine", "Support"],
            path: "Sources/TNFEngine"),

        // Engine component
        .target(
            name: "Engine",
            dependencies: [],
            path: "Sources/Engine"),

        // Support component
        .target(
            name: "Support",
            dependencies: [],
            path: "Sources/Support"),

        // Test target
        .testTarget(
            name: "TNFEngineTests",
            dependencies: ["TNFEngine"]),
    ]
)
