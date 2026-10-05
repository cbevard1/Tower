/// Discovers HDHomeRun tuners on the local network.
///
/// Conforming types perform SSDP/Bonjour discovery and return
/// `[Tuner]` results. Manual fallback (user-entered IP) is layered
/// on top by a composite discoverer.
public protocol TunerDiscoverer: Sendable {
    /// Discover tuners on the local network.
    /// - Returns: An array of discovered tuners.
    func discover() async throws -> [Tuner]
}
