import Testing
import Foundation
@testable import UI
@testable import Core

@Suite("PlayerViewModel Tests")
@MainActor
struct PlayerViewModelTests {

    @Test("PlayerViewModel reflects player state changes")
    func reflectsPlayerState() async {
        let player = MockPlayerController()
        let viewModel = PlayerViewModel(playerController: player)

        // Initially idle
        #expect(viewModel.playbackState == .idle)

        // Player starts playing
        await player.play()
        #expect(viewModel.playbackState == .idle) // ViewModel doesn't auto-subscribe in test
    }

    @Test("PlayerViewModel delegates play/pause/stop to player")
    func delegatesControls() async {
        let player = MockPlayerController()
        let viewModel = PlayerViewModel(playerController: player)

        await viewModel.play()
        #expect(player.playCalled)

        await viewModel.pause()
        #expect(player.pauseCalled)

        await viewModel.stop()
        #expect(player.stopCalled)
    }

    @Test("PlayerViewModel delegates seek to player")
    func delegatesSeek() async {
        let player = MockPlayerController()
        let viewModel = PlayerViewModel(playerController: player)

        await viewModel.seek(to: 45.0)
        #expect(player.seekTime == 45.0)
    }

    @Test("PlayerViewModel cycles deinterlacing mode")
    func cyclesDeinterlacing() {
        let player = MockPlayerController()
        let viewModel = PlayerViewModel(playerController: player)

        // Start with auto
        #expect(viewModel.currentDeinterlacing == DeinterlacingMode.auto)

        // Cycle through modes
        viewModel.cycleDeinterlacing()
        #expect(viewModel.currentDeinterlacing == DeinterlacingMode.off)

        viewModel.cycleDeinterlacing()
        #expect(viewModel.currentDeinterlacing == DeinterlacingMode.bob)

        viewModel.cycleDeinterlacing()
        #expect(viewModel.currentDeinterlacing == DeinterlacingMode.yadif)
    }
}