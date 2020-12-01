// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "QMobileDataStore",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v14)
    ],
    products: [
        .library(  name: "QMobileDataStore",  targets: ["QMobileDataStore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/DaveWoodCom/XCGLogger.git", from: "7.0.0"),
        .package(url: "https://github.com/phimage/MomXML.git", .revision("HEAD")),
        .package(url: "https://github.com/phimage/Prephirences.git", from: "5.1.0")
    ],
    targets: [
        .target(
            name: "QMobileDataStore",
            dependencies: [
                "XCGLogger",
                "Prephirences"
            ],
            path: "Sources"),
        .testTarget(
            name: "QMobileDataStoreTests",
            dependencies: ["QMobileDataStore", "MomXML"],
            path: "Tests")
    ]
)
