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
    private var currentLimit = 20
    @Published var allDesignations: [String] = []
    @Published var allDepartments: [String] = []
    @Published var allStatuses: [String] = []
    @Published var showNewBanner = false
    // MARK: - UI STATE
    private var hasLoadedInitially = false
    private var isRefreshingTaskRunning = false
    @Published var isRefreshing = false
    private let  syncState: SyncState
    private let syncManager: SyncManaging
    @Published private(set) var employees: [Employee] = []
    @Published private(set) var searchResults: [Employee] = []

    @Published var searchQuery = ""
    @Published var selectedDesignations: Set<String> = []
    @Published var selectedDepartments: Set<String> = []
    @Published var selectedStatuses: Set<String> = []
    @Published var isPaginatingUI = false
    @Published var isLoading = false

    private var isPaginating = false
    private var observerId: UUID?
    private var reloadTask: Task<Void,Never>?
    
    let repo: EmployeeRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    init(repo: EmployeeRepositoryProtocol,syncState: SyncState,  syncManager: SyncManaging) {
        self.repo = repo
        
        self.syncState = syncState
        self.syncManager = syncManager
//        observeEmployees()
        
        observerId = SyncNotifier.shared.addObserver {
            [weak self] in
            self?.reloadTask?.cancel()
            self?.reloadTask = Task{
                try? await Task.sleep(nanoseconds: 300_000_000)
                print("Gonna initial load-----")
                self?.hasLoadedInitially = false
               await self?.loadInitial()
            }
        }
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


//    private func observeEmployees() {
//        repo.observeEmployees(limit: currentLimit)
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] employees in
//                guard let self = self else { return }
//                // Only update from observer when idle — not during load/paginate/refresh
//                guard !self.isPaginating, !self.isLoading, !self.isRefreshingTaskRunning else { return }
//                self.employees = employees
//            }
//            .store(in: &cancellables)
//    }
    
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
        if hasLoadedInitially { return }
        hasLoadedInitially = true
        isLoading = true                         // guard is now active
        let data = await repo.loadUntilFilled(targetCount: 10)
        currentLimit = 20
        employees = data                         // single authoritative write
        isLoading = false                        // guard released; observer takes over
    }
//    func shouldLoadMore(currentItem: Employee) -> Bool {
//        guard let last = displayEmployees.last else { return false }
//        return currentItem.id == last.id
//    }
    
    func loadMore() async {
        guard !isPaginating else { return }
        isPaginating = true
        isPaginatingUI = true

        let data = await repo.loadMore()
        
        if !data.isEmpty {
            employees.append(contentsOf: data)
        }

        isPaginating = false
        isPaginatingUI = false
    }

//    private func resubscribeObserver() {
//        cancellables.removeAll()
////        observeEmployees()
//    }
    
    func refresh() async {
        guard !isRefreshingTaskRunning else { return }
        isRefreshingTaskRunning = true
        isLoading = true
        syncState.isRefreshing = true
        syncManager.stopAutoSync()
        
        let data = await repo.refresh()
        currentLimit = 20
        employees = data
        syncState.isRefreshing = false
        syncManager.startAutoSync()
        isLoading = false
        isRefreshingTaskRunning = false
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
}
