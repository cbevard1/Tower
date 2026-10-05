import Testing
import Foundation
@testable import TunerClient
@testable import Core

@Suite("Tuner Discovery Tests")
struct DiscoveryTests {

    @Test("ManualTunerStore saves and retrieves IP address")
    func manualTunerStore() {
        // Use a unique suite name to avoid conflicts with other tests
        let suiteName = "test.manual.tuner.store.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ManualTunerStore(defaults: defaults)
        let testIP = "192.168.1.100"

        // Initially empty
        #expect(store.getManualIP() == nil)

        // Save IP
        store.setManualIP(testIP)
        #expect(store.getManualIP() == testIP)

        // Clear IP
        store.clearManualIP()
        #expect(store.getManualIP() == nil)
    }

    @Test("TunerDiscovererImpl returns manual tuner when SSDP fails")
    func discoverWithManualFallback() async throws {
        // Use a unique suite name to avoid conflicts
        let suiteName = "test.manual.tuner.store.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ManualTunerStore(defaults: defaults)
        store.setManualIP("192.168.1.50")

        let discoverer = TunerDiscovererImpl(manualStore: store)
        let tuners = try await discoverer.discover()

        // Should return at least the manual tuner
        #expect(!tuners.isEmpty)
        let manualTuner = tuners.first { $0.manualOverride == true }
        #expect(manualTuner != nil)
        #expect(manualTuner?.ipAddress == "192.168.1.50")
        #expect(manualTuner?.tunerCount == 2)
    }

    @Test("TunerDiscovererImpl merges SSDP and manual results without duplicates")
    func discoverMergesResults() async throws {
        let suiteName = "test.manual.tuner.store.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ManualTunerStore(defaults: defaults)
        store.setManualIP("192.168.1.50")

        let discoverer = TunerDiscovererImpl(manualStore: store)
        let tuners = try await discoverer.discover()

        // Should not have duplicate IPs
        let ips = tuners.map { $0.ipAddress }
        let uniqueIPs = Set(ips)
        #expect(ips.count == uniqueIPs.count)
    }
}