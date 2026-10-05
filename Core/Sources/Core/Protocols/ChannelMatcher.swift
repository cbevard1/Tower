/// Matches tuner channels to guide (XMLTV) channels.
public struct ChannelMatch: Sendable, Hashable {
    public let tunerChannelID: String
    public let guideChannelID: String
    public let matchType: MatchType
    public let confidence: Double

    public enum MatchType: String, Sendable {
        case number     // exact number match
        case callsign   // callsign match
        case major      // major number only
        case manual     // user override
    }

    public init(
        tunerChannelID: String,
        guideChannelID: String,
        matchType: MatchType,
        confidence: Double
    ) {
        self.tunerChannelID = tunerChannelID
        self.guideChannelID = guideChannelID
        self.matchType = matchType
        self.confidence = confidence
    }
}

/// Matches tuner channels to guide channels using strategy chain.
public protocol ChannelMatcher: Sendable {
    /// Match tuner channels against guide channels.
    func match(
        tunerChannels: [Channel],
        guideChannels: [GuideEntry]
    ) async throws -> [ChannelMatch]
}
