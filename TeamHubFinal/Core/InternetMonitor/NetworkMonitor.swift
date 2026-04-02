//
//  NetworkMonitor.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 25/03/26.
//

import Foundation
import Network
import Combine

protocol NetworkMonitoring {
    var isConnected: Bool { get }
    var onStatusChange: ((Bool) -> Void)? { get set }
}

final class NetworkMonitor: NetworkMonitoring ,ObservableObject{

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    @Published private(set) var isConnected: Bool = true

    var onStatusChange: ((Bool) -> Void)?
    init() {
        
        monitor.pathUpdateHandler = {
            [weak self] path in
            guard let self = self else { return }

            DispatchQueue.main.async {

                let connected = (path.status == .satisfied)

                self.isConnected = connected

                print("🌐 Network: \(connected ? "Online" : "Offline")")

                // THIS WAS MISSING
                self.onStatusChange?(connected)
            }
        }

        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
