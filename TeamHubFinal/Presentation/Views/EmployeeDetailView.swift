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
                HStack {
                    Spacer()
                    AvatarView(url: vm.avatarURL, initials: vm.avatarInitials, size: 150)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
            
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

                // Joining Date
                row(title: "joinig date", value: vm.joiningDate)
                
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
            EditEmployeeView(employee: vm.employee,
            ) { updated in
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

