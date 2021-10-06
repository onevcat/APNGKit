// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "APNGKit",
    platforms: [.macOS(.v10_12), .iOS(.v10), .tvOS(.v10)],
    products: [
        .library(name: "APNGKit", targets: ["APNGKit"])
    ],
    targets: [
        .target(name: "APNGKit"),
        .testTarget(name: "APNGKitTests", dependencies: ["APNGKit"], resources: [
            .copy("Resources/SpecTesting")
        ])
    ]
)
