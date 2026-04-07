//
//  AvatarView.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 07/04/26.
//
import SwiftUI
import Foundation
import Kingfisher

struct AvatarView: View {
    let url: URL?
    let initials: String

    let size: CGFloat 

    var body: some View {
        ZStack {
            if let url {
                KFImage(url)
                    .placeholder { initialsView }
                    .onFailure { _ in } // falls through to placeholder
                    .resizable()
                    .scaledToFill()
            } else {
                initialsView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color(.systemGray4), lineWidth: 1))
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(Color(.gray).opacity(0.15))
            Text(initials)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.gray)
        }
    }
}
