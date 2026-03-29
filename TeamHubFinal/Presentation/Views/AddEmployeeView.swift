//
//  AddEmployeeView.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 25/03/26.
//

import SwiftUI
struct AddEmployeeView: View {

    @Environment(\.dismiss) private var dismiss

    var onSave: (Employee) -> Void

    @State private var name = ""
    @State private var email = ""
    @State private var city = ""
    @State private var country = ""
    @State private var isActive = true

    @State private var phones: [EditablePhone] = []

    private let phoneTypes = ["home", "office", "other"]

    var body: some View {
        NavigationStack {
            Form {

                Section("Basic Info") {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                    TextField("City", text: $city)
                    TextField("Country", text: $country)

                    Toggle("Active", isOn: $isActive)
                }

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
                    
                    
                    
                }
            }
        }
    }
    private func addPhone() {
        phones.append(
            EditablePhone(id: UUID().uuidString, type: "home", number: "")
        )
    }

    private func removePhone(_ id: String) {
        phones.removeAll { $0.id == id }
    }

    private func save() {

        let employee = Employee(
            id: UUID().uuidString,
            name: name,
            designation: "New", // or from picker later
            department: "General",
            isActive: isActive,
            imgUrl: nil,
            email: email,
            city: city,
            joiningDate: nil,
            country: country,
            phones: phones.map { $0.toDomain() }
        )

        onSave(employee)
        dismiss()
    }

}
