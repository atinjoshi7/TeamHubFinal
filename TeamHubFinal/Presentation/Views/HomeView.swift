//
//  HomeView.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 24/03/26.
//
import SwiftUI

struct HomeView: View {

    
    @EnvironmentObject private var network: NetworkMonitor
    @EnvironmentObject private var theme: ThemeManager

    @StateObject private var vm: HomeViewModel
    @State private var path = NavigationPath()

    @State private var showFilterSheet = false
    @State private var showAddSheet = false
   

    @FocusState private var isFocused: Bool

    init(vm: HomeViewModel) {
        _vm = StateObject(wrappedValue: vm)
    }

    var body: some View {

        NavigationStack(path: $path) {

            VStack(spacing: 0) {

                // 🔍 SEARCH + THEME
                HStack {

                    SearchBarView(
                        text: $vm.searchQuery,
                        onChange: { _ in
                            vm.handleSearch(query: vm.searchQuery)
                            },
                        isFocused: $isFocused
                    )

                    Button {
                        withAnimation {
                            theme.toggle()
                        }
                    } label: {
                        Image(systemName: theme.isDarkMode ? "moon.fill" : "sun.max.fill")
                            .frame(width: 40, height: 40)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

                contentView
            }
            .navigationTitle("Employees")

            // 🔁 Navigation
            .navigationDestination(for: Employee.self) { employee in
                EmployeeDetailView(
                    vm: EmployeeDetailViewModel(
                        employee: employee,
                        designations: vm.allDesignations,
                        departments: vm.allDepartments
                    ),
                    onUpdate: { updated in
                        vm.updateEmployee(updated)
                    }
                )
            }

            // 👆 dismiss keyboard
            .simultaneousGesture(
                TapGesture().onEnded {
                    isFocused = false
                }
            )
            
            // 🚀 Initial load
            .task(id: "one time"){
                await vm.loadInitial()
                await vm.filters()
            }

            // 🧰 Toolbar
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {

                    Button {
                        showFilterSheet = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }

                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }

            // ➕ Add Employee
            .sheet(isPresented: $showAddSheet) {
                AddEmployeeView(
                    departments: vm.allDepartments,
                    designations: vm.allDesignations
                ) { newEmployee in
                    vm.addEmployee(newEmployee)
                }
            }

            // 🎯 Filters
            .sheet(isPresented: $showFilterSheet) {
                FilterView(
                   
                    designations: vm.allDesignations,
                    departments: vm.allDepartments,
                    statuses: vm.allStatuses,

                    // ✅ PASS CURRENT STATE
                    selectedDesignations: vm.selectedDesignations,
                    selectedDepartments: vm.selectedDepartments,
                    selectedStatuses: vm.selectedStatuses
                ) { designations, departments, statuses in

                    vm.selectedDesignations = designations
                    vm.selectedDepartments = departments
                    vm.selectedStatuses = statuses

                    Task {
                        await vm.performSearch()
                    }
                }
            }
        }
    }
}

extension HomeView {

    @ViewBuilder
    private var contentView: some View {

        
        if (vm.isLoading && vm.hasLoadedInitially) || (vm.isLoading && vm.displayEmployees.isEmpty){
            List {
                ForEach(0..<10, id: \.self) { _ in
                    ShimmerRowView()
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                }
            }
            .listStyle(.plain)
            .allowsHitTesting(false)
        }
        else {
            
            if !vm.isLoading && vm.displayEmployees.isEmpty {
                EmptyStateView()
            }
            else if vm.showNewBanner {
                Button {
                    vm.showNewBanner = false
                } label: {
                    Text("New employees available")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                }
            }
            listView
        }
    }
}
extension HomeView {

    private var listView: some View {

        List {

            ForEach(vm.displayEmployees, id: \.id) { employee in

                EmployeeRowView(employee: employee)
                    .id(employee.id)
                    .onAppear {
                        // SIMPLE PAGINATION TRIGGER
                        if employee.id == vm.displayEmployees.last?.id {
                            Task {
                                if vm.isSearchingOrFiltering {
                                    Task { await vm.performSearchLoadMore() }
                                } else {
                                    Task { await vm.loadMore() }
                                }
                            }
                        }
                    }

                    .onTapGesture {
                        path.append(employee)
                    }

                    .contentShape(Rectangle())
            }
            .onDelete(perform: vm.deleteEmployee)

            if vm.isPaginatingUI{
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .id(UUID())
            }
        }
        .listStyle(.plain)
        .scrollDismissesKeyboard(.immediately)

        //  CLEAN REFRESH (no syncManager here anymore)
        .refreshable {
            Task {
                await vm.refresh()
            }
        }
    }
}
