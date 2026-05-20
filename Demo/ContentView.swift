import SwiftUI
import UIKit
import CRSPartnerBLESDK

struct ContentView: View {
    @StateObject private var viewModel = DemoViewModel()
    @State private var didAutoAuthorize = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Config")) {
                    LabeledInputRow(
                        title: "clientId",
                        placeholder: "Server SDK client identifier",
                        text: $viewModel.clientId
                    )
                    LabeledInputRow(
                        title: "partnerUserId",
                        placeholder: "Partner app user identifier",
                        text: $viewModel.partnerUserId
                    )
                }

                Section(header: Text("Actions")) {
                    Button("Initialize") {
                        Task { await viewModel.applyPartnerUser() }
                    }
                    Button("Authorize") {
                        Task { await viewModel.authorize() }
                    }
                    Button("Start Heart Broadcast") {
                        Task { await viewModel.start() }
                    }
                    Button("Stop Heart Broadcast") {
                        Task { await viewModel.stop() }
                    }
                    Button("Revoke") {
                        Task { await viewModel.revoke() }
                    }
                    .foregroundColor(.red)
                }

                Section(header: Text("State")) {
                    Text(viewModel.status)
                    if let device = viewModel.deviceText {
                        Text(device)
                            .font(.footnote)
                    }
                }

                Section(header: Text("Logs")) {
                    ForEach(viewModel.logs.indices, id: \.self) { index in
                        Text(viewModel.logs[index])
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Partner BLE Demo")
        }
        .onOpenURL { url in
            Task { await viewModel.handleOpenURL(url) }
        }
        .onAppear {
            guard !didAutoAuthorize else { return }
            didAutoAuthorize = true
            Task {
                let restored = await viewModel.restoreCachedAuthorization()
                guard ProcessInfo.processInfo.arguments.contains("--auto-authorize"),
                      !restored else {
                    return
                }
                await viewModel.authorize()
            }
        }
    }
}

private struct LabeledInputRow: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.footnote)
                .foregroundColor(.secondary)
                .frame(width: 96, alignment: .leading)
            TextField(placeholder, text: $text)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .multilineTextAlignment(.trailing)
        }
    }
}

@MainActor
final class DemoViewModel: ObservableObject {
    @Published var clientId = "ble_sdk_it_1778767839068"
    @Published var partnerUserId = "demo-user"
    @Published var status = "Idle"
    @Published var logs: [String] = []

    private var sdk = CRSPartnerBLESDKClient()
    private var cachedDevices: [CRSAuthorizedDevice] = []
    private var hrToken: CRSHeartBroadcastResult?
    private var sportStartUtc = UInt32(Date().timeIntervalSince1970)

    init() {
        configureSDK()
    }

    var deviceText: String? {
        let device = cachedDevices.first
        return device.map { "deviceName=\($0.deviceName), model=\($0.deviceModel), state=\(deviceStateText($0.connectionState))" }
    }

    func applyPartnerUser() async {
        hrToken?.stop()
        hrToken = nil
        cachedDevices = []
        sportStartUtc = UInt32(Date().timeIntervalSince1970)
        configureSDK()
        status = "Initialized"
        append("reinitialized clientId=\(clientId), partnerUserId=\(partnerUserId)")
        do {
            cachedDevices = try await sdk.listAuthorizedDevices()
            if cachedDevices.isEmpty {
                append("authorized cache empty")
            } else {
                status = "Authorized from cache"
                append("cache restored devices=\(cachedDevices.count)")
            }
        } catch {
            append("cache check error: \(error)")
        }
        appendSdkLogs()
    }

    @discardableResult
    func restoreCachedAuthorization() async -> Bool {
        configureSDK()
        do {
            cachedDevices = try await sdk.listAuthorizedDevices()
            guard !cachedDevices.isEmpty else {
                status = "Idle"
                append("cache empty")
                appendSdkLogs()
                return false
            }
            status = "Authorized from cache"
            append("cache restored devices=\(cachedDevices.count)")
            appendSdkLogs()
            return true
        } catch let error as CRSSdkError where error.code == .notAuthorized {
            status = "Idle"
            append("cache empty")
            appendSdkLogs()
            return false
        } catch {
            setFailureStatus("Cache restore failed", error: error)
            append("cache restore error: \(errorDescription(error))")
            appendSdkLogs()
            return false
        }
    }

    func authorize() async {
        append("authorize tapped clientId=\(clientId)")
        configureSDK()
        sportStartUtc = UInt32(Date().timeIntervalSince1970)
        status = "Opening COROS App..."
        do {
            let result = try await sdk.authorize(CRSAuthorizationRequest())
            cachedDevices = result.devices
            status = "Authorized"
            append("authorized devices=\(cachedDevices.count)")
            appendSdkLogs()
        } catch {
            setFailureStatus("Authorize failed", error: error)
            append("authorize error: \(errorDescription(error))")
            appendSdkLogs()
        }
    }

    func handleOpenURL(_ url: URL) async {
        do {
            let result = try await sdk.handleOpenURL(url)
            cachedDevices = result.devices
            status = "Authorized by callback"
            append("callback authorized devices=\(result.devices.count)")
        } catch {
            setFailureStatus("Callback failed", error: error)
            append("callback error: \(errorDescription(error))")
            appendSdkLogs()
        }
    }

    func start() async {
        if cachedDevices.isEmpty {
            _ = await restoreCachedAuthorization()
        }
        guard !cachedDevices.isEmpty else {
            status = "Start failed\nerror=missing authorized device"
            append("missing authorized device")
            return
        }
        do {
            hrToken?.stop()
            let result = try await sdk.startHeartBroadcast(sportStartUtc: sportStartUtc) { [weak self] sample in
                Task { @MainActor in
                    self?.append("hr=\(sample.heartRate), t=\(sample.timestampS), sportStartUtc=\(sample.sportStartUtc)")
                }
            }
            hrToken = result
            await refreshAuthorizedDevicesForDisplay()
            status = "Streaming"
            append("start protocolRet=\(result.protocolRet)")
        } catch {
            setFailureStatus("Start failed", error: error)
            append("start error: \(errorDescription(error))")
            appendSdkLogs()
        }
    }

    func stop() async {
        if cachedDevices.isEmpty {
            _ = await restoreCachedAuthorization()
        }
        guard !cachedDevices.isEmpty else {
            status = "Stop failed\nerror=missing authorized device"
            append("missing authorized device")
            return
        }
        hrToken?.stop()
        hrToken = nil
        await refreshAuthorizedDevicesForDisplay()
        status = "Stopped"
        append("stop requested")
        appendSdkLogs()
    }

    func revoke() async {
        if cachedDevices.isEmpty {
            _ = await restoreCachedAuthorization()
        }
        do {
            try await sdk.revoke()
            cachedDevices = []
            hrToken?.stop()
            hrToken = nil
            status = "Revoked"
            append("revoked")
        } catch {
            setFailureStatus("Revoke failed", error: error)
            append("revoke error: \(errorDescription(error))")
            appendSdkLogs()
        }
    }

    private func configureSDK() {
        sdk = CRSPartnerBLESDKClient()
        do {
            try sdk.initialize(
                CRSSdkInitConfig(
                    clientId: clientId,
                    partnerUserId: partnerUserId,
                    environment: .serverEnvironmentTest,
                    logOptions: CRSLogOptions(
                        isEnabled: true,
                        printsToConsole: true,
                        writesToFile: true,
                        maxStoredEntries: 200,
                        minimumLevel: .debug
                    )
                )
            )
        } catch {
            setFailureStatus("SDK init failed", error: error)
            append("sdk init error: \(errorDescription(error))")
        }
    }

    private func refreshAuthorizedDevicesForDisplay() async {
        do {
            cachedDevices = try await sdk.listAuthorizedDevices()
        } catch {
            append("refresh device state error: \(errorDescription(error))")
        }
    }

    private func setFailureStatus(_ title: String, error: Error) {
        status = "\(title)\n\(errorDescription(error))"
    }

    private func deviceStateText(_ state: CRSDeviceConnectionState) -> String {
        switch state {
        case .connected:
            return "connected"
        case .connecting:
            return "connecting"
        case .reconnecting:
            return "reconnecting"
        case .rebindRequired:
            return "rebindRequired"
        case .disconnected:
            return "disconnected"
        }
    }

    private func errorDescription(_ error: Error) -> String {
        if let sdkError = error as? CRSSdkError {
            var parts = ["code=\(sdkError.code)"]
            if let message = sdkError.message, !message.isEmpty {
                parts.append("message=\(message)")
            }
            if let tLogId = sdkError.tLogId, !tLogId.isEmpty {
                parts.append("tLogId=\(tLogId)")
            }
            return parts.joined(separator: "\n")
        }
        return "error=\(error.localizedDescription)"
    }

    private func appendSdkLogs() {
        let sdkLogs = sdk.logSnapshot().suffix(20).map { entry in
            "[\(entry.formattedTimestamp)][\(entry.level.rawValue)][\(entry.category)] \(entry.message)"
        }
        logs.insert(contentsOf: sdkLogs.reversed(), at: 0)
        if logs.count > 120 {
            logs.removeLast(logs.count - 120)
        }
        sdk.clearLogs()
    }

    private func append(_ line: String) {
        logs.insert(line, at: 0)
        if logs.count > 120 {
            logs.removeLast()
        }
    }
}
