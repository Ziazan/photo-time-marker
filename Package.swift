// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacPhotoWatermark",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MacPhotoWatermark", targets: ["MacPhotoWatermark"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MacPhotoWatermark",
            dependencies: [],
            path: "Sources",
            resources: [
                .process("Resources")
            ]
        )
    ]
) 