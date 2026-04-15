//
//  EmployeeRowView.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 24/03/26.
//

import SwiftUI
import Kingfisher
struct EmployeeRowView: View {
    let employee: Employee
    let hasSyncError: Bool
   
    var body: some View {
        HStack(spacing: 12) {
            AvatarView(
                url: ImageURLHelper.validURL(from: employee.imgUrl ?? ""),
                   initials: initials,
                  size: 50
               )
            VStack(alignment: .leading, spacing: 4) {
                Text(employee.name)
                    .font(.headline)

                Text("\(employee.designation) • \(employee.department)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(employee.isActive ? "Active" : "Inactive")
                    .font(.caption)
                    .foregroundColor(employee.isActive ? .green : .red)
            }

            Spacer(minLength: 8)

            if hasSyncError {
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                    .accessibilityLabel("Sync error")
            }
        }
        .padding(.vertical, 6)
    }
    private var fallbackAvatar: some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 50, height: 50)
            .overlay(
                Text(initials)
                    .font(.headline)
                    .foregroundColor(.gray)
            )
    }

    private var initials: String {
        let words = employee.name
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        
        switch words.count {
        case 0: return "?"
        case 1: return String(words[0].prefix(1)).uppercased()
        default: return (String(words[0].prefix(1)) + String(words[1].prefix(1))).uppercased()
        }
    }
}
struct ImageURLHelper {
    
    static func validURL(from string: String?) -> URL? {
        guard
            let string,
            !string.isEmpty,
            let url = URL(string: string),
            url.scheme == "https" || url.scheme == "http"
        else { return nil }
        
        return url
    }
}
