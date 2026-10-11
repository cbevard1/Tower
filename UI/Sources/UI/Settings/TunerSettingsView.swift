import SwiftUI
import Core
import TunerClient

/// Tuner settings section
public struct TunerSettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    let onTestConnection: () async -> Void

    public init(
        viewModel: SettingsViewModel,
        onTestConnection: @escaping () async -> Void
    ) {
        self.viewModel = viewModel
        self.onTestConnection = onTestConnection
    }

    public var body: some View {
        Form {
            Section("Tuner Discovery") {
                Toggle("Auto-discover tuners on network", isOn: $viewModel.autoDiscoverTuners)

                HStack {
                    Text("Manual Tuner IP")
                    TextField("192.168.1.x", text: $viewModel.manualTunerIP)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)
                }

                Button("Test Connection") {
                    Task { await onTestConnection() }
                }
                .disabled(viewModel.manualTunerIP.isEmpty)

                if let ip = viewModel.manualTunerStore.getManualIP(), !ip.isEmpty {
                    Text("Current: \(ip)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }
}