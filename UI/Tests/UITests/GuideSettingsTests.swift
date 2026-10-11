import Testing
import Foundation
@testable import UI
@testable import Core
@testable import GuideIngestion

@Suite("Guide Settings Tests")
@MainActor
struct GuideSettingsTests {

    @Test("SettingsViewModel saves XMLTV URL")
    func xmltvURLPersistence() throws {
        let suiteName = "test.guide.settings.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        
        let viewModel = SettingsViewModel(defaults: defaults)
        
        // Initially empty
        #expect(viewModel.xmltvURL == "")
        
        // Set URL
        let testURL = "http://example.com/xmltv.xml"
        viewModel.xmltvURL = testURL
        #expect(viewModel.xmltvURL == testURL)
        
        // Simulate app restart
        let viewModel2 = SettingsViewModel(defaults: defaults)
        #expect(viewModel2.xmltvURL == testURL)
    }
    
    @Test("SettingsViewModel saves auto-refresh interval")
    func autoRefreshIntervalPersistence() throws {
        let suiteName = "test.guide.settings.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        
        let viewModel = SettingsViewModel(defaults: defaults)
        
        #expect(viewModel.autoRefreshInterval == 12) // Default 12 hours
        
        viewModel.autoRefreshInterval = 6
        #expect(viewModel.autoRefreshInterval == 6)
        
        // Simulate app restart
        let viewModel2 = SettingsViewModel(defaults: defaults)
        #expect(viewModel2.autoRefreshInterval == 6)
    }
    
    @Test("Manual match override creates ChannelMatch with manual type")
    func manualMatchOverride() {
        let tunerChannel = Channel(id: "tuner-7.1", tunerID: "tuner", number: "7.1", name: "KABC", callsign: "KABC")
        let guideEntry = GuideEntry(
            id: "guide-1",
            channelID: "I9.1.tuner",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600),
            title: "Test Show",
            isNew: false,
            categories: []
        )
        
        // Test that manual match can be created with correct type
        let manualMatch = ChannelMatch(
            tunerChannelID: tunerChannel.id,
            guideChannelID: guideEntry.channelID,
            matchType: .manual,
            confidence: 1.0
        )
        #expect(manualMatch.matchType == .manual)
        #expect(manualMatch.confidence == 1.0)
        #expect(manualMatch.tunerChannelID == tunerChannel.id)
        #expect(manualMatch.guideChannelID == guideEntry.channelID)
    }
}