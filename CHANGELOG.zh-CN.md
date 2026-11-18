# 更新日志

中文 | [English](CHANGELOG.md)

## 0.1.5 — 2026-11-18

### 修复授权等待状态导致无法再次检测

- 修复上一轮授权尚未收到回调时，再次调用 `authorize()` 返回 `authorization is already pending` 的问题。典型场景是跳转 COROS 后直接切回 Partner App，再次点击“去高驰检测”或“重新检查”。
- 同一 SDK 实例的重复/并发授权调用现在共用一轮服务端请求、授权 `state` 和回调结果。授权链接可用后，再次调用会复用该链接唤醒 COROS，不会覆盖首轮 `state`。
- 合并正在执行的唤醒操作及间隔不足 1 秒的快速连点，避免反复跳转。
- 取消某个调用方的 Task 只结束该调用方的等待；保留当前授权流程，后续 `authorize()` 仍可继续唤醒 COROS。
- 等待流程最迟在 5 分钟后超时；签名链接更早到期时，以链接有效期为准。后续调用会清理过期流程并创建新一轮授权。SDK 回到前台时也会检查过期状态。
- 隔离每轮授权的定时器和回调；上一轮迟到的回调不会写入当前流程，旧定时器也不会结束新一轮授权。

### 升级与兼容

- 公开 API 保持不变，没有新增接口。训记等 Partner App 只需升级 SDK，无需增加取消接口调用或修改现有 `authorize()` 调用方式。
- 原有接入要求保持有效：收到 COROS 回跳 URL 后，原样转交给发起授权的同一个 SDK 实例的 `handleOpenURL(_:)`。SDK 无法替代宿主 App 接收系统 URL 回调。
- Swift Package Manager 选择版本 `0.1.5`；CocoaPods 可通过本仓库 Git tag 固定该版本：

```ruby
pod 'CRSPartnerBLESDK', :git => 'https://github.com/coroslab/CRSPartnerBLESDK-iOS.git', :tag => '0.1.5'
```

## 0.1.4

- 将 SDK 对外公开仓库迁移到 GitHub `coroslab` 组织下。
- 更新 Swift Package Manager 和 CocoaPods 源地址为 `github.com/coroslab/CRSPartnerBLESDK-iOS`。

## 0.1.3

- 移除 Swift Package Manager 和 CocoaPods 接入中的 public SwiftProtobuf 依赖。
- 更新二进制 framework，对外暴露 SDK wrapper model，不再暴露 protobuf 生成模型。
- 新增 CocoaPods 和 Swift Package Manager 两个独立 demo target，便于分别验证接入方式。

## 0.1.2

- 首次发布 CRSPartnerBLESDK iOS 对外包。
- 新增 iOS 接入说明。
- 新增集成生成 framework 包的 demo app。
- 新增 `CRSPartnerBLESDK.xcframework` 的 Swift Package Manager 和 CocoaPods 接入方式。
