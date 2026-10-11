import Foundation
import Core

/// Parses XMLTV data into GuideEntry and Channel objects.
public struct XMLTVParser: Sendable {

    public init() {}

    /// Parse XMLTV data and return guide entries.
    /// Handles both plain XML and gzipped XML.
    public func parse(_ data: Data) throws -> [GuideEntry] {
        let (entries, _) = try parseWithChannels(data)
        return entries
    }

    /// Parse XMLTV data and return both guide entries and channel info (including icons).
    public func parseWithChannels(_ data: Data) throws -> ([GuideEntry], [XMLTVChannel]) {
        // Check if data is gzipped
        let xmlData: Data
        if data.isGzipped {
            xmlData = try data.gunzipped()
        } else {
            xmlData = data
        }

        let parser = XMLTVInternalParser()
        let result = try parser.parse(xmlData)
        return (result.entries, result.channels)
    }
}

/// Internal parser state.
private final class XMLTVInternalParser: NSObject, XMLParserDelegate {
    private var entries: [GuideEntry] = []
    private var channels: [XMLTVChannel] = []
    private var currentElement = ""
    private var currentProgramme: ProgrammeBuilder?
    private var currentChannel: ChannelBuilder?
    private var currentText = ""

    private final class ProgrammeBuilder {
        var channelID: String = ""
        var startTime: Date?
        var endTime: Date?
        var title: String = ""
        var description: String?
        var episodeTitle: String?
        var seasonNumber: Int?
        var episodeNumber: Int?
        var isNew: Bool = false
        var categories: [String] = []
        var rating: String?
    }

    private final class ChannelBuilder {
        var id: String = ""
        var displayName: String = ""
        var iconURL: String?
    }

    func parse(_ data: Data) throws -> (entries: [GuideEntry], channels: [XMLTVChannel]) {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.shouldResolveExternalEntities = false
        
        if !parser.parse() {
            throw parser.parserError ?? XMLTVError.parseFailed("Unknown parsing error")
        }
        
        return (entries, channels)
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        currentText = ""

        switch elementName {
        case "channel":
            currentChannel = ChannelBuilder()
            currentChannel?.id = attributeDict["id"] ?? ""
        case "programme":
            currentProgramme = ProgrammeBuilder()
            currentProgramme?.channelID = attributeDict["channel"] ?? ""
            if let startStr = attributeDict["start"] {
                currentProgramme?.startTime = parseXMLTVDate(startStr)
            }
            if let stopStr = attributeDict["stop"] {
                currentProgramme?.endTime = parseXMLTVDate(stopStr)
            }
        case "icon":
            currentChannel?.iconURL = attributeDict["src"]
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch elementName {
        case "channel":
            if let channel = currentChannel, !channel.id.isEmpty {
                channels.append(XMLTVChannel(
                    id: channel.id,
                    displayName: channel.displayName,
                    iconURL: channel.iconURL
                ))
            }
            currentChannel = nil
        case "programme":
            if let prog = currentProgramme, !prog.channelID.isEmpty, let start = prog.startTime, let end = prog.endTime {
                let entry = GuideEntry(
                    id: UUID().uuidString,
                    channelID: prog.channelID,
                    startTime: start,
                    endTime: end,
                    title: prog.title,
                    description: prog.description,
                    episodeTitle: prog.episodeTitle,
                    seasonNumber: prog.seasonNumber,
                    episodeNumber: prog.episodeNumber,
                    isNew: prog.isNew,
                    categories: prog.categories,
                    rating: prog.rating
                )
                entries.append(entry)
            }
            currentProgramme = nil
        case "display-name":
            if let channel = currentChannel, !currentText.isEmpty && channel.displayName.isEmpty {
                channel.displayName = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        case "title":
            if let prog = currentProgramme, !currentText.isEmpty {
                prog.title = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        case "desc":
            if let prog = currentProgramme, !currentText.isEmpty {
                prog.description = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        case "sub-title":
            if let prog = currentProgramme, !currentText.isEmpty {
                prog.episodeTitle = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        case "category":
            if let prog = currentProgramme, !currentText.isEmpty {
                prog.categories.append(currentText.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        case "rating":
            if let prog = currentProgramme, !currentText.isEmpty, prog.rating == nil {
                prog.rating = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        case "value":
            if let prog = currentProgramme, !currentText.isEmpty, prog.rating == nil {
                prog.rating = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        case "episode-num":
            if let prog = currentProgramme, !currentText.isEmpty {
                parseEpisodeNum(currentText.trimmingCharacters(in: .whitespacesAndNewlines), into: prog)
            }
        case "previously-shown":
            if let prog = currentProgramme {
                prog.isNew = false
            }
        case "new":
            if let prog = currentProgramme {
                prog.isNew = true
            }
        default:
            break
        }
        
        currentText = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("XMLTV Parse Error: \(parseError)")
    }

    private func parseXMLTVDate(_ str: String) -> Date? {
        // XMLTV date format: "YYYYMMDDHHMMSS ZZZ" or "YYYYMMDDHHMMSS"
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        // Try with timezone
        formatter.dateFormat = "yyyyMMddHHmmss Z"
        if let date = formatter.date(from: str) {
            return date
        }
        
        // Try without timezone
        formatter.dateFormat = "yyyyMMddHHmmss"
        if let date = formatter.date(from: str) {
            return date
        }
        
        return nil
    }

    private func parseEpisodeNum(_ str: String, into builder: ProgrammeBuilder) {
        // XMLTV episode-num format: "S.E.P/TP" where S=season, E=episode, P=part, TP=total parts
        // Example: "0.0.0/1" = season 1, episode 1
        let parts = str.split(separator: ".")
        if parts.count >= 2 {
            if let season = Int(parts[0]) {
                builder.seasonNumber = season + 1  // XMLTV uses 0-based
            }
            let epParts = parts[1].split(separator: "/")
            if let episode = Int(epParts[0]) {
                builder.episodeNumber = episode + 1  // XMLTV uses 0-based
            }
        }
    }
}

/// XMLTV Channel info
public struct XMLTVChannel: Sendable {
    public let id: String
    public let displayName: String
    public let iconURL: String?

    public init(id: String, displayName: String, iconURL: String?) {
        self.id = id
        self.displayName = displayName
        self.iconURL = iconURL
    }
}

/// XMLTV parsing errors
public enum XMLTVError: Error, Sendable {
    case parseFailed(String)
    case invalidDate(String)
}