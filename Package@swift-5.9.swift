// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "APNGKit",
    platforms: [.macOS(.v10_14), .iOS(.v12), .tvOS(.v12), .visionOS(.v1)],
    products: [
        .library(name: "APNGKit", targets: ["APNGKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/onevcat/Delegate.git", from: "1.3.0")
    ],
    targets: [
        .target(
            name: "APNGKit",
            dependencies: ["Delegate"],
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .testTarget(
            name: "APNGKitTests",
            dependencies: ["APNGKit"],
            resources: [
                .copy("Resources/SpecTesting"),
                .copy("Resources/General"),
            ]
        )
    ]
)
