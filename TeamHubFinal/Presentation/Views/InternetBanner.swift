//
//  InternetBanner.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 13/04/26.
//

import SwiftUI

struct InternetBannerView: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "wifi.slash")
                .font(.caption2)

            Text("Offline")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color.red)
        .clipShape(Capsule())
    }
}
