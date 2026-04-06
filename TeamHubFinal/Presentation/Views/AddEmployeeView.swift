//
//  AddEmployeeView.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 25/03/26.
//

import SwiftUI
struct AddEmployeeView: View {

    @Environment(\.dismiss) private var dismiss
    let departments:[String]
    let designations:[String]
    var onSave: (Employee) -> Void
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
    

    var body: some View {
        NavigationStack {
            Form {

                Section("Basic Info") {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                    TextField("City", text: $city)
                    TextField("Country", text: $country)
                    // 🔥 Department Dropdown
                    Picker("Department", selection: $selectedDepartment) {
                                            Text("Select Department").tag("")
                                            ForEach(departments.sorted(), id: \.self) { dept in
                                                Text(dept).tag(dept)
                                            }
                                        }
                                        .pickerStyle(.menu)

                       // 🔥 Designation Dropdown
                    Picker("Designation", selection: $selectedDesignation) {
                                            Text("Select Designation").tag("")
                                            ForEach(designations.sorted(), id: \.self) { des in
                                                Text(des).tag(des)
                                            }
                                        }
                                        .pickerStyle(.menu)

                    Toggle("Active", isOn: $isActive)
                }
                Section("Joining Date") {
                    DatePicker(
                        "Select Joining Date",
                        selection: $joiningDate,
                        in: ...Date(),   // ✅ only past & today
                        displayedComponents: .date
                    )
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

        guard !selectedDepartment.isEmpty , !selectedDesignation.isEmpty else{
            print("No department/designation is selected")
            return
        }
        let employee = Employee(
            id: UUID().uuidString.lowercased(),
            name: name,
            designation: selectedDesignation, // or from picker later
            department: selectedDepartment,
            isActive: isActive,
            imgUrl: nil,
            email: email,
            city: city,
            joiningDate: DateUtils.toYYYYMMDD(joiningDate),
            country: country,
            phones: phones.map { $0.toDomain() },
            createdAt: Date(),
            deletedAt: nil,
           
        )

        onSave(employee)
        dismiss()
    }

}
