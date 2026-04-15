//
//  SyncManager.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 27/03/26.
//

import Foundation
import Combine
protocol SyncManaging {
    func start()
    func syncNow() async
    func startAutoSync() async
    func stopAutoSync()
    func syncFromServer() async
    var syncRunning: Bool { get }
    func pushLocalChanges() async
}

final class SyncManager: SyncManaging {

    private let repo: EmployeeRepositoryProtocol
    private var network: NetworkMonitoring
    private let syncErrorStore: SyncErrorStore
    private var isSyncing = false
    private var syncTimer: Timer?
    private(set) var syncRunning = false
    private var hasStartedObserving = false
    
    init(repo: EmployeeRepositoryProtocol,
         network: NetworkMonitoring,
         syncErrorStore: SyncErrorStore) {
        self.repo = repo
        self.network = network
        self.syncErrorStore = syncErrorStore
    }

    // Start observing network
    func start() {
        guard !hasStartedObserving else { return }
        hasStartedObserving = true

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
        await runSyncCycle(pushPendingLocals: true, syncFromServer: true)
    }
    
    
    func startAutoSync() async {
        start()
        stopAutoSync() // prevent duplicates
        syncRunning = true

        syncTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            
            Task {
                await self?.syncNow()
            }
        }
    }
    
    func stopAutoSync() {
        syncTimer?.invalidate()
        syncTimer = nil
        syncRunning = false
    }
    
    func syncFromServer() async {
        await runSyncCycle(pushPendingLocals: false, syncFromServer: true)
    }
}
extension SyncManager {

     func pushLocalChanges() async {
        await runSyncCycle(pushPendingLocals: true, syncFromServer: true)
    }

    private func runSyncCycle(pushPendingLocals: Bool, syncFromServer shouldSyncFromServer: Bool) async {
        guard network.isConnected else { return }
        guard !isSyncing else { return }

        isSyncing = true
        defer { isSyncing = false }

        if pushPendingLocals {
            await pushPendingLocalChanges()
        }

        guard shouldSyncFromServer else { return }
        await repo.syncFromServer()
    }

    private func pushPendingLocalChanges() async {
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
                syncErrorStore.clearError(for: employee.id)

                print("Synced: \(employee.id)")

            } catch let error as NetworkError {
                let message = "Sync failed: \(error.message)"
                syncErrorStore.setError(message, for: employee.id)
                print("Cannot sync \(employee.name):", message)
            } catch {
                let message = "Sync failed: \(error.localizedDescription)"
                syncErrorStore.setError(message, for: employee.id)
                print("Sync failed for \(employee.id): \(message)")
            }
        }
    }
}
 
