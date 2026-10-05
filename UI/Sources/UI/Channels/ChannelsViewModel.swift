import SwiftUI
import Core

/// State of the channels view
@MainActor
public enum ChannelsViewState: Equatable {
    case loading
    case loaded([Channel])
    case error(String)
    case tunerOffline(Tuner)
}

/// View model for the Channels screen
@MainActor
@Observable
public final class ChannelsViewModel {
    private let discoverer: TunerDiscoverer
    private let lineupProvider: LineupProvider
    private let playerController: PlayerController

    public private(set) var state: ChannelsViewState = .loading
    public private(set) var channels: [Channel] = []
    public private(set) var discoveredTuners: [Tuner] = []

    public init(
        discoverer: TunerDiscoverer,
        lineupProvider: LineupProvider,
        playerController: PlayerController
    ) {
        self.discoverer = discoverer
        self.lineupProvider = lineupProvider
        self.playerController = playerController
    }

    /// Load channels from discovered tuners
    public func loadChannels() async {
        state = .loading

        do {
            let tuners = try await discoverer.discover()
            discoveredTuners = tuners

            if tuners.isEmpty {
                state = .error("No tuners found. Please check your network or enter a manual IP in Settings.")
                return
            }

            // For now, use the first tuner (TODO: support multiple tuners)
            let primaryTuner = tuners[0]
            let channels = try await lineupProvider.fetchLineup(for: primaryTuner)

            // Sort by affineNumber for proper channel ordering
            let sortedChannels = channels.sorted { $0.affineNumber < $1.affineNumber }

            self.channels = sortedChannels
            state = .loaded(sortedChannels)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    /// Play a selected channel
    public func playChannel(_ channel: Channel) async {
        do {
            // Find the tuner for this channel
            guard let tuner = discoveredTuners.first(where: { $0.id == channel.tunerID }) else {
                state = .error("Tuner not found for channel \(channel.number)")
                return
            }

            try await playerController.open(url: channel.streamURL(tunerIP: tuner.ipAddress), deinterlacing: .yadif)
        } catch {
            state = .error("Failed to play channel: \(error.localizedDescription)")
        }
    }

    /// Refresh the channel list
    public func refresh() async {
        await loadChannels()
    }
}