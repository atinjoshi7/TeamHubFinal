//////
//////  EmployeeRepositoryProtocol.swift
//////  TeamHubFinal
//////
//////  Created by Atin Joshi on 24/03/26.
//////
////

import Foundation
import Combine
import CoreData
protocol EmployeeRepositoryProtocol {

    // MARK: List
    func loadInitial() async -> [Employee]
    func loadMore() async -> [Employee]
    func refresh() async -> [Employee]

    // MARK: Search + Filter
    func search(
        query: String?,
        designations: [String],
        departments: [String],
        statuses: [String]
    ) async -> [Employee]

    // MARK: CRUD
    func addEmployee(_ employee: Employee)
    func updateEmployee(_ employee: Employee)
    func deleteEmployee(_ id: String)

    // MARK: Filters
    func fetchFilters() async -> Filters
    func fetchFiltersFromDB() -> Filters

    // MARK: Sync
    func syncFromServer() async

       func fetchPendingSync() -> [Employee]
       func markSynced(_ id: String)
   
       func syncCreate(_ employee: Employee) async throws
       func syncUpdate(_ employee: Employee) async throws
       func syncDelete(_ id: String) async throws
   
       func getSyncAction(for id: String) -> String
      func fetchFromLocal(limit: Int) -> [Employee]
    func observeEmployees(limit: Int) -> AnyPublisher<[Employee], Never>
}

final class EmployeeRepository: EmployeeRepositoryProtocol {

    private let remote: EmployeeRemoteDataSourceProtocol
    private let local: EmployeeLocalDataSourceProtocol
    private let network: NetworkMonitoring

    private var offset = 0
    private let limit = 20
    private var hasNext = true

    init(remote: EmployeeRemoteDataSourceProtocol,
         local: EmployeeLocalDataSourceProtocol,
         network: NetworkMonitor) {
        self.remote = remote
        self.local = local
        self.network = network
    }

    // MARK: - INITIAL

    func loadInitial() async -> [Employee] {

        offset = 0
        hasNext = true

        let db = local.fetch(limit: limit, offset: offset)

        if !db.isEmpty {
            return db.filter { $0.deletedAt == nil }
        }

        return await loadMore()
    }

    // MARK: - PAGINATION

    func loadMore() async -> [Employee] {

        guard hasNext else {
            return local.fetch(limit: offset, offset: 0)
                .filter { $0.deletedAt == nil }
        }

        if network.isConnected {
            do {
                let res = try await remote.fetch(limit: limit, offset: offset)

                let domain = res.data.map { $0.toDomain() }

                local.save(domain)

                offset += limit
                hasNext = res.meta.hasNextPage

            } catch {
                print("❌ API fail, fallback DB")
            }
        }

        return local.fetch(limit: offset, offset: 0)
            .filter { $0.deletedAt == nil }
    }
    
    
    func fetchFromLocal(limit: Int) -> [Employee] {
        local.fetch(limit: limit, offset: 0)
    }

    // Observe Employee
    func observeEmployees(limit: Int) -> AnyPublisher<[Employee], Never> {
        local.observeEmployees(limit: limit)
    }
    
    
    // MARK: - REFRESH

    func refresh() async -> [Employee] {

        offset = 0
        hasNext = true

        guard network.isConnected else {
            return local.fetch(limit: limit, offset: 0)
        }

        do {
            let res = try await remote.fetch(limit: limit, offset: offset)

            let domain = res.data.map { $0.toDomain() }

            local.clearAll()
            local.save(domain)
            offset = limit
            hasNext = res.meta.hasNextPage

            return domain

        } catch {
            return local.fetch(limit: limit, offset: 0)
        }
    }

    // MARK: - SEARCH + FILTER (UNIFIED)

    func search(
        query: String?,
        designations: [String],
        departments: [String],
        statuses: [String]
    ) async -> [Employee] {

        if network.isConnected {
            do {
                let res = try await remote.fetchFilteredEmployees(
                    limit: 50,
                    offset: 0,
                    search: query,
                    designations: designations,
                    departments: departments,
                    statuses: statuses
                )

                return res.data
                    .map { $0.toDomain() }
                    .filter { $0.deletedAt == nil }

            } catch {
                print("❌ API search fail → fallback DB")
            }
        }

        return local.fetchFiltered(
            search: query,
            designations: designations,
            departments: departments,
            statuses: statuses
        )
    }

    // MARK: - CRUD

    func addEmployee(_ employee: Employee) {
        local.add(employee)
    }

    func updateEmployee(_ employee: Employee) {
        local.update(employee)
    }

    func deleteEmployee(_ id: String) {
        local.delete(id)
    }

    // MARK: - FILTERS

    func fetchFilters() async -> Filters {
        (try? await remote.fetchFilters().toDomain()) ?? local.fetchFiltersFromDB()
    }

    func fetchFiltersFromDB() -> Filters {
        local.fetchFiltersFromDB()
    }

    // MARK: - SYNC

    func syncFromServer() async {

        let lastSeq = UserDefaults.standard.integer(forKey: "sync_seq")

        do {
            let res = try await remote.sync(seq: lastSeq)

            let employees = res.data.employees.map { $0.toDomain() }

            for emp in employees {

                if emp.deletedAt != nil {
                    local.softDelete(emp.id, date: emp.deletedAt)
                } else {
                    local.updateFromServer(emp)
                }
            }

            UserDefaults.standard.set(res.data.nextCursor.seq, forKey: "sync_seq")

            NotificationCenter.default.post(name: .didSyncData, object: nil)

        } catch {
            print("❌ Sync failed:", error)
        }
    }
    
    func fetchPendingSync() -> [Employee] {
        local.fetchPendingSync()
    }

    func markSynced(_ id: String) {
        local.markSynced(id)
    }

    func getSyncAction(for id: String) -> String {
        local.getSyncAction(for: id)
    }

    func syncCreate(_ employee: Employee) async throws {
        try await remote.createEmployee(employee)

    }

    func syncUpdate(_ employee: Employee) async throws {
        try await remote.updateEmployee(employee)
    }

    func syncDelete(_ id: String) async throws {
        try await remote.deleteEmployee(id)
    }

}
