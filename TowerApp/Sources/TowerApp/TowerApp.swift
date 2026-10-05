//  TowerApp.swift
//  Tower — Application Entry Point
//
//  Task 1.1 deliverable: minimal @main App struct.
//  Full DI wiring, TabView, and navigation arrive in Task 1.10.

import SwiftUI

import Core
import TunerClient
import PlaybackEngine
import UI

@main
struct TowerApp: App {
    var body: some Scene {
        WindowGroup {
            VStack {
                Text("Tower")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("HDHomeRun OTA television viewer")
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 960, minHeight: 540)
        }
    }
}
