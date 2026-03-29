//
//  HomeView.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 24/03/26.
//

import SwiftUI

struct HomeView: View {
    
    @StateObject private var vm: HomeViewModel
    @State private var path = NavigationPath()
    @FocusState private var isFocused: Bool
    @EnvironmentObject private var network: NetworkMonitor
    @State private var showFilterSheet = false
    @State private var showAddSheet = false
    @EnvironmentObject private var theme: ThemeManager
    init(vm: HomeViewModel) {
        _vm = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                
//                // 🔍 Search Bar
//                SearchBarView(
//                    text: $vm.searchQuery,
//                    onChange: vm.onSearchChanged,
//                    isFocused: $isFocused
//                )
//
                HStack {

                    SearchBarView(
                        text: $vm.searchQuery,
                        onChange: vm.onSearchChanged,
                        isFocused: $isFocused
                    )

                    Button {
                        withAnimation {
                            theme.toggle()
                        }
                    } label: {
                        Image(systemName: theme.isDarkMode ? "moon.fill" : "sun.max.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 40, height: 40)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
//                .padding(.horizontal)
//                .padding(.vertical, 6)
                
                
                contentView
            }
            .navigationTitle("Employees")
            .navigationDestination(for: Employee.self) { employee in
                EmployeeDetailView(
                    vm: EmployeeDetailViewModel(employee: employee),
                    onUpdate: { updated in
                        vm.updateEmployee(updated)
                    }
                )
            }
            .simultaneousGesture(
                TapGesture().onEnded {
                    isFocused = false
                }
            )
            .task {
                await vm.loadInitial()
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
//                        showFilterSheet = true
                        Task {

                              // ✅ Check cache FIRST
                              if vm.cachedFilters != nil {
                                  showFilterSheet = true
                                  return
                              }

                              // 🔥 First time → fetch
                              await vm.prepareFilters()
                              showFilterSheet = true
                          }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    Button {
                               showAddSheet = true
                           } label: {
                               Image(systemName: "plus")
                           }
                    
//                    Button {
//                        withAnimation {
//                            theme.toggle()
//                        }
//                    } label: {
//                        Image(systemName: theme.isDarkMode ? "moon.fill" : "sun.max.fill")
//                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddEmployeeView { newEmployee in
                    vm.addEmployee(newEmployee)
                }
            }
            .sheet(isPresented: $showFilterSheet) {
                FilterView(
                       vm: FilterViewModel(
                           repo: vm.repo,
                           network: network,
                           initialFilters: vm.cachedFilters // 🔥 pass preloaded
                       )
                   ) { designations, departments, statuses in

                    vm.applyFilters(
                        designations: Array(designations),
                        departments: Array(departments),
                        statuses: Array(statuses)
                    )
                }
            }
        }
    }
}

// MARK: - 🔹 VIEW EXTENSIONS

extension HomeView {
    
    @ViewBuilder
    private var contentView: some View {
        
        if vm.employees.isEmpty && vm.state == .loading {
            ProgressView()
                .frame(maxHeight: .infinity)
        }
        else if vm.employees.isEmpty {
            EmptyStateView()
        }
        else {
            listView
        }
    }
}

extension HomeView {
    
    private var listView: some View {
        List {
            ForEach(vm.employees) { employee in
                EmployeeRowView(employee: employee)
                    
                    .onAppear {
                        Task {  vm.loadMoreIfNeeded(currentItem: employee, ) }
                    }
                    .onTapGesture {
                        path.append(employee)
                    }
                    .contentShape(Rectangle())
            }
            .onDelete(perform: vm.deleteEmployee)
            
            if vm.state == .loading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .listStyle(.plain)
        .refreshable {
            await vm.loadInitial()
        }
    }
}

//#Preview {
//    HomeView()
//}

