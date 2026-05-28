# CRSPartnerBLESDK iOS 接入说明

中文 | [English](IntegrationGuide.en.md)

本文面向 Partner App iOS 接入方，只描述对外公开 API 和必要 App 配置。

## 1. 接入前准备

### 1.1 系统要求

- iOS 14.0 及以上。
- Partner App 需要具备蓝牙权限说明文案。
- 用户手机需要安装并登录 COROS App。
- 用户需要在 COROS App 内完成授权，并保持目标 COROS 设备可被 COROS App 连接。

### 1.2 开放平台注册信息

接入前请向 COROS 开放平台确认以下信息：

- `clientId`：COROS 分配给 Partner App 的客户端标识。
- Partner App Bundle ID：由 SDK 在运行时读取，需与服务端登记值一致。
- Callback URI：Partner App 用于接收 COROS App 授权回调的 URI，例如 `yourapp://coros/ble/callback`。
- Server Environment：生产环境或测试环境。
- Partner User ID：Partner App 自有用户标识，需要在同一个 Partner App 用户生命周期内保持稳定。

`partnerUserId` 切换代表 Partner App 登录用户切换。账号切换后请重新初始化 SDK，并重新走授权流程。

## 2. App 配置

### 2.1 URL Scheme

Partner App 需要在 `Info.plist` 中注册 callback URI 使用的 scheme。示例：

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.example.partner.callback</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>yourapp</string>
        </array>
    </dict>
</array>
```

### 2.2 蓝牙权限说明

Partner App 需要配置蓝牙权限说明文案：

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app uses Bluetooth to connect to your authorized COROS device.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app uses Bluetooth to receive heart rate data from your authorized COROS device.</string>
```

## 3. 引入 SDK

### 3.1 Swift Package Manager

在 Xcode 中选择 **File > Add Package Dependencies**，添加：

```text
https://github.com/coroslab/CRSPartnerBLESDK-iOS.git
```

选择 `CRSPartnerBLESDK` product。

### 3.2 CocoaPods

在 `Podfile` 中添加：

```ruby
platform :ios, '14.0'

target 'YourApp' do
  use_frameworks!
  pod 'CRSPartnerBLESDK', '~> 0.1.4'
end
```

业务代码引入：

```swift
import CRSPartnerBLESDK
```

业务代码通过 `CRSPartnerBLESDK` 提供的 public API 完成接入。

Demo 工程包含 `CRSPartnerBLEDemoPods` 和 `CRSPartnerBLEDemoSPM` 两个 target，分别用于验证 CocoaPods 和 Swift Package Manager 接入。`CRSPartnerBLEDemoPods` 保留默认 demo Bundle ID 和 callback scheme；`CRSPartnerBLEDemoSPM` 使用独立 Bundle ID 和 callback scheme，完整授权联调前需要在服务端单独登记。

## 4. 初始化

建议在 App 启动后、业务使用 SDK 前完成初始化：

```swift
import CRSPartnerBLESDK

let sdk = CRSPartnerBLESDKClient.shared

try sdk.initialize(
    CRSSdkInitConfig(
        clientId: "<clientId from COROS Open Platform>",
        partnerUserId: "<stable partner user id>",
        environment: .serverEnvironmentProduction,
        logOptions: .disabled
    )
)
```

参数说明：

| 参数 | 说明 |
| --- | --- |
| `clientId` | COROS 分配给 Partner App 的客户端标识。 |
| `partnerUserId` | Partner App 自有用户标识，必须非空。 |
| `environment` | SDK 服务环境，生产环境使用 `.serverEnvironmentProduction`，测试环境使用 `.serverEnvironmentTest`。 |
| `logOptions` | SDK 日志配置，默认关闭。 |

## 5. 授权

Partner App 调用 `authorize()` 发起授权。SDK 会在需要时打开 COROS App，用户在 COROS App 内完成授权后，通过 callback URI 回到 Partner App。

```swift
do {
    let result = try await sdk.authorize()
    let devices = result.devices
    // 保存或展示已授权设备信息。
} catch let error as CRSSdkError {
    // 使用 error.code 做业务提示或重试决策。
} catch {
    // 处理其他系统错误。
}
```

默认授权范围为 BLE 心率广播权限。当前没有特殊需求时，不需要传入 `CRSAuthorizationRequest`。

### 5.1 转交授权回调

iOS 无法让 SDK 自动接管 Partner App 的 URL 回调，Partner App 需要在收到 callback URI 后转交给 SDK。

SwiftUI 示例：

```swift
.onOpenURL { url in
    Task {
        do {
            let result = try await CRSPartnerBLESDKClient.shared.handleOpenURL(url)
            // result.devices 为本次授权后的设备列表。
        } catch {
            // 展示授权失败原因或记录日志。
        }
    }
}
```

UIKit SceneDelegate 示例：

```swift
func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let url = URLContexts.first?.url else { return }
    Task {
        _ = try await CRSPartnerBLESDKClient.shared.handleOpenURL(url)
    }
}
```

Partner App 收到 Callback URI 后，只需要原样转交给 `handleOpenURL(_:)`，不要解析、修改或持久化。

## 6. 获取授权设备

授权完成后，可读取当前已授权设备列表。

```swift
let devices = try await CRSPartnerBLESDKClient.shared.listAuthorizedDevices()

for device in devices {
    print(device.deviceName)
    print(device.deviceModel)
    print(device.connectionState)
}
```

对外字段说明：

| 字段 | 说明 |
| --- | --- |
| `deviceName` | COROS 设备的完整蓝牙名称。 |
| `deviceModel` | 标准设备型号。 |
| `connectionState` | 当前连接状态。 |

当前对外心率接口按“当前唯一授权设备”工作；如果没有授权设备、授权设备超过当前支持数量，或设备未就绪，SDK 会抛出 `CRSSdkError`。

## 7. 心率广播

调用 `startHeartBroadcast(sportStartUtc:onSample:)` 开启手表心率广播并监听心率样本。返回值也是本次会话的停止句柄。

```swift
let sportStartUtc = UInt32(Date().timeIntervalSince1970)

let hrToken = try await CRSPartnerBLESDKClient.shared.startHeartBroadcast(
    sportStartUtc: sportStartUtc
) { sample in
    print("heart rate:", sample.heartRate)
    print("timestamp:", sample.timestampS)
}

// 需要停止心率广播时调用：
hrToken.stop()
```

`CRSHeartRateSample` 字段说明：

| 字段 | 说明 |
| --- | --- |
| `sportStartUtc` | 本次运动开始时间，Unix 秒级时间戳。 |
| `timestampS` | 样本时间，Unix 秒级时间戳。 |
| `heartRate` | 心率值，单位 bpm。 |

建议在业务页面退出、运动结束、用户退出登录或 App 不再需要数据时调用 `hrToken.stop()`。

## 8. 撤销授权

Partner App 可调用 `revoke()` 撤销当前授权。

```swift
do {
    try await CRSPartnerBLESDKClient.shared.revoke()
} catch {
    // 根据业务需要提示或重试。
}
```

撤销后再次使用心率能力前，需要重新授权。

## 9. 错误处理

SDK 统一通过 `CRSSdkError` 返回稳定错误码、可读信息和可选服务端追踪 ID。

```swift
do {
    _ = try await CRSPartnerBLESDKClient.shared.listAuthorizedDevices()
} catch let error as CRSSdkError {
    switch error.code {
    case .notAuthorized:
        // 引导用户重新授权。
        break
    case .deviceNotReady:
        // 提示用户确认 COROS App 和设备连接状态。
        break
    case .bluetoothPoweredOff, .bluetoothUnauthorized:
        // 引导用户打开蓝牙或授权系统权限。
        break
    case .rebindRequired, .commandChannelAuthFailed:
        // 重新发起授权。
        break
    default:
        // 其他错误按业务兜底处理。
        break
    }
}
```

排查服务端相关问题时，可同时上报 `CRSSdkError.tLogId` 给 COROS 支持人员。

## 10. 日志

SDK 日志默认关闭。联调或问题排查时可打开内存日志、控制台日志或文件日志。

```swift
try CRSPartnerBLESDKClient.shared.initialize(
    CRSSdkInitConfig(
        clientId: "<clientId>",
        partnerUserId: "<partnerUserId>",
        environment: .serverEnvironmentTest,
        logOptions: CRSLogOptions(
            isEnabled: true,
            printsToConsole: true,
            writesToFile: true,
            maxStoredEntries: 200,
            minimumLevel: .info
        )
    )
)
```

读取日志：

```swift
let entries = CRSPartnerBLESDKClient.shared.logSnapshot()
let logFileURL = CRSPartnerBLESDKClient.shared.currentLogFileURL()
CRSPartnerBLESDKClient.shared.clearLogs()
```

日志仅用于联调和故障排查。Partner App 上传或转发日志前，应遵守自身隐私政策并取得必要授权。

## 11. 接入检查清单

- `clientId` 已在 COROS 开放平台登记。
- Partner App Bundle ID 已在 COROS 开放平台登记。
- Callback URI 已登记，并与 `Info.plist` 中 URL Scheme 一致。
- `partnerUserId` 非空，且与 Partner App 登录用户稳定绑定。
- 测试环境使用 `.serverEnvironmentTest`，生产环境使用 `.serverEnvironmentProduction`。
- App 已配置蓝牙权限说明。
- App 的 URL 回调已转交给 `handleOpenURL(_:)`。
- 授权成功后再调用心率能力。
- 页面退出、运动结束或账号切换时停止心率广播。
