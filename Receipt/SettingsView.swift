//
//  SettingsView.swift
//  Receipt
//
//  Created by Zelda on 15/07/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

//extension View {
//    func errorAlert(error: Binding<String?>, buttonTitle: String = "OK") -> some View {
//        return alert(isPresented: .constant(error != nil)) {
//            Button(buttonTitle) {
//                error.wrappedValue = nil
//            }
//        } message: { error in
//            Text(error ?? "")
//        }
//    }
//}

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

struct DocumentPicker: UIViewControllerRepresentable {
    var onDocumentsPicked: ([URL]) -> Void
    var contentTypes: [UTType] = [
        UTType(exportedAs: "public.receipts")
    ]
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onDocumentsPicked: onDocumentsPicked)
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes, asCopy: true)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onDocumentsPicked: ([URL]) -> Void
        init(onDocumentsPicked: @escaping ([URL]) -> Void) {
            self.onDocumentsPicked = onDocumentsPicked
        }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onDocumentsPicked(urls)
        }
    }
}

struct SettingsError {
    var title: String
    var message: String
}

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @AppStorage("colorTheme") private var colorThemeSelection: ColorTheme = ColorTheme.auto

    @Query private var items: [Item]
    
    @State private var shareURL: ShareURL?
    
    @State private var showDeletionWarning: Bool = false
    @State private var showingRestorePicker = false
    
    @State private var errorMessage: SettingsError?
    
    private var websiteUrl = URL(string: "https://zelda.sh")!
    @State private var showWebsiteSheet = false
    private var repoUrl = URL(string: "https://github.com/Ichicoro/Receipt")
    
    var shouldShowErrorMsg: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: {_ in errorMessage = nil }
        )
    }
    
    var entries: [Item] { items.reversed() }
    
    func backupToFileAndShare() {
        let codableItems = items.map { CodableItem(item: $0) }
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .millisecondsSince1970
            let data = try encoder.encode(codableItems)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("ReceiptBackup_\(Date().timeIntervalSince1970).receipts")
            try data.write(to: tempURL)
            shareURL = ShareURL(url: tempURL)
        } catch {
            // Optionally, handle error with an alert
            print("Failed to back up: \(error)")
            errorMessage = SettingsError(title: "Failed to create backup", message: error.localizedDescription)
        }
    }
    
    func restoreFromBackup(url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .millisecondsSince1970
            let codableItems = try decoder.decode([CodableItem].self, from: data)
            for codable in codableItems {
                let existingItems = try modelContext.fetch(.init(predicate: #Predicate<Item> { $0.uuid == codable.uuid }))
                if let existing = existingItems.first {
                    existing.text = codable.text
                    existing.timestamp = codable.timestamp
                    // No need to insert, just updated in context
                } else {
                    let newItem = Item(uuid: codable.uuid, text: codable.text, timestamp: codable.timestamp)
                    modelContext.insert(newItem)
                }
            }
        } catch {
            print("Failed to restore backup: \(error)")
            errorMessage = SettingsError(title: "Failed to restore backup", message: error.localizedDescription)
        }
    }
    
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button(action: { dismiss() }) {
                if #available(iOS 26, *) {
                    Label("Done", systemImage: "checkmark")
                } else {
                    Text("Done")
                }
            }
            .tint(.accent)
        }
    }
    
    var acknowledgementsSection: some View {
        Group {
            ChevronLink(url: websiteUrl.absoluteString, label: {
                VStack(alignment: .leading) {
                    Text("Made with <3 by Zelda!")
                    Text("(Opens https://zelda.sh)")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            })
            ChevronLink(
                url: repoUrl!.absoluteString,
                label: { Text("GitHub Repo") }
            )
            NavigationLink(destination: AcknowledgementsView()) {
                Text("Licenses")
            }
        }
    }
    
    // Info section
    private var infoSection: some View {
        Section("Info") {
            Text("There are \(items.count) entries")
        }
    }
    
    // Preferences section
    private var preferencesSection: some View {
        Section("Preferences") {
            HStack {
                Text("App theme")
                Spacer()
                ZStack {
                    Picker(selection: Binding(
                        get: { colorThemeSelection },
                        set: { colorThemeSelection = $0 }
                    ), content: {
                        Label("Auto", systemImage: "wand.and.sparkles").tag(ColorTheme.auto)
                        Label("Light", systemImage: "sun.max.fill").tag(ColorTheme.light)
                        Label("Dark", systemImage: "moon.fill").tag(ColorTheme.dark)
                    }, label: {
                        HStack {
                            Text(colorThemeSelection.rawValue.capitalized)
                            Image(systemName: "chevron.down")
                        }.opacity(0)
                    }).tint(.accent).opacity(0)
                    HStack {
                        Spacer()
                        Text(colorThemeSelection.rawValue.capitalized)
                        Image(systemName: "chevron.down")
                    }.frame(alignment: .trailing)
                }.frame(alignment: .trailing)
            }
        }
    }
    
    // Backup & Restore section
    private var backupSection: some View {
        Section("Entry backup & restore") {
            Button("Backup entries") {
                backupToFileAndShare()
            }
            Button("Restore entries") {
                showingRestorePicker = true
            }
        }
    }
    
    // Danger Zone section
    private var dangerZoneSection: some View {
        Section(content: {
            Button("Remove all entries", role: .destructive) {
                showDeletionWarning = true
            }
        }, header: {
            Text("DANGER ZONE!")
        }, footer: {
            Text("Make sure you've made a backup, since there's no going back!")
                .font(.system(size: 13))
        })
    }
    
    // Miscellaneous section
    private var miscellaneousSection: some View {
        Section(
            content: {
                acknowledgementsSection
            },
            header: {
                Text("Miscellaneous")
            },
            footer: {
                HStack {
                    Text("Through the darkness of future past,\nthe magician longs to see,\none chance out between two worlds,\nfire walk with me!")
                        .font(.system(size: 13, type: .Italic))
                        .padding(.top, 5)
                }
            }
        )
    }
    
    // Deletion alert
    private var deletionAlert: some View {
        EmptyView()
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
    
    // Error alert
    private var errorAlert: some View {
        EmptyView()
            .alert(errorMessage?.title ?? "???", isPresented: shouldShowErrorMsg, actions: {
                Button("Ok", role: .cancel, action: {
                    errorMessage = nil
                })
            }, message: {
                Text("\(errorMessage?.message ?? "???")")
            })
    }
    
    var body: some View {
        NavigationView {
            Form {
                infoSection
                preferencesSection
                backupSection
                dangerZoneSection
                miscellaneousSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbar
            }
        }
        .font(.system(size: 16))
        .sheet(item: $shareURL, onDismiss: { shareURL = nil }) { shareURL in
            ShareSheet(url: shareURL.url)
        }
        .sheet(isPresented: $showingRestorePicker) {
            DocumentPicker(
                onDocumentsPicked: { urls in
                    showingRestorePicker = false
                    if let url = urls.first {
                        restoreFromBackup(url: url)
                    }
                }
            )
        }
        .overlay(deletionAlert)
        .overlay(errorAlert)
    }
}

#Preview {
    @Previewable @AppStorage("colorTheme") var colorThemeSelection: ColorTheme = ColorTheme.auto
    
    SettingsView()
        .preferredColorScheme(colorThemeSelection.colorScheme)
        .modelContainer(for: Item.self)
}

