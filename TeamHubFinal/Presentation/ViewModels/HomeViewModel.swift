//
//  HomeViewModel.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 24/03/26.
//

import Foundation
import Combine
import SwiftUI
class HomeViewModel: ObservableObject{
    @Published private(set) var employees: [Employee] = []
    @Published private(set) var filteredEmployees: [Employee] = []
    private let network: NetworkMonitoring
    private let syncManager: SyncManaging
    @Published private(set) var state: State = .idle
    @Published var searchQuery = ""
    @Published var cachedFilters: Filters?
    private var debounceTask: Task<Void, Never>?
    
    enum State: Equatable{
        case idle, loading, loaded, error(String)
    }
   let repo : EmployeeRepositoryProtocol
    private var isFetching = false
        private var hasNext = true
    private var offset = 0
        private let limit = 20
//        private var hasNext = true
        private var isLoading = false
    
    init(repo:EmployeeRepositoryProtocol,network: NetworkMonitoring,syncManager: SyncManaging){
        self.repo = repo
        self.network = network
        self.syncManager = syncManager
    }
    func loadInitial() async{
        offset = 0
        employees.removeAll()
        hasNext = true
        await loadMore()
    }
    func prepareFilters() async {
        if network.isConnected {
            cachedFilters = try? await repo.fetchFilters()
        } else {
            cachedFilters = repo.fetchFiltersFromDB()
        }
    }
    // MARK: Pagination Core Logic (DB FIRST)
    func loadMore() async {
        guard !isFetching, hasNext else { return }

        isFetching = true
        isLoading = true

        // 1️⃣ Try DB first
        let dbData = repo.fetchFromDB(limit: limit, offset: offset)

        if !dbData.isEmpty {
            employees.append(contentsOf: dbData)
            offset += limit
            isFetching = false
            isLoading = false
            return
        }

        // 2️⃣ If DB empty → hit API
        do {
            let result = try await repo.fetch(limit: limit, offset: offset)

            // Save already done in repo
            let freshFromDB = repo.fetchFromDB(limit: limit, offset: offset)

            employees.append(contentsOf: freshFromDB)
            offset += limit
            hasNext = result.hasNext
        } catch {
            print("❌ Pagination Error: \(error)")
        }

        isFetching = false
        isLoading = false
    }

    // MARK: Smart Trigger (IMPORTANT)
    func loadMoreIfNeeded(currentItem: Employee) {
        guard let last = employees.last else { return }
        if currentItem.id == last.id {
            Task { await loadMore() }
        }
    }
    
    func onSearchChanged(_ text: String) {
            searchQuery = text
            debounceTask?.cancel()

            debounceTask = Task {
                try? await Task.sleep(nanoseconds: 100_000_000)

                if Task.isCancelled { return }

                await performSearch()
            }
        }
    func addEmployee(_ employee: Employee) {

        repo.addEmployee(employee)
        employees.insert(employee, at: 0)

        // trigger sync immediately
        Task {
            await syncManager.syncNow()
        }
    }

    
    private func performSearch() async {

        if searchQuery.isEmpty {
            await loadInitial()
            return
        }

        isLoading = true

        if network.isConnected {
            // 🔥 API SEARCH
            employees = (try? await repo.search(query: searchQuery)) ?? []
        } else {
            // 🔥 DB SEARCH (NSPredicate)
            employees = repo.searchLocal(query: searchQuery)
        }

        isLoading = false
    }
    
    func updateEmployee(_ employee: Employee) {
        repo.updateEmployee(employee)


        print("🔥 updateEmployee called:", employee.id)
        
        Task {
                await syncManager.syncNow()
            }
        print("🔥 updateEmployee called:", employee.id)
    }
    func applyFilters(
        designations: [String],
        departments: [String],
        statuses: [String]
    ) {
        Task {
            isLoading = true

            if network.isConnected {
                // 🔥 API FILTER
                let result = try? await repo.fetchFilteredFromAPI(
                        designations: designations,
                        departments: departments,
                        statuses: statuses,
                        limit: 20,
                        offset: 0
                    )

                    employees = result?.employees ?? []
                
            } else {
                // 🔥 DB FILTER
                employees = repo.fetchFilteredFromDB(
                    designations: designations,
                    departments: departments,
                    statuses: statuses
                )
            }

            isLoading = false
        }
    }

    func deleteEmployee(at offsets: IndexSet) {

        offsets.forEach { index in
            let emp = employees[index]
            repo.deleteEmployee(emp.id)
        }

        employees.remove(atOffsets: offsets)
    }
}
