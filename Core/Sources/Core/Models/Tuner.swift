import Foundation

/// Represents a physical or manually-configured HDHomeRun tuner device.
///
/// - `id`: Device ID from HDHomeRun (e.g. "1234ABCD")
/// - `ipAddress`: IP address of the tuner on the local network
/// - `model`: HDHomeRun model string (e.g. "HDHR4-2US")
/// - `firmwareVersion`: Firmware version string
/// - `tunerCount`: Number of tuners on the device
/// - `discoveredAt`: When the device was discovered
/// - `manualOverride`: True if the user entered the IP manually
public struct Tuner: Identifiable, Hashable, Sendable {
    public let id: String
    public let ipAddress: String
    public let model: String
    public let firmwareVersion: String
    public let tunerCount: Int
    public let discoveredAt: Date
    public let manualOverride: Bool

    public init(
        id: String,
        ipAddress: String,
        model: String,
        firmwareVersion: String,
        tunerCount: Int,
        discoveredAt: Date = Date(),
        manualOverride: Bool = false
    ) {
        self.id = id
        self.ipAddress = ipAddress
        self.model = model
        self.firmwareVersion = firmwareVersion
        self.tunerCount = tunerCount
        self.discoveredAt = discoveredAt
        self.manualOverride = manualOverride
    }
}
