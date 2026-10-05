import SwiftUI
import Core
import PlaybackEngine

/// View model for the Player screen
@MainActor
@Observable
public final class PlayerViewModel {
    private let playerController: PlayerController

    public private(set) var playbackState: PlaybackState = .idle
    public private(set) var currentDeinterlacing: DeinterlacingMode = .auto

    public init(playerController: PlayerController) {
        self.playerController = playerController

        // Subscribe to player state updates
        Task {
            for await state in playerController.stateUpdates {
                self.playbackState = state
            }
        }
    }

    /// Play or resume playback
    public func play() async {
        await playerController.play()
    }

    /// Pause playback
    public func pause() async {
        await playerController.pause()
    }

    /// Stop playback
    public func stop() async {
        await playerController.stop()
    }

    /// Seek to a specific time
    public func seek(to time: TimeInterval) async {
        await playerController.seek(to: time)
    }

    /// Toggle play/pause
    public func togglePlayPause() async {
        switch playbackState {
        case .playing:
            await pause()
        case .paused, .idle, .buffering, .loading:
            await play()
        default:
            await play()
        }
    }

    /// Cycle through deinterlacing modes
    public func cycleDeinterlacing() {
        let allModes = DeinterlacingMode.allCases
        guard let currentIndex = allModes.firstIndex(of: currentDeinterlacing) else {
            currentDeinterlacing = .auto
            return
        }
        let nextIndex = (currentIndex + 1) % allModes.count
        currentDeinterlacing = allModes[nextIndex]
    }

    /// Set deinterlacing mode explicitly
    public func setDeinterlacing(_ mode: DeinterlacingMode) {
        currentDeinterlacing = mode
    }
}