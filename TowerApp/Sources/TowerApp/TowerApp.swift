//  TowerApp.swift
//  Tower — Application Entry Point
//
//  Task 1.10: App wiring with DI, TabView, and navigation.

import SwiftUI
import Core
import TunerClient
import PlaybackEngine
import UI

@main
struct TowerApp: App {
    @StateObject private var container = AppContainer()
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(container)
                .environmentObject(appState)
                .frame(minWidth: 1000, minHeight: 700)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))

        // Settings window
        Settings {
            SettingsView()
                .environmentObject(container)
                .frame(width: 600, height: 500)
        }

        // Menu bar commands
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    // TODO: Implement
                }
            }

            CommandMenu("Window") {
                Button("Now Playing") {
                    // TODO: Focus player window
                }
                .keyboardShortcut("1", modifiers: [.command])

                Divider()

                Button("Toggle Fullscreen") {
                    appState.toggleFullscreen()
                }
                .keyboardShortcut("f", modifiers: [.command])

                Button("Toggle Picture-in-Picture") {
                    appState.togglePiP()
                }
                .keyboardShortcut("p", modifiers: [.command])
            }

            CommandMenu("View") {
                Button("Deinterlacing: Auto") { }
                    .keyboardShortcut("d", modifiers: [])

                Divider()

                Button("Refresh Channels") {
                    // TODO: Trigger channel refresh
                }
                .keyboardShortcut("r", modifiers: [.command])
            }

            CommandMenu("Playback") {
                Button("Play/Pause") {
                    // TODO
                }
                .keyboardShortcut(" ", modifiers: [])

                Button("Stop") {
                    // TODO
                }
                .keyboardShortcut(".", modifiers: [.command])

                Divider()

                Button("Channel Up") {
                    // TODO
                }
                .keyboardShortcut(.pageUp, modifiers: [])

                Button("Channel Down") {
                    // TODO
                }
                .keyboardShortcut(.pageDown, modifiers: [])

                Divider()

                Button("Seek Forward 10s") {
                    // TODO
                }
                .keyboardShortcut(.rightArrow, modifiers: [])

                Button("Seek Backward 10s") {
                    // TODO
                }
                .keyboardShortcut(.leftArrow, modifiers: [])
            }
        }
    }
}

/// Root content view with tab navigation
private struct ContentView: View {
    @EnvironmentObject private var container: AppContainer
    @EnvironmentObject private var appState: AppState

    @State private var selectedTab: Tab = .channels

    var body: some View {
        TabView(selection: $selectedTab) {
            // Channels tab
            NavigationStack {
                ChannelsView(
                    discoverer: try! container.resolveOrFail(TunerDiscoverer.self),
                    lineupProvider: try! container.resolveOrFail(LineupProvider.self),
                    playerController: try! container.resolveOrFail(PlayerController.self)
                )
            }
            .tabItem {
                Label("Channels", systemImage: "antenna.radiowaves.left.and.right")
            }
            .tag(Tab.channels)

            // Guide tab (placeholder)
            NavigationStack {
                GuidePlaceholderView()
            }
            .tabItem {
                Label("Guide", systemImage: "calendar")
            }
            .tag(Tab.guide)

            // Now Playing tab
            NavigationStack {
                PlayerContainerView()
            }
            .tabItem {
                Label("Now Playing", systemImage: "play.tv")
            }
            .tag(Tab.player)
        }
        .onAppear {
            // Restore last selected tab
        }
    }

    private enum Tab: String, CaseIterable {
        case channels, guide, player
    }
}

/// Container view for the player that provides the PlayerViewModel
private struct PlayerContainerView: View {
    @EnvironmentObject private var container: AppContainer
    @EnvironmentObject private var appState: AppState

    var body: some View {
        if let playerController = container.resolve(PlayerController.self) as? VLCPlayerController {
            PlayerView(
                playerController: playerController,
                onChannelUp: { /* TODO: Implement channel up */ },
                onChannelDown: { /* TODO: Implement channel down */ },
                onClose: { appState.setCurrentChannel(nil as Channel?) }
            )
            .environmentObject(appState)
        } else {
            VStack(spacing: 16) {
                Image(systemName: "play.tv")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("No channel playing")
                    .font(.title2)
                Text("Select a channel from the Channels tab to start watching")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Browse Channels") {
                    // TODO: Switch to channels tab
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// Placeholder for Guide tab
private struct GuidePlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Program Guide")
                .font(.title)
            Text("Guide data will appear here after XMLTV configuration")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Configure Guide Source") {
                // TODO: Open settings to guide tab
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}