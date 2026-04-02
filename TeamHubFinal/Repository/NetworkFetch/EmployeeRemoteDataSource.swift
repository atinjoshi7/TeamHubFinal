//
//  EmployeeRemoteDataSource.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 24/03/26.
//

import Foundation
protocol EmployeeRemoteDataSourceProtocol {
    func fetch(limit: Int, offset: Int) async throws -> (employees: [EmployeeDTO], hasNext: Bool)
    func search(limit: Int, offset: Int, query: String) async throws -> [EmployeeDTO]
    func fetchFilters() async throws -> FiltersResponseDTO
    func fetchFilteredEmployees(
        limit: Int,
        offset: Int,
        search:String?,
        designations: [String],
        departments: [String],
        statuses: [String]
    ) async throws -> (employees: [EmployeeDTO], hasNext: Bool)
    func createEmployee(_ employee: Employee) async throws
    func updateEmployee(_ employee: Employee) async throws
    func deleteEmployee(_ id: String) async throws
    func updateEmployeeDTO(_ dto: EmployeeDTO) async throws
}

final class EmployeeRemoteDataSource: EmployeeRemoteDataSourceProtocol {
    
    private let api: APIClient
    
    init(api: APIClient) {
        self.api = api
    }
    
    func fetch(limit: Int, offset: Int) async throws -> (employees: [EmployeeDTO], hasNext: Bool) {
        let res: EmployeesResponseDTO = try await api.request(.employees(limit: limit, offset: offset))
        return (res.data, res.meta.hasNextPage)
    }
    
    func search(limit: Int, offset: Int, query: String) async throws -> [EmployeeDTO] {
        let res: EmployeesResponseDTO = try await api.request(.search(limit: limit, offset: offset, query: query))
        
        return res.data
    }
    
    // NEW
    func fetchFilters() async throws -> FiltersResponseDTO {
        try await api.request(.filters)
    }
    
    func fetchFilteredEmployees(
        limit: Int,
        offset: Int,
        search: String?,
        designations: [String],
        departments: [String],
        statuses: [String]
    ) async throws -> (employees: [EmployeeDTO], hasNext: Bool) {
        
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
        
        return (
            res.data,
            res.meta.hasNextPage
        )
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
}
