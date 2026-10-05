import Foundation

/// Persists and queries guide data (GRDB-backed).
public protocol GuideRepository: Sendable {
    /// Save guide entries atomically (replace strategy).
    func save(_ entries: [GuideEntry]) async throws

    /// Fetch entries for a specific channel within a time window.
    func entries(
        for channelID: String,
        from start: Date,
        to end: Date
    ) async throws -> [GuideEntry]

    /// Fetch entries within a time window across all channels.
    func entries(from start: Date, to end: Date) async throws -> [GuideEntry]
}
