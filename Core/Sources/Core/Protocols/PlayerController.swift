import Foundation

/// Playback state communicated by a `PlayerController`.
///
/// Used with `PlayerController.stateUpdates` to notify UI layers.
public enum PlaybackState: Sendable, Equatable {
    case idle
    case loading
    case buffering
    case playing
    case paused
    case stopped
    case error(String)

    public static func == (lhs: PlaybackState, rhs: PlaybackState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.loading, .loading),
             (.buffering, .buffering),
             (.playing, .playing),
             (.paused, .paused),
             (.stopped, .stopped):
            return true
        case (.error(let lhsMsg), .error(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}

/// Controls media playback of an HTTP stream.
///
/// Conforming types (typically a VLCKit wrapper) expose play, pause,
/// seek, and deinterlacing controls. State updates are published
/// for SwiftUI bindings.
///
/// All playback operations run on the main actor since they interact
/// with VLCKit which requires main-thread execution.
@MainActor
public protocol PlayerController: Sendable {
    /// Open and begin preparing a stream URL.
    /// - Parameters:
    ///   - url: The stream URL to open.
    ///   - deinterlacing: Deinterlacing mode to apply.
    func open(url: URL, deinterlacing: DeinterlacingMode) async throws

    /// Start or resume playback.
    func play() async

    /// Pause playback.
    func pause() async

    /// Stop playback and release resources.
    func stop() async

    /// Seek to a specific time in the stream.
    /// - Parameter time: Time offset in seconds.
    func seek(to time: TimeInterval) async

    /// Current playback state updates (async sequence).
    var stateUpdates: AsyncStream<PlaybackState> { get }
}