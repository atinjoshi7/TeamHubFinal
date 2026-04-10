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
    
    private var searchOffset = 0
    private let limit = 10
    private var lastSearchQuery: String?
    private(set) var isSearching = false
    // MARK: - UI STATE
    var hasLoadedInitially = false
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
    private(set) var initialSearchRequestDone = false
    private var observerId: UUID?
    private var reloadTask: Task<Void,Never>?
    private var searchTask: Task<Void,Never>?
    var selectedFilters: SelectedFilters {
        SelectedFilters(
            designations: selectedDesignations,
            departments: selectedDepartments,
            statuses: selectedStatuses
        )
    }
    
    let repo: EmployeeRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    init(repo: EmployeeRepositoryProtocol,syncState: SyncState,  syncManager: SyncManaging) {
        self.repo = repo
        
        self.syncState = syncState
        self.syncManager = syncManager

        
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

//    var newEmployee:Int{
//        if repo.a
//    }
    
    // MARK: - COMPUTED

    var displayEmployees: [Employee] {
        isSearchingOrFiltering ? searchResults : employees
    }

     var isSearchingOrFiltering: Bool {
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
    
    func handleSearch(query: String) {
        isLoading = true
        defer {
            isLoading = false
//            initialSearchRequestDone = true
        }
        searchTask?.cancel()
        
        searchTask = Task {
            
            try? await Task.sleep(nanoseconds: 900_000_000)
            
            guard !Task.isCancelled else { return }
            
            await performSearch()
        }
    }
    
    // MARK: - LOAD

    func loadInitial() async {
        guard !hasLoadedInitially else { return }
        hasLoadedInitially = true
        isLoading = true// guard is now active
        defer {
            isLoading = false
            initialSearchRequestDone = false
//            searchResults = []
        }
        let data = await repo.loadUntilFilled(targetCount: 10)
        
        if !syncManager.syncRunning {
           await syncManager.startAutoSync()
        }
        currentLimit = 20
        employees = data                         // single authoritative write
//        isLoading = false                        // guard released; observer takes over
    }

    func loadMore() async {
        guard !isPaginating else { return }
        isPaginating = true
        isPaginatingUI = true
        
        let data = await repo.loadMore()
        
        //        if !data.isEmpty {
        employees.append(contentsOf: data)
        //        }
        
        isPaginating = false
        isPaginatingUI = false
    }
    
    func refresh() async {
        
        guard !isRefreshingTaskRunning else { return }
        isRefreshingTaskRunning = true
        isLoading = true
        syncState.isRefreshing = true
//        syncManager.stopAutoSync()
        
        defer {
            syncState.isRefreshing = false
//            syncManager.startAutoSync()
            isLoading = false
            isRefreshingTaskRunning = false
        }
        if isSearchingOrFiltering {
            await performSearch()
        }
        else {
            await repo.refresh()
            
            hasLoadedInitially = false
            await loadInitial()
        }
        
        
//        currentLimit = 20
//        employees = data
        
    }

    // MARK: - SEARCH (UNIFIED)

    func performSearch() async {
        
        let result = await repo.searchNFilter(
            query: searchQuery,
            designations: Array(selectedDesignations),
            departments: Array(selectedDepartments),
            statuses: Array(selectedStatuses)
        )
        
        searchResults = result.filter { $0.deletedAt == nil }
    }
    func performSearchLoadMore() async {
        guard !isPaginating else { return }
        isPaginating = true
        isPaginatingUI = true
        
        let result = await repo.searchNFilterLoadMore(
            query: searchQuery,
            designations: Array(selectedDesignations),
            departments: Array(selectedDepartments),
            statuses: Array(selectedStatuses)
        )
//        if result.isEmpty {
//            searchResults = []
//        }
        searchResults.append(contentsOf: result.filter { $0.deletedAt == nil })
        
        isPaginating = false
        isPaginatingUI = false
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
