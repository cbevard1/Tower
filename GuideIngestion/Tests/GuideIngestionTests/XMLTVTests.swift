import Testing
import Foundation
@testable import GuideIngestion
@testable import Core

@Suite("XMLTV Parser Tests")
struct XMLTVTests {

    @Test("XMLTVParser parses sample XMLTV into GuideEntry array")
    func parseSampleXMLTV() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <tv source-info-name="Test XMLTV" generator-info-name="test">
          <channel id="I7.1.tuner">
            <display-name>7.1 KABC-DT</display-name>
            <display-name>KABC</display-name>
            <icon src="http://example.com/logo_7.1.png"/>
          </channel>
          <channel id="I13.1.tuner">
            <display-name>13.1 KDEF-DT</display-name>
            <display-name>KDEF</display-name>
          </channel>
          <programme start="20240101000000 +0000" stop="20240101010000 +0000" channel="I7.1.tuner">
            <title>Evening News</title>
            <desc>Local news at 6pm</desc>
            <category>News</category>
            <rating system="TV Parental Guidelines">
              <value>TV-PG</value>
            </rating>
          </programme>
          <programme start="20240101010000 +0000" stop="20240101020000 +0000" channel="I7.1.tuner">
            <title>Sports Center</title>
            <desc>Sports highlights</desc>
            <category>Sports</category>
            <rating system="TV Parental Guidelines">
              <value>TV-14</value>
            </rating>
          </programme>
          <programme start="20240101000000 +0000" stop="20240101003000 +0000" channel="I13.1.tuner">
            <title>Movie: Action Hero</title>
            <desc>Action movie</desc>
            <category>Movie</category>
            <episode-num system="xmltv_ns">0.0.0/1</episode-num>
          </programme>
        </tv>
        """

        let parser = XMLTVParser()
        let data = xml.data(using: .utf8)!
        let entries = try parser.parse(data)

        #expect(entries.count == 3)

        // Check first entry
        let e1 = entries[0]
        #expect(e1.channelID == "I7.1.tuner")
        #expect(e1.title == "Evening News")
        #expect(e1.description == "Local news at 6pm")
        #expect(e1.categories == ["News"])
        #expect(e1.rating == "TV-PG")

        // Check second entry
        let e2 = entries[1]
        #expect(e2.channelID == "I7.1.tuner")
        #expect(e2.title == "Sports Center")
        #expect(e2.categories == ["Sports"])
        #expect(e2.rating == "TV-14")

        // Check third entry
        let e3 = entries[2]
        #expect(e3.channelID == "I13.1.tuner")
        #expect(e3.title == "Movie: Action Hero")
        #expect(e3.categories == ["Movie"])
    }

    @Test("XMLTVParser extracts channel icons")
    func parseChannelIcons() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <tv>
          <channel id="I7.1.tuner">
            <display-name>KABC</display-name>
            <icon src="http://example.com/logo_7.1.png"/>
          </channel>
          <programme start="20240101000000 +0000" stop="20240101010000 +0000" channel="I7.1.tuner">
            <title>Test</title>
          </programme>
        </tv>
        """

        let parser = XMLTVParser()
        let data = xml.data(using: .utf8)!
        let (_, channels) = try parser.parseWithChannels(data)

        #expect(channels.count == 1)
        let channel = channels[0]
        #expect(channel.id == "I7.1.tuner")
        #expect(channel.iconURL == "http://example.com/logo_7.1.png")
    }
}