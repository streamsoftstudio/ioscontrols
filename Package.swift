// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IOSControls",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "IOSControls",
            targets: ["IOSControls"]
        ),
    ],
    targets: [
        .target(name: "IOSControls"),
        .testTarget(
            name: "IOSControlsTests",
            dependencies: ["IOSControls"]
        ),
    ]
)
