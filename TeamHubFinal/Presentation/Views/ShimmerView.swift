//
//  ShimmerView.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 05/04/26.
//

import SwiftUI

// ShimmerRowView.swift
struct ShimmerRowView: View {
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 160, height: 14)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray6))
                    .frame(width: 100, height: 12)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .opacity(animating ? 0.4 : 1.0)
        .animation(.easeInOut(duration: 0.9).repeatForever(), value: animating)
        .onAppear { animating = true }
    }
}
