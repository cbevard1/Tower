import SwiftUI
import Core
import TunerClient
import GuideIngestion

/// Main settings screen
public struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    @State private var selectedTab: SettingsTab = .tuner

    public init(
        manualTunerStore: ManualTunerStore = ManualTunerStore()
    ) {
        self._viewModel = State(initialValue: SettingsViewModel(manualTunerStore: manualTunerStore))
    }

    public var body: some View {
        NavigationSplitView {
            List(SettingsTab.allCases, selection: $selectedTab) { tab in
                Label(tab.title, systemImage: tab.systemImage)
                    .tag(tab)
            }
            .navigationTitle("Settings")
        } detail: {
            switch selectedTab {
            case .tuner:
                TunerSettingsView(
                    viewModel: viewModel,
                    onTestConnection: { /* TODO */ }
                )
            case .playback:
                PlaybackSettingsView(viewModel: viewModel)
            case .guide:
                GuideSettingsView(viewModel: viewModel) {
                    // Trigger refresh
                }
            case .advanced:
                AdvancedSettingsView(viewModel: viewModel)
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }

    private enum SettingsTab: String, CaseIterable, Identifiable {
        case tuner, playback, guide, advanced
        var id: String { rawValue }

        var title: String {
            switch self {
            case .tuner: return "Tuner"
            case .playback: return "Playback"
            case .guide: return "Guide"
            case .advanced: return "Advanced"
            }
        }

        var systemImage: String {
            switch self {
            case .tuner: return "antenna.radiowaves.left.and.right"
            case .playback: return "play.tv"
            case .guide: return "calendar"
            case .advanced: return "gearshape.2"
            }
        }
    }
}

/// Placeholder for Advanced settings
private struct AdvancedSettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("Logging") {
                Picker("Log Level", selection: .constant(0)) {
                    Text("Error").tag(0)
                    Text("Warning").tag(1)
                    Text("Info").tag(2)
                    Text("Debug").tag(3)
                }
            }

            Section("Data") {
                Button("Reset Guide Database", role: .destructive) { }
                Button("Export Settings") { }
                Button("Import Settings") { }
            }
        }
        .formStyle(.grouped)
    }
}