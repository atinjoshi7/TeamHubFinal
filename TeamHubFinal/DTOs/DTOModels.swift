//
//  DTOModels.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 24/03/26.
//
import Foundation

struct PhoneDTO: Codable {
    let id: String?
    let type: String?
    let number: String?
}

struct EmployeeDTO: Codable {
    let id: String?
    let name: String?
    let designation: String?
    let department: String?
    let isActive: Bool?
    let imgUrl: String?
    let email: String?
    let city: String?
    let joiningDate: String?
    let country: String?
    var deletedAt: String?
    let createdAt: String?
    let version: Int?
    let mobiles: [PhoneDTO]?
}
struct EditablePhone: Identifiable {
    let id: String
    var type: String
    var number: String
    // For existing phones
    init(from phone: Phone) {
        self.id = phone.id
        self.type = phone.type
        self.number = phone.number
    }
    // For new phones (THIS FIXES YOUR ERROR)
       init(id: String, type: String, number: String) {
           self.id = id
           self.type = type
           self.number = number
       }
    func toDomain() -> Phone {
        Phone(id: id, type: type, number: number)
    }
}

struct EmployeesResponseDTO: Decodable {
    let data: [EmployeeDTO]
    let meta: MetaDTO
}

struct MetaDTO: Decodable {
    let hasNextPage: Bool
}

extension EmployeeDTO {
    func toDomain() -> Employee {
        let formatter = ISO8601DateFormatter()
        return Employee(
            id: id ?? UUID().uuidString,
            name: name ?? "Unknown",
            designation: designation ?? "N/A",
            department: department ?? "N/A",
            isActive: isActive ?? false,
            imgUrl: imgUrl,
            email: email ?? "",
            city: city ?? "",
            joiningDate: joiningDate ?? "",
            country: country ?? "",
            phones: mobiles?.compactMap {
                Phone(
                    id: $0.id ?? UUID().uuidString,
                    type: $0.type ?? "other",
                    number: $0.number ?? ""
                )
            } ?? [],
            createdAt: formatter.date(from: createdAt ?? ""),   // ✅
            deletedAt: formatter.date(from: deletedAt ?? "")
        )
    }
}

enum SyncAction: String {
    case create
    case update
    case delete
}

