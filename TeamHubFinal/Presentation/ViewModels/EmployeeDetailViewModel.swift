//
//  EmployeeDetailViewModel.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 25/03/26.
//

import Foundation
import Combine
final class EmployeeDetailViewModel: ObservableObject {

    @Published private(set) var employee: Employee
    var departments: [String]
    var designations: [String]
    init(employee: Employee,designations:[String],departments:[String]) {
        self.employee = employee
        self.departments = departments
        self.designations = designations
    }

    // MARK: - Display Helpers
    var avatarURL: URL? {
        ImageURLHelper.validURL(from: employee.imgUrl)
    }

    var avatarInitials: String {
        let words = employee.name
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            
        switch words.count {
        case 0: return "?"
        case 1: return String(words[0].prefix(1)).uppercased()  // "Neymar" → "N"
        default: return (String(words[0].prefix(1)) + String(words[1].prefix(1))).uppercased() // "Neymar Jr" → "NJ"
        }
    }
    var name: String { employee.name }
    var email: String { employee.email }
    var cityCountry: String { "\(employee.city), \(employee.country)" }
    var designation: String { employee.designation }
    var department: String { employee.department }
    var isActiveText: String { employee.isActive ? "Active" : "Inactive" }
    var joiningDate: String { employee.joiningDate ?? ""}
    var phones: [Phone] {
        employee.phones
    }
    func setEmployee(_ employee: Employee) {
        self.employee = employee
    }
}
