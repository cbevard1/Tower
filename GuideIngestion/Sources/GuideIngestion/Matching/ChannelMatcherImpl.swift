import Foundation
import Core

/// Strategy for matching tuner channels to guide channels.
public protocol MatchStrategy: Sendable {
    var matchType: ChannelMatch.MatchType { get }
    func match(tunerChannel: Channel, guideChannels: [GuideEntry]) -> (guideChannelID: String, confidence: Double)?
}

/// Matches tuner channels to guide channels using a chain of strategies.
public final class ChannelMatcherImpl: ChannelMatcher, Sendable {
    private let strategies: [any MatchStrategy] = [
        ExactNumberMatchStrategy(),
        CallsignMatchStrategy(),
        MajorNumberMatchStrategy()
    ]

    public init() {}

    public func match(
        tunerChannels: [Channel],
        guideChannels: [GuideEntry]
    ) async throws -> [ChannelMatch] {
        // Build lookup of guide channel IDs to their entries (use first entry for each channel)
        var guideChannelMap: [String: GuideEntry] = [:]
        for entry in guideChannels {
            if guideChannelMap[entry.channelID] == nil {
                guideChannelMap[entry.channelID] = entry
            }
        }

        var matches: [ChannelMatch] = []

        for tunerChannel in tunerChannels {
            var bestMatch: ChannelMatch?

            for strategy in strategies {
                if let (guideChannelID, confidence) = strategy.match(
                    tunerChannel: tunerChannel,
                    guideChannels: Array(guideChannelMap.values)
                ) {
                    let match = ChannelMatch(
                        tunerChannelID: tunerChannel.id,
                        guideChannelID: guideChannelID,
                        matchType: strategy.matchType,
                        confidence: confidence
                    )
                    bestMatch = match
                    break // Use first (highest confidence) match
                }
            }

            if let match = bestMatch {
                matches.append(match)
            }
        }

        return matches
    }
}

/// Exact number match strategy (e.g., "7.1" == "7.1")
private struct ExactNumberMatchStrategy: MatchStrategy {
    let matchType = ChannelMatch.MatchType.number

    func match(tunerChannel: Channel, guideChannels: [GuideEntry]) -> (guideChannelID: String, confidence: Double)? {
        let tunerNumber = tunerChannel.number
        
        for guideChannel in guideChannels {
            // Extract number from guide channel ID (e.g., "I7.1.tuner" -> "7.1")
            let guideNumber = extractNumber(from: guideChannel.channelID)
            if guideNumber == tunerNumber {
                return (guideChannel.channelID, 1.0)
            }
        }
        return nil
    }

    private func extractNumber(from channelID: String) -> String? {
        // Expected format: "I7.1.tuner" or similar
        // Extract the number part between "I" and ".tuner"
        let pattern = #"I([0-9]+\.?[0-9]*)\.tuner"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: channelID.utf16.count)
        
        if let match = regex?.firstMatch(in: channelID, options: [], range: range),
           let range = Range(match.range(at: 1), in: channelID) {
            return String(channelID[range])
        }
        return nil
    }
}

/// Callsign match strategy (e.g., "KABC" == "KABC")
private struct CallsignMatchStrategy: MatchStrategy {
    let matchType = ChannelMatch.MatchType.callsign

    func match(tunerChannel: Channel, guideChannels: [GuideEntry]) -> (guideChannelID: String, confidence: Double)? {
        let tunerCallsign = tunerChannel.callsign.uppercased()
        
        for guideChannel in guideChannels {
            // Extract callsign from guide channel ID
            let guideCallsign = extractCallsign(from: guideChannel.channelID)
            if !guideCallsign.isEmpty && guideCallsign.uppercased() == tunerCallsign {
                return (guideChannel.channelID, 0.9)
            }
        }
        return nil
    }

    private func extractCallsign(from channelID: String) -> String {
        // This is a simplified extraction - in practice you'd need a mapping
        // For now, return empty to disable this strategy until proper mapping exists
        return ""
    }
}

/// Major number only match strategy (e.g., "7.1" matches "7.2" on major number 7)
private struct MajorNumberMatchStrategy: MatchStrategy {
    let matchType = ChannelMatch.MatchType.major

    func match(tunerChannel: Channel, guideChannels: [GuideEntry]) -> (guideChannelID: String, confidence: Double)? {
        let tunerMajor = extractMajorNumber(from: tunerChannel.number)
        
        for guideChannel in guideChannels {
            let guideNumber = extractNumber(from: guideChannel.channelID)
            let guideMajor = extractMajorNumber(from: guideNumber ?? "")
            if tunerMajor == guideMajor && tunerMajor != 0 {
                return (guideChannel.channelID, 0.7)
            }
        }
        return nil
    }

    private func extractMajorNumber(from number: String) -> Int {
        let parts = number.split(separator: ".")
        return Int(parts[0]) ?? 0
    }

    private func extractNumber(from channelID: String) -> String? {
        let pattern = #"I([0-9]+\.?[0-9]*)\.tuner"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: channelID.utf16.count)
        
        if let match = regex?.firstMatch(in: channelID, options: [], range: range),
           let range = Range(match.range(at: 1), in: channelID) {
            return String(channelID[range])
        }
        return nil
    }
}