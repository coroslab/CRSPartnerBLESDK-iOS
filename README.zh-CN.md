# CRSPartnerBLESDK iOS

中文 | [English](README.md)

CRSPartnerBLESDK 是面向 iOS Partner App 的 COROS Partner BLE SDK。

## 环境要求

- iOS 14.0 或以上。
- Xcode 15 或以上。
- 已在 COROS 开放平台登记 `clientId`、callback URI 和 Bundle ID。

## Swift Package Manager

在 Xcode 中选择 **File > Add Package Dependencies**，添加：

```text
https://github.com/coroslab/CRSPartnerBLESDK-iOS.git
```

选择 `CRSPartnerBLESDK` product。

## CocoaPods

在 `Podfile` 中添加：

```ruby
platform :ios, '14.0'

target 'YourApp' do
  use_frameworks!
  pod 'CRSPartnerBLESDK', '~> 0.1.4'
end
```

Pod 内包含 `CRSPartnerBLESDK.xcframework`。

## 基础用法

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

开启心率广播：

```swift
let token = try await CRSPartnerBLESDKClient.shared.startHeartBroadcast(
    sportStartUtc: UInt32(Date().timeIntervalSince1970)
) { sample in
    print(sample.timestampS, sample.heartRate)
}

token.stop()
```

## 文档

查看 [中文接入说明](Docs/IntegrationGuide.md) 或 [English Integration Guide](Docs/IntegrationGuide.en.md)。

## Demo

Demo App 位于 [Demo](Demo)。工程包含两个 target，可分别验证 CocoaPods 和 Swift Package Manager 接入：

```sh
cd Demo
pod install
open CRSPartnerBLEDemo.xcworkspace
```

构建 `CRSPartnerBLEDemoPods` 验证 CocoaPods 接入，或构建 `CRSPartnerBLEDemoSPM` 验证 Swift Package Manager 接入。
`CRSPartnerBLEDemoPods` 保留默认 demo Bundle ID 和 callback scheme。`CRSPartnerBLEDemoSPM` 使用独立 Bundle ID 和 callback scheme，完整授权流程联调前需要先登记这些值。

## 版本

当前版本：`0.1.4`。
