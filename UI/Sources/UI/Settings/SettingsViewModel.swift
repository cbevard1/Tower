import SwiftUI
import Core
import TunerClient
import GuideIngestion

/// View model for the Settings screen
@MainActor
@Observable
public final class SettingsViewModel {
    private let manualTunerStoreInstance: ManualTunerStore
    private let defaults: UserDefaults

    // MARK: - Tuner Settings

    public var manualTunerIP: String {
        get { manualTunerStoreInstance.getManualIP() ?? "" }
        set { manualTunerStoreInstance.setManualIP(newValue) }
    }

    public var autoDiscoverTuners: Bool {
        get { defaults.bool(forKey: "autoDiscoverTuners") }
        set { defaults.set(newValue, forKey: "autoDiscoverTuners") }
    }

    // Access to the manual tuner store for testing connection
    public var manualTunerStore: ManualTunerStore {
        manualTunerStoreInstance
    }

    // MARK: - Playback Settings

    public var deinterlacingMode: DeinterlacingMode {
        get {
            if let raw = defaults.string(forKey: "deinterlacingMode"),
               let mode = DeinterlacingMode(rawValue: raw) {
                return mode
            }
            return .auto
        }
        set { defaults.set(newValue.rawValue, forKey: "deinterlacingMode") }
    }

    public var hardwareDecodeEnabled: Bool {
        get { defaults.object(forKey: "hardwareDecodeEnabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "hardwareDecodeEnabled") }
    }

    public var bufferSize: Int {
        get { defaults.object(forKey: "bufferSize") as? Int ?? 300 }
        set { defaults.set(newValue, forKey: "bufferSize") }
    }

    // MARK: - Guide Settings

    public var xmltvURL: String {
        get { defaults.string(forKey: "xmltvURL") ?? "" }
        set { defaults.set(newValue, forKey: "xmltvURL") }
    }

    public var autoRefreshInterval: Int {
        get { defaults.object(forKey: "autoRefreshInterval") as? Int ?? 12 }
        set { defaults.set(newValue, forKey: "autoRefreshInterval") }
    }

    public var lastGuideRefresh: Date? {
        get {
            if let interval = defaults.object(forKey: "lastGuideRefresh") as? TimeInterval {
                return Date(timeIntervalSince1970: interval)
            }
            return nil
        }
        set { defaults.set(newValue?.timeIntervalSince1970, forKey: "lastGuideRefresh") }
    }

    // MARK: - Initialization

    public init(
        manualTunerStore: ManualTunerStore = ManualTunerStore(),
        defaults: UserDefaults = .standard
    ) {
        self.manualTunerStoreInstance = manualTunerStore
        self.defaults = defaults

        // Register defaults
        if defaults.object(forKey: "autoDiscoverTuners") == nil {
            defaults.set(true, forKey: "autoDiscoverTuners")
        }
        if defaults.object(forKey: "autoRefreshInterval") == nil {
            defaults.set(12, forKey: "autoRefreshInterval")
        }
    }

    // MARK: - Actions

    public func testConnection() async -> Bool {
        // TODO: Implement connection test
        return true
    }
}