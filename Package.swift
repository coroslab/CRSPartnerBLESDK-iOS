// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CRSPartnerBLESDK",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "CRSPartnerBLESDK",
            targets: [
                "CRSPartnerBLESDK"
            ]
        )
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "CRSPartnerBLESDK",
            path: "Frameworks/CRSPartnerBLESDK.xcframework"
        )
    ]
)
