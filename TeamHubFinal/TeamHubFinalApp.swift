//
//  TeamHubFinalApp.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 24/03/26.
//

import SwiftUI
import CoreData

@main
struct TeamHubFinalApp: App {
    
    let container = AppDIContainer()
    @StateObject private var network = NetworkMonitor()
    @StateObject private var themeManager = ThemeManager()
   

    var body: some Scene {
        WindowGroup {
            container.makeHome()
                .environmentObject(network)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
                
                
        }
    }
}
