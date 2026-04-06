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

    init(employee: Employee) {
        self.employee = employee
    }

    // MARK: - Display Helpers

    var name: String { employee.name }
    var email: String { employee.email }
    var cityCountry: String { "\(employee.city), \(employee.country)" }
    var designation: String { employee.designation }
    var department: String { employee.department }
    var isActiveText: String { employee.isActive ? "Active" : "Inactive" }
    var joiningDate: String { (employee.joiningDate != nil) ? "" : ""} 
    var phones: [Phone] {
        employee.phones
    }
    func setEmployee(_ employee: Employee) {
        self.employee = employee
    }
}
