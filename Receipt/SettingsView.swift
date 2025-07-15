//
//  SettingsView.swift
//  Receipt
//
//  Created by Zelda on 15/07/25.
//

import SwiftUI
import SwiftData

struct CodableItem: Codable, Identifiable {
    var id: UUID { uuid }
    let uuid: UUID
    let text: String
    let timestamp: Date
    
    init(item: Item) {
        self.uuid = item.uuid
        self.text = item.text
        self.timestamp = item.timestamp
    }
}

struct ShareURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    @State private var shareURL: ShareURL?
    
    @State private var showDeletionWarning: Bool = false
    
    var entries: [Item] { items.reversed() }
    
    func backupToFileAndShare() {
        let codableItems = items.map { CodableItem(item: $0) }
        do {
            let data = try JSONEncoder().encode(codableItems)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("ReceiptBackup_\(Date().timeIntervalSince1970).receipts")
            try data.write(to: tempURL)
            shareURL = ShareURL(url: tempURL)
        } catch {
            // Optionally, handle error with an alert
            print("Failed to back up: \(error)")
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Info") {
                    Text("There are \(items.count) entries")
                }
                
                Section("Entry backup & restore") {
                    Button("Backup entries") {
                        backupToFileAndShare()
                    }
                    Button("Restore entries") {}
                }
                
                Section("DANGER ZONE!") {
                    Button("Remove all entries", role: .destructive) {
                        showDeletionWarning = true
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Are you sure you want to remove all entries?", isPresented: $showDeletionWarning) {
                Button("Cancel", role: .cancel) {
                    showDeletionWarning = false
                }
                Button("Delete all entries", role: .destructive) {
                    showDeletionWarning = false
                    for item in items {
                        modelContext.delete(item)
                    }
                }
            } message: {
                Text("There is no going back!")
            }
        }
        .font(.custom("SpaceMono-Regular", size: 16))
        .sheet(item: $shareURL, onDismiss: { shareURL = nil }) { shareURL in
            ShareSheet(url: shareURL.url)
        }
    }
}

#Preview {
    SettingsView().modelContainer(for: Item.self)
}
