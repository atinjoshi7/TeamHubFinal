//
//  HomeViewModel.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 24/03/26.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    enum State: Equatable{
        case idle, loading, loaded, error(String)
    }
    @Published private(set) var state: State = .idle
    // MARK: - Published
    @Published private(set) var employees: [Employee] = []
    @Published private(set) var combinedEmployees: [Employee] = []

    @Published var selectedDesignations: Set<String> = []
    @Published var selectedDepartments: Set<String> = []
    @Published var selectedStatuses: Set<String> = []

    @Published var isLoading = false
    @Published var isSearchingLoading = false
    @Published var searchQuery = ""
    @Published var cachedFilters: Filters?

    // MARK: - Dependencies
     private let network: NetworkMonitoring
     private let syncManager: SyncManaging
     let repo: EmployeeRepositoryProtocol

    // MARK: - Pagination (API DRIVEN)
    private var isFetching = false
    private var hasNext = true
    private var offset = 0
    private let limit = 20

    // MARK: - Search Pagination
    private var searchOffset = 0
    private var searchHasNext = true

    // MARK: - Debounce
    private var debounceTask: Task<Void, Never>?

    // MARK: - Init
    init(
        repo: EmployeeRepositoryProtocol,
        network: NetworkMonitoring,
        syncManager: SyncManaging
    ) {
        self.repo = repo
        self.network = network
        self.syncManager = syncManager
    }

    // MARK: - Computed
    var isFiltering: Bool {
        return !selectedDesignations.isEmpty ||
               !selectedDepartments.isEmpty ||
               !selectedStatuses.isEmpty
    }

    var isSearching: Bool {
        return !searchQuery.isEmpty
    }

    var displayEmployees: [Employee] {
        if isSearching || isFiltering {
            return combinedEmployees
        } else {
            return employees
        }
    }
        
    // MARK: - Initial Load
//    func loadInitial() async {
//        offset = 0
//        hasNext = true
//        employees.removeAll()
//        repo.clearAllEmployees()
//        await loadMore()
//    }
    
    func loadInitial() async {

        if isSearching || isFiltering {
            searchOffset = 0
            searchHasNext = true
            combinedEmployees.removeAll()
            await loadMoreCombined()
            return
        }

        offset = 0
        hasNext = true

        // ✅ STEP 1: LOAD FROM DB FIRST
        let dbData = repo.fetchFromDB(limit: limit, offset: offset)

        if !dbData.isEmpty {
            print("📦 Loaded from DB")

            employees = dbData
            offset += limit

            // ✅ STEP 2: OPTIONAL BACKGROUND SYNC
            if network.isConnected {
                Task {
                    await self.loadMore()
                }
            }

            return
        }

        // ❌ ONLY IF DB EMPTY → HIT API
        print("🌐 DB empty → calling API")

        employees.removeAll()
        await loadMore()
    }

    // MARK: - Pagination (CORE FIXED)
    func loadMore() async {
        if isFetching { return }
        if hasNext == false { return }

        isFetching = true
        isLoading = true

    
        do {
            let result = try await repo.fetch(limit: limit, offset: offset)

            let allData = repo.fetchFromDB(limit: offset + limit, offset: 0)

            employees = allData

            offset = offset + limit
            hasNext = result.hasNext

            // 🔥 AUTO FETCH FIX (CRITICAL)
            if employees.count < 10 && hasNext {
                print("⚡ Auto fetching next page because visible data is low")
                isFetching = false
                await loadMore()
                return
            }

            
        } catch {
            print("❌ Pagination Error:", error)
        }

        isFetching = false
        isLoading = false
    }
    // MARK: - Scroll Trigger (FIXED)
    func loadMoreIfNeeded(currentItem: Employee) {
        let list = displayEmployees

        // 🔥 prevent auto-trigger on small list
        if list.count < 15 { return }

        guard let last = list.last else { return }

        if currentItem.id == last.id {
            Task {
                if isSearching || isFiltering {
                    await loadMoreCombined()
                } else {
                    await loadMore()
                }
            }
        }
    }

    // MARK: - Refresh (YOUR REQUIREMENT)
        func refresh() async {
    
            guard !isFetching else { return }
    
            isFetching = true
            isLoading = true
    
            offset = 0
            hasNext = true
    
            do {
                // ✅ STEP 1: Fetch FIRST
                let result = try await repo.fetch(limit: limit, offset: 0)
    
                // ✅ STEP 2: Clear DB AFTER success
                repo.clearAllEmployees()
    
                // ✅ STEP 3: Save fresh data
                repo.save(employees: result.employees)
    
                // ✅ STEP 4: Load from DB
                let fresh = repo.fetchFromDB(limit: limit, offset: 0)
                employees = fresh
    
                offset = limit
                hasNext = result.hasNext
    
                // ✅ AUTO PAGINATION (same fix)
                if employees.count < 10 && hasNext {
                    isFetching = false
                    await loadMore()
                    return
                }
    
            } catch {
                print("❌ Refresh failed:", error)
    
                // ✅ OFFLINE FALLBACK (IMPORTANT)
                let fallback = repo.fetchFromDB(limit: limit, offset: 0)
                employees = fallback
            }
    
            isFetching = false
            isLoading = false
        }
    // MARK: - Search
    func onSearchChanged(_ text: String) {
        searchQuery = text
        debounceTask?.cancel()

        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)

            if Task.isCancelled { return }

            await performSearch()
        }
    }

    private func performSearch() async {
        if searchQuery.isEmpty && !isFiltering {
            await loadInitial()
            return
        }

        searchOffset = 0
        searchHasNext = true
        combinedEmployees.removeAll()

        await loadMoreCombined()
    }

    // MARK: - Combined (Search + Filter)
    func loadMoreCombined() async {

        if isSearchingLoading { return }
        if searchHasNext == false { return }

        isSearchingLoading = true
        isLoading = true

        if network.isConnected {

            let result = try? await repo.fetchCombined(
                search: searchQuery,
                designations: Array(selectedDesignations),
                departments: Array(selectedDepartments),
                statuses: Array(selectedStatuses),
                limit: limit,
                offset: searchOffset
            )

            let newData = result?.employees ?? []

            //  Prevent duplicates
            let existingIds = Set(combinedEmployees.map { $0.id })
            let newItems = newData.filter { emp in
                return existingIds.contains(emp.id) == false
            }

            combinedEmployees.append(contentsOf: newItems)

            searchOffset = searchOffset + limit
            searchHasNext = result?.hasNext ?? false

        } else {
            combinedEmployees = repo.fetchFilteredFromDB(
                search: searchQuery,
                designations: Array(selectedDesignations),
                departments: Array(selectedDepartments),
                statuses: Array(selectedStatuses)
            )

            searchHasNext = false
        }

        isSearchingLoading = false
        isLoading = false
    }

    // MARK: - Filters
    func applyFilters(
        designations: [String],
        departments: [String],
        statuses: [String]
    ) {
        selectedDesignations = Set(designations)
        selectedDepartments = Set(departments)
        selectedStatuses = Set(statuses)

        searchOffset = 0
        searchHasNext = true
        combinedEmployees.removeAll()

        Task {
            await loadMoreCombined()
        }
    }

    // MARK: - Add
    func addEmployee(_ employee: Employee) {
        repo.addEmployee(employee)

        // Insert on top (UX)
        employees.insert(employee, at: 0)

        Task {
            await syncManager.syncNow()
        }
    }

    // MARK: - Update
    func updateEmployee(_ employee: Employee) {
        repo.updateEmployee(employee)

        Task {
            await syncManager.syncNow()
        }
    }

    // MARK: - Delete (SOFT DELETE)
    func deleteEmployee(at offsets: IndexSet) {
        offsets.forEach { index in
            let emp = displayEmployees[index]

            repo.deleteEmployee(emp.id)

            employees.removeAll { $0.id == emp.id }
            combinedEmployees.removeAll { $0.id == emp.id }
        }

        Task {
            await syncManager.syncNow()
        }
    }

    // MARK: - Filters preload
    func prepareFilters() async {
        if network.isConnected {
            cachedFilters = try? await repo.fetchFilters()
        } else {
            cachedFilters = repo.fetchFiltersFromDB()
        }
    }
}
