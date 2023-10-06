// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DIVESDK",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "DIVEOnlineSDK",
            targets: ["DIVEOnlineSDK"]),
        .library(
            name: "DIVESDK",
            targets: ["DIVESDK"])
    ],
    dependencies: [
        .package(url: "https://github.com/IDScanNet/IDScanIDDetectorIOS.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/IDScanNet/IDScanToolsIOS.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(
            name: "DIVESDKCommon",
            dependencies: [
                
            ]
        ),
        .target(
            name: "DIVEOnlineSDK",
            dependencies: [
                "DIVESDKCommon",
                "IDScanCapture",
                .product(name: "IDScanPDFDetector", package: "IDScanIDDetectorIOS"),
                .product(name: "IDScanMRZDetector", package: "IDScanIDDetectorIOS"),
                .product(name: "IDSSystemInfo", package: "IDScanToolsIOS"),
                .product(name: "IDSLocationManager", package: "IDScanToolsIOS")
            ]
        ),
        .target(
            name: "DIVESDK",
            dependencies: [
                "DIVESDKCommon",
                "IDScanCapture",
                .product(name: "IDScanPDFDetector", package: "IDScanIDDetectorIOS"),
                .product(name: "IDScanMRZDetector", package: "IDScanIDDetectorIOS")
            ]
        ),
        .binaryTarget(
            name: "IDScanCapture",
            path: "Libs/IDScanCapture.xcframework"
        )
    ]
)
