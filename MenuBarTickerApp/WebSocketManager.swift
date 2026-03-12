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
    var statusTitle: String = "Connecting..."
    private var webSocketTask: URLSessionWebSocketTask?
    let symbol: String = "XRP_USD"
    
    init() {
        connect()
    }
    
    func connect() {
        let url = URL(string: "wss://stream.crypto.com/v2/market")!
        var request = URLRequest(url: url)
        
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        
        // Explicitly create the task with the request
        webSocketTask = URLSession.shared.webSocketTask(with: request)
        webSocketTask?.resume()
        
        sendSubscription()
        receiveMessage()
    }
    
    private func sendSubscription() {
        let sub = SubscriptionMessage(
            id: 1,
            method: "subscribe",
            params: SubscriptionParams(channels: ["ticker.\(symbol)"])
        )
        
        // Encode to JSON string
        guard let data = try? JSONEncoder().encode(sub),
              let jsonString = String(data: data, encoding: .utf8) else { return }
        
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
                    // update statusTitle with the price
                    DispatchQueue.main.async {
                        self?.statusTitle = self?.parsePrice(from: text) ?? text
                    }
                }
                self?.receiveMessage()
            case .failure:
                DispatchQueue.main.async { self?.statusTitle = "Offline" }
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
                  !price.isEmpty else {
                return nil
            }
            
            let symbol = instrument.replacingOccurrences(of: "_USD", with: "")
            return "\(symbol): $\(price)"
            
        } catch {
            return nil
        }
    }
}
