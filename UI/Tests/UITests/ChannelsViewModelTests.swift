import Testing
import Foundation
@testable import UI
@testable import Core
@testable import TunerClient

/// Mock TunerDiscoverer for testing
final class MockTunerDiscoverer: TunerDiscoverer, @unchecked Sendable {
    var tunersToReturn: [Tuner] = []
    var shouldThrow = false

    func discover() async throws -> [Tuner] {
        if shouldThrow {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Discovery failed"])
        }
        return tunersToReturn
    }
}

/// Mock LineupProvider for testing
final class MockLineupProvider: LineupProvider, @unchecked Sendable {
    var channelsToReturn: [Channel] = []
    var shouldThrow = false

    func fetchLineup(for tuner: Tuner) async throws -> [Channel] {
        if shouldThrow {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Lineup fetch failed"])
        }
        return channelsToReturn
    }
}

/// Mock PlayerController for testing
@MainActor
final class MockPlayerController: PlayerController {
    var state: PlaybackState = .idle
    var lastOpenedURL: URL?
    var lastDeinterlacingMode: DeinterlacingMode?
    let stateContinuation: AsyncStream<PlaybackState>.Continuation
    let stateStream: AsyncStream<PlaybackState>

    init() {
        let (stream, continuation) = AsyncStream<PlaybackState>.makeStream()
        self.stateStream = stream
        self.stateContinuation = continuation
    }

    var stateUpdates: AsyncStream<PlaybackState> { stateStream }

    func open(url: URL, deinterlacing: DeinterlacingMode) async throws {
        lastOpenedURL = url
        lastDeinterlacingMode = deinterlacing
        state = .loading
        stateContinuation.yield(state)
        state = .playing
        stateContinuation.yield(state)
    }

    func play() async { state = .playing; stateContinuation.yield(state) }
    func pause() async { state = .paused; stateContinuation.yield(state) }
    func stop() async { state = .stopped; stateContinuation.yield(state) }
    func seek(to time: TimeInterval) async {}
}

@Suite("ChannelsViewModel Tests")
@MainActor
struct ChannelsViewModelTests {

    @Test("ChannelsViewModel loads channels on appear")
    func loadsChannelsOnAppear() async throws {
        let discoverer = MockTunerDiscoverer()
        let lineupProvider = MockLineupProvider()

        let tuner = Tuner(
            id: "1234ABCD",
            ipAddress: "192.168.1.50",
            model: "HDHR4-2US",
            firmwareVersion: "20240101",
            tunerCount: 2,
            discoveredAt: Date(),
            manualOverride: false
        )
        discoverer.tunersToReturn = [tuner]

        let ch1 = Channel(id: "1234ABCD-7.1", tunerID: "1234ABCD", number: "7.1", name: "KABC-DT", callsign: "KABC")
        let ch2 = Channel(id: "1234ABCD-7.2", tunerID: "1234ABCD", number: "7.2", name: "KABC-DT2", callsign: "KABC")
        let ch3 = Channel(id: "1234ABCD-13.1", tunerID: "1234ABCD", number: "13.1", name: "KDEF-DT", callsign: "KDEF")
        lineupProvider.channelsToReturn = [ch1, ch2, ch3]

        let viewModel = ChannelsViewModel(
            discoverer: discoverer,
            lineupProvider: lineupProvider,
            playerController: MockPlayerController()
        )

        // Initially loading
        #expect(viewModel.state == .loading)

        // Load channels
        await viewModel.loadChannels()

        // Should have loaded channels
        if case .loaded(let channels) = viewModel.state {
            #expect(channels.count == 3)
            #expect(channels.map { $0.number } == ["7.1", "7.2", "13.1"])
        } else {
            Issue.record("Expected loaded state")
        }
    }

    @Test("ChannelsViewModel handles discovery error")
    func handlesDiscoveryError() async throws {
        let discoverer = MockTunerDiscoverer()
        discoverer.shouldThrow = true

        let viewModel = ChannelsViewModel(
            discoverer: discoverer,
            lineupProvider: MockLineupProvider(),
            playerController: MockPlayerController()
        )

        await viewModel.loadChannels()

        if case .error(let message) = viewModel.state {
            #expect(message.contains("Discovery failed"))
        } else {
            Issue.record("Expected error state")
        }
    }

    @Test("ChannelsViewModel handles lineup fetch error")
    func handlesLineupError() async throws {
        let discoverer = MockTunerDiscoverer()
        let lineupProvider = MockLineupProvider()

        let tuner = Tuner(
            id: "1234ABCD",
            ipAddress: "192.168.1.50",
            model: "HDHR4-2US",
            firmwareVersion: "20240101",
            tunerCount: 2,
            discoveredAt: Date(),
            manualOverride: false
        )
        discoverer.tunersToReturn = [tuner]
        lineupProvider.shouldThrow = true

        let viewModel = ChannelsViewModel(
            discoverer: discoverer,
            lineupProvider: lineupProvider,
            playerController: MockPlayerController()
        )

        await viewModel.loadChannels()

        if case .error(let message) = viewModel.state {
            #expect(message.contains("Lineup fetch failed"))
        } else {
            Issue.record("Expected error state")
        }
    }

    @Test("ChannelsViewModel plays selected channel")
    func playsSelectedChannel() async throws {
        let discoverer = MockTunerDiscoverer()
        let lineupProvider = MockLineupProvider()
        let player = MockPlayerController()

        let tuner = Tuner(
            id: "1234ABCD",
            ipAddress: "192.168.1.50",
            model: "HDHR4-2US",
            firmwareVersion: "20240101",
            tunerCount: 2,
            discoveredAt: Date(),
            manualOverride: false
        )
        discoverer.tunersToReturn = [tuner]

        let channel = Channel(id: "1234ABCD-7.1", tunerID: "1234ABCD", number: "7.1", name: "KABC-DT", callsign: "KABC")
        lineupProvider.channelsToReturn = [channel]

        let viewModel = ChannelsViewModel(
            discoverer: discoverer,
            lineupProvider: lineupProvider,
            playerController: player
        )

        await viewModel.loadChannels()
        await viewModel.playChannel(channel)

        #expect(player.lastOpenedURL?.absoluteString == "http://192.168.1.50:5004/auto/v7.1")
        #expect(player.lastDeinterlacingMode == .yadif)
    }
}