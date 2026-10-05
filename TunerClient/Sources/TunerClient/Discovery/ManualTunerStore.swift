import Foundation

/// Persists a manually-entered HDHomeRun tuner IP address.
///
/// Uses `UserDefaults` with key "manualTunerIP". The stored IP is used
/// as a fallback when SSDP discovery fails or returns no results.
///
/// Marked `@unchecked Sendable` because `UserDefaults` is not Sendable
/// but we only read/write from it in a thread-safe manner.
public final class ManualTunerStore: @unchecked Sendable {
    private let defaults: UserDefaults
    private let key = "manualTunerIP"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Returns the manually-configured IP address, or `nil` if none set.
    public func getManualIP() -> String? {
        defaults.string(forKey: key)
    }

    /// Saves a manual tuner IP address.
    public func setManualIP(_ ip: String) {
        defaults.set(ip, forKey: key)
    }

    /// Clears the manual tuner IP address.
    public func clearManualIP() {
        defaults.removeObject(forKey: key)
    }
}