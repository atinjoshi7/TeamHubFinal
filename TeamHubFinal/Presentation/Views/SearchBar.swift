//
//  SearchBar.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 24/03/26.
//

import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    var onChange: (String) -> Void
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")

            TextField("Search employees...", text: $text)
                .focused($isFocused)
                .onChange(of: text) { _ , newValue in
                    onChange(newValue)
                }

            if !text.isEmpty {
                Button {
                    text = ""
                    onChange("")
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding()
    }
}
