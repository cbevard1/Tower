import SwiftUI
import Core
import TunerClient
import PlaybackEngine

/// Main channels screen showing a grid of available channels
public struct ChannelsView: View {
    @State private var viewModel: ChannelsViewModel
    @State private var playingChannelID: String?

    public init(
        discoverer: TunerDiscoverer,
        lineupProvider: LineupProvider,
        playerController: PlayerController
    ) {
        self._viewModel = State(initialValue: ChannelsViewModel(
            discoverer: discoverer,
            lineupProvider: lineupProvider,
            playerController: playerController
        ))
    }

    public var body: some View {
        NavigationSplitView {
            // Sidebar with tuner status
            List {
                Section("Tuners") {
                    ForEach(viewModel.discoveredTuners) { tuner in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(tuner.model)
                                    .font(.headline)
                                Text(tuner.ipAddress)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if tuner.manualOverride {
                                Image(systemName: "hand.tap")
                                    .foregroundStyle(.orange)
                            } else {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }

                Section("Actions") {
                    Button("Refresh Channels") {
                        Task { await viewModel.loadChannels() }
                    }
                    Button("Settings") {
                        // TODO: Navigate to settings
                    }
                }
            }
            .navigationTitle("Channels")
        } detail: {
            // Main channel grid
            ZStack {
                switch viewModel.state {
                case .loading:
                    ProgressView("Loading channels...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .loaded(let channels):
                    ChannelGridView(
                        channels: channels,
                        playingChannelID: playingChannelID,
                        onChannelTap: { channel in
                            playingChannelID = channel.id
                            Task {
                                await viewModel.playChannel(channel)
                            }
                        }
                    )

                case .error(let message):
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundStyle(.orange)
                        Text("Error")
                            .font(.title)
                        Text(message)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        Button("Retry") {
                            Task { await viewModel.loadChannels() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .tunerOffline(let tuner):
                    VStack(spacing: 16) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(.red)
                        Text("Tuner Offline")
                            .font(.title)
                        Text("Cannot reach \(tuner.model) at \(tuner.ipAddress)")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        Button("Retry") {
                            Task { await viewModel.loadChannels() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Channels")
            .toolbar {
                ToolbarItemGroup {
                    Button {
                        Task { await viewModel.loadChannels() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.state == .loading)
                }
            }
        }
        .task {
            await viewModel.loadChannels()
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}