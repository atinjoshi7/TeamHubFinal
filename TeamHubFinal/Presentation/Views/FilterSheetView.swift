//
//  FilterSheetView.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 25/03/26.
//

import Foundation
import SwiftUI

struct SelectedFilters {
    var designations: Set<String>
    var departments: Set<String>
    var statuses: Set<String>
}

struct FilterView: View {

    @Environment(\.dismiss) private var dismiss
//    @Binding var isSearchorFilter: Bool
    
    // ✅ OPTIONS
    let designations: [String]
    let departments: [String]
    let statuses: [String]

    // ✅ LOCAL STATE (temporary UI editing)
    @State private var selectedDesignations: Set<String>
    @State private var selectedDepartments: Set<String>
    @State private var selectedStatuses: Set<String>

    let onApply: (Set<String>, Set<String>, Set<String>) -> Void

    init(
        designations: [String],
        departments: [String],
        statuses: [String],
        selectedDesignations: Set<String>,
        selectedDepartments: Set<String>,
        selectedStatuses: Set<String>,
        onApply: @escaping (Set<String>, Set<String>, Set<String>) -> Void,
       
    ) {
        self.designations = designations
        self.departments = departments
        self.statuses = statuses

        _selectedDesignations = State(initialValue: selectedDesignations)
        _selectedDepartments = State(initialValue: selectedDepartments)
        _selectedStatuses = State(initialValue: selectedStatuses)

        self.onApply = onApply
    }

    var body: some View {
        NavigationStack {
            List {

                Section("Designation") {
                    multiSelectSection(
                        items: designations,
                        selected: $selectedDesignations
                    )
                }

                Section("Department") {
                    multiSelectSection(
                        items: departments,
                        selected: $selectedDepartments
                    )
                }

                Section("Status") {
                    multiSelectSection(
                        items: statuses,
                        selected: $selectedStatuses
                    )
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Filters")
            .toolbar {

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        selectedDesignations.removeAll()
                        selectedDepartments.removeAll()
                        selectedStatuses.removeAll()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        onApply(
                            selectedDesignations,
                            selectedDepartments,
                            selectedStatuses
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
