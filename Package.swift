// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ModelGen",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "modelgen", targets: ["modelgen"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.4.0"),
        // .package(url: "https://github.com/lukepistrol/SwiftLintPlugin", from: "0.58.2"),
        .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.3.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "modelgen",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources",
//            plugins: [
//                .plugin(name: "SwiftLint", package: "SwiftLintPlugin")
//            ]
        ),
        .testTarget(
            name: "modelgenTests",
            dependencies: [ 
                "modelgen",
                .product(name: "CustomDump", package: "swift-custom-dump")
            ],
            path: "Tests"
        )
    ]
)
