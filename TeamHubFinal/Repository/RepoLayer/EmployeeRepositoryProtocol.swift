//
//  EmployeeRepositoryProtocol.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 24/03/26.
//

import Foundation
protocol EmployeeRepositoryProtocol {
    
    func fetch(limit: Int, offset: Int) async throws -> (employees: [Employee], hasNext: Bool)
    
    func fetchFromDB(limit: Int, offset: Int) -> [Employee]
    
    func search(query: String) async throws -> [Employee]
    
    func updateEmployee(_ employee: Employee)
    
    func addEmployee(_ employee: Employee)
    
    func deleteEmployee(_ id: String)
    
    func fetchFilters() async throws -> Filters
        func fetchFiltersFromDB() -> Filters

        func fetchFilteredFromDB(
            designations: [String],
            departments: [String],
            statuses: [String]
        ) -> [Employee]
    
    func fetchFilteredFromAPI(
        designations: [String],
        departments: [String],
        statuses: [String],
        limit: Int,
        offset: Int
    ) async throws -> (employees: [Employee], hasNext: Bool)
    
    func searchLocal(query: String) -> [Employee]
    
    // Sync
    func fetchPendingSync() -> [Employee]
    func markSynced(_ id: String)

    func syncCreate(_ employee: Employee) async throws
    func syncUpdate(_ employee: Employee) async throws
    func syncDelete(_ id: String) async throws
    
    func getSyncAction(for id: String) -> String
}


final class EmployeeRepository: EmployeeRepositoryProtocol {
    
    private let remote: EmployeeRemoteDataSourceProtocol
    private let local: EmployeeLocalDataSourceProtocol
    
    init(remote: EmployeeRemoteDataSourceProtocol,
         local: EmployeeLocalDataSourceProtocol) {
        self.remote = remote
        self.local = local
    }
    
    func fetch(limit: Int, offset: Int) async throws -> (employees: [Employee], hasNext: Bool) {
        let res = try await remote.fetch(limit: limit, offset: offset)
        let domain = res.employees.map { $0.toDomain() }
        
        local.save(domain)
        
        return (domain, res.hasNext)
    }
    
    func fetchFromDB(limit: Int, offset: Int) -> [Employee] {
        local.fetch(limit: limit, offset: offset)
    }
    
    func search(query: String) async throws -> [Employee] {
        let res = try await remote.search(limit: 20, offset: 0, query: query)
        return res.map { $0.toDomain() }
    }
    
    func updateEmployee(_ employee: Employee) {
        local.update(employee)
    }
    
    func searchLocal(query: String) -> [Employee] {
        local.search(query: query)
    }
    func fetchFilters() async throws -> Filters {
            let dto = try await remote.fetchFilters()
            return dto.toDomain()
        }

        func fetchFiltersFromDB() -> Filters {
            local.fetchFiltersFromDB()
        }

        func fetchFilteredFromDB(
            designations: [String],
            departments: [String],
            statuses: [String]
        ) -> [Employee] {
            local.fetchFiltered(
                designations: designations,
                departments: departments,
                statuses: statuses
            )
        }
    func fetchFilteredFromAPI(
        designations: [String],
        departments: [String],
        statuses: [String],
        limit: Int,
        offset: Int
    ) async throws -> (employees: [Employee], hasNext: Bool) {

        let res = try await remote.fetchFilteredEmployees(
            limit: limit,
            offset: offset,
            designations: designations,
            departments: departments,
            statuses: statuses
        )

        let domain = res.employees.map { $0.toDomain() }

        // 🔥 IMPORTANT: DO NOT SAVE FILTERED DATA TO DB
        // (your requirement: no DB pollution)

        return (domain, res.hasNext)
    }
    
    func addEmployee(_ employee: Employee) {
        local.add(employee)
    }

    func deleteEmployee(_ id: String) {
        local.delete(id)
    }
    
    func fetchPendingSync() -> [Employee] {
        local.fetchPendingSync()
    }

    func markSynced(_ id: String) {
        local.markSynced(id)
    }

    // MARK: - API Sync

    func syncCreate(_ employee: Employee) async throws {
        try await remote.createEmployee(employee)
    }

    func syncUpdate(_ employee: Employee) async throws {
        try await remote.updateEmployee(employee)
    }

    func syncDelete(_ id: String) async throws {
        try await remote.deleteEmployee(id)
    }
    
    func getSyncAction(for id: String) -> String {
        local.getSyncAction(for: id)
    }
}
