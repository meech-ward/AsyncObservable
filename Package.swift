// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AsyncObservable",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AsyncObservable",
            targets: ["AsyncObservable"]),
        .library(
            name: "AsyncObservableUserDefaults",
            targets: ["AsyncObservableUserDefaults"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "AsyncObservable"),
        .target(
            name: "AsyncObservableUserDefaults",
            dependencies: ["AsyncObservable"]),
        .testTarget(
            name: "AsyncObservableTests",
            dependencies: ["AsyncObservable"]
        ),
        .testTarget(
            name: "AsyncObservableUserDefaultsTests",
            dependencies: ["AsyncObservableUserDefaults"]
        ),
    ]
)
