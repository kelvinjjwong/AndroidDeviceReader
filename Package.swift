// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AndroidDeviceReader",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AndroidDeviceReader",
            targets: ["AndroidDeviceReader"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/kelvinjjwong/SharedDeviceLib", from: "1.0.3"),
        .package(url: "https://github.com/kelvinjjwong/LoggerFactory", from: "1.1.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "AndroidDeviceReader",
            dependencies: ["SharedDeviceLib", "LoggerFactory"]),
        .testTarget(
            name: "AndroidDeviceReaderTests",
            dependencies: ["SharedDeviceLib", "LoggerFactory", "AndroidDeviceReader"]),
    ],
    swiftLanguageVersions: [.v5]
)
