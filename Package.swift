// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "APNGKit",
    platforms: [.macOS(.v10_10), .iOS(.v8)],
    products: [
        .library(
            name: "APNGKit",
            targets: ["APNGKit"]),
        .library(
            name: "Clibpng",
            targets: ["Clibpng"]),
    ],
    targets: [
        .target(
            name: "APNGKit",
            dependencies: [
                "Clibpng",
            ],
            path: "APNGKit",
            exclude: ["libpng-apng"]
        ),
        .target(
            name: "Clibpng",
            path: "APNGKit/libpng-apng"),
    ],
    swiftLanguageVersions: [.v4_2]
)
