# CRSPartnerBLESDK iOS

CRSPartnerBLESDK is the COROS Partner BLE SDK for iOS apps.

## Requirements

- iOS 14.0 or later.
- Xcode 15 or later.
- COROS Open Platform `clientId`, callback URI, and bundle ID registration.

## Swift Package Manager

In Xcode, open **File > Add Package Dependencies** and add:

```text
https://github.com/coros/CRSPartnerBLESDK-iOS.git
```

Select the `CRSPartnerBLESDK` product.

## CocoaPods

Add the SDK to your `Podfile`:

```ruby
platform :ios, '14.0'

target 'YourApp' do
  use_frameworks!
  pod 'CRSPartnerBLESDK', '~> 0.1.0'
end
```

If the pod is not published to a specs repo yet, use the Git tag directly:

```ruby
pod 'CRSPartnerBLESDK',
    :git => 'https://github.com/coros/CRSPartnerBLESDK-iOS.git',
    :tag => '0.1.0'
```

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

See [Docs/IntegrationGuide.md](Docs/IntegrationGuide.md).

## Demo

The demo app is in [Demo](Demo). It uses CocoaPods:

```sh
cd Demo
pod install
open CRSPartnerBLEDemo.xcworkspace
```

## Version

Current version: `0.1.0`.
