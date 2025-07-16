//
//  ChevronLink.swift
//  Scontrino
//
//  Created by Zelda on 16/07/25.
//

import SwiftUI

struct ChevronLink<Label: View>: View {
    @Environment(\.openURL) private var openURL
    
    let url: String
    let label: Label
    
    init(url: String, @ViewBuilder label: () -> Label) {
        self.url = url
        self.label = label()
    }
    
    var body: some View {
        NavigationLink(destination: EmptyView(), label: {
            Button(
                action: { openURL(URL(string: url)!) }
            ) {
                label.tint(.accent)
            }
        })
    }
}
//
//#Preview {
//    ChevronLink(url: "https://zelda.sh") { Text("Open Zelda") }
//}
