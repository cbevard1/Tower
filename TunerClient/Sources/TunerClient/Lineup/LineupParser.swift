import Foundation
import Core

/// Parses HDHomeRun `lineup.json` into `Channel` values.
public struct LineupParser: Sendable {

    public init() {}

    /// Parse lineup JSON data into an array of channels.
    /// - Parameters:
    ///   - data: Raw JSON data from the tuner's `lineup.json` endpoint.
    ///   - tunerID: The HDHomeRun device ID.
    ///   - tunerIP: The tuner's IP address (used for stream URL building).
    /// - Returns: Parsed channels with computed `affineNumber` for sorting.
    public func parse(_ data: Data, tunerID: String, tunerIP: String) throws -> [Channel] {
        let decoder = JSONDecoder()
        let lineupEntries = try decoder.decode([LineupEntry].self, from: data)

        return lineupEntries.map { entry in
            // Extract callsign from GuideName (e.g., "KABC-DT" -> "KABC")
            let callsign = entry.GuideName.components(separatedBy: "-").first ?? entry.GuideName

            return Channel(
                id: "\(tunerID)-\(entry.GuideNumber)",
                tunerID: tunerID,
                number: entry.GuideNumber,
                name: entry.GuideName,
                callsign: callsign,
                modulation: entry.Modulation,
                programCount: entry.ProgramCount
            )
        }
    }

    private struct LineupEntry: Codable {
        let GuideNumber: String
        let GuideName: String
        let URL: String
        let HD: Int
        let Favorite: Int
        let Modulation: String?
        let ProgramCount: Int
        let VideoCodec: String?
        let AudioCodec: String?
        let DRM: Int
    }
}