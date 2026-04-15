//
//  EditEmployeeView.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 07/04/26.
//

import SwiftUI


struct EditEmployeeView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var homeVM: HomeViewModel

    var employee: Employee
    var onSave: (Employee) -> Void
    
    @State private var phones: [EditablePhone]

    // MARK: - Fields
    @State private var name: String
    @State private var email: String
    @State private var city: String
    @State private var country: String
    @State private var isActive: Bool
    @State private var joiningDate: String
    @State private var department: String
    @State private var designation: String

    let departments: [String]
    let designations: [String]

    private let phoneTypes = ["home", "office", "other"]

    // MARK: - Errors
    @State private var nameError: String?
    @State private var emailError: String?
    @State private var cityError: String?
    @State private var countryError: String?
    @State private var phoneErrors: [String: String] = [:]

    // MARK: - Change Detection
    private var hasChanges: Bool {

        if name != employee.name { return true }
        if email != employee.email { return true }
        if city != employee.city { return true }
        if country != employee.country { return true }
        if isActive != employee.isActive { return true }
        if department != employee.department { return true }
        if designation != employee.designation { return true }
        if joiningDate != (employee.joiningDate ?? "") { return true }

        let originalPhones = employee.phones.map { $0.id + $0.number + $0.type }
        let currentPhones = phones.map { $0.id + $0.number + $0.type }

        return originalPhones != currentPhones
    }

    private var isFormValid: Bool {
        let baseValid = EmployeeFormValidator.validateForm(
            name: name,
            email: email,
            city: city,
            country: country,
            department: department,
            designation: designation,
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
        return homeVM.emailExists(email, excludingEmployeeID: employee.id)
    }

    // MARK: - Init
    init(employee: Employee,
         departments: [String],
         designations: [String],
         onSave: @escaping (Employee) -> Void) {

        self.employee = employee
        self.onSave = onSave

        _name = State(initialValue: employee.name)
        _email = State(initialValue: employee.email)
        _city = State(initialValue: employee.city)
        _country = State(initialValue: employee.country)
        _isActive = State(initialValue: employee.isActive)
        _phones = State(initialValue: employee.phones.map { EditablePhone(from: $0) })
        _joiningDate = State(initialValue: employee.joiningDate ?? "")
        _department = State(initialValue: employee.department)
        _designation = State(initialValue: employee.designation)

        self.departments = departments
        self.designations = designations
    }

    // MARK: - UI
    var body: some View {
        NavigationStack {
            Form {

                // MARK: - Basic Info
                Section("Basic Information") {

                    field("Name", text: $name, error: nameError) {
                        validateName()
                    }

                    field("Email", text: $email, error: emailError) {
                        validateEmail()
                    }

                    field("City", text: $city, error: cityError) {
                        validateCity()
                    }

                    field("Country", text: $country, error: countryError) {
                        validateCountry()
                    }

                    // Department
                    Picker(selection: $department) {
                        Text("Select Department").tag("")
                        if !departments.contains(department) && !department.isEmpty {
                            Text(department).tag(department)
                        }
                        ForEach(departments.sorted(), id: \.self) {
                            Text($0).tag($0)
                        }
                    } label: {
                        requiredLabel("Department")
                    }
                    .pickerStyle(.menu)

                    // Designation
                    Picker(selection: $designation) {
                        Text("Select Designation").tag("")
                        if !designations.contains(designation) && !designation.isEmpty {
                            Text(designation).tag(designation)
                        }
                        ForEach(designations.sorted(), id: \.self) {
                            Text($0).tag($0)
                        }
                    } label: {
                        requiredLabel("Designation")
                    }
                    .pickerStyle(.menu)

                    DatePicker(
                        selection: Binding(
                            get: { DateUtils.parse(joiningDate) ?? Date() },
                            set: { joiningDate = DateUtils.toYYYYMMDD($0) ?? "" }
                        ),
                        in: ...Date(),
                        displayedComponents: .date
                    ) {
                        requiredLabel("Joining Date")
                    }

                    Toggle("Active", isOn: $isActive)
                }

                // MARK: - Phones
                Section("Phone Numbers") {

                    if phones.isEmpty {
                        Text("No phone numbers")
                            .foregroundColor(.secondary)
                    }

                    ForEach($phones) { $phone in
                        VStack(alignment: .leading, spacing: 6) {

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
                                .onChange(of: phone.number) { _, newValue in
                                    _ = newValue
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
                        Button {
                            addPhone()
                        } label: {
                            Label("Add Phone", systemImage: "plus")
                        }
                    }
                }
            }
            .navigationTitle("Edit Employee")
            .toolbar {

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEmployee()
                    }
                    .disabled(!hasChanges || !isFormValid)
                }
            }
        }
    }

    // MARK: - Field UI
    private func field(
        _ title: String,
        text: Binding<String>,
        error: String?,
        onChange: @escaping () -> Void
    ) -> some View {

        VStack(alignment: .leading, spacing: 4) {
            requiredLabel(title)

            TextField(title, text: text)
                .onChange(of: text.wrappedValue) { _, _ in
                    onChange()
                }

            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: - Validation
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

    // MARK: - Phone Helpers
    private func addPhone() {
        phones.append(
            EditablePhone(id: UUID().uuidString, type: "home", number: "")
        )
    }

    private func removePhone(_ id: String) {
        phones.removeAll { $0.id == id }
    }

    // MARK: - Save
    private func saveEmployee() {

        let isValid = EmployeeFormValidator.validateForm(
            name: name,
            email: email,
            city: city,
            country: country,
            department: department,
            designation: designation,
            phones: phones
        )

        validateName()
        validateEmail()
        validateCity()
        validateCountry()
        phones.forEach { validatePhone($0.id) }

        guard isValid, !isDuplicateEmail else {
            print("Validation Failed")
            return
        }
        guard phones.allSatisfy({ !isDuplicateHomeNumber(for: $0) }) else { return }

        let updated = Employee(
            id: employee.id,
            name: name,
            designation: designation,
            department: department,
            isActive: isActive,
            imgUrl: employee.imgUrl,
            email: email,
            city: city,
            joiningDate: joiningDate,
            country: country,
            phones: phones.map { $0.toDomain() },
            createdAt: Date(),
            deletedAt: nil
        )

        onSave(updated)
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
        return homeVM.homePhoneExists(phone.number, excludingEmployeeID: employee.id)
    }
}
