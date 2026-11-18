# Changelog

[中文](CHANGELOG.zh-CN.md) | English

## 0.1.5 — 2026-11-18

### Fix authorization remaining pending when checking again

- Fixed `authorization is already pending` when `authorize()` is called again before the previous authorization callback arrives, for example after switching back from COROS and tapping the partner app's check/open-COROS button again.
- Repeated/concurrent authorization calls on the same SDK instance now share one server request, authorization `state`, and callback result. Once the link is available, another call reopens COROS using that same link without replacing the original `state`.
- Coalesced URL opens already in flight and rapid taps less than one second apart.
- Cancelling a caller's Task only ends that caller's wait. The current flow remains available for a subsequent `authorize()` call to reopen COROS.
- Authorization waits time out after at most five minutes, or earlier when the signed link expires. The next call replaces an expired flow with a fresh authorization request. The SDK also checks expiry when the app becomes active.
- Isolated callbacks and timers by authorization session so stale callbacks do not update the active flow and old timers cannot end a newer flow.

### Upgrade and compatibility

- Public APIs are unchanged; no new interface is required. Partner apps, including Xunji, only need to update the SDK without adding cancellation hooks or changing existing `authorize()` calls.
- The existing integration requirement still applies: forward COROS callback URLs unchanged to `handleOpenURL(_:)` on the same SDK instance that started authorization. The SDK cannot receive the host app's system URL callbacks on its behalf.
- Select version `0.1.5` in Swift Package Manager. CocoaPods users can pin this repository's Git tag:

```ruby
pod 'CRSPartnerBLESDK', :git => 'https://github.com/coroslab/CRSPartnerBLESDK-iOS.git', :tag => '0.1.5'
```

## 0.1.4

- Moved the public SDK repository to the `coroslab` GitHub organization.
- Updated Swift Package Manager and CocoaPods source URLs to `github.com/coroslab/CRSPartnerBLESDK-iOS`.

## 0.1.3

- Removed the public SwiftProtobuf dependency from Swift Package Manager and CocoaPods integration.
- Updated the binary framework to expose SDK wrapper models instead of protobuf-generated models.
- Added separate demo targets for CocoaPods and Swift Package Manager verification.

## 0.1.2

- Initial CRSPartnerBLESDK iOS external package.
- Added iOS integration guide.
- Added demo app that integrates the generated framework package.
- Added Swift Package Manager and CocoaPods integration for `CRSPartnerBLESDK.xcframework`.
