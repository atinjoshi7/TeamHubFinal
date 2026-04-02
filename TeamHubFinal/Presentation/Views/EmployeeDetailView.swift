//
//  EmployeeDetailView.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 24/03/26.
//
import Foundation
import SwiftUI
import Combine
struct EmployeeDetailView: View {

    @StateObject private var vm: EmployeeDetailViewModel
    let onUpdate: (Employee) -> Void

    @State private var showEdit = false

    init(vm: EmployeeDetailViewModel,
         onUpdate: @escaping (Employee) -> Void) {
        _vm = StateObject(wrappedValue: vm)
        self.onUpdate = onUpdate
    }

    var body: some View {

        List {
            Section {

                //  Name
                row(title: "Name", value: vm.name)

                // Email
                row(title: "Email", value: vm.email)

                // City + Country
                row(title: "Location", value: vm.cityCountry)

                // Department
                row(title: "Department", value: vm.department)

                // Designation
                row(title: "Designation", value: vm.designation)

                // Status
                row(title: "Status", value: vm.isActiveText)

                //Phones (0–3)
                if vm.phones.isEmpty {
                    row(title: "Phones", value: "No phone numbers")
                } else {
                    ForEach(vm.phones) { phone in
                        row(title: phone.type.capitalized,
                            value: phone.number)
                    }
                }

            } header: {
                Text("Employee Details")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Details")
        .toolbar {
            Button("Edit") {
                showEdit = true
            }
        }
        .sheet(isPresented: $showEdit) {
            EditEmployeeView(employee: vm.employee) { updated in
                onUpdate(updated)
                vmRefresh(updated)
            }
        }
    }

    // MARK: - Reusable Row

    private func row(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }

    // MARK: - Update VM after edit
    private func vmRefresh(_ updated: Employee) {
        vm.objectWillChange.send()
        vm.setEmployee(updated)
    }
}

import SwiftUI

struct EditEmployeeView: View {

    @Environment(\.dismiss) private var dismiss

    let employee: Employee
    var onSave: (Employee) -> Void
    
    @State private var phones: [EditablePhone]
    // MARK: - Basic Fields
    @State private var name: String
    @State private var email: String
    @State private var city: String
    @State private var country: String
    @State private var isActive: Bool

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
            designation: employee.designation,
            department: employee.department,
            isActive: isActive,
            imgUrl: employee.imgUrl,
            email: email,
            city: city,
            joiningDate: nil,
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

