import Foundation

/// Represents a single program entry in the TV guide.
///
/// - `id`: Unique identifier (UUID in production)
/// - `channelID`: Matches `Channel.id`
/// - `startTime` / `endTime`: Program window (UTC)
/// - `title`: Program title
/// - `description`: Optional long description
/// - `episodeTitle`: Episode title if part of a series
/// - `seasonNumber` / `episodeNumber`: Series episode info
/// - `isNew`: Whether this is a new episode
/// - `categories`: Genre categories (e.g. "Sports", "Movie")
/// - `rating`: TV rating (e.g. "TV-PG")
public struct GuideEntry: Identifiable, Hashable, Sendable {
    public let id: String
    public let channelID: String
    public let startTime: Date
    public let endTime: Date
    public let title: String
    public let description: String?
    public let episodeTitle: String?
    public let seasonNumber: Int?
    public let episodeNumber: Int?
    public let isNew: Bool
    public let categories: [String]
    public let rating: String?

    public init(
        id: String = UUID().uuidString,
        channelID: String,
        startTime: Date,
        endTime: Date,
        title: String,
        description: String? = nil,
        episodeTitle: String? = nil,
        seasonNumber: Int? = nil,
        episodeNumber: Int? = nil,
        isNew: Bool = false,
        categories: [String] = [],
        rating: String? = nil
    ) {
        self.id = id
        self.channelID = channelID
        self.startTime = startTime
        self.endTime = endTime
        self.title = title
        self.description = description
        self.episodeTitle = episodeTitle
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
        self.isNew = isNew
        self.categories = categories
        self.rating = rating
    }
}
