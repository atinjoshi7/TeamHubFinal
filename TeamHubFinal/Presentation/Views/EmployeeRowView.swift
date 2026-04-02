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
//            if let raw = employee.imgUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
//               let url = URL(string: raw) {
//                KFImage(url)
//                    .placeholder {
//                        fallbackAvatar
//                    }
//                    .onFailure { error in
//                        print("❌ Image load failed: \(error)")
//                    }
//                    .retry(maxCount: 2, interval: .seconds(1))
//                    .resizable()
//                    .scaledToFill()
//                    .frame(width: 50, height: 50)
//                    .clipShape(Circle())
//            } else {
//                fallbackAvatar
//            }
            AvatarView(
                   urlString: employee.imgUrl,
                   name: employee.name,
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



struct AvatarView: View {
    
    let urlString: String?
    let name: String
    let size: CGFloat
    
    var body: some View {
        
        if let url = validURL {
            KFImage(url)
                .placeholder {
                    fallback
                }
                .onFailure { error in
                    print("❌ Image load failed:", error)
                }
                .retry(maxCount: 2, interval: .seconds(1))
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            fallback
        }
    }
}

// MARK: - Helpers
extension AvatarView {
    
    private var validURL: URL? {
        guard let raw = urlString?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty,
              let url = URL(string: raw)
        else {
            return nil
        }
        return url
    }
    
    private var fallback: some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: size, height: size)
            .overlay(
                Text(initials)
                    .font(.headline)
                    .foregroundColor(.gray)
            )
    }
    
    private var initials: String {
        let comps = name.split(separator: " ")
        return comps.prefix(2)
            .compactMap { $0.first }
            .map { String($0) }
            .joined()
    }
}
