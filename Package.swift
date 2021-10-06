// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "APNGKit",
    platforms: [.macOS(.v10_10), .iOS(.v8)],
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
