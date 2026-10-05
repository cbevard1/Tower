import Foundation
@preconcurrency import VLCKit
import Core

/// VLCKit-based implementation of `PlayerController`.
///
/// Wraps `VLCMediaPlayer` to provide async playback control,
/// deinterlacing, and state publishing.
@MainActor
public final class VLCPlayerController: NSObject, PlayerController, @unchecked Sendable {
    private let _mediaPlayer: VLCMediaPlayer
    private var stateContinuation: AsyncStream<PlaybackState>.Continuation?
    private var _state: PlaybackState = .idle
    private let _stateUpdates: AsyncStream<PlaybackState>

    public var mediaPlayer: VLCMediaPlayer { _mediaPlayer }

    public override init() {
        self._mediaPlayer = VLCMediaPlayer()

        // Set up state publishing
        let (stream, continuation) = AsyncStream<PlaybackState>.makeStream()
        self.stateContinuation = continuation
        self._stateUpdates = stream

        super.init()

        // Observe VLC state changes via KVO
        setupObservation()
    }

    deinit {
        stateContinuation?.finish()
        // Note: Can't safely remove observers in deinit due to isolation
        // VLCKit will clean up when the player is deallocated
    }

    public var stateUpdates: AsyncStream<PlaybackState> { _stateUpdates }

    /// Open and begin preparing a stream URL.
    /// - Parameters:
    ///   - url: The stream URL to open.
    ///   - deinterlacing: Deinterlacing mode to apply.
    public func open(url: URL, deinterlacing: DeinterlacingMode) async throws {
        updateState(.loading)

        // Create media from URL
        let media = VLCMedia(url: url)
        _mediaPlayer.media = media

        // Apply deinterlacing mode
        applyDeinterlacing(deinterlacing)

        // Start playback
        _mediaPlayer.play()

        // VLC will transition through states via KVO
    }

    /// Start or resume playback.
    public func play() async {
        _mediaPlayer.play()
    }

    /// Pause playback.
    public func pause() async {
        _mediaPlayer.pause()
    }

    /// Stop playback and release resources.
    public func stop() async {
        _mediaPlayer.stop()
        updateState(.stopped)
    }

    /// Seek to a specific time in the stream.
    /// - Parameter time: Time offset in seconds.
    public func seek(to time: TimeInterval) async {
        _mediaPlayer.setTime(time)
    }

    private func setupObservation() {
        // Observe isPlaying, isPaused, isEnded via KVO
        _mediaPlayer.addObserver(self, forKeyPath: "isPlaying", options: [.new], context: nil)
        _mediaPlayer.addObserver(self, forKeyPath: "isPaused", options: [.new], context: nil)
        _mediaPlayer.addObserver(self, forKeyPath: "isEnded", options: [.new], context: nil)
    }

    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard object as AnyObject? === _mediaPlayer else { return }
        Task { @MainActor in
            handleStateChange()
        }
    }

    @MainActor
    private func handleStateChange() {
        let newState: PlaybackState

        if _mediaPlayer.isEnded {
            newState = .stopped
        } else if _mediaPlayer.isPlaying {
            newState = .playing
        } else if _mediaPlayer.isPaused {
            newState = .paused
        } else {
            // Check if media is loaded/buffering
            if _mediaPlayer.media != nil {
                newState = .buffering
            } else {
                newState = .idle
            }
        }

        updateState(newState)
    }

    private func updateState(_ state: PlaybackState) {
        _state = state
        stateContinuation?.yield(state)
    }

    private func applyDeinterlacing(_ mode: DeinterlacingMode) {
        // VLCKit uses string constants for deinterlacing modes
        let vlcMode: String

        switch mode {
        case .auto:
            vlcMode = VLCDeinterlacingMode.yadif() // Default to yadif for auto
        case .off:
            vlcMode = VLCDeinterlacingMode.none()
        case .bob:
            vlcMode = VLCDeinterlacingMode.bob()
        case .yadif:
            vlcMode = VLCDeinterlacingMode.yadif()
        case .yadif2x:
            vlcMode = VLCDeinterlacingMode.yadif2x()
        case .phosphor:
            vlcMode = VLCDeinterlacingMode.phosphor()
        case .blend:
            vlcMode = VLCDeinterlacingMode.blend()
        }

        // Store the deinterlacing preference
        // Note: VLCKit for macOS applies deinterlacing via video filter settings
        UserDefaults.standard.set(vlcMode, forKey: "VLCDeinterlacingMode")
    }
}