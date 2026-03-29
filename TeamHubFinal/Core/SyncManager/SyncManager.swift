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
}

final class SyncManager: SyncManaging {

    private let repo: EmployeeRepositoryProtocol
    private var network: NetworkMonitoring

    private var isSyncing = false

    init(repo: EmployeeRepositoryProtocol,
         network: NetworkMonitoring) {
        self.repo = repo
        self.network = network
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
        guard network.isConnected else {
            print("No internet. Skipping sync")
            return
        }

        guard !isSyncing else {
            print("Already syncing")
            return
        }

        isSyncing = true

        print("Sync started")

        await pushLocalChanges()

        isSyncing = false

        print("Sync finished")
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
                    try await repo.syncDelete(employee.id)

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
