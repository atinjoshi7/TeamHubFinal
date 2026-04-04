//
//  HomeView.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 24/03/26.
//
import SwiftUI

struct HomeView: View {

    @Environment(\.scenePhase) private var scenePhase
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
                            Task { await vm.performSearch() }
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
                    vm: EmployeeDetailViewModel(employee: employee),
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
            .task {
                await vm.filters()
                await vm.loadInitial()
               
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
                    vm: FilterViewModel(
                        repo: vm.repo,
                        network: network,
                        initialFilters: nil
                    )
                ) { designations, departments, statuses in

                    vm.selectedDesignations = designations
                    vm.selectedDepartments = departments
                    vm.selectedStatuses = statuses

                    Task {
                        await vm.performSearch()
                    }
                }
            }
//            .onChange(of: scenePhase) { _, phase in
//                if phase == .active {
//                    Task {
//                        await vm.repo.syncFromServer()
//                    }
//                }
//            }
        }
    }
}

extension HomeView {

    @ViewBuilder
    private var contentView: some View {

        if vm.isLoading {
               ProgressView()
                   .frame(maxHeight: .infinity)
           }
//           else if vm.displayEmployees.isEmpty {
//               EmptyStateView()
//           }
        else {
            if vm.showNewBanner {
                Button {
                    vm.showNewBanner = false

                    // scroll to top OR reload
                    Task {
                        await vm.loadInitial()
                    }

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

            ForEach(vm.displayEmployees) { employee in

                EmployeeRowView(employee: employee)

                    .onAppear {
                        // SIMPLE PAGINATION TRIGGER
                        if employee.id == vm.displayEmployees.last?.id {
                            Task { await vm.loadMore() }
                        }
                    }

                    .onTapGesture {
                        path.append(employee)
                    }

                    .contentShape(Rectangle())
            }
            .onDelete(perform: vm.deleteEmployee)

            if vm.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
        .listStyle(.plain)
        .scrollDismissesKeyboard(.immediately)

        // 🔥 CLEAN REFRESH (no syncManager here anymore)
        .refreshable {
            await vm.refresh()
        }
    }
}
