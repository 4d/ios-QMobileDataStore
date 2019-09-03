// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "QMobileDataStore",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(  name: "QMobileDataStore",  targets: ["QMobileDataStore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/DaveWoodCom/XCGLogger.git", from: "7.0.0"),
        .package(url: "https://github.com/phimage/MomXML.git", .revision("HEAD")),
        .package(url: "https://github.com/phimage/Prephirences.git", .revision("HEAD"))
    ],
    targets: [
        .target(
            name: "QMobileDataStore",
            dependencies: [
                "XCGLogger",
                "MomXML",
                "Prephirences"
            ],
            path: "Sources"),
        .testTarget(
            name: "QMobileDataStoreTests",
            dependencies: ["QMobileDataStore"],
            path: "Tests")
    ]
)
