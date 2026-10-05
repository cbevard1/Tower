/// Provides the channel lineup for a given HDHomeRun tuner.
///
/// Consumers fetch `lineup.json` from the tuner and parse the
/// response into `[Channel]` values.
public protocol LineupProvider: Sendable {
    /// Fetch the channel lineup for the given tuner.
    /// - Parameter tuner: The tuner whose lineup to fetch.
    /// - Returns: Parsed channels.
    func fetchLineup(for tuner: Tuner) async throws -> [Channel]
}
