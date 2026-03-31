//
//  FilterViewModel.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 25/03/26.
//

import Foundation
import Combine



final class FilterViewModel: ObservableObject {

    @Published var filters: Filters = .init(
        designations: [],
        departments: [],
        statuses: []
    )
    @Published var AddDepartments: Set<String> = []
    @Published var AddDesignations: Set<String> = []
    @Published var selectedDesignations: Set<String> = []
    @Published var selectedDepartments: Set<String> = []
    @Published var selectedStatuses: Set<String> = []

    private let repo: EmployeeRepositoryProtocol
    private let network: NetworkMonitoring

    init(repo: EmployeeRepositoryProtocol,
         network: NetworkMonitoring,
         initialFilters: Filters?) {
        
        self.repo = repo
        self.network = network
        self.filters = initialFilters ?? Filters(
            designations: [],
            departments: [],
            statuses: []
        )
    }
    func loadFilters() async {
        if network.isConnected {
            filters = (try? await repo.fetchFilters()) ?? filters
        } else {
            filters = repo.fetchFiltersFromDB()
        }
    }
    
    func fetchFilters() async{
        filters = (try? await repo.fetchFilters()) ?? filters
        AddDepartments = Set(filters.departments)
        AddDesignations = Set(filters.designations)
    }
    
    func reset() {
        selectedDesignations.removeAll()
        selectedDepartments.removeAll()
        selectedStatuses.removeAll()
    }
}
