//
//  ThemeManager.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 29/03/26.
//

import Foundation
import SwiftUI
import Combine
//final class ThemeManager: ObservableObject {
//
//    @AppStorage("isDarkMode") private var stored = false
//
//    @Published var isDarkMode: Bool = false
//
//    init() {
//        isDarkMode = stored
//    }
//
//    func toggle() {
//        isDarkMode.toggle()
//        stored = isDarkMode
//        print("🌗 Theme:", isDarkMode ? "Dark" : "Light")
//    }
//
//    var scheme: ColorScheme {
//        isDarkMode ? .dark : .light
//    }
//}
import SwiftUI

final class ThemeManager: ObservableObject {

    // 🔥 Persisted value
    @AppStorage("isDarkMode") private var storedIsDarkMode: Bool = false

    // 🔥 Exposed state
    @Published var isDarkMode: Bool = false

    init() {
        isDarkMode = storedIsDarkMode
    }

    func toggle() {
        isDarkMode.toggle()
        storedIsDarkMode = isDarkMode
        print("🌗 Theme changed: \(isDarkMode ? "Dark" : "Light")")
    }

    var colorScheme: ColorScheme {
        isDarkMode ? .dark : .light
    }
}
