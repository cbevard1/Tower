import Testing
import Foundation
@testable import Core
import VLCKit

/// Mock PlayerController for testing protocol conformance
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

@Suite("PlayerController Protocol Tests")
@MainActor
struct PlayerTests {

    @Test("MockPlayerController implements PlayerController protocol")
    func mockPlayerControllerProtocol() {
        let player = MockPlayerController()
        #expect(player.state == .idle)
    }

    @Test("MockPlayerController state transitions")
    func mockPlayerControllerStateTransitions() async throws {
        let player = MockPlayerController()

        // Test open
        try await player.open(url: URL(string: "http://example.com/stream")!, deinterlacing: .yadif)
        #expect(player.lastOpenedURL?.absoluteString == "http://example.com/stream")
        #expect(player.lastDeinterlacingMode == .yadif)
        #expect(player.state == .playing)

        // Test pause
        await player.pause()
        #expect(player.pauseCalled)
        #expect(player.state == .paused)

        // Test play
        await player.play()
        #expect(player.playCalled)
        #expect(player.state == .playing)

        // Test stop
        await player.stop()
        #expect(player.stopCalled)
        #expect(player.state == .stopped)

        // Test seek
        await player.seek(to: 30.0)
        #expect(player.seekTime == 30.0)
    }

    @Test("DeinterlacingMode all cases present")
    func deinterlacingModeAllCases() {
        let expectedCases: [DeinterlacingMode] = [.auto, .off, .bob, .yadif, .yadif2x, .phosphor, .blend]
        #expect(DeinterlacingMode.allCases.count == expectedCases.count)
        for expected in expectedCases {
            #expect(DeinterlacingMode.allCases.contains(expected))
        }
    }

    @Test("DeinterlacingMode display names")
    func deinterlacingModeDisplayNames() {
        for mode in DeinterlacingMode.allCases {
            #expect(!mode.displayName.isEmpty)
        }
    }
}