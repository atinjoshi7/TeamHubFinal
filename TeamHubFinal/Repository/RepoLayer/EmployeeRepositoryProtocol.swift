////
////  EmployeeRepositoryProtocol.swift
////  TeamHubFinal
////
////  Created by Atin Joshi on 24/03/26.
////
//
import Foundation
protocol EmployeeRepositoryProtocol {
    
    func fetch(limit: Int, offset: Int) async throws -> (employees: [Employee], hasNext: Bool)
    
    func fetchFromDB(limit: Int, offset: Int) -> [Employee]
    
    func search(query: String, limit: Int, offset:Int) async throws -> [Employee]
    
    func updateEmployee(_ employee: Employee)
    
    func addEmployee(_ employee: Employee)
    
    func deleteEmployee(_ id: String)
    
    func fetchFilters() async throws -> Filters
    
    func fetchFiltersFromDB() -> Filters
    
    func fetchFilteredFromDB(
        search: String?,
        designations: [String],
        departments: [String],
        statuses: [String]
    ) -> [Employee]
    
    func fetchCombined(
        search:String?,
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
    
    func clearAllEmployees()
    
    func save(employees:[Employee])
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
        print("Api is hitting in refresh/dbNotEmpty")
        local.save(domain)
        
        return (domain, res.hasNext)
    }
    
    func fetchFromDB(limit: Int, offset: Int) -> [Employee] {
        local.fetch(limit: limit, offset: offset)
    }
    
    func search(query: String, limit: Int, offset: Int) async throws -> [Employee] {
        let res = try await remote.search(limit: limit, offset: offset, query: query)
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
        search: String?,
        designations: [String],
        departments: [String],
        statuses: [String]
    ) -> [Employee] {
        local.fetchFiltered(
            search: search,
            designations: designations,
            departments: departments,
            statuses: statuses
        )
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
    
    func save(employees:[Employee]){
        local.save(employees)
    }
    
    // MARK: - API Sync
    
    func syncCreate(_ employee: Employee) async throws {
        try await remote.createEmployee(employee)
    }
    
    func syncUpdate(_ employee: Employee) async throws {
        try await remote.updateEmployee(employee)
    }
    
    func clearAllEmployees() {
        local.clearAll()
    }
    
    
//    func syncDelete(_ id: String) async throws {
//        
//        // Get syncAction from DB
//        let action = local.getSyncAction(for: id)
//        
//        guard action == "delete" else {
//            print("Not delete action:", action)
//            return
//        }
//        
//        let employees = local.fetchPendingSync()
//        
//        guard let employee = employees.first(where: { $0.id == id }) else {
//            print("Employee not found for delete")
//            return
//        }
//        
//        var dto = employee.toDTO()
//        dto.deletedAt = ISO8601DateFormatter().string(from: Date())
//        
//        print("DELETE API HIT:", id)
//        
//        try await remote.updateEmployeeDTO(dto)
//    }
    func syncDelete(_ id: String) async throws {

        let action = local.getSyncAction(for: id)

        guard action == "delete" else { return }

        do {
            try await remote.deleteEmployee(id)

            local.markSynced(id)   // ✅ IMPORTANT

            print("✅ Delete synced:", id)

        } catch {
            print("❌ Delete failed:", error)
            throw error
        }
    }
    func getSyncAction(for id: String) -> String {
        local.getSyncAction(for: id)
    }
    
    func fetchCombined(
        search: String?,
        designations: [String],
        departments: [String],
        statuses: [String],
        limit: Int,
        offset: Int
    ) async throws -> (employees: [Employee], hasNext: Bool) {
        
        let res = try await remote.fetchFilteredEmployees(
            limit: limit,
            offset: offset,
            search: search,
            designations: designations,
            departments: departments,
            statuses: statuses
        )
        let domain = res.employees
                .map { $0.toDomain() }
                .filter { $0.deletedAt == nil }   // ADD THIS

        return (domain, res.hasNext)
//        return (res.employees.map { $0.toDomain() }, res.hasNext)
    }
}




