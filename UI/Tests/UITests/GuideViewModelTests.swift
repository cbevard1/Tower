import Testing
import Foundation
@testable import UI
@testable import Core
@testable import GuideIngestion

@Suite("GuideViewModel Tests")
@MainActor
struct GuideViewModelTests {

    @Test("GuideViewModel loads guide entries for visible time range")
    func loadsGuideEntries() async throws {
        // Create shared database manager
        let dbManager = try DatabaseManager(inMemory: true)
        try dbManager.migrate()
        let repo = GuideRepositoryImpl(dbManager: dbManager)
        
        // Add test data - use channel IDs that match the tuner channels
        let now = Date()
        let entries = [
            GuideEntry(
                id: "1",
                channelID: "tuner-7.1",
                startTime: now,
                endTime: now.addingTimeInterval(3600),
                title: "Morning News",
                isNew: true,
                categories: ["News"]
            ),
            GuideEntry(
                id: "2",
                channelID: "tuner-7.1",
                startTime: now.addingTimeInterval(7200),
                endTime: now.addingTimeInterval(10800),
                title: "Afternoon Show",
                isNew: false,
                categories: ["Entertainment"]
            ),
            GuideEntry(
                id: "3",
                channelID: "tuner-13.1",
                startTime: now,
                endTime: now.addingTimeInterval(1800),
                title: "Morning Movie",
                isNew: true,
                categories: ["Movie"]
            )
        ]
        try await repo.save(entries)
        
        let channels = [
            Channel(id: "tuner-7.1", tunerID: "tuner", number: "7.1", name: "KABC", callsign: "KABC"),
            Channel(id: "tuner-13.1", tunerID: "tuner", number: "13.1", name: "KDEF", callsign: "KDEF")
        ]
        
        let matcher = ChannelMatcherImpl()
        
        let viewModel = GuideViewModel(
            repository: repo,
            channels: channels,
            matcher: ChannelMatcherImpl()
        )
        
        // Set time range to cover test data
        let startOfDay = Calendar.current.startOfDay(for: now)
        let endOfDay = startOfDay.addingTimeInterval(24 * 3600)
        viewModel.timeRange = startOfDay...endOfDay
        
        await viewModel.loadGuideEntries()
        
        // Should have loaded entries for both channels
        #expect(viewModel.guideEntries.count == 3)
    }
    
    @Test("GuideViewModel time range filtering works")
    func timeRangeFiltering() async throws {
        let dbManager = try DatabaseManager(inMemory: true)
        try dbManager.migrate()
        let repo = GuideRepositoryImpl(dbManager: dbManager)
        
        let now = Date()
        let entries = [
            GuideEntry(
                id: "1",
                channelID: "tuner-7.1",
                startTime: now,
                endTime: now.addingTimeInterval(3600),
                title: "Show 1",
                isNew: false,
                categories: []
            ),
            GuideEntry(
                id: "2",
                channelID: "tuner-7.1",
                startTime: now.addingTimeInterval(7200),
                endTime: now.addingTimeInterval(10800),
                title: "Show 2",
                isNew: false,
                categories: []
            )
        ]
        try await repo.save(entries)
        
        let viewModel = GuideViewModel(
            repository: repo,
            channels: [Channel(id: "tuner-7.1", tunerID: "tuner", number: "7.1", name: "Test", callsign: "TEST")],
            matcher: ChannelMatcherImpl()
        )
        
        // Set narrow time range that only includes first show
        let start = now
        let end = now.addingTimeInterval(5400) // 1.5 hours
        viewModel.timeRange = start...end
        
        await viewModel.loadGuideEntries()
        
        // Should only include first show
        #expect(viewModel.guideEntries.count == 1)
        #expect(viewModel.guideEntries[0].title == "Show 1")
    }
}