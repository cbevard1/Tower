import Foundation

/// Represents a TV channel returned by the HDHomeRun lineup endpoint.
///
/// - `id`: Composite identifier: `"<tunerID>-<number>"` (e.g. "1234ABCD-7.1")
/// - `tunerID`: The HDHomeRun device ID the channel belongs to
/// - `number`: Display number as a string (e.g. "7.1", "13.2")
/// - `name`: Full channel name (e.g. "KABC-DT")
/// - `callsign`: Short identifier (e.g. "KABC")
/// - `affineNumber`: Numeric sort key — major * 100 + minor (7.1 → 701)
/// - `modulation`: Modulation type if reported by the tuner
/// - `programCount`: Number of sub-programs on this physical channel
public struct Channel: Identifiable, Hashable, Sendable {
    public let id: String
    public let tunerID: String
    public let number: String
    public let name: String
    public let callsign: String
    public let modulation: String?
    public let programCount: Int

    public init(
        id: String,
        tunerID: String,
        number: String,
        name: String,
        callsign: String,
        modulation: String? = nil,
        programCount: Int = 1
    ) {
        self.id = id
        self.tunerID = tunerID
        self.number = number
        self.name = name
        self.callsign = callsign
        self.modulation = modulation
        self.programCount = programCount
    }

    /// Numeric sort key: major * 100 + minor.
    /// Parsing rules:
    ///   - "7.1"  → 701
    ///   - "7.2"  → 702
    ///   - "13"   → 1300  (no minor)
    ///   - "99.10" → 9910
    public var affineNumber: Int {
        let parts = number.split(separator: ".")
        let major = Int(parts[0]) ?? 0
        let minor = parts.count > 1 ? (Int(parts[1]) ?? 0) : 0
        return major * 100 + minor
    }

    /// Build a stream URL for this channel on a tuner with the given IP.
    /// - Parameter tunerIP: The IP address of the HDHomeRun tuner.
    /// - Returns: A fully-qualified HTTP URL for the stream.
    public func streamURL(tunerIP: String) -> URL {
        URL(string: "http://\(tunerIP):5004/auto/v\(number)")!
    }
}