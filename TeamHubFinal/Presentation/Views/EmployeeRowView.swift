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
 
    var body: some View {
        HStack(spacing: 12) {
            if let raw = employee.imgUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
               let url = URL(string: raw) {
                KFImage(url)
                    .placeholder {
                        fallbackAvatar
                    }
                    .onFailure { error in
                        print("❌ Image load failed: \(error)")
                    }
                    .retry(maxCount: 2, interval: .seconds(1))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                fallbackAvatar
            }

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
        let comps = employee.name.split(separator: " ")
        return comps.prefix(2)
            .compactMap { $0.first }
            .map { String($0) }
            .joined()
    }
}

