import Foundation
import Core

/// Builds HTTP stream URLs for HDHomeRun channels.
///
/// HDHomeRun tuners serve streams at:
/// `http://<ip>:5004/auto/v<channel-number>`
///
/// The channel number in the URL uses the raw number string
/// (e.g., "7.1"), preserving the dot.
public struct StreamURLBuilderImpl: StreamURLBuilder, Sendable {

    public init() {}

    /// Build a stream URL for the given channel on the given tuner.
    /// - Parameters:
    ///   - channel: The channel to stream.
    ///   - tuner: The tuner serving the stream.
    /// - Returns: A fully-qualified HTTP URL.
    public func buildStreamURL(for channel: Channel, tuner: Tuner) throws -> URL {
        // Use the channel number directly (e.g., "7.1" -> "v7.1")
        let urlString = "http://\(tuner.ipAddress):5004/auto/v\(channel.number)"

        guard let url = URL(string: urlString) else {
            throw StreamURLBuilderError.invalidURL(urlString)
        }
        return url
    }
}

/// Errors thrown by `StreamURLBuilderImpl`.
public enum StreamURLBuilderError: Error, Sendable {
    case invalidURL(String)
}