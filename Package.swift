// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HotSoda",
    products: [
        .library(name: "HotSoda", targets: ["HotSoda"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/fluent-sqlite.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0")
    ],
    targets: [
        .target(name: "HotSoda", dependencies: [
            "FluentSQLite",
            "Vapor"
        ]),
        .testTarget(name: "HotSodaTests", dependencies: ["HotSoda"])
    ]
)
