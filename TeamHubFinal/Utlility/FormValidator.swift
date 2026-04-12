//
//  FormValidator.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 10/04/26.
//

import Foundation

struct EmployeeFormValidator {

    // MARK: - Name
    static func validateName(_ text: String) -> String? {
        if text.isEmpty { return nil }
        let regex = "^[A-Za-z ]{1,}$"
        let valid = NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: text)
        return valid ? nil : "Enter valid name"
    }

    // MARK: - Email
    static func validateEmail(_ text: String) -> String? {

        if text.isEmpty { return nil }

        // Cannot start with number
        if let first = text.first, first.isNumber {
            return "Email cannot start with a number"
        }

        // '@' must be before '.'
        if let atIndex = text.firstIndex(of: "@"),
           let dotIndex = text.lastIndex(of: "."),
           atIndex > dotIndex {
            return "'@' must come before domain"
        }

        let regex = "^[A-Za-z][A-Za-z0-9._%+-]*@[A-Za-z0-9.-]+\\.[A-Za-z]{1,}$"
        let valid = NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: text)

        return valid ? nil : "Invalid email"
    }

    // MARK: - City / Country
    static func validateLocation(_ text: String) -> String? {
        if text.isEmpty { return nil }
        let regex = "^[A-Za-z ]{1,}$"
        let valid = NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: text)
        return valid ? nil : "Invalid value"
    }

    // MARK: - Phone
    static func validatePhone(_ text: String) -> String? {
        if text.isEmpty { return nil }
        let regex = #"^\+?[0-9]{7,15}$"#
        let valid = NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: text)
        return valid ? nil : "Invalid phone (7–15 digits)"
    }

    // MARK: - Full Form Validation
    static func validateForm(
        name: String,
        email: String,
        city: String,
        country: String,
        department: String,
        designation: String,
        phones: [EditablePhone]
    ) -> Bool {

        if validateName(name) != nil { return false }
        if validateEmail(email) != nil { return false }
        if validateLocation(city) != nil { return false }
        if validateLocation(country) != nil { return false }

        if department.isEmpty || designation.isEmpty {
            return false
        }

        for phone in phones {
            if validatePhone(phone.number) != nil {
                return false
            }
        }

        return true
    }
}
