import SwiftUI
import Core
import PlaybackEngine
import VLCKit

/// Full-screen player view with controls
public struct PlayerView: View {
    @State private var viewModel: PlayerViewModel
    @State private var isFullscreen = false
    @State private var isPiP = false

    private let playerController: VLCPlayerController
    private let onChannelUp: () -> Void
    private let onChannelDown: () -> Void
    private let onClose: () -> Void

    public init(
        playerController: VLCPlayerController,
        onChannelUp: @escaping () -> Void,
        onChannelDown: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.playerController = playerController
        self.onChannelUp = onChannelUp
        self.onChannelDown = onChannelDown
        self.onClose = onClose
        self._viewModel = State(initialValue: PlayerViewModel(playerController: playerController))
    }

    public var body: some View {
        ZStack {
            // Video layer
            VideoViewRepresentable(mediaPlayer: playerController.mediaPlayer)
                .background(Color.black)
                .ignoresSafeArea()

            // Controls overlay
            PlayerControlsView(
                viewModel: viewModel,
                onChannelUp: onChannelUp,
                onChannelDown: onChannelDown,
                onToggleFullscreen: { toggleFullscreen() },
                onTogglePiP: { togglePiP() }
            )
            .padding()
        }
        .background(Color.black)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onKeyPress { keyPress in
            handleKeyPress(keyPress)
        }
        .onAppear {
            // Enter fullscreen on appear if not already
            if !isFullscreen {
                toggleFullscreen()
            }
        }
        .onDisappear {
            if isFullscreen {
                toggleFullscreen()
            }
        }
    }

    private func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        let key = keyPress.characters

        switch key {
        case " ":
            Task { await viewModel.togglePlayPause() }
            return .handled
        case "\u{1B}": // Escape
            if isFullscreen {
                toggleFullscreen()
            } else {
                onClose()
            }
            return .handled
        case "f", "F":
            toggleFullscreen()
            return .handled
        case "d", "D":
            viewModel.cycleDeinterlacing()
            return .handled
        case "\u{1B}[C": // Right arrow
            Task { await seekRelative(+10) }
            return .handled
        case "\u{1B}[D": // Left arrow
            Task { await seekRelative(-10) }
            return .handled
        case "\u{1B}[A": // Up arrow
            Task { await seekRelative(+30) }
            return .handled
        case "\u{1B}[B": // Down arrow
            Task { await seekRelative(-30) }
            return .handled
        case "\u{007D}": // PageDown
            onChannelUp()
            return .handled
        case "\u{007B}": // PageUp
            onChannelDown()
            return .handled
        default:
            return .ignored
        }
    }

    private func seekRelative(_ delta: TimeInterval) async {
        // TODO: Get current time from player and seek
        // For now, just seek to delta
        await viewModel.seek(to: delta)
    }

    private func toggleFullscreen() {
        isFullscreen.toggle()
        // TODO: Implement actual fullscreen toggle via NSWindow
    }

    private func togglePiP() {
        isPiP.toggle()
        // TODO: Implement PiP via VLCKit
    }
}