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
                Button("Reconnect") {
                    wsManager.connect()
                }
                Divider()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            } label: {
                Text(wsManager.statusTitle)
            }
        }
}
