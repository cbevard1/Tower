import SwiftUI
import AppKit
import VLCKit

/// NSViewRepresentable wrapper for VLCKit's video output
public struct VideoViewRepresentable: NSViewRepresentable {
    let mediaPlayer: VLCMediaPlayer

    public init(mediaPlayer: VLCMediaPlayer) {
        self.mediaPlayer = mediaPlayer
    }

    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        
        // Set the drawable for VLCKit
        mediaPlayer.drawable = view
        
        return view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {
        // Ensure drawable is still set
        mediaPlayer.drawable = nsView
    }
}