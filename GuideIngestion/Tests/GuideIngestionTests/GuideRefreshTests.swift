import Testing
import Foundation
@testable import GuideIngestion
@testable import Core

@Suite("Guide Refresh Tests")
struct GuideRefreshTests {

    @Test("GuideRefreshCoordinator refreshes guide data atomically")
    func refreshGuideData() async throws {
        let dbManager = try DatabaseManager(inMemory: true)
        try dbManager.migrate()
        
        let repo = GuideRepositoryImpl(dbManager: dbManager)
        let provider = MockXMLTVProvider()
        
        // Set up mock data
        let now = Date()
        provider.entriesToReturn = [
            GuideEntry(
                id: "1",
                channelID: "I7.1.tuner",
                startTime: now,
                endTime: now.addingTimeInterval(3600),
                title: "Test Show",
                isNew: true,
                categories: ["News"]
            )
        ]
        provider.channelsToReturn = [
            XMLTVChannel(id: "I7.1.tuner", displayName: "7.1 KABC", iconURL: "http://example.com/logo.png")
        ]
        
        let matcher = ChannelMatcherImpl()
        let coordinator = GuideRefreshCoordinator(
            provider: provider,
            repository: repo,
            matcher: matcher
        )
        
        // Add tuner channels for matching
        let tunerChannels = [
            Channel(id: "tuner-7.1", tunerID: "tuner", number: "7.1", name: "KABC-DT", callsign: "KABC")
        ]
        
        try await coordinator.refresh(tunerChannels: tunerChannels)
        
        // Verify data was saved
        let entries = try await repo.entries(
            for: "I7.1.tuner",
            from: now.addingTimeInterval(-3600),
            to: now.addingTimeInterval(7200)
        )
        #expect(entries.count == 1)
        #expect(entries[0].title == "Test Show")
        
        // Verify provider was called
        #expect(provider.fetchCallCount == 1)
    }

    @Test("GuideRefreshCoordinator handles provider errors gracefully")
    func refreshHandlesProviderError() async throws {
        let dbManager = try DatabaseManager(inMemory: true)
        try dbManager.migrate()
        
        let repo = GuideRepositoryImpl(dbManager: dbManager)
        let provider = MockXMLTVProvider()
        provider.shouldThrow = true
        
        let matcher = ChannelMatcherImpl()
        let coordinator = GuideRefreshCoordinator(
            provider: provider,
            repository: repo,
            matcher: matcher
        )
        
        let tunerChannels = [
            Channel(id: "tuner-7.1", tunerID: "tuner", number: "7.1", name: "KABC-DT", callsign: "KABC")
        ]
        
        await #expect(throws: Error.self) {
            try await coordinator.refresh(tunerChannels: [])
        }
    }
}

// Mock provider for testing
private final class MockXMLTVProvider: GuideProvider, @unchecked Sendable {
    var entriesToReturn: [GuideEntry] = []
    var channelsToReturn: [XMLTVChannel] = []
    var shouldThrow = false
    var fetchCallCount = 0

    func fetch() async throws -> [GuideEntry] {
        fetchCallCount += 1
        if shouldThrow {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Provider error"])
        }
        return entriesToReturn
    }
}