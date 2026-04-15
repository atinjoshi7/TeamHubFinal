//
//  AddEmployeeView.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 25/03/26.
//

import SwiftUI

struct AddEmployeeView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var homeVM: HomeViewModel

    let departments: [String]
    let designations: [String]
    var onSave: (Employee) -> Void

    // MARK: - State
    @State private var joiningDate: Date = Date()
    @State private var name = ""
    @State private var email = ""
    @State private var city = ""
    @State private var country = ""
    @State private var isActive = true

    @State private var phones: [EditablePhone] = []
    @State private var selectedDepartment: String = ""
    @State private var selectedDesignation: String = ""

    private let phoneTypes = ["home", "office", "other"]

    // MARK: - Errors
    @State private var nameError: String?
    @State private var emailError: String?
    @State private var cityError: String?
    @State private var countryError: String?
    @State private var phoneErrors: [String: String] = [:]

    private var isFormValid: Bool {
        let baseValid = EmployeeFormValidator.validateForm(
            name: name,
            email: email,
            city: city,
            country: country,
            department: selectedDepartment,
            designation: selectedDesignation,
            phones: phones
        )

        guard baseValid else { return false }
        guard !isDuplicateEmail else { return false }

        return phones.allSatisfy { phone in
            !isDuplicateHomeNumber(for: phone)
        }
    }

    private var isDuplicateEmail: Bool {
        guard EmployeeFormValidator.validateEmail(email) == nil else { return false }
        return homeVM.emailExists(email)
    }
    var body: some View {
        NavigationStack {
            Form {

                // MARK: - Basic Info
                Section("Basic Info") {

                    // Name
                    VStack(alignment: .leading) {
                        requiredLabel("Name")
                        TextField("Enter name", text: $name)
                            .onChange(of: name) { _, _ in
                                validateName()
                            }

                        if let error = nameError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }

                    // Email
                    VStack(alignment: .leading) {
                        requiredLabel("Email")
                        TextField("Enter email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .onChange(of: email) { _,_ in
                                validateEmail()
                            }

                        if let error = emailError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }

                    // City
                    VStack(alignment: .leading) {
                        requiredLabel("City")
                        TextField("Enter city", text: $city)
                            .onChange(of: city) { _,_ in
                                validateCity()
                            }

                        if let error = cityError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }

                    // Country
                    VStack(alignment: .leading) {
                        requiredLabel("Country")
                        TextField("Enter country", text: $country)
                            .onChange(of: country) { _,_ in
                                validateCountry()
                            }

                        if let error = countryError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }

                    // Department Picker
                    Picker(selection: $selectedDepartment) {
                        Text("Select Department").tag("")
                        ForEach(departments.sorted(), id: \.self) { dept in
                            Text(dept).tag(dept)
                        }
                    } label: {
                        requiredLabel("Department")
                    }
                    .pickerStyle(.menu)

                    // Designation Picker
                    Picker(selection: $selectedDesignation) {
                        Text("Select Designation").tag("")
                        ForEach(designations.sorted(), id: \.self) { des in
                            Text(des).tag(des)
                        }
                    } label: {
                        requiredLabel("Designation")
                    }
                    .pickerStyle(.menu)

                    Toggle("Active", isOn: $isActive)
                }

                // MARK: - Joining Date
                Section("Joining Date") {
                    DatePicker(
                        selection: $joiningDate,
                        in: ...Date(),
                        displayedComponents: .date
                    ) {
                        requiredLabel("Select Joining Date")
                    }
                }

                // MARK: - Phones
                Section("Phones") {
                    ForEach($phones) { $phone in
                        VStack(alignment: .leading) {

                            Picker(selection: $phone.type) {
                                ForEach(phoneTypes, id: \.self) {
                                    Text($0.capitalized)
                                }
                            } label: {
                                requiredLabel("Phone Type")
                            }
                            .pickerStyle(.menu)
                            .onChange(of: phone.type) { _, _ in
                                validatePhone(phone.id)
                            }

                            requiredLabel("Phone Number")
                            TextField("Enter phone number", text: $phone.number)
                                .keyboardType(.numberPad)
                                .onChange(of: phone.number) { _, _ in
                                    validatePhone(phone.id)
                                }

                            if let error = phoneErrors[phone.id] {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }

                            Button("Delete", role: .destructive) {
                                removePhone(phone.id)
                            }
                        }
                    }

                    if phones.count < 3 {
                        Button("Add Phone") {
                            addPhone()
                        }
                    }
                }
            }
            .navigationTitle("Add Employee")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        save()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }

    // MARK: - Validation Functions

    private func validateName() {
        nameError = EmployeeFormValidator.validateName(name)
    }

    private func validateEmail() {
        if let error = EmployeeFormValidator.validateEmail(email) {
            emailError = error
            return
        }

        emailError = isDuplicateEmail ? "Already exists" : nil
    }

    private func validateCity() {
        cityError = EmployeeFormValidator.validateLocation(city)
    }

    private func validateCountry() {
        countryError = EmployeeFormValidator.validateLocation(country)
    }

    private func validatePhone(_ id: String) {
        guard let phone = phones.first(where: { $0.id == id }) else { return }

        if let error = EmployeeFormValidator.validatePhone(phone.number) {
            phoneErrors[id] = error
            return
        }

        phoneErrors[id] = isDuplicateHomeNumber(for: phone) ? "Already exists" : nil
    }

    // MARK: - Actions

    private func addPhone() {
        phones.append(
            EditablePhone(id: UUID().uuidString, type: "home", number: "")
        )
    }

    private func removePhone(_ id: String) {
        phones.removeAll { $0.id == id }
    }

    private func save() {

        let isValid = EmployeeFormValidator.validateForm(
            name: name,
            email: email,
            city: city,
            country: country,
            department: selectedDepartment,
            designation: selectedDesignation,
            phones: phones
        )

        validateName()
        validateEmail()
        validateCity()
        validateCountry()
        phones.forEach { validatePhone($0.id) }

        guard isValid, !isDuplicateEmail else { return }
        guard phones.allSatisfy({ !isDuplicateHomeNumber(for: $0) }) else { return }

        let employee = Employee(
            id: UUID().uuidString.lowercased(),
            name: name,
            designation: selectedDesignation,
            department: selectedDepartment,
            isActive: isActive,
            imgUrl: nil,
            email: email,
            city: city,
            joiningDate: DateUtils.toYYYYMMDD(joiningDate),
            country: country,
            phones: phones.map { $0.toDomain() },
            createdAt: Date(),
            deletedAt: nil
        )

        onSave(employee)
        dismiss()
    }

    private func requiredLabel(_ title: String) -> some View {
        HStack(spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("*")
                .font(.caption)
                .foregroundColor(.red)
        }
    }

    private func isDuplicateHomeNumber(for phone: EditablePhone) -> Bool {
        guard phone.type.caseInsensitiveCompare("home") == .orderedSame else { return false }
        guard EmployeeFormValidator.validatePhone(phone.number) == nil else { return false }
        return homeVM.homePhoneExists(phone.number)
    }
}
