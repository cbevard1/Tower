import SwiftUI
import Core

/// Player controls overlay
public struct PlayerControlsView: View {
    @Bindable var viewModel: PlayerViewModel
    let onChannelUp: () -> Void
    let onChannelDown: () -> Void
    let onToggleFullscreen: () -> Void
    let onTogglePiP: () -> Void

    @State private var isVisible = true

    public init(
        viewModel: PlayerViewModel,
        onChannelUp: @escaping () -> Void,
        onChannelDown: @escaping () -> Void,
        onToggleFullscreen: @escaping () -> Void,
        onTogglePiP: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onChannelUp = onChannelUp
        self.onChannelDown = onChannelDown
        self.onToggleFullscreen = onToggleFullscreen
        self.onTogglePiP = onTogglePiP
    }

    public var body: some View {
        VStack {
            Spacer()

            if isVisible {
                VStack(spacing: 12) {
                    // Timeline / progress
                    ProgressView(value: 0.5) // TODO: Bind to actual progress
                        .progressViewStyle(.linear)
                        .frame(height: 4)

                    // Main controls
                    HStack(spacing: 24) {
                        // Channel down
                        Button(action: onChannelDown) {
                            Image(systemName: "chevron.down.square.fill")
                                .font(.system(size: 32))
                        }
                        .buttonStyle(.plain)

                        // Play/Pause
                        Button(action: { Task { await viewModel.togglePlayPause() } }) {
                            Image(systemName: viewModel.playbackState == .playing ? "pause.fill" : "play.fill")
                                .font(.system(size: 44))
                        }
                        .buttonStyle(.plain)

                        // Channel up
                        Button(action: onChannelUp) {
                            Image(systemName: "chevron.up.square.fill")
                                .font(.system(size: 32))
                        }
                        .buttonStyle(.plain)
                    }

                    // Secondary controls
                    HStack(spacing: 16) {
                        // Deinterlacing
                        Menu {
                            ForEach(DeinterlacingMode.allCases, id: \.self) { mode in
                                Button(mode.displayName) {
                                    viewModel.setDeinterlacing(mode)
                                }
                            }
                        } label: {
                            Label(viewModel.currentDeinterlacing.displayName, systemImage: "tv.badge.wifi")
                                .font(.caption)
                        }
                        .menuStyle(.borderlessButton)

                        Spacer()

                        // PiP
                        Button(action: onTogglePiP) {
                            Image(systemName: "pip")
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                        .help("Picture in Picture")

                        // Fullscreen
                        Button(action: onToggleFullscreen) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                        .help("Fullscreen")
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isVisible)
        .onHover { hovering in
            if hovering {
                withAnimation { isVisible = true }
            } else {
                withAnimation { isVisible = false }
            }
        }
        .onTapGesture {
            withAnimation { isVisible.toggle() }
        }
    }
}