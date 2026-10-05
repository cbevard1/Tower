import SwiftUI
import Core

/// Grid view for displaying channels
public struct ChannelGridView: View {
    let channels: [Channel]
    let playingChannelID: String?
    let onChannelTap: (Channel) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 16)
    ]

    public init(
        channels: [Channel],
        playingChannelID: String? = nil,
        onChannelTap: @escaping (Channel) -> Void
    ) {
        self.channels = channels
        self.playingChannelID = playingChannelID
        self.onChannelTap = onChannelTap
    }

    public var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(channels) { channel in
                    ChannelCardView(
                        channel: channel,
                        isPlaying: channel.id == playingChannelID,
                        onTap: { onChannelTap(channel) }
                    )
                    .contextMenu {
                        Button("Play") {
                            onChannelTap(channel)
                        }
                        Divider()
                        Button("Copy Stream URL") {
                            let url = channel.streamURL(tunerIP: "192.168.1.50")
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(url.absoluteString, forType: .string)
                        }
                    }
                }
            }
            .padding(16)
        }
    }
}