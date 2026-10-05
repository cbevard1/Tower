import Foundation
import Network
import Core

/// Composite tuner discoverer that tries SSDP first, falls back to manual IP.
///
/// Implements `TunerDiscoverer` protocol from Core.
public final class TunerDiscovererImpl: TunerDiscoverer, @unchecked Sendable {
    private let ssdpDiscoverer = SSDPDiscoverer()
    private let manualStore: ManualTunerStore
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "tower.network-monitor")
    private var onNetworkChange: (@Sendable () -> Void)?

    public init(manualStore: ManualTunerStore = ManualTunerStore()) {
        self.manualStore = manualStore
        startNetworkMonitoring()
    }

    deinit {
        pathMonitor.cancel()
    }

    /// Discover tuners on the local network.
    ///
    /// First attempts SSDP discovery. If that fails or returns empty,
    /// falls back to the manually-configured IP (if set).
    /// - Returns: Array of discovered tuners, deduplicated by IP address.
    public func discover() async throws -> [Tuner] {
        var allTuners: [Tuner] = []

        // Try SSDP discovery
        do {
            let ssdpTuners = try await ssdpDiscoverer.discover()
            allTuners.append(contentsOf: ssdpTuners)
        } catch {
            // SSDP failed, log and continue to fallback
            print("SSDP discovery failed: \(error)")
        }

        // Add manual tuner if configured
        if let manualIP = manualStore.getManualIP(), !manualIP.isEmpty {
            let manualTuner = Tuner(
                id: "manual-\(manualIP)",
                ipAddress: manualIP,
                model: "HDHomeRun (Manual)",
                firmwareVersion: "Unknown",
                tunerCount: 2,
                discoveredAt: Date(),
                manualOverride: true
            )
            allTuners.append(manualTuner)
        }

        // Deduplicate by IP address (prefer non-manual if both exist)
        var seenIPs = Set<String>()
        var deduplicated: [Tuner] = []

        for tuner in allTuners {
            if !seenIPs.contains(tuner.ipAddress) {
                seenIPs.insert(tuner.ipAddress)
                deduplicated.append(tuner)
            } else if tuner.manualOverride == false {
                // Replace manual with discovered if we have both
                if let idx = deduplicated.firstIndex(where: { $0.ipAddress == tuner.ipAddress }) {
                    deduplicated[idx] = tuner
                }
            }
        }

        return deduplicated
    }

    /// Sets a callback to be invoked when network changes.
    ///
    /// The callback runs on a background queue. Call `discover()` again
    /// to refresh the tuner list after a network change.
    public func setNetworkChangeHandler(_ handler: @escaping @Sendable () -> Void) {
        onNetworkChange = handler
    }

    private func startNetworkMonitoring() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                self?.onNetworkChange?()
            }
        }
        pathMonitor.start(queue: monitorQueue)
    }
}