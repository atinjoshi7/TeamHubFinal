//
//  SyncManager.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 27/03/26.
//

import Foundation

protocol SyncManaging {
    func start()
    func syncNow() async
    func startAutoSync() async
    func stopAutoSync()
    func syncFromServer() async
    var syncRunning: Bool { get }
}

final class SyncManager: SyncManaging {

    private let repo: EmployeeRepositoryProtocol
    private var network: NetworkMonitoring
    private let syncState: SyncState
    private var isSyncing = false
    private var syncTimer: Timer?
    private(set) var syncRunning = false
    init(repo: EmployeeRepositoryProtocol,
         network: NetworkMonitoring,syncState:SyncState) {
        self.repo = repo
        self.network = network
        self.syncState = syncState
    }

    // Start observing network
    
    func start() {
        print("SyncManager started")

        //Immediate sync if already online
        if network.isConnected {
            Task { await syncNow() }
        }

        network.onStatusChange = { [weak self] isConnected in
            guard let self = self else { return }

            print("Network changed: \(isConnected)")

            if isConnected {
                Task {
                    await self.syncNow()
                }
            }
        }
    }

    // Manual trigger
    func syncNow() async {

        guard network.isConnected else { return }
        guard !isSyncing else { return }

        isSyncing = true

        // 1. Push local
        await pushLocalChanges()

        // 2. Pull from server
        await repo.syncFromServer()

        isSyncing = false
    }
    
    
    func startAutoSync() async {
        
        syncRunning = true
        stopAutoSync() // prevent duplicates

        syncTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            
            Task {
                await self?.syncNow()
            }
        }
    }
    
    func stopAutoSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    func syncFromServer() async {

        guard !isSyncing else { return }
        isSyncing = true

        defer { isSyncing = false }

        // your sync logic
//        startAutoSync()
        await repo.syncFromServer()
    }
}
extension SyncManager {

    private func pushLocalChanges() async {

        let pending = repo.fetchPendingSync()

        print("Pending items: \(pending.count)")

        for employee in pending {

            //  fetch syncAction from DB via repo
            let action = repo.getSyncAction(for: employee.id)

            do {
                switch action {

                case "create":
                    try await repo.syncCreate(employee)

                case "update":
                    try await repo.syncUpdate(employee)

                case "delete":
                    print("DELETE FLOW START:", employee.id)
                        try await repo.syncDelete(employee.id)
                        print("DELETE API SUCCESS:", employee.id)

                default:
                    continue
                }

                repo.markSynced(employee.id)

                print("Synced: \(employee.id)")

            } catch {
                print("Sync failed for \(employee.id): \(error)")
            }
        }
    }
}
 
