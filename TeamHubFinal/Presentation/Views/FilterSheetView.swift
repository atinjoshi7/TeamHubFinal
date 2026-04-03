//
//  FilterSheetView.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 25/03/26.
//

import Foundation
import SwiftUI

struct FilterView: View {

    @StateObject private var vm: FilterViewModel
    @Environment(\.dismiss) private var dismiss

    let onApply: (Set<String>, Set<String>, Set<String>) -> Void

    init(vm: FilterViewModel,
         onApply: @escaping (Set<String>, Set<String>, Set<String>) -> Void) {
                 _vm = StateObject(wrappedValue: vm)
                 self.onApply = onApply
    }

    var body: some View {
        NavigationStack {
            List {

                // MARK: - Designations
                Section("Designation") {
                    multiSelectSection(
                        items: vm.filters.designations,
                        selected: $vm.selectedDesignations
                    )
                }

                // MARK: - Departments
                Section("Department") {
                    multiSelectSection(
                        items: vm.filters.departments,
                        selected: $vm.selectedDepartments
                    )
                }

                // MARK: - Status
                Section("Status") {
                    multiSelectSection(
                        items: vm.filters.statuses,
                        selected: $vm.selectedStatuses
                    )
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Filters")
            .toolbar {

                // Reset
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        vm.reset()
                    }
                }

                // Apply
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        onApply(
                            vm.selectedDesignations,
                            vm.selectedDepartments,
                            vm.selectedStatuses
                        )
                        dismiss()
                    }
                }
            }
            
        }
    }
}
extension FilterView {

    func multiSelectSection(
        items: [String],
        selected: Binding<Set<String>>
    ) -> some View {

        ForEach(items, id: \.self) { item in
            Button {
                toggle(item, selected: selected)
            } label: {
                HStack {
                    Text(item)

                    Spacer()

                    if selected.wrappedValue.contains(item) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }

    private func toggle(_ item: String,
                        selected: Binding<Set<String>>) {

        if selected.wrappedValue.contains(item) {
            selected.wrappedValue.remove(item)
        } else {
            selected.wrappedValue.insert(item)
        }
    }
}
