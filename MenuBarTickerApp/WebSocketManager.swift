//
//  WebSocketManager.swift
//  MenuBarApp
//
//  Created by Nicholas Guest on 12/03/26.
//

import Foundation
import Observation

struct SubscriptionMessage: Codable {
    let id: Int
    let method: String
    let params: SubscriptionParams
}

struct SubscriptionParams: Codable {
    let channels: [String]
}

struct CryptoResponse: Decodable {
    let result: TickerResult?
}

struct TickerResult: Decodable {
    let data: [TickerData]?
}

struct TickerData: Decodable {
    let k: String?
    let i: String?
}

@Observable
class WebSocketManager {
    var statusTitle: String = "..." {
        didSet {
            statusTitleDidChange?(statusTitle)
        }
    }
    var statusTitleDidChange: ((String) -> Void)?
    private var webSocketTask: URLSessionWebSocketTask?
    private var reconnectTimer: Timer?
    private var isConnecting: Bool = false

    var symbol: String = "XRP_USD"
    let wsURL: String = "wss://stream.crypto.com/v2/market"

    init() {
        connect()
    }

    func connect() {
        // Show reconnecting status immediately
        DispatchQueue.main.async {
            self.statusTitle = "Recon..."
        }

        // Prevent multiple simultaneous connection attempts
        guard !isConnecting else { return }
        isConnecting = true

        let url = URL(string: wsURL)!
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()

        // Clear existing timers
        reconnectTimer?.invalidate()

        sendSubscription()
        receiveMessage()

        // Reset flag after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isConnecting = false
        }
    }

    func updateSymbol(to newSymbol: String) {
        guard newSymbol != symbol else { return }
        symbol = newSymbol

        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil

        connect()
    }

    private func sendSubscription() {
        let sub = SubscriptionMessage(
            id: 1,
            method: "subscribe",
            params: SubscriptionParams(channels: ["ticker.\(symbol)"])
        )

        // Encode to JSON string
        guard let data = try? JSONEncoder().encode(sub),
            let jsonString = String(data: data, encoding: .utf8)
        else { return }

        let message = URLSessionWebSocketTask.Message.string(jsonString)

        webSocketTask?.send(message) { error in
            if let error = error {
                print("Subscription failed: \(error)")
            }
        }
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                if case .string(let text) = message {
                    if let formattedPrice = self?.parsePrice(from: text) {
                        DispatchQueue.main.async {
                            self?.statusTitle = formattedPrice
                        }
                    }
                }
                self?.receiveMessage()  // Loop for next message

            case .failure(let error):
                print("WebSocket Disconnected: \(error)")
                self?.handleDisconnection()
            }
        }
    }

    private func handleDisconnection() {
        DispatchQueue.main.async {
            self.statusTitle = "Recon..."

            // Invalidate any old timer
            self.reconnectTimer?.invalidate()

            // Attempt to reconnect every 1 second
            self.reconnectTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) {
                [weak self] _ in
                print("Attempting reconnect...")
                self?.connect()
            }
        }
    }

    private func parsePrice(from jsonString: String) -> String? {
        guard let data = jsonString.data(using: .utf8) else { return nil }

        do {
            let decoded = try JSONDecoder().decode(CryptoResponse.self, from: data)

            // Use guard to ensure the data exists and contains the price 'k'
            guard let firstData = decoded.result?.data?.first,
                let price = firstData.k,
                let instrument = firstData.i,
                !price.isEmpty
            else {
                return nil
            }

            let firstChar = instrument.first.map(String.init) ?? ""
            return "\(firstChar): \(price)"

        } catch {
            return nil
        }
    }
}
