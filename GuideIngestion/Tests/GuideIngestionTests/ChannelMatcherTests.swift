import Testing
import Foundation
@testable import GuideIngestion
@testable import Core

@Suite("Channel Matcher Tests")
struct ChannelMatcherTests {

    @Test("Exact number match returns confidence 1.0")
    func exactNumberMatch() async throws {
        let matcher = ChannelMatcherImpl()

        let tunerChannels = [
            Channel(id: "tuner-7.1", tunerID: "tuner", number: "7.1", name: "KABC-DT", callsign: "KABC")
        ]

        let guideChannels = [
            GuideEntry(
                id: "guide-1",
                channelID: "I7.1.tuner",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                title: "Test Show",
                isNew: false,
                categories: ["News"]
            )
        ]

        let matches = try await matcher.match(tunerChannels: tunerChannels, guideChannels: guideChannels)
        #expect(matches.count == 1)
        #expect(matches[0].matchType == .number)
        #expect(matches[0].confidence == 1.0)
    }

    @Test("Callsign match is superseded by exact number match")
    func callsignMatchSupersededByNumber() async throws {
        let matcher = ChannelMatcherImpl()

        let tunerChannels = [
            Channel(id: "tuner-7.1", tunerID: "tuner", number: "7.1", name: "KABC-DT", callsign: "KABC")
        ]

        // Even though callsign matches, exact number match takes precedence
        let guideChannels = [
            GuideEntry(
                id: "guide-1",
                channelID: "I7.1.tuner",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                title: "Test Show",
                isNew: false,
                categories: ["News"]
            )
        ]

        let matches = try await matcher.match(tunerChannels: tunerChannels, guideChannels: guideChannels)
        // Exact number match takes precedence over callsign
        #expect(matches.count == 1)
        #expect(matches[0].matchType == .number)
        #expect(matches[0].confidence == 1.0)
    }

    @Test("Major number only match returns confidence 0.7")
    func majorNumberMatch() async throws {
        let matcher = ChannelMatcherImpl()

        let tunerChannels = [
            Channel(id: "tuner-7.1", tunerID: "tuner", number: "7.1", name: "KABC-DT", callsign: "KABC")
        ]

        // Guide channel with different minor number
        let guideChannels = [
            GuideEntry(
                id: "guide-1",
                channelID: "I7.2.tuner",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                title: "Test Show",
                isNew: false,
                categories: ["News"]
            )
        ]

        let matches = try await matcher.match(tunerChannels: tunerChannels, guideChannels: guideChannels)
        #expect(matches.count == 1)
        #expect(matches[0].matchType == .major)
        #expect(matches[0].confidence == 0.7)
    }

    @Test("No match when no similarity")
    func noMatch() async throws {
        let matcher = ChannelMatcherImpl()

        let tunerChannels = [
            Channel(id: "tuner-7.1", tunerID: "tuner", number: "7.1", name: "KABC-DT", callsign: "KABC")
        ]

        let guideChannels = [
            GuideEntry(
                id: "guide-1",
                channelID: "I13.1.tuner",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                title: "Test Show",
                isNew: false,
                categories: ["News"]
            )
        ]

        let matches = try await matcher.match(tunerChannels: tunerChannels, guideChannels: guideChannels)
        #expect(matches.isEmpty)
    }
}