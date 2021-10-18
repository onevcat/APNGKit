// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "APNGKit",
    platforms: [.macOS(.v10_12), .iOS(.v10), .tvOS(.v10)],
    products: [
        .library(name: "APNGKit", targets: ["APNGKit"])
    ],
    dependencies: [
        .package(name: "Delegate", url: "https://github.com/onevcat/Delegate.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(name: "APNGKit", dependencies: ["Delegate"]),
        .testTarget(name: "APNGKitTests", dependencies: ["APNGKit"], resources: [
            .copy("Resources/SpecTesting"),
            .copy("Resources/General")
        ])
    ]
)
