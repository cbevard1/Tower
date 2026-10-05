import SwiftUI
import Core

/// A card view displaying a single channel
public struct ChannelCardView: View {
    let channel: Channel
    let isPlaying: Bool
    let onTap: () -> Void

    public init(
        channel: Channel,
        isPlaying: Bool = false,
        onTap: @escaping () -> Void
    ) {
        self.channel = channel
        self.isPlaying = isPlaying
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                // Channel number badge
                HStack {
                    Text(channel.number)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.2))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(Capsule())

                    if isPlaying {
                        Image(systemName: "waveform")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .symbolEffect(.pulse)
                    }

                    Spacer()
                }

                // Channel name
                Text(channel.name)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)

                // Callsign
                Text(channel.callsign)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isPlaying ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}