//
//  APIBuilder.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 29/03/26.
//

import Foundation


enum APIEndpoint {

    case employees(limit: Int, offset: Int)
    case search(limit: Int, offset: Int, query: String)
    case filters

    case createEmployee(Employee)
    case updateEmployee(id: String, employee: Employee)
    case deleteEmployee(id: String)
    case updateEmployeeDTO(id: String, dto: EmployeeDTO)
    case filteredEmployees(
        limit: Int,
        offset: Int,
        search: String?,
        designations: [String],
        departments: [String],
        statuses: [String]
    )
    case sync(seq: Int)
    private var base: String {
        "https://employee-static-api.onrender.com/api"
    }

    // MARK: - URL

    var url: URL? {
        switch self {

        case let .employees(limit, offset):
            return URL(string: "\(base)/employees?limit=\(limit)&offset=\(offset)")

        case let .search(limit, offset, query):
            var components = URLComponents(string: "\(base)/employees")
            components?.queryItems = [
                .init(name: "limit", value: "\(limit)"),
                .init(name: "offset", value: "\(offset)"),
                .init(name: "search", value: query)
            ]
            return components?.url

        case .filters:
            return URL(string: "\(base)/employees/filters")

        case .createEmployee:
            return URL(string: "\(base)/employees")

        case .updateEmployee(let id, _):
            return URL(string: "\(base)/employees/\(id)")

        case .deleteEmployee(let id):
            return URL(string: "\(base)/employees/\(id)")
            
        case .updateEmployeeDTO(let id, _):
            return URL(string: "\(base)/employees/\(id)")
        case .sync:
            return URL(string: "\(base)/sync")
            
        case let .filteredEmployees(limit, offset, search, designations, departments, statuses):

            var components = URLComponents(string: "\(base)/employees")

            var queryItems: [URLQueryItem] = [
                .init(name: "limit", value: "\(limit)"),
                .init(name: "offset", value: "\(offset)")
            ]

            if let search, !search.isEmpty {
                    queryItems.append(.init(name: "search", value: search))
                }
            
            if !designations.isEmpty {
                queryItems.append(.init(name: "designation",
                                        value: designations.joined(separator: ",")))
            }
            

            if !departments.isEmpty {
                queryItems.append(.init(name: "department",
                                        value: departments.joined(separator: ",")))
            }

            if !statuses.isEmpty {
                queryItems.append(.init(name: "status",
                                        value: statuses.joined(separator: ",")))
            }
       
            components?.queryItems = queryItems
            return components?.url
        }
    }

    // MARK: - METHOD

    var method: String {
        switch self {
        case .createEmployee:
            return "POST"
        case .updateEmployee:
            return "PATCH"
        case .deleteEmployee:
            return "DELETE"
        case .updateEmployeeDTO:
            return "PATCH"
        case .sync:
                return "POST"
        default:
            return "GET"
        }
    }

    // MARK: - HEADERS

    var headers: [String: String] {
        switch self {
        case .createEmployee, .updateEmployee, .updateEmployeeDTO, .sync:
            return ["Content-Type": "application/json"]
        default:
            return [:]
        }
    }

    // MARK: - BODY

    var body: Data? {
        switch self {

        case .createEmployee(let employee):
            return try? JSONEncoder().encode(employee.toDTO())

        case .updateEmployee(_, let employee):
            return try? JSONEncoder().encode(employee.toDTO())
        case .updateEmployeeDTO(_, let dto):
            return try? JSONEncoder().encode(dto)
        case .sync(let seq):
               let body: [String: Any] = [
                   "cursor": [
                       "seq": seq
                   ]
               ]
               return try? JSONSerialization.data(withJSONObject: body)
            
        default:
            return nil
        }
    }
}
extension Employee {

    func toDTO() -> EmployeeDTO {
        
        let formatter = ISO8601DateFormatter()

        return EmployeeDTO(
            id: id,
            name: name,
            designation: designation,
            department: department,
            isActive: isActive,
            imgUrl: imgUrl,
            email: email,
            city: city,
            joiningDate: joiningDate,
            country: country,

            // ONLY send when deleting
            deletedAt: deletedAt != nil ? formatter.string(from: deletedAt!) : nil,

            //  NEVER send createdAt
            createdAt: createdAt != nil ? formatter.string(from: createdAt!) : nil,

            version: nil,
            mobiles: phones.map {
                PhoneDTO(
                    id: $0.id,
                    type: $0.type,
                    number: $0.number
                )
            }
        )
    }
}
