import VLCKit
import Foundation
import Core

/// Manages concurrent tuner streams for HDHomeRun devices.
///
/// Each HDHomeRun device has a limited number of tuners (typically 2 for Connect/Duo).
/// This manager ensures we don't exceed the tuner limit by automatically stopping
/// the oldest background stream when a new stream is requested.
@MainActor
public final class TunerManager: Sendable {
    private let maxConcurrentStreams: Int
    private var activeSessions: [StreamSession] = []
    private var onTunerConflict: (@Sendable (Channel) -> Void)?

    public init(maxConcurrentStreams: Int = 2) {
        self.maxConcurrentStreams = maxConcurrentStreams
    }

    /// Set a handler to be called when a tuner conflict occurs and a stream is stopped.
    public func setTunerConflictHandler(_ handler: @escaping @Sendable (Channel) -> Void) {
        onTunerConflict = handler
    }

    /// Request a stream for the given channel.
    ///
    /// If the tuner limit is reached, the oldest background session is stopped.
    /// - Parameters:
    ///   - channel: The channel to stream.
    ///   - playerController: The player controller to use for playback.
    ///   - tunerIP: The IP address of the tuner (default: "192.168.1.50").
    /// - Returns: The created stream session.
    public func requestStream(
        for channel: Channel,
        playerController: PlayerController,
        tunerIP: String = "192.168.1.50"
    ) async throws -> StreamSession {
        // If we have room for another stream, create it
        if activeSessions.count < maxConcurrentStreams {
            let isBackground = activeSessions.count > 0 // First is foreground, rest background
            let session = StreamSession(channel: channel, playerController: playerController, isBackground: isBackground)
            activeSessions.append(session)
            try await playerController.open(url: channel.streamURL(tunerIP: tunerIP), deinterlacing: .yadif)
            return session
        }

        // At capacity - stop oldest background session
        guard let oldestBackgroundIndex = activeSessions.indices.last(where: { activeSessions[$0].isBackground }) else {
            // No background sessions, stop the oldest overall
            let stoppedSession = activeSessions.removeFirst()
            await stoppedSession.playerController.stop()
            onTunerConflict?(stoppedSession.channel)

            let session = StreamSession(channel: channel, playerController: playerController, isBackground: false)
            activeSessions.insert(session, at: 0)
            try await playerController.open(url: channel.streamURL(tunerIP: tunerIP), deinterlacing: .yadif)
            return session
        }

        let stoppedSession = activeSessions.remove(at: oldestBackgroundIndex)
        await stoppedSession.playerController.stop()
        onTunerConflict?(stoppedSession.channel)

        let session = StreamSession(channel: channel, playerController: playerController, isBackground: false)
        activeSessions.append(session)
        try await playerController.open(url: channel.streamURL(tunerIP: tunerIP), deinterlacing: .yadif)
        return session
    }

    /// Current active stream sessions.
    public var currentSessions: [StreamSession] {
        activeSessions
    }

    /// Stop all active streams.
    public func stopAll() async {
        for session in activeSessions {
            await session.playerController.stop()
        }
        activeSessions.removeAll()
    }
}

/// Represents an active stream session.
@MainActor
public final class StreamSession: Sendable {
    public let channel: Channel
    public let playerController: PlayerController
    public let startedAt: Date
    public var isBackground: Bool

    public init(channel: Channel, playerController: PlayerController, isBackground: Bool = false) {
        self.channel = channel
        self.playerController = playerController
        self.startedAt = Date()
        self.isBackground = isBackground
    }
}

/// Marker symbol confirming `PlaybackEngine` module imports resolve,
/// including the VLCKit binary dependency.
package enum PlaybackEngineModule {
    package static let version = "0.1.0"
}