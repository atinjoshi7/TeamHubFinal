//
//  EmployeeRemoteDataSource.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 24/03/26.
//

import Foundation
protocol EmployeeRemoteDataSourceProtocol {
    
    func fetch(limit: Int, offset: Int) async throws -> EmployeesResponseDTO
    
    func search(limit: Int, offset: Int, query: String) async throws -> [EmployeeDTO]
    
    func fetchFilters() async throws -> FiltersResponseDTO
    
    func fetchSearchNFilteredEmployees(
        limit: Int,
        offset: Int,
        search:String?,
        designations: [String],
        departments: [String],
        statuses: [String]
    ) async throws -> EmployeesResponseDTO
    
    func createEmployee(_ employee: Employee) async throws
    func updateEmployee(_ employee: Employee) async throws
    func deleteEmployee(_ id: String) async throws
    func updateEmployeeDTO(_ dto: EmployeeDTO) async throws
    func sync(seq: Int) async throws -> SyncResponseDTO
}

final class EmployeeRemoteDataSource: EmployeeRemoteDataSourceProtocol {
    
    private let api: APIClient
    
    init(api: APIClient) {
        self.api = api
    }
    
    func fetch(limit: Int, offset: Int) async throws -> EmployeesResponseDTO {
        let res: EmployeesResponseDTO = try await api.request(.employees(limit: limit, offset: offset))
        return res
    }
    
    func search(limit: Int, offset: Int, query: String) async throws -> [EmployeeDTO] {
        let res: EmployeesResponseDTO = try await api.request(.search(limit: limit, offset: offset, query: query))
        
        return res.data
    }
    
    // NEW
    func fetchFilters() async throws -> FiltersResponseDTO {
        try await api.request(.filters)
    }
    
    func fetchSearchNFilteredEmployees(
        limit: Int,
        offset: Int,
        search: String?,
        designations: [String],
        departments: [String],
        statuses: [String]
    ) async throws -> EmployeesResponseDTO {
        
        let res: EmployeesResponseDTO = try await api.request(
            .filteredEmployees(
                limit: limit,
                offset: offset,
                search: search,
                designations: designations,
                departments: departments,
                statuses: statuses
            )
        )
        
        return res
    }
    func createEmployee(_ employee: Employee) async throws {
        
        print(" API CREATE: \(employee.id)")
        
        // Placeholder (since API not ready)
        let _: EmptyResponse = try await api.request(
            .createEmployee(employee)
        )
    }
    func updateEmployee(_ employee: Employee) async throws {
        
        print("API UPDATE: \(employee.id)")
        
        let _: EmptyResponse = try await api.request(
            .updateEmployee(id: employee.id, employee: employee)
        )
    }
    func deleteEmployee(_ id: String) async throws {
        
        print(" API DELETE: \(id)")
        
        let _: EmptyResponse = try await api.request(
            .deleteEmployee(id: id)
        )
    }
    func updateEmployeeDTO(_ dto: EmployeeDTO) async throws {
        
        print("API DELETE (soft): \(dto.id ?? "")")
        
        let _: EmptyResponse = try await api.request(
            .updateEmployeeDTO(id: dto.id ?? "", dto: dto)
        )
    }
    func sync(seq: Int) async throws -> SyncResponseDTO {
        print("Entered in Remote Sync function")
        return try await api.request(.sync(seq: seq))
    }
}
