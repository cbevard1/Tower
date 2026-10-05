import Testing
import Foundation
@testable import Core

@Suite("Channel Tests")
struct ChannelTests {

    @Test("affineNumber computes correct sort key for various channel formats")
    func affineNumber() {
        // Major.minor format
        let ch1 = Channel(
            id: "tuner-7.1", tunerID: "tuner", number: "7.1", name: "KABC", callsign: "KABC"
        )
        #expect(ch1.affineNumber == 701)

        let ch2 = Channel(
            id: "tuner-7.2", tunerID: "tuner", number: "7.2", name: "KABC2", callsign: "KABC2"
        )
        #expect(ch2.affineNumber == 702)

        // Major only (no minor)
        let ch3 = Channel(
            id: "tuner-13", tunerID: "tuner", number: "13", name: "KDEF", callsign: "KDEF"
        )
        #expect(ch3.affineNumber == 1300)

        // Two-digit minor
        let ch4 = Channel(
            id: "tuner-99.10", tunerID: "tuner", number: "99.10", name: "KXYZ", callsign: "KXYZ"
        )
        #expect(ch4.affineNumber == 9910)

        // Single digit major
        let ch5 = Channel(
            id: "tuner-2.1", tunerID: "tuner", number: "2.1", name: "KGHI", callsign: "KGHI"
        )
        #expect(ch5.affineNumber == 201)
    }

    @Test("Channel sorts correctly by affineNumber")
    func channelSorting() {
        let channels = [
            Channel(id: "t-13", tunerID: "t", number: "13", name: "A", callsign: "A"),
            Channel(id: "t-7.1", tunerID: "t", number: "7.1", name: "B", callsign: "B"),
            Channel(id: "t-7.2", tunerID: "t", number: "7.2", name: "C", callsign: "C"),
            Channel(id: "t-2.1", tunerID: "t", number: "2.1", name: "D", callsign: "D"),
            Channel(id: "t-99.10", tunerID: "t", number: "99.10", name: "E", callsign: "E"),
        ]

        let sorted = channels.sorted { $0.affineNumber < $1.affineNumber }
        let numbers = sorted.map { $0.number }

        #expect(numbers == ["2.1", "7.1", "7.2", "13", "99.10"])
    }

    @Test("Channel ID is composite of tunerID and number")
    func channelIDFormat() {
        let channel = Channel(
            id: "1234ABCD-7.1",
            tunerID: "1234ABCD",
            number: "7.1",
            name: "KABC-DT",
            callsign: "KABC"
        )
        #expect(channel.id == "1234ABCD-7.1")
        #expect(channel.tunerID == "1234ABCD")
    }
}