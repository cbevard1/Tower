import SwiftUI
import Foundation
import Core
import GuideIngestion

/// View model for the Guide grid screen.
@MainActor
@Observable
public final class GuideViewModel {
    private let repository: GuideRepository
    private let matcher: ChannelMatcher
    
    public private(set) var guideEntries: [GuideEntry] = []
    public private(set) var channels: [Channel] = []
    public var timeRange: ClosedRange<Date> = {
        let start = Calendar.current.startOfDay(for: Date())
        let end = start.addingTimeInterval(24 * 3600)
        return start...end
    }()
    
    public init(
        repository: GuideRepository,
        channels: [Channel] = [],
        matcher: ChannelMatcher
    ) {
        self.repository = repository
        self.channels = channels
        self.matcher = matcher
    }
    
    /// Load guide entries for the current time range and channels.
    public func loadGuideEntries() async {
        do {
            // Extract unique channel IDs
            let channelIDs = Set(channels.map { $0.id })
            
            // Fetch entries for all channels in the time range
            var allEntries: [GuideEntry] = []
            
            for channelID in channelIDs {
                let entries = try await repository.entries(
                    for: channelID,
                    from: timeRange.lowerBound,
                    to: timeRange.upperBound
                )
                allEntries.append(contentsOf: entries)
            }
            
            // Sort by start time
            allEntries.sort { $0.startTime < $1.startTime }
            
            self.guideEntries = allEntries
        } catch {
            // Handle error - in production, would update an error state
            print("Failed to load guide entries: \(error)")
        }
    }
    
    /// Update the list of channels and reload.
    public func updateChannels(_ channels: [Channel]) {
        self.channels = channels
        Task { await loadGuideEntries() }
    }
    
    /// Update the time range and reload.
    public func updateTimeRange(_ range: ClosedRange<Date>) {
        self.timeRange = range
        Task { await loadGuideEntries() }
    }
    
    /// Get entries for a specific channel within the time range.
    public func entriesForChannel(_ channelID: String) -> [GuideEntry] {
        guideEntries.filter { $0.channelID == channelID }
    }
    
    /// Check if there's a live show at the given time for a channel.
    public func isLive(at time: Date, channelID: String) -> Bool {
        entriesForChannel(channelID).contains { entry in
            entry.startTime <= time && entry.endTime > time
        }
    }
}