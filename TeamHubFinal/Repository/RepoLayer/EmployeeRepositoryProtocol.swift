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
    func searchNFilter(
        query: String?,
        designations: [String],
        departments: [String],
        statuses: [String],
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

    
    func loadUntilFilled(targetCount: Int) async -> [Employee]
    func fetchFromDB(limit: Int) -> [Employee]
//    func observeEmployees(limit:Int) -> AnyPublisher<[Employee], Never>
}

final class EmployeeRepository: EmployeeRepositoryProtocol {

    private let remote: EmployeeRemoteDataSourceProtocol
    private let local: EmployeeLocalDataSourceProtocol
    private let network: NetworkMonitoring

    
    private var apiOffset: Int = UserDefaults.standard.integer(forKey: "api_offset")
    private var dbOffset = 0
    private let limit = 20
    private var hasNext = true
    private var searchOffset = 0

    init(remote: EmployeeRemoteDataSourceProtocol,
         local: EmployeeLocalDataSourceProtocol,
         network: NetworkMonitor) {
        self.remote = remote
        self.local = local
        self.network = network
    }
    
    
    func fetchFromDB(limit: Int) -> [Employee] {
        return local.fetchNonDeleted(limit: limit, offset: 0)
    }
    
    // MARK: - INITIAL
    func loadInitial() async -> [Employee] {

        apiOffset = 0
        dbOffset = 0
        hasNext = true
        UserDefaults.standard.set(apiOffset, forKey: "api_offset")

        let dbData = local.fetchNonDeleted(limit: limit, offset: 0)

        if !dbData.isEmpty {
           
            let initial = Array(dbData.prefix(limit))
            dbOffset = initial.count
            return initial
        }

        return await loadMore()
    }
    // MARK: - PAGINATION
    func loadMore() async -> [Employee] {

        print("📊 dbOffset:", dbOffset, "apiOffset:", apiOffset)

        // ✅ STEP 1: Try DB first
        let dbData = local.fetchNonDeleted(limit: limit, offset: dbOffset)

        if !dbData.isEmpty {
            dbOffset += dbData.count
            return dbData
        }

        // ✅ STEP 2: DB exhausted → call API
        guard hasNext else {
            return []
        }

        if network.isConnected {
            do {
                print("API CALL → offset:", apiOffset)

                let res = try await remote.fetch(limit: limit, offset: apiOffset)

                let domain = res.data.map { $0.toDomain() }
                local.save(domain)

                apiOffset += res.data.count
                hasNext = res.meta.hasNextPage
                UserDefaults.standard.set(apiOffset, forKey: "api_offset")

            } catch {
                print("❌ API fail:", error.localizedDescription)
            }
        }

        // 🔥 After API → fetch again from DB
        var newData = local.fetchNonDeleted(limit: limit, offset: dbOffset)
        
        if newData.isEmpty {
            newData = await self.loadMore()
        }

        dbOffset += newData.count

        return newData
    }
    
    
    func fetchFromLocal(limit: Int) -> [Employee] {
        local.fetch(limit: limit, offset: 0)
    }
    
    // MARK: - REFRESH
    func refresh() async -> [Employee] {

        print("🔄 REFRESH START")

        // ✅ RESET BOTH OFFSETS
        apiOffset = 0
        dbOffset = 0
        hasNext = true

        // ✅ DO NOT clear DB
        // We will just overwrite via API

        let data = await loadUntilFilled(targetCount: limit)
        dbOffset = data.count // changed now.
        print("✅ REFRESH DONE:", data.count)

        return data
    }

    // MARK: - SEARCH + FILTER (UNIFIED)

    func searchNFilter(
        query: String?,
        designations: [String],
        departments: [String],
        statuses: [String]
    ) async -> [Employee] {

        if network.isConnected {
            do {
                let res = try await remote.fetchSearchNFilteredEmployees(
                    limit: 1000,
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

            if lastSeq == 0 {
                // 🔥 First launch: DB already populated via paginated API.
                // Just save the cursor — do NOT apply changes to avoid
                // re-inserting everything and triggering observer flood.
                print("⚠️ Bootstrap sync — skipping apply, saving seq only")
            } else if !employees.isEmpty {
                // ✅ Incremental sync — batch update in a single CoreData save
                defer { SyncNotifier.shared.notify() }
                local.batchUpdateFromServer(employees)
                print(employees)
                print("✅ Sync applied \(employees.count) changes")
                
            } else {
                print("✅ Sync — nothing new (seq: \(lastSeq))")
            }

            // Always advance the cursor
            UserDefaults.standard.set(res.data.nextCursor.seq, forKey: "sync_seq")

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

    func loadUntilFilled(targetCount: Int) async -> [Employee] {

        dbOffset = 0
        var visible = local.fetchNonDeleted(limit: limit, offset: dbOffset)
        
        if visible.isEmpty {
            apiOffset = 0
            UserDefaults.standard.set(apiOffset, forKey: "api_offset")
        }
        while visible.count < targetCount && hasNext {

            if network.isConnected {
                do {
                    let res = try await remote.fetch(limit: limit, offset: apiOffset)

                    let domain = res.data.map { $0.toDomain() }
                    local.save(domain)

                    if apiOffset == 0 {
                        UserDefaults.standard.set(res.meta.latestUpdatedSeq, forKey: "sync_seq")
                    }
                    apiOffset += res.data.count
                    hasNext = res.meta.hasNextPage
                    UserDefaults.standard.set(apiOffset, forKey: "api_offset")

                } catch {
//                    break
                }
            } else {
//                break
            }

            visible = local.fetchNonDeleted(limit: limit, offset: 0)
        }

        let result = Array(visible.prefix(targetCount))
        dbOffset = result.count   // only advance by what we actually show

        return result
    }
}
