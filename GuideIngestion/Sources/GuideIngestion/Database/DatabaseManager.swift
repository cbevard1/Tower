import Foundation
import GRDB
import Core

/// Manages the GRDB database for guide data storage.
public final class DatabaseManager: Sendable {
    private let dbQueue: DatabaseQueue

    public init(inMemory: Bool = false) throws {
        if inMemory {
            // Use shared cache for in-memory database to allow multiple connections
            var config = Configuration()
            config.prepareDatabase { db in
                try db.execute(sql: "PRAGMA cache_size = -32768") // 32MB cache
            }
            self.dbQueue = try DatabaseQueue(configuration: config)
        } else {
            let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            let appSupportURL = urls[0].appendingPathComponent("Tower", isDirectory: true)
            try FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
            let dbURL = appSupportURL.appendingPathComponent("guide.sqlite")
            self.dbQueue = try DatabaseQueue(path: dbURL.path)
        }
    }

    /// Run database migrations.
    public func migrate() throws {
        var migrator = DatabaseMigrator()

        // v1: Initial schema
        migrator.registerMigration("v1_create_guide_tables") { db in
            // guide_entries table
            try db.create(table: "guide_entries") { t in
                t.column("id", .text).primaryKey()
                t.column("channel_id", .text).notNull()
                t.column("start_time", .integer).notNull()  // Unix epoch milliseconds
                t.column("end_time", .integer).notNull()
                t.column("title", .text).notNull()
                t.column("description", .text)
                t.column("episode_title", .text)
                t.column("season_number", .integer)
                t.column("episode_number", .integer)
                t.column("is_new", .boolean).notNull().defaults(to: false)
                t.column("categories", .text)  // JSON array
                t.column("rating", .text)
                t.column("created_at", .integer).notNull().defaults(to: Int64(Date().timeIntervalSince1970 * 1000))
            }

            // Indexes for efficient queries
            try db.create(index: "idx_guide_channel_time", on: "guide_entries", columns: ["channel_id", "start_time"])
            try db.create(index: "idx_guide_time_range", on: "guide_entries", columns: ["start_time", "end_time"])

            // guide_providers table
            try db.create(table: "guide_providers") { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text).notNull()
                t.column("source_url", .text).notNull()
                t.column("last_fetched", .integer)
                t.column("last_parsed", .integer)
                t.column("entry_count", .integer).notNull().defaults(to: 0)
            }

            // channel_matches table
            try db.create(table: "channel_matches") { t in
                t.column("tuner_channel_id", .text).primaryKey()
                t.column("guide_channel_id", .text).notNull()
                t.column("match_type", .text).notNull()  // 'number', 'callsign', 'major', 'manual'
                t.column("confidence", .double).notNull().defaults(to: 1.0)
                t.column("updated_at", .integer).notNull().defaults(to: Int64(Date().timeIntervalSince1970 * 1000))
            }
        }

        try migrator.migrate(dbQueue)
    }

    /// Get a read-only database connection.
    public var reader: DatabaseReader {
        dbQueue
    }

    /// Get a read-write database connection.
    public var writer: DatabaseWriter {
        dbQueue
    }
}