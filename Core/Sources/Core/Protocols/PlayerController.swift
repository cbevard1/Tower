import Foundation

/// Playback state communicated by a `PlayerController`.
///
/// Used with `PlayerController.stateUpdates` to notify UI layers.
public enum PlaybackState: Sendable {
    case idle
    case loading
    case buffering
    case playing
    case paused
    case stopped
    case error(String)
}

/// Controls media playback of an HTTP stream.
///
/// Conforming types (typically a VLCKit wrapper) expose play, pause,
/// seek, and deinterlacing controls. State updates are published
/// for SwiftUI bindings.
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
