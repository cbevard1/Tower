/// Provides EPG (Electronic Program Guide) data.
///
/// A guide provider downloads and parses XMLTV data, returning
/// `GuideEntry` values for matching channels.
public protocol GuideProvider: Sendable {
    /// Fetch and parse guide entries.
    /// - Returns: Parsed guide entries.
    func fetch() async throws -> [GuideEntry]
}
