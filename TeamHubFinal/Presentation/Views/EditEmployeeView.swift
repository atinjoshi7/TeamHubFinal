//
//  EditEmployeeView.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 07/04/26.
//

import SwiftUI

struct EditEmployeeView: View {

    @Environment(\.dismiss) private var dismiss

    var employee: Employee
    var onSave: (Employee) -> Void
    
    @State private var phones: [EditablePhone]

    // MARK: - Basic Fields
    @State private var name: String
    @State private var email: String
    @State private var city: String
    @State private var country: String
    @State private var isActive: Bool
    @State private var joiningDate: String
    @State private var department: String
    @State private var designation: String
    // MARK: - Phones (Editable)

    private let phoneTypes = ["home", "office", "other"]

    init(employee: Employee, onSave: @escaping (Employee) -> Void) {
        self.employee = employee
        self.onSave = onSave

        _name = State(initialValue: employee.name)
        _email = State(initialValue: employee.email)
        _city = State(initialValue: employee.city)
        _country = State(initialValue: employee.country)
        _isActive = State(initialValue: employee.isActive)
        _phones = State(
            initialValue: employee.phones.map { EditablePhone(from: $0) }
        )
        _joiningDate = State(initialValue: employee.joiningDate ?? "")
        _department = State(initialValue: employee.department)
        _designation = State(initialValue: employee.designation)
    }

    var body: some View {
        NavigationStack {
            Form {

                // Mark: Basic Info
                Section("Basic Information") {
                    labeledField("Name", text: $name)
                    labeledField("Email", text: $email)
                    labeledField("City", text: $city)
                    labeledField("Country", text: $country)
                    labeledField("Department", text:$department)
                    labeledField("Designation", text: $designation)
//                    Section {
                        DatePicker(
                            "Joining Date",
                            selection: Binding(
                                get: {
                                    DateUtils.parse(joiningDate) ?? Date()
                                },
                                set: { newDate in
                                    // store temp if you want editable
                                    joiningDate = DateUtils.toYYYYMMDD(newDate) ?? ""
                                }
                            ),
                            in: ...Date(),
                            displayedComponents: .date
                        )
//                    }
                    Toggle("Active", isOn: $isActive)
                }

                // Mark: Phone Section
                Section("Phone Numbers") {

                    if phones.isEmpty {
                        Text("No phone numbers")
                            .foregroundColor(.secondary)
                    }
                    ForEach($phones) { $phone in
                        VStack(alignment: .leading, spacing: 8) {

                            Picker("Type", selection: $phone.type) {
                                ForEach(phoneTypes, id: \.self) { type in
                                    Text(type.capitalized).tag(type)
                                }
                            }.pickerStyle(.menu)

                            TextField("Number", text: $phone.number)
                                .keyboardType(.numberPad)

                            Button(role: .destructive) {
                                removePhone(phone.id)
                            } label: {
                                Text("Delete")
                            }
                        }
                    }

                    // Add Phone (max 3)
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
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEmployee()
                    }
                }
            }
        }
    }
    // Mark: - Reusable Field

    private func labeledField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            TextField(title, text: text)
        }
    }
    // Mark: - Phone Helpers

    private func addPhone() {
        let newPhone = EditablePhone(
            id: UUID().uuidString,
            type: "home",
            number: ""
        )
        phones.append(newPhone)
    }

    private func removePhone(_ id: String) {
        phones.removeAll { $0.id == id }
    }

    private func saveEmployee() {

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
            phones: phones.map{
                $0.toDomain()
            },
            createdAt: Date(),
            deletedAt:nil
        )

        onSave(updated)
        dismiss()
    }
}

