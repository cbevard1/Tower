import SwiftUI
import Core
import GuideIngestion

/// Guide settings section
public struct GuideSettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    let onRefreshNow: () async -> Void

    public init(
        viewModel: SettingsViewModel,
        onRefreshNow: @escaping () async -> Void
    ) {
        self.viewModel = viewModel
        self.onRefreshNow = onRefreshNow
    }

    public var body: some View {
        Form {
            Section("Guide Data Source") {
                TextField("XMLTV URL", text: $viewModel.xmltvURL)
                    .textFieldStyle(.roundedBorder)
                    .help("Enter the URL to your XMLTV data source")

                Picker("Auto-refresh interval", selection: $viewModel.autoRefreshInterval) {
                    Text("Every 6 hours").tag(6)
                    Text("Every 12 hours").tag(12)
                    Text("Every 24 hours").tag(24)
                    Text("Manual only").tag(0)
                }

                HStack {
                    Button("Refresh Now") {
                        Task { await onRefreshNow() }
                    }
                    .buttonStyle(.borderedProminent)

                    if let lastRefreshed = viewModel.lastGuideRefresh {
                        Text("Last refreshed: \(lastRefreshed, format: .dateTime)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Channel Matching") {
                NavigationLink("Channel Match Editor") {
                    ChannelMatchEditorView()
                }

                Text("Manually override automatic channel matching")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

/// ChannelMatch conformance to Identifiable
extension ChannelMatch: Identifiable {
    public var id: String {
        "\(tunerChannelID)-\(guideChannelID)"
    }
}

/// View model for channel match editor
@MainActor
@Observable
public final class ChannelMatchEditorViewModel {
    public var matches: [ChannelMatch] = []
    public var unmatchedTunerChannels: [Channel] = []
    public var unmatchedGuideChannels: [GuideEntry] = []

    public init() {}

    public func loadMatches() {
        // Load from database
    }

    public func saveMatch(_ match: ChannelMatch) {
        // Save to database
    }

    public func removeMatch(_ match: ChannelMatch) {
        // Remove from database
    }
}

/// Channel match editor view
public struct ChannelMatchEditorView: View {
    @State private var viewModel = ChannelMatchEditorViewModel()

    public init() {}

    public var body: some View {
        Form {
            Section("Unmatched Tuner Channels") {
                ForEach(viewModel.unmatchedTunerChannels) { channel in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(channel.number)
                                .fontWeight(.bold)
                            Text(channel.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Menu("Match...") {
                            ForEach(viewModel.unmatchedGuideChannels) { guideChannel in
                                Button("\(guideChannel.channelID) - \(guideChannel.title)") {
                                    // Create manual match
                                }
                            }
                        }
                    }
                }
            }

            Section("Manual Overrides") {
                ForEach(viewModel.matches) { match in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Tuner: \(match.tunerChannelID)")
                            Text("Guide: \(match.guideChannelID)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(match.matchType.rawValue.capitalized)
                            .font(.caption)
                            .padding(4)
                            .background(Color.accentColor.opacity(0.2))
                            .cornerRadius(4)
                        Button("Remove") {
                            viewModel.removeMatch(match)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Channel Match Editor")
    }
}