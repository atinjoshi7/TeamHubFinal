//
//  SyncErrorState.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 16/04/26.
//

import Foundation
import Combine

final class SyncErrorStore: ObservableObject {
    static let shared = SyncErrorStore()

    @Published private var messagesByEmployeeID: [String: String]

    private let storageKey = "sync_error_messages"

    private init() {
        messagesByEmployeeID = UserDefaults.standard.dictionary(forKey: storageKey) as? [String: String] ?? [:]
    }

    func message(for employeeID: String) -> String? {
        let message = messagesByEmployeeID[employeeID]?.trimmingCharacters(in: .whitespacesAndNewlines)
        return message?.isEmpty == false ? message : nil
    }

    func hasError(for employeeID: String) -> Bool {
        message(for: employeeID) != nil
    }

    func setError(_ message: String, for employeeID: String) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.setError(message, for: employeeID)
            }
            return
        }

        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedMessage.isEmpty else {
            clearError(for: employeeID)
            return
        }

        messagesByEmployeeID[employeeID] = trimmedMessage
        persist()
    }

    func clearError(for employeeID: String) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.clearError(for: employeeID)
            }
            return
        }

        guard messagesByEmployeeID.removeValue(forKey: employeeID) != nil else { return }
        persist()
    }

    private func persist() {
        if messagesByEmployeeID.isEmpty {
            UserDefaults.standard.removeObject(forKey: storageKey)
        } else {
            UserDefaults.standard.set(messagesByEmployeeID, forKey: storageKey)
        }
    }
}
