// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NapsterTV",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "8.9.0")
    ],
    targets: [
        .executableTarget(
            name: "NapsterTV",
            dependencies: [
                .product(name: "Kingfisher", package: "Kingfisher")
            ],
            path: "Sources/NapsterTV",
            resources: [
                .process("../../Resources")
            ]
        )
    ]
)
