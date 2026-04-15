//
//  AddEmployeeView.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 25/03/26.
//

import SwiftUI

struct AddEmployeeView: View {

    @Environment(\.dismiss) private var dismiss

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

    private var hasChanges: Bool{
        if name != "" && email != "" && city != "" &&  country != "" {
            return true
        }else{
            return false
        }
    }
    var body: some View {
        NavigationStack {
            Form {

                // MARK: - Basic Info
                Section("Basic Info") {

                    // Name
                    VStack(alignment: .leading) {
                        TextField("Name", text: $name)
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
                        TextField("Email", text: $email)
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
                        TextField("City", text: $city)
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
                        TextField("Country", text: $country)
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
                    Picker("Department", selection: $selectedDepartment) {
                        Text("Select Department").tag("")
                        ForEach(departments.sorted(), id: \.self) { dept in
                            Text(dept).tag(dept)
                        }
                    }
                    .pickerStyle(.menu)

                    // Designation Picker
                    Picker("Designation", selection: $selectedDesignation) {
                        Text("Select Designation").tag("")
                        ForEach(designations.sorted(), id: \.self) { des in
                            Text(des).tag(des)
                        }
                    }
                    .pickerStyle(.menu)

                    Toggle("Active", isOn: $isActive)
                }

                // MARK: - Joining Date
                Section("Joining Date") {
                    DatePicker(
                        "Select Joining Date",
                        selection: $joiningDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                }

                // MARK: - Phones
                Section("Phones") {
                    ForEach($phones) { $phone in
                        VStack(alignment: .leading) {

                            Picker("Type", selection: $phone.type) {
                                ForEach(phoneTypes, id: \.self) {
                                    Text($0.capitalized)
                                }
                            }
                            .pickerStyle(.menu)

                            TextField("Number", text: $phone.number)
                                .keyboardType(.numberPad)
                                .onChange(of: phone.number) { _, newValue in
                                    validatePhone(phone.id, value: newValue)
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
                    .disabled(!hasChanges)
                }
            }
        }
    }

    // MARK: - Validation Functions

    private func validateName() {
        if name.isEmpty {
            nameError = nil
        } else {
            nameError = EmployeeFormValidator.validateName(name)
        }
    }

    private func validateEmail() {
        if email.isEmpty {
            emailError = nil
        } else {
            emailError = EmployeeFormValidator.validateEmail(email)
        }
    }

    private func validateCity() {
        if city.isEmpty {
            cityError = nil
        } else {
            cityError = EmployeeFormValidator.validateLocation(city)
        }
    }

    private func validateCountry() {
        if country.isEmpty {
            countryError = nil
        } else {
            countryError = EmployeeFormValidator.validateLocation(country)
        }
    }

    private func validatePhone(_ id: String, value: String) {
        if value.isEmpty {
            phoneErrors[id] = nil
        } else {
            phoneErrors[id] = EmployeeFormValidator.validatePhone(value)
        }
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

        guard isValid else { return }

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
}
