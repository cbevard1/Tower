import Foundation
import GRDB
import Core

/// GRDB-backed implementation of GuideRepository.
public final class GuideRepositoryImpl: GuideRepository, Sendable {
    private let dbManager: DatabaseManager

    public init(dbManager: DatabaseManager) {
        self.dbManager = dbManager
    }

    /// Save guide entries atomically using a transactional replace strategy.
    /// Deletes all existing entries and inserts the new ones in a single transaction.
    public func save(_ entries: [GuideEntry]) async throws {
        try await dbManager.writer.write { db in
            // Delete all existing entries
            try GuideEntryRecord.deleteAll(db)

            // Insert new entries
            for entry in entries {
                var record = GuideEntryRecord(entry: entry)
                try record.insert(db)
            }
        }
    }

    /// Fetch entries for a specific channel within a time window.
    public func entries(
        for channelID: String,
        from start: Date,
        to end: Date
    ) async throws -> [GuideEntry] {
        let startMs = Int64(start.timeIntervalSince1970 * 1000)
        let endMs = Int64(end.timeIntervalSince1970 * 1000)

        return try await dbManager.reader.read { db in
            try GuideEntryRecord
                .filter(Column("channel_id") == channelID)
                .filter(Column("start_time") < endMs && Column("end_time") > startMs)
                .order(Column("start_time"))
                .fetchAll(db)
                .map { $0.toGuideEntry() }
        }
    }

    /// Fetch entries within a time window across all channels.
    public func entries(from start: Date, to end: Date) async throws -> [GuideEntry] {
        let startMs = Int64(start.timeIntervalSince1970 * 1000)
        let endMs = Int64(end.timeIntervalSince1970 * 1000)

        return try await dbManager.reader.read { db in
            try GuideEntryRecord
                .filter(Column("start_time") < endMs && Column("end_time") > startMs)
                .order(Column("start_time"))
                .fetchAll(db)
                .map { $0.toGuideEntry() }
        }
    }
}

/// GRDB record for GuideEntry.
private struct GuideEntryRecord: FetchableRecord, MutablePersistableRecord {
    var id: String
    var channelID: String
    var startTime: Int64
    var endTime: Int64
    var title: String
    var description: String?
    var episodeTitle: String?
    var seasonNumber: Int?
    var episodeNumber: Int?
    var isNew: Bool
    var categories: String?
    var rating: String?
    var createdAt: Int64

    init(entry: GuideEntry) {
        self.id = entry.id
        self.channelID = entry.channelID
        self.startTime = Int64(entry.startTime.timeIntervalSince1970 * 1000)
        self.endTime = Int64(entry.endTime.timeIntervalSince1970 * 1000)
        self.title = entry.title
        self.description = entry.description
        self.episodeTitle = entry.episodeTitle
        self.seasonNumber = entry.seasonNumber
        self.episodeNumber = entry.episodeNumber
        self.isNew = entry.isNew
        self.categories = (try? JSONEncoder().encode(entry.categories))?.toString()
        self.rating = entry.rating
        self.createdAt = Int64(Date().timeIntervalSince1970 * 1000)
    }

    // FetchableRecord conformance
    init(row: Row) throws {
        id = row["id"]
        channelID = row["channel_id"]
        startTime = row["start_time"]
        endTime = row["end_time"]
        title = row["title"]
        description = row["description"]
        episodeTitle = row["episode_title"]
        seasonNumber = row["season_number"]
        episodeNumber = row["episode_number"]
        isNew = row["is_new"]
        categories = row["categories"]
        rating = row["rating"]
        createdAt = row["created_at"]
    }

    // MutablePersistableRecord conformance
    func encode(to container: inout PersistenceContainer) throws {
        container["id"] = id
        container["channel_id"] = channelID
        container["start_time"] = startTime
        container["end_time"] = endTime
        container["title"] = title
        container["description"] = description
        container["episode_title"] = episodeTitle
        container["season_number"] = seasonNumber
        container["episode_number"] = episodeNumber
        container["is_new"] = isNew
        container["categories"] = categories
        container["rating"] = rating
        container["created_at"] = createdAt
    }

    func toGuideEntry() -> GuideEntry {
        let categoriesArray: [String]
        if let categories = categories, let data = categories.data(using: .utf8) {
            categoriesArray = (try? JSONDecoder().decode([String].self, from: data)) ?? []
        } else {
            categoriesArray = []
        }

        return GuideEntry(
            id: id,
            channelID: channelID,
            startTime: Date(timeIntervalSince1970: TimeInterval(startTime) / 1000),
            endTime: Date(timeIntervalSince1970: TimeInterval(endTime) / 1000),
            title: title,
            description: description,
            episodeTitle: episodeTitle,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            isNew: isNew,
            categories: categoriesArray,
            rating: rating
        )
    }

    static let databaseTableName = "guide_entries"
}

// Helper extension to convert Data to String
private extension Data {
    func toString() -> String {
        String(decoding: self, as: UTF8.self)
    }
}