# CRSPartnerBLESDK iOS

[中文](README.zh-CN.md) | English

CRSPartnerBLESDK is the COROS Partner BLE SDK for iOS apps.

## Requirements

- iOS 14.0 or later.
- Xcode 15 or later.
- COROS Open Platform `clientId`, callback URI, and bundle ID registration.

## Swift Package Manager

In Xcode, open **File > Add Package Dependencies** and add:

```text
https://github.com/coroschina/CRSPartnerBLESDK-iOS.git
```

Select the `CRSPartnerBLESDK` product.

## CocoaPods

Add the SDK to your `Podfile`:

```ruby
platform :ios, '14.0'

target 'YourApp' do
  use_frameworks!
  pod 'CRSPartnerBLESDK', '~> 0.1.3'
end
```

The pod includes `CRSPartnerBLESDK.xcframework`.

## Basic Usage

```swift
import CRSPartnerBLESDK

let sdk = CRSPartnerBLESDKClient.shared

try sdk.initialize(
    CRSSdkInitConfig(
        clientId: "<clientId>",
        partnerUserId: "<partnerUserId>",
        environment: .serverEnvironmentProduction
    )
)

let auth = try await sdk.authorize()
let devices = auth.devices
```

Start heart rate broadcast:

```swift
let token = try await CRSPartnerBLESDKClient.shared.startHeartBroadcast(
    sportStartUtc: UInt32(Date().timeIntervalSince1970)
) { sample in
    print(sample.timestampS, sample.heartRate)
}

token.stop()
```

## Documentation

See [English Integration Guide](Docs/IntegrationGuide.en.md) or [中文接入说明](Docs/IntegrationGuide.md).

## Demo

The demo app is in [Demo](Demo). It contains two targets so CocoaPods and Swift Package Manager can be verified independently:

```sh
cd Demo
pod install
open CRSPartnerBLEDemo.xcworkspace
```

Build `CRSPartnerBLEDemoPods` to verify CocoaPods integration, or build `CRSPartnerBLEDemoSPM` to verify Swift Package Manager integration.
`CRSPartnerBLEDemoPods` keeps the default demo bundle ID and callback scheme. `CRSPartnerBLEDemoSPM` uses a separate bundle ID and callback scheme, so register those values before running the full authorization flow from that target.

## Version

Current version: `0.1.3`.
