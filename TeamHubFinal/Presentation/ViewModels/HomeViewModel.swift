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
    
    //
    @Published private(set) var employees: [Employee] = []
    @Published private(set) var combinedEmployees: [Employee] = [] // (Search or Filtered) OR (search andFiltered)
    
    @Published var selectedDesignations: Set<String> = []
    @Published var selectedDepartments: Set<String> = []
    @Published var selectedStatuses: Set<String> = []
    @Published var isLoading = false
    @Published var isSearchingLoading = false
    @Published private(set) var state: State = .idle
    @Published var searchQuery = ""
    @Published var cachedFilters: Filters?
    
    // Objects
    private let network: NetworkMonitoring
    private let syncManager: SyncManaging
    let repo : EmployeeRepositoryProtocol
    
    // Debounce
    private var debounceTask: Task<Void, Never>?
    
    // Pagination terms.
    private var isFetching = false
    private var hasNext = true
    private var offset = 0
    private let limit = 20
    
   
    // Searching Pagination
    private var searchOffset = 0
    private var searchHasNext = true
  
   
    //
    enum State: Equatable{
        case idle, loading, loaded, error(String)
    }



    var isFiltering: Bool {
        !selectedDesignations.isEmpty ||
        !selectedDepartments.isEmpty ||
        !selectedStatuses.isEmpty
    }
    var isSearching: Bool {
        !searchQuery.isEmpty
    }
    var displayEmployees: [Employee] {
        if isSearching || isFiltering {
            return combinedEmployees   //SINGLE PIPELINE
        } else {
            return employees
        }
    }
    
    init(repo:EmployeeRepositoryProtocol,network: NetworkMonitoring,syncManager: SyncManaging){
        self.repo = repo
        self.network = network
        self.syncManager = syncManager
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

        // Try DB first
        let dbData = repo.fetchFromDB(limit: limit, offset: offset)

        if !dbData.isEmpty {
            employees.append(contentsOf: dbData)
            offset += limit
            isFetching = false
            isLoading = false
            return
        }

        // If DB empty → hit API
        do {
            let result = try await repo.fetch(limit: limit, offset: offset)

            // Save already done in repo
            let freshFromDB = repo.fetchFromDB(limit: limit, offset: offset)

            employees.append(contentsOf: freshFromDB)
            offset += limit
            hasNext = result.hasNext
        } catch {
            print(" Pagination Error: \(error)")
        }

        isFetching = false
        isLoading = false
    }
    
    func loadMoreCombined() async {

        guard !isSearchingLoading, searchHasNext else { return }
        isLoading = true
        isSearchingLoading = true

        if network.isConnected {

            let result = try? await repo.fetchCombined(
                search: searchQuery,
                designations: Array(selectedDesignations),
                departments: Array(selectedDepartments),
                statuses: Array(selectedStatuses),
                limit: limit,
                offset: searchOffset   // single offset
            )

            let newData = result?.employees ?? []

            combinedEmployees.append(contentsOf: newData)

            searchOffset += limit
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
        isLoading = false
        isSearchingLoading = false
    }
    
    func loadInitial() async {

        if isSearching || isFiltering {

            searchOffset = 0
            searchHasNext = true
            combinedEmployees.removeAll()

            await loadMoreCombined()
            return
        }

        offset = 0
        employees.removeAll()
        hasNext = true

        await loadMore()
    }
 
    
    // MARK: Smart Trigger (IMPORTANT)
    func loadMoreIfNeeded(currentItem: Employee) {

        let list = displayEmployees

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

    func onSearchChanged(_ text: String) {
            searchQuery = text
            debounceTask?.cancel()
        // Immediately show loader
//        if !text.isEmpty {
//            isSearchingLoading = true
//        }
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

        if searchQuery.isEmpty && !isFiltering {
            await loadInitial()
            return
        }

        searchOffset = 0
        searchHasNext = true
        combinedEmployees.removeAll()

        await loadMoreCombined()
    }
    
    func updateEmployee(_ employee: Employee) {
        repo.updateEmployee(employee)


        print(" updateEmployee called:", employee.id)
        
        Task {
                await syncManager.syncNow()
            }
        print(" updateEmployee called:", employee.id)
    }

    func applyFilters(
        designations: [String],
        departments: [String],
        statuses: [String]
    ) {

        selectedDesignations = Set(designations)
        selectedDepartments = Set(departments)
        selectedStatuses = Set(statuses)

        // RESET FILTER STATE
        searchOffset = 0
        searchHasNext = true
        combinedEmployees.removeAll()
        Task {
               await loadMoreCombined()
           }
    }
    
    func deleteEmployee(at offsets: IndexSet) {

        offsets.forEach { index in
            let emp = displayEmployees[index]
            repo.deleteEmployee(emp.id)
        }

        employees.remove(atOffsets: offsets)
    }
}
