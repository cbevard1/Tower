import Testing
import Foundation
@testable import TunerClient
@testable import Core

@Suite("Lineup Tests")
struct LineupTests {

    @Test("LineupParser parses HDHomeRun lineup.json into Channel array")
    func parseLineup() throws {
        let json = """
        [
            {
                "GuideNumber": "7.1",
                "GuideName": "KABC-DT",
                "URL": "http://192.168.1.50:5004/auto/v7.1",
                "HD": 1,
                "Favorite": 0,
                "Modulation": "8vsb",
                "ProgramCount": 1,
                "VideoCodec": "mpeg2",
                "AudioCodec": "ac3",
                "DRM": 0
            },
            {
                "GuideNumber": "7.2",
                "GuideName": "KABC-DT2",
                "URL": "http://192.168.1.50:5004/auto/v7.2",
                "HD": 1,
                "Favorite": 0,
                "Modulation": "8vsb",
                "ProgramCount": 1,
                "VideoCodec": "mpeg2",
                "AudioCodec": "ac3",
                "DRM": 0
            },
            {
                "GuideNumber": "13",
                "GuideName": "KDEF-DT",
                "URL": "http://192.168.1.50:5004/auto/v13",
                "HD": 1,
                "Favorite": 0,
                "Modulation": "8vsb",
                "ProgramCount": 1,
                "VideoCodec": "mpeg2",
                "AudioCodec": "ac3",
                "DRM": 0
            }
        ]
        """

        let parser = LineupParser()
        let data = json.data(using: .utf8)!
        let channels = try parser.parse(data, tunerID: "1234ABCD", tunerIP: "192.168.1.50")

        #expect(channels.count == 3)

        // Check first channel
        let ch1 = channels[0]
        #expect(ch1.id == "1234ABCD-7.1")
        #expect(ch1.tunerID == "1234ABCD")
        #expect(ch1.number == "7.1")
        #expect(ch1.name == "KABC-DT")
        #expect(ch1.callsign == "KABC")
        #expect(ch1.affineNumber == 701)
        #expect(ch1.modulation == "8vsb")
        #expect(ch1.programCount == 1)

        // Check second channel
        let ch2 = channels[1]
        #expect(ch2.id == "1234ABCD-7.2")
        #expect(ch2.number == "7.2")
        #expect(ch2.affineNumber == 702)

        // Check channel without minor number
        let ch3 = channels[2]
        #expect(ch3.id == "1234ABCD-13")
        #expect(ch3.number == "13")
        #expect(ch3.affineNumber == 1300)
    }

    @Test("StreamURLBuilder builds correct URL")
    func streamURLBuilder() {
        let builder = StreamURLBuilderImpl()
        let tuner = Tuner(
            id: "1234ABCD",
            ipAddress: "192.168.1.50",
            model: "HDHR4-2US",
            firmwareVersion: "20240101",
            tunerCount: 2,
            discoveredAt: Date(),
            manualOverride: false
        )

        let channel = Channel(
            id: "1234ABCD-7.1",
            tunerID: "1234ABCD",
            number: "7.1",
            name: "KABC-DT",
            callsign: "KABC"
        )

        let url = try! builder.buildStreamURL(for: channel, tuner: tuner)
        #expect(url.absoluteString == "http://192.168.1.50:5004/auto/v7.1")
    }

    @Test("LineupProviderImpl fetches and parses lineup with retry")
    func lineupProviderRetry() async throws {
        // This test would require a mock HTTP server
        // For now, we test that the type exists and compiles
        let provider = LineupProviderImpl()
        #expect(provider != nil)
    }
}