import Testing
import Foundation
@testable import GuideIngestion
@testable import Core

@Suite("GuideIngestion Database Tests")
struct DatabaseTests {

    @Test("DatabaseManager creates schema and can save/query guide entries")
    func databaseSchemaAndQueries() async throws {
        let dbManager = try DatabaseManager(inMemory: true)
        try dbManager.migrate()

        let repo = GuideRepositoryImpl(dbManager: dbManager)

        // Create test entries
        let now = Date()
        let entries = [
            GuideEntry(
                id: "1",
                channelID: "tuner-7.1",
                startTime: now,
                endTime: now.addingTimeInterval(3600),
                title: "Test Show 1",
                description: "Description 1",
                isNew: true,
                categories: ["News"],
                rating: "TV-PG"
            ),
            GuideEntry(
                id: "2",
                channelID: "tuner-7.1",
                startTime: now.addingTimeInterval(3600),
                endTime: now.addingTimeInterval(7200),
                title: "Test Show 2",
                description: "Description 2",
                isNew: false,
                categories: ["Sports"],
                rating: "TV-14"
            ),
            GuideEntry(
                id: "3",
                channelID: "tuner-13.1",
                startTime: now,
                endTime: now.addingTimeInterval(1800),
                title: "Test Show 3",
                isNew: true,
                categories: ["Movie"],
                rating: "TV-MA"
            )
        ]

        // Save entries
        try await repo.save(entries)

        // Query by channel and time range - use a wider range to include all entries
        let start = now.addingTimeInterval(-7200)
        let end = now.addingTimeInterval(10800)

        let channelEntries = try await repo.entries(
            for: "tuner-7.1",
            from: start,
            to: end
        )
        #expect(channelEntries.count == 2)

        // Query by time range across all channels
        let allEntries = try await repo.entries(
            from: start,
            to: end
        )
        #expect(allEntries.count == 3)

        // Verify entry content
        let entry1 = channelEntries.first { $0.title == "Test Show 1" }
        #expect(entry1 != nil)
        #expect(entry1?.isNew == true)
        #expect(entry1?.categories == ["News"])
        #expect(entry1?.rating == "TV-PG")
    }

    @Test("GuideRepositoryImpl transactional replace works")
    func transactionalReplace() async throws {
        let dbManager = try DatabaseManager(inMemory: true)
        try dbManager.migrate()

        let repo = GuideRepositoryImpl(dbManager: dbManager)

        // Initial entries
        let now = Date()
        let initialEntries = [
            GuideEntry(
                id: "1",
                channelID: "tuner-7.1",
                startTime: now,
                endTime: now.addingTimeInterval(3600),
                title: "Old Show",
                isNew: false,
                categories: ["News"],
                rating: "TV-PG"
            )
        ]
        try await repo.save(initialEntries)

        var entries = try await repo.entries(for: "tuner-7.1", from: now.addingTimeInterval(-3600), to: now.addingTimeInterval(7200))
        #expect(entries.count == 1)
        #expect(entries[0].title == "Old Show")

        // Replace with new entries (transactional)
        let newEntries = [
            GuideEntry(
                id: "2",
                channelID: "tuner-7.1",
                startTime: now,
                endTime: now.addingTimeInterval(3600),
                title: "New Show",
                isNew: true,
                categories: ["Sports"],
                rating: "TV-14"
            )
        ]
        try await repo.save(newEntries)

        entries = try await repo.entries(for: "tuner-7.1", from: now.addingTimeInterval(-3600), to: now.addingTimeInterval(7200))
        #expect(entries.count == 1)
        #expect(entries[0].title == "New Show")
        #expect(entries[0].isNew == true)
    }
}