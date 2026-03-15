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
    @State private var selectedSymbol: String = "XRP_USD"

    var body: some Scene {
        MenuBarExtra {
            Picker("Pair", selection: $selectedSymbol) {
                Text("BTC/USD").tag("BTC_USD")
                Text("ETH/USD").tag("ETH_USD")
                Text("XRP/USD").tag("XRP_USD")
            }
            .onChange(of: selectedSymbol) { _, newValue in
                wsManager.updateSymbol(to: newValue)
            }

            Divider()

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
