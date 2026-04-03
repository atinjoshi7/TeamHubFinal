//
//  HomeViewModel.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 24/03/26.
//





import Foundation
import SwiftUI
import Combine
@MainActor
final class HomeViewModel: ObservableObject {

    @Published var allDesignations: [String] = []
    @Published var allDepartments: [String] = []
    @Published var allStatuses: [String] = []
    
    // MARK: - UI STATE

    @Published private(set) var employees: [Employee] = []
    @Published private(set) var searchResults: [Employee] = []

    @Published var searchQuery = ""
    @Published var selectedDesignations: Set<String> = []
    @Published var selectedDepartments: Set<String> = []
    @Published var selectedStatuses: Set<String> = []
    @Published var isPaginatingUI = false
    @Published var isLoading = false

    private var isPaginating = false
    
    let repo: EmployeeRepositoryProtocol

    init(repo: EmployeeRepositoryProtocol) {
        self.repo = repo
        observeSync()
    }

    // MARK: - COMPUTED

    var displayEmployees: [Employee] {
        isSearchingOrFiltering ? searchResults : employees
    }

    private var isSearchingOrFiltering: Bool {
        !searchQuery.isEmpty ||
        !selectedDesignations.isEmpty ||
        !selectedDepartments.isEmpty ||
        !selectedStatuses.isEmpty
    }

    
    func filters() async {

        // ✅ avoid refetch
        if !allDesignations.isEmpty { return }

        let data = await repo.fetchFilters()

        allDesignations = data.designations
        allDepartments = data.departments
        allStatuses = data.statuses
    }
    
    // MARK: - LOAD

    func loadInitial() async {

        isLoading = true

        let data = await repo.loadInitial()

        // 🔥 ALWAYS FILTER DELETED
        employees = data.filter { $0.deletedAt == nil }

        isLoading = false
    }

    func loadMore() async {

        guard !isPaginating else { return }

          isPaginating = true
        isPaginatingUI = true
        // ❌ DO NOT SHOW LOADER FOR PAGINATION
        let data = await repo.loadMore()

        employees = data.filter { $0.deletedAt == nil }
        
        isPaginating = false
        isPaginatingUI = true
    }

    func refresh() async {

        isLoading = true

        let data = await repo.refresh()

        employees = data.filter{ $0.deletedAt == nil}

        isLoading = false
    }

    // MARK: - SEARCH (UNIFIED)

    func performSearch() async {

        // 🔥 RESET IF EMPTY
        if !isSearchingOrFiltering {
            searchResults = []
            employees = await repo.loadInitial()
            return
        }

        let result = await repo.search(
            query: searchQuery,
            designations: Array(selectedDesignations),
            departments: Array(selectedDepartments),
            statuses: Array(selectedStatuses)
        )

        searchResults = result.filter { $0.deletedAt == nil }
    }

    // MARK: - CRUD (INSTANT UI UPDATE)

    func addEmployee(_ emp: Employee) {

        repo.addEmployee(emp)

        // 🔥 instant UI
        employees.insert(emp, at: 0)
    }

    func updateEmployee(_ emp: Employee) {

        repo.updateEmployee(emp)

        if let i = employees.firstIndex(where: { $0.id == emp.id }) {
            employees[i] = emp
        }
    }

    func deleteEmployee(at offsets: IndexSet) {

        offsets.forEach {
            let emp = employees[$0]
            repo.deleteEmployee(emp.id)
        }

        employees.remove(atOffsets: offsets)
    }

    // MARK: - SYNC OBSERVER (CRITICAL FIX)

    private func observeSync() {

        NotificationCenter.default.addObserver(
            forName: .didSyncData,
            object: nil,
            queue: .main
        ) { [weak self] _ in

            guard let self = self else { return }

            Task { @MainActor in
                print("🔄 Sync → refreshing UI")

                // 🔥 DO NOT CALL loadInitial (it resets pagination)
                let updated = await self.repo.loadMore()
//                let updated = await self.repo.refresh()

                self.employees = updated.filter { $0.deletedAt == nil }
            }
        }
    }
}
extension Notification.Name {
    static let didSyncData = Notification.Name("didSyncData")
}
