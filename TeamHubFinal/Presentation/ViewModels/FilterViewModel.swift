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
    
    @Published var selectedDesignations: Set<String> = []
    @Published var selectedDepartments: Set<String> = []
    @Published var selectedStatuses: Set<String> = []

    private let repo: EmployeeRepositoryProtocol
    private let network: NetworkMonitoring

    init(repo: EmployeeRepositoryProtocol,
         network: NetworkMonitoring,
    selected: SelectedFilters) {
        
        self.repo = repo
        self.network = network
        self.selectedDepartments = selected.departments
        self.selectedDesignations = selected.designations
        self.selectedStatuses = selected.statuses
    }
    func loadFilters() async {
        if network.isConnected {
            filters = (await repo.fetchFilters()) ?? filters
        } else {
            filters = repo.fetchFiltersFromDB()
        }
    }
    
    
    func reset() {
        selectedDesignations.removeAll()
        selectedDepartments.removeAll()
        selectedStatuses.removeAll()
    }
}
