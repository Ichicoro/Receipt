//
//  ChevronLink.swift
//  Scontrino
//
//  Created by Zelda on 16/07/25.
//

import SwiftUI

struct ChevronLink<Label: View>: View {
    @Environment(\.openURL) private var openURL
    
    @State private var showSheet = false
    
    let url: String
    let label: Label
    
    init(url: String, @ViewBuilder label: () -> Label) {
        self.url = url
        self.label = label()
    }
    
    var body: some View {
        Button(action: { showSheet = true }) {
            HStack {
                label
                Spacer(minLength: 6)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .opacity(0.3)
//                    .padding(.trailing, 1)
            }
            .contentShape(Rectangle())
            .tint(.accent)
        }
        .fullScreenCover(isPresented: $showSheet, content: {
            SafariView(url: URL(string: url)!)
                .ignoresSafeArea()
        })
    }
}

#Preview {
    NavigationView {
        Form {
            Section("Info") {
                ChevronLink(url: "https://zelda.sh", label: { Text("Chevron!") })
                NavigationLink(destination: EmptyView(), label: { Text("Navigation!") })
            }
        }
    }
}
