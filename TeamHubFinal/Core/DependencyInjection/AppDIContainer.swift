//
//  AppDIContainer.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 24/03/26.
//

import Foundation

final class AppDIContainer{
    private lazy var api: APIClient = URLSessionAPIClient()
    private lazy var core: CoreDataStacking = CoreDataStack.shared
    private lazy var remote: EmployeeRemoteDataSourceProtocol =
            EmployeeRemoteDataSource(api: api)
    private lazy var network: NetworkMonitoring = NetworkMonitor()
    private lazy var local: EmployeeLocalDataSourceProtocol =
           EmployeeLocalDataSource(stack: core)
        private lazy var repo: EmployeeRepositoryProtocol =
            EmployeeRepository(remote: remote, local: local)

        func makeHome() -> HomeView {
            HomeView(
                       vm: HomeViewModel(
                           repo: repo,
                           network: network,
                           syncManager: syncManager
                       )
                   )
        }
    var networkMonitor: NetworkMonitoring {
            network
        }
    
    lazy var syncManager: SyncManaging = SyncManager(
        repo: repo,
        network: networkMonitor
    )

}
