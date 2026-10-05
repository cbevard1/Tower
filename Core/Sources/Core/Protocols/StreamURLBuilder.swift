import Foundation

/// Builds HTTP stream URLs for HDHomeRun channels.
///
/// HDHomeRun tuners serve streams at:
/// `http://<ip>:5004/auto/v<channel-number>`
///
/// Note: The channel number in the URL uses the raw number string
/// (e.g. "7.1"), not the affine number. The `Channel.streamURL`
/// computed property and this builder produce the same result.
public protocol StreamURLBuilder: Sendable {
    /// Build a stream URL for the given channel on the given tuner.
    /// - Parameters:
    ///   - channel: The channel to stream.
    ///   - tuner: The tuner serving the stream.
    /// - Returns: A fully-qualified HTTP URL.
    func buildStreamURL(for channel: Channel, tuner: Tuner) throws -> URL
}
