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
                "CRSPartnerBLESDK",
                "CRSPartnerBLESDKDependencies"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.37.0")
    ],
    targets: [
        .binaryTarget(
            name: "CRSPartnerBLESDK",
            path: "Frameworks/CRSPartnerBLESDK.xcframework"
        ),
        .target(
            name: "CRSPartnerBLESDKDependencies",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ],
            path: "Support/CRSPartnerBLESDKDependencies"
        )
    ]
)
