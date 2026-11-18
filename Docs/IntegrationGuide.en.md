# CRSPartnerBLESDK iOS Integration Guide

[中文](IntegrationGuide.md) | English

This guide is for Partner App iOS integration. It only covers public SDK APIs and required app configuration.

## 1. Before You Start

### 1.1 Requirements

- iOS 14.0 or later.
- The Partner App must provide Bluetooth permission descriptions.
- The user must have COROS App installed and signed in.
- The user must complete authorization in COROS App, and the target COROS device must remain connectable by COROS App.

### 1.2 Open Platform Registration

Confirm the following values with COROS Open Platform before integration:

- `clientId`: the client identifier assigned to the Partner App by COROS.
- Partner App Bundle ID: read by the SDK at runtime and must match the server registration.
- Callback URI: the URI used by the Partner App to receive COROS App authorization callbacks, for example `yourapp://coros/ble/callback`.
- Server Environment: production or test.
- Partner User ID: the Partner App's own user identifier. It must remain stable during the same Partner App user lifecycle.

Changing `partnerUserId` means the Partner App login user has changed. Reinitialize the SDK and run authorization again after account switching.

## 2. App Configuration

### 2.1 URL Scheme

Register the callback URI scheme in `Info.plist`. Example:

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

### 2.2 Bluetooth Permission Descriptions

Configure Bluetooth permission descriptions:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app uses Bluetooth to connect to your authorized COROS device.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app uses Bluetooth to receive heart rate data from your authorized COROS device.</string>
```

## 3. Add the SDK

### 3.1 Swift Package Manager

In Xcode, select **File > Add Package Dependencies** and add:

```text
https://github.com/coroslab/CRSPartnerBLESDK-iOS.git
```

Select the `CRSPartnerBLESDK` product.

### 3.2 CocoaPods

Add the SDK to your `Podfile`:

```ruby
platform :ios, '14.0'

target 'YourApp' do
  use_frameworks!
  pod 'CRSPartnerBLESDK', :git => 'https://github.com/coroslab/CRSPartnerBLESDK-iOS.git', :tag => '0.1.5'
end
```

Import the SDK in app code:

```swift
import CRSPartnerBLESDK
```

Use the public APIs provided by `CRSPartnerBLESDK` for integration.

The demo project contains two targets: `CRSPartnerBLEDemoPods` and `CRSPartnerBLEDemoSPM`. They verify CocoaPods and Swift Package Manager integration independently. `CRSPartnerBLEDemoPods` keeps the default demo Bundle ID and callback scheme. `CRSPartnerBLEDemoSPM` uses a separate Bundle ID and callback scheme; register those values on the server before running the full authorization flow.

## 4. Initialize

Initialize the SDK after app startup and before using SDK features:

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

Parameters:

| Parameter | Description |
| --- | --- |
| `clientId` | Client identifier assigned to the Partner App by COROS. |
| `partnerUserId` | Partner App user identifier. Must be non-empty. |
| `environment` | SDK server environment. Use `.serverEnvironmentProduction` for production and `.serverEnvironmentTest` for test. |
| `logOptions` | SDK log configuration. Disabled by default. |

## 5. Authorization

Call `authorize()` to start authorization. The SDK opens COROS App when needed. After the user completes authorization in COROS App, COROS App returns to the Partner App through the callback URI.

```swift
do {
    let result = try await sdk.authorize()
    let devices = result.devices
    // Store or display authorized device information.
} catch let error as CRSSdkError {
    // Use error.code for business prompts or retry decisions.
} catch {
    // Handle other system errors.
}
```

The default authorization scope is BLE heart rate broadcast permission. If there is no special requirement, you do not need to pass `CRSAuthorizationRequest`.

### 5.1 Forward Authorization Callback

iOS does not allow the SDK to automatically take over the Partner App URL callback. The Partner App must forward the callback URI to the SDK after receiving it.

SwiftUI example:

```swift
.onOpenURL { url in
    Task {
        do {
            let result = try await CRSPartnerBLESDKClient.shared.handleOpenURL(url)
            // result.devices is the device list after this authorization.
        } catch {
            // Display the authorization failure reason or record logs.
        }
    }
}
```

UIKit SceneDelegate example:

```swift
func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let url = URLContexts.first?.url else { return }
    Task {
        _ = try await CRSPartnerBLESDKClient.shared.handleOpenURL(url)
    }
}
```

After receiving the callback URI, forward it as-is to `handleOpenURL(_:)`. Do not parse, modify, or persist it.

### 5.2 Repeated calls and retries (0.1.5+)

No new API or changes to existing call sites are required. Multiple `authorize()` calls on the same SDK instance wait for the same authorization result. Once the link is ready, another call reopens COROS using that link. URL opens already in flight and taps less than one second apart are coalesced.

Cancelling one caller's Task only cancels that caller's wait, leaving the shared flow available for later calls. The flow expires after five minutes or the earlier signed-link deadline; calling again after expiry starts a fresh authorization. Stale callbacks and timers cannot finish a newer flow.

The host app must still forward callback URLs unchanged as described in section 5.1, using the same SDK instance that started authorization. Updating the SDK does not replace missing host-side URL forwarding.

## 6. List Authorized Devices

After authorization succeeds, read the current authorized device list:

```swift
let devices = try await CRSPartnerBLESDKClient.shared.listAuthorizedDevices()

for device in devices {
    print(device.deviceName)
    print(device.deviceModel)
    print(device.connectionState)
}
```

Public fields:

| Field | Description |
| --- | --- |
| `deviceName` | Full Bluetooth name of the COROS device. |
| `deviceModel` | Standard device model. |
| `connectionState` | Current connection state. |

The current public heart rate API works with the single currently authorized device. If there is no authorized device, more than one authorized device, or the device is not ready, the SDK throws `CRSSdkError`.

## 7. Heart Rate Broadcast

Call `startHeartBroadcast(sportStartUtc:onSample:)` to start watch heart rate broadcast and listen for heart rate samples. The returned value is also the stop handle for this session.

```swift
let sportStartUtc = UInt32(Date().timeIntervalSince1970)

let hrToken = try await CRSPartnerBLESDKClient.shared.startHeartBroadcast(
    sportStartUtc: sportStartUtc
) { sample in
    print("heart rate:", sample.heartRate)
    print("timestamp:", sample.timestampS)
}

// Stop heart rate broadcast when needed:
hrToken.stop()
```

`CRSHeartRateSample` fields:

| Field | Description |
| --- | --- |
| `sportStartUtc` | Start time of this activity, as a Unix timestamp in seconds. |
| `timestampS` | Sample time, as a Unix timestamp in seconds. |
| `heartRate` | Heart rate value in bpm. |

Call `hrToken.stop()` when the business page exits, the activity ends, the user logs out, or the app no longer needs data.

## 8. Revoke Authorization

The Partner App can call `revoke()` to revoke the current authorization.

```swift
do {
    try await CRSPartnerBLESDKClient.shared.revoke()
} catch {
    // Prompt or retry according to business needs.
}
```

After revocation, authorization must be performed again before using heart rate features.

## 9. Error Handling

The SDK returns stable error codes, readable messages, and an optional server trace ID through `CRSSdkError`.

```swift
do {
    _ = try await CRSPartnerBLESDKClient.shared.listAuthorizedDevices()
} catch let error as CRSSdkError {
    switch error.code {
    case .notAuthorized:
        // Guide the user to authorize again.
        break
    case .deviceNotReady:
        // Ask the user to confirm COROS App and device connection state.
        break
    case .bluetoothPoweredOff, .bluetoothUnauthorized:
        // Guide the user to enable Bluetooth or grant system permission.
        break
    case .rebindRequired, .commandChannelAuthFailed:
        // Start authorization again.
        break
    default:
        // Fallback handling for other errors.
        break
    }
}
```

When troubleshooting server-side issues, also provide `CRSSdkError.tLogId` to COROS support.

## 10. Logs

SDK logs are disabled by default. Enable memory logs, console logs, or file logs during integration and troubleshooting.

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

Read logs:

```swift
let entries = CRSPartnerBLESDKClient.shared.logSnapshot()
let logFileURL = CRSPartnerBLESDKClient.shared.currentLogFileURL()
CRSPartnerBLESDKClient.shared.clearLogs()
```

Logs are only for integration and troubleshooting. Before uploading or forwarding logs, the Partner App should follow its own privacy policy and obtain any required authorization.

## 11. Integration Checklist

- `clientId` is registered on COROS Open Platform.
- Partner App Bundle ID is registered on COROS Open Platform.
- Callback URI is registered and matches the URL scheme in `Info.plist`.
- `partnerUserId` is non-empty and stably bound to the Partner App login user.
- Use `.serverEnvironmentTest` for test and `.serverEnvironmentProduction` for production.
- Bluetooth permission descriptions are configured.
- The app URL callback is forwarded to `handleOpenURL(_:)`.
- Heart rate features are called only after authorization succeeds.
- Stop heart rate broadcast when the page exits, the activity ends, or the account switches.
