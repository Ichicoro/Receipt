//  AcknowledgementsView.swift
//  Receipt

import SwiftUI

struct AcknowledgementsView: View {
    struct LicenseStruct {
        var title: String
        var filename: String
    }
    
    @State private var licenseTexts: [(name: String, text: String)] = []

    func loadLicenses() {
        // Add all license filenames here
        let licenses = [
            LicenseStruct(title: "FocusOnAppear", filename: "FocusOnAppear_LICENSE"),
            LicenseStruct(title: "SpaceMono (Open font license)" ,filename: "OFL.txt")
        ]
        var loaded: [(String, String)] = []
        for license in licenses {
            if let url = Bundle.main.url(forResource: license.filename, withExtension: nil),
               let text = try? String(contentsOf: url, encoding: .utf8) {
                loaded.append((license.title, text))
            }
        }
        self.licenseTexts = loaded
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                ForEach(licenseTexts, id: \.name) { license in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(license.name)
                            .font(.custom("SpaceMono-Regular", size: 18))
                        Text(license.text)
                            .font(.custom("SpaceMono-Regular", size: 15))
                            .textSelection(.enabled)
                            .padding(5)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Acknowledgements")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadLicenses)
        .font(.custom("SpaceMono-Regular", size: 16))
    }
}

#Preview {
    NavigationView {
        AcknowledgementsView()
    }
}
