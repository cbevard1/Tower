/// Deinterlacing mode selection for video playback.
///
/// This core type is consumed by `PlayerController.open(deinterlacing:)`.
/// The PlaybackEngine module extends it with VLCKit-specific mappings.
public enum DeinterlacingMode: String, CaseIterable, Sendable, Hashable, Codable {
    /// Automatic selection based on stream analysis.
    case auto
    /// No deinterlacing.
    case off
    /// Bob deinterlacing (doubles framerate).
    case bob
    /// Yadif (yet another deinterlacing filter).
    case yadif
    /// Yadif 2x (doubles framerate with yadif).
    case yadif2x
    /// Phosphor (smooth motion).
    case phosphor
    /// Linear blend.
    case blend

    public var displayName: String {
        switch self {
        case .auto:     "Auto"
        case .off:      "Off"
        case .bob:      "Bob"
        case .yadif:    "Yadif"
        case .yadif2x:  "Yadif 2x"
        case .phosphor: "Phosphor"
        case .blend:    "Blend"
        }
    }
}
