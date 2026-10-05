import Foundation
import Core
import VLCKit

/// Shared mock PlayerController for testing
@MainActor
final class MockPlayerController: PlayerController {
    var state: PlaybackState = .idle
    var lastOpenedURL: URL?
    var lastDeinterlacingMode: DeinterlacingMode?
    var playCalled = false
    var pauseCalled = false
    var stopCalled = false
    var seekTime: TimeInterval?
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

    func play() async {
        playCalled = true
        state = .playing
        stateContinuation.yield(state)
    }

    func pause() async {
        pauseCalled = true
        state = .paused
        stateContinuation.yield(state)
    }

    func stop() async {
        stopCalled = true
        state = .stopped
        stateContinuation.yield(state)
    }

    func seek(to time: TimeInterval) async {
        seekTime = time
    }
}

/// Shared mock TunerDiscoverer for testing
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

/// Shared mock LineupProvider for testing
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