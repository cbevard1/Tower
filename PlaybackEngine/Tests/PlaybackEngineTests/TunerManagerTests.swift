import Testing
import Foundation
@testable import Core
import VLCKit

/// Stream session for tracking active streams
@MainActor
final class StreamSession: Sendable {
    let channel: Channel
    let playerController: PlayerController
    let startedAt: Date
    var isBackground: Bool

    init(channel: Channel, playerController: PlayerController, isBackground: Bool = false) {
        self.channel = channel
        self.playerController = playerController
        self.startedAt = Date()
        self.isBackground = isBackground
    }
}

/// TunerManager for managing concurrent streams
@MainActor
final class TunerManager: Sendable {
    private let maxConcurrentStreams: Int
    private var activeSessions: [StreamSession] = []
    private var onTunerConflict: (@Sendable (Channel) -> Void)?

    init(maxConcurrentStreams: Int = 2) {
        self.maxConcurrentStreams = maxConcurrentStreams
    }

    func setTunerConflictHandler(_ handler: @escaping @Sendable (Channel) -> Void) {
        onTunerConflict = handler
    }

    func requestStream(for channel: Channel, playerController: PlayerController, tunerIP: String = "192.168.1.50") async throws -> StreamSession {
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

    var currentSessions: [StreamSession] {
        activeSessions
    }

    func stopAll() async {
        for session in activeSessions {
            await session.playerController.stop()
        }
        activeSessions.removeAll()
    }
}

/// Thread-safe mutable box for testing
final class Box<T>: @unchecked Sendable {
    private let lock = NSLock()
    var value: T

    init(_ value: T) {
        self.value = value
    }

    @discardableResult
    func withLock<R>(_ body: (inout T) throws -> R) rethrows -> R {
        lock.lock()
        defer { lock.unlock() }
        return try body(&value)
    }
}

@Suite("TunerManager Tests")
@MainActor
struct TunerManagerTests {

    @Test("TunerManager allows up to maxConcurrentStreams")
    func maxConcurrentStreams() async throws {
        let manager = TunerManager(maxConcurrentStreams: 2)

        let ch1 = Channel(id: "t-7.1", tunerID: "t", number: "7.1", name: "A", callsign: "A")
        let ch2 = Channel(id: "t-7.2", tunerID: "t", number: "7.2", name: "B", callsign: "B")
        let ch3 = Channel(id: "t-9.1", tunerID: "t", number: "9.1", name: "C", callsign: "C")

        let p1 = MockPlayerController()
        let p2 = MockPlayerController()
        let p3 = MockPlayerController()

        _ = try await manager.requestStream(for: ch1, playerController: p1)
        #expect(manager.currentSessions.count == 1)

        _ = try await manager.requestStream(for: ch2, playerController: p2)
        #expect(manager.currentSessions.count == 2)

        // Third request should trigger auto-stop
        _ = try await manager.requestStream(for: ch3, playerController: p3)
        #expect(manager.currentSessions.count == 2)
    }

    @Test("TunerManager calls conflict handler when stopping session")
    func conflictHandlerCalled() async throws {
        let manager = TunerManager(maxConcurrentStreams: 2)
        let stoppedChannel = Box(nil as Channel?)

        manager.setTunerConflictHandler { channel in
            stoppedChannel.withLock { $0 = channel }
        }

        let ch1 = Channel(id: "t-7.1", tunerID: "t", number: "7.1", name: "A", callsign: "A")
        let ch2 = Channel(id: "t-7.2", tunerID: "t", number: "7.2", name: "B", callsign: "B")
        let ch3 = Channel(id: "t-9.1", tunerID: "t", number: "9.1", name: "C", callsign: "C")

        let p1 = MockPlayerController()
        let p2 = MockPlayerController()
        let p3 = MockPlayerController()

        _ = try await manager.requestStream(for: ch1, playerController: p1)
        _ = try await manager.requestStream(for: ch2, playerController: p2)
        _ = try await manager.requestStream(for: ch3, playerController: p3)

        let stopped = stoppedChannel.withLock { $0 }
        #expect(stopped != nil)
        #expect(stopped?.id == "t-7.1" || stopped?.id == "t-7.2")
    }

    @Test("TunerManager tracks background vs foreground")
    func backgroundForegroundTracking() async throws {
        let manager = TunerManager(maxConcurrentStreams: 2)

        let ch1 = Channel(id: "t-7.1", tunerID: "t", number: "7.1", name: "A", callsign: "A")
        let ch2 = Channel(id: "t-7.2", tunerID: "t", number: "7.2", name: "B", callsign: "B")

        let p1 = MockPlayerController()
        let p2 = MockPlayerController()

        let s1 = try await manager.requestStream(for: ch1, playerController: p1)
        let s2 = try await manager.requestStream(for: ch2, playerController: p2)

        // First session should be foreground (not background)
        #expect(s1.isBackground == false)
        // Second session should be background
        #expect(s2.isBackground == true)
    }
}