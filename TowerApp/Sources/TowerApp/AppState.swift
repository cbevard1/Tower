import SwiftUI
import Core
import PlaybackEngine

/// Global app state shared across views
@MainActor
public final class AppState: ObservableObject {
    /// Currently playing channel (if any)
    @Published public private(set) var currentChannel: Channel?

    /// Current playback state
    @Published public private(set) var playbackState: PlaybackState = .idle

    /// Whether the player is in fullscreen mode
    @Published public private(set) var isFullscreen: Bool = false

    /// Whether the player is in Picture-in-Picture mode
    @Published public private(set) var isPiP: Bool = false

    /// Last error message
    @Published public private(set) var lastError: String?

    public init() {}

    // MARK: - Channel Management

    /// Set the currently playing channel
    public func setCurrentChannel(_ channel: Channel?) {
        currentChannel = channel
    }

    // MARK: - Playback State

    /// Update playback state
    public func updatePlaybackState(_ state: PlaybackState) {
        playbackState = state
    }

    // MARK: - Window Management

    /// Toggle fullscreen
    public func toggleFullscreen() {
        isFullscreen.toggle()
    }

    /// Toggle Picture-in-Picture
    public func togglePiP() {
        isPiP.toggle()
    }

    /// Set fullscreen state
    public func setFullscreen(_ fullscreen: Bool) {
        isFullscreen = fullscreen
    }

    /// Set PiP state
    public func setPiP(_ pip: Bool) {
        isPiP = pip
    }

    // MARK: - Error Handling

    /// Set error message
    public func setError(_ message: String?) {
        lastError = message
        // Auto-clear after 5 seconds
        if let message = message {
            Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                if lastError == message {
                    lastError = nil
                }
            }
        } else {
            lastError = nil
        }
    }

    /// Clear error
    public func clearError() {
        lastError = nil
    }
}