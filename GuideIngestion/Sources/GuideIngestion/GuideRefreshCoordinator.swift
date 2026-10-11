import Foundation
import Core

/// Coordinates the guide data refresh process.
public final class GuideRefreshCoordinator: Sendable {
    private let provider: GuideProvider
    private let repository: GuideRepository
    private let matcher: ChannelMatcher

    public init(
        provider: GuideProvider,
        repository: GuideRepository,
        matcher: ChannelMatcher
    ) {
        self.provider = provider
        self.repository = repository
        self.matcher = matcher
    }

    /// Refresh guide data for the given tuner channels.
    /// Downloads XMLTV, parses it, matches channels, and stores in database.
    public func refresh(tunerChannels: [Channel]) async throws {
        // 1. Fetch and parse XMLTV data
        let guideEntries = try await provider.fetch()
        
        // 2. Match tuner channels to guide channels
        let _ = try await matcher.match(tunerChannels: [], guideChannels: guideEntries)
        
        // 3. Save guide entries to database (transactional replace)
        try await repository.save(guideEntries)
    }
}