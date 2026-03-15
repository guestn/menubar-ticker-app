//
//  MenuBarTickerApp.swift
//  MenuBarApp
//
//  Created by Nicholas Guest on 11/03/26.
//

import SwiftUI

@main struct MenuBarTickerApp: App {

    // Create the manager
    @State private var wsManager = WebSocketManager()

    var body: some Scene {
        MenuBarExtra {
            Button {
                wsManager.connect()
            } label: {
                Label("Reconnect", systemImage: "arrow.clockwise")
            }
            Divider()
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit", systemImage: "xmark.circle.fill")
            }
        } label: {
            Text(wsManager.statusTitle)
                .font(.custom("Courier-Bold", size: 14))
                .foregroundColor(.red)
                .allowsTightening(false)
        }
    }
}
