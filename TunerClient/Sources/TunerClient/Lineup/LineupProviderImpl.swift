import Foundation
import Core

/// Fetches and parses the channel lineup from an HDHomeRun tuner.
///
/// Implements `LineupProvider` protocol from Core with retry logic.
public struct LineupProviderImpl: LineupProvider, Sendable {
    private let session: URLSession
    private let parser: LineupParser
    private let maxRetries: Int
    private let baseDelay: TimeInterval

    public init(
        session: URLSession = .shared,
        parser: LineupParser = LineupParser(),
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0
    ) {
        self.session = session
        self.parser = parser
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
    }

    /// Fetch the channel lineup for the given tuner.
    /// - Parameter tuner: The tuner whose lineup to fetch.
    /// - Returns: Parsed channels.
    public func fetchLineup(for tuner: Tuner) async throws -> [Channel] {
        let url = URL(string: "http://\(tuner.ipAddress)/lineup.json")!

        var lastError: Error?

        for attempt in 0..<maxRetries {
            do {
                let (data, response) = try await session.data(from: url)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw LineupProviderError.invalidResponse
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    throw LineupProviderError.httpError(httpResponse.statusCode)
                }

                return try parser.parse(data, tunerID: tuner.id, tunerIP: tuner.ipAddress)
            } catch {
                lastError = error
                // Exponential backoff: 1s, 2s, 4s, ...
                if attempt < maxRetries - 1 {
                    let delay = baseDelay * pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }

        throw lastError ?? LineupProviderError.maxRetriesExceeded
    }
}

/// Errors thrown by `LineupProviderImpl`.
public enum LineupProviderError: Error, Sendable, CustomStringConvertible {
    case invalidResponse
    case httpError(Int)
    case maxRetriesExceeded
    case parsingFailed(Error)

    public var description: String {
        switch self {
        case .invalidResponse:
            return "Invalid HTTP response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .maxRetriesExceeded:
            return "Max retries exceeded fetching lineup"
        case .parsingFailed(let error):
            return "Parsing failed: \(error.localizedDescription)"
        }
    }
}