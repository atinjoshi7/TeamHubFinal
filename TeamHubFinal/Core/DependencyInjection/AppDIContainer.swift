//
//  AppDIContainer.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 24/03/26.
//

import Foundation
import Combine
import SwiftUI

final class AppDIContainer{
    let syncState = SyncState()
    private lazy var api: APIClient = URLSessionAPIClient()
    
    private lazy var core: CoreDataStacking = CoreDataStack.shared
    
    private lazy var remote: EmployeeRemoteDataSourceProtocol =
    EmployeeRemoteDataSource(api: api)
    
    private lazy var network: NetworkMonitoring = NetworkMonitor()
    
  
    
    private lazy var local: EmployeeLocalDataSourceProtocol =
    EmployeeLocalDataSource(stack: core)
    
    lazy var syncManager: SyncManaging = SyncManager(
        repo: repo,
        network: network,
        syncState: syncState
    )
    
    private lazy var repo: EmployeeRepositoryProtocol =
    EmployeeRepository(remote: remote, local: local, network: network as! NetworkMonitor)
    
    func makeHome() -> HomeView {
        HomeView(
            vm: HomeViewModel(
                repo: repo,
                syncState: syncState,
                syncManager: syncManager,
                network: network as! NetworkMonitor
            )
        )
    }
    
    
  
    
}
