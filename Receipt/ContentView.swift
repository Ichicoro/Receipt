//
//  ContentView.swift
//  Receipt
//
//  Created by Zelda on 15/07/25.
//

import FocusOnAppear
import SwiftData
import SwiftUI

//import AVKit
//import CoreHaptics

struct SubmitButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .padding()
            .background(.accent)
            .foregroundColor(colorScheme == .dark ? .black : .white)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring, value: configuration.isPressed)
            .controlSize(.extraLarge)
    }
}

struct CancelButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .tint(.secondary)
            .padding()
            .background(.secondary)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring, value: configuration.isPressed)
            .controlSize(.extraLarge)
    }
}

struct LogItemView: View {
    let item: Item
    
    var date: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE dd/MM/yyyy, HH:mm"
        return dateFormatter.string(from: item.timestamp).uppercased()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                HStack {
                    Text(date)
                }
                .foregroundStyle(.background)
                .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                .background(.accent)
            }
            
            Text(item.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    @State private var selection: Set<UUID> = []
    //    @State private var engine: CHHapticEngine?
    
    let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
    
    var entries: [Item] {
        items.sorted(by: { item1, item2 in
            item1.timestamp > item2.timestamp
        })
    }
    
    @Environment(\.colorScheme) var colorScheme
    
    @AppStorage("colorTheme") private var colorThemeSelection: ColorTheme = ColorTheme.auto
    
    @State private var showInputSheet = false
    @State private var inputText = ""
    @State private var showAreYouSureDialog = false
    
    @State private var isSettingsOpen = false
    
    @FocusState private var focusedInput
    
    var actualTextLength: Int { inputText.trimmingCharacters(in: .whitespacesAndNewlines).count }
    
    var bottomListPadding: CGFloat {
        if #available(iOS 26, *) {
            return 25
        } else {
            return 80
        }
    }
    
    //    init() {
    //        prepareHaptics()
    //    }
    
    //    func prepareHaptics() {
    //        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
    //            print("Haptics not supported")
    //            return
    //        }
    //
    //        do {
    //            let audioSession = AVAudioSession.sharedInstance()
    //            try audioSession.setCategory(.ambient)
    //            engine = try CHHapticEngine(audioSession: audioSession)
    //            engine?.stoppedHandler = { _ in
    //                print("Stopped engine")
    //            }
    //            try engine?.start()
    //            print("Engine started")
    //        } catch {
    //            print("There was an error creating the engine: \(error.localizedDescription)")
    //        }
    //    }
    
    //    func playAHAP(filename: String) {
    //        print("Playing AHAP \(filename)")
    //        guard let engine = self.engine else {
    //            print("Engine not found")
    //            return
    //        }
    //        guard let path = Bundle.main.path(forResource: filename, ofType: "ahap") else {
    //            print("File not found")
    //            return
    //        }
    //
    //        do {
    //            try engine.start() // Start the engine if it's not already running
    //            try engine.playPattern(from: URL(fileURLWithPath: path))
    //        } catch {
    //            print("Failed to play pattern: \(error.localizedDescription)")
    //        }
    //    }
    
    func pressCancel() {
        if inputText.trimmingCharacters(in: .whitespaces).count > 0 {
            showAreYouSureDialog = true
        } else {
            showInputSheet = false
            inputText = ""
        }
    }
    
    var inputSheet: some View {
        VStack(spacing: 20) {
            TextField("What to print", text: $inputText, axis: .vertical)
                .focusOnAppear()
                .focused($focusedInput)
                .frame(maxHeight: .infinity, alignment: .top)
                .scrollDismissesKeyboard(.never)
                .multilineTextAlignment(.leading)
                .padding(20)
                .background(.regularMaterial)
                .cornerRadius(20)
            
            HStack(spacing: 16) {
                Button(action: {
                    pressCancel()
                }) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(CancelButtonStyle())
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                
                Button(action: {
                    addItem()
                }) {
                    Text("Add Item")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .disabled(actualTextLength == 0)
                .buttonStyle(SubmitButtonStyle())
                .opacity(actualTextLength == 0 ? 0.50 : 1.0)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                //                .sensoryFeedback(.success, trigger: isCreateButtonPressed)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .presentationDetents([.fraction(0.35)])
        .interactiveDismissDisabled()
        .alert("Are you sure you want to discard your input?", isPresented: $showAreYouSureDialog) {
            Button("Discard", role: .destructive) {
                showInputSheet = false
                inputText = ""
                showAreYouSureDialog = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You have unsaved input. Discard it?")
        }
    }
    
    var body: some View {
        NavigationSplitView {
            Group {
                if entries.count > 0 {
                    List(selection: $selection) {
                        Section(
                            content: {
                                ForEach(entries) { item in
                                    LogItemView(item: item)
                                }
                                .onDelete(perform: deleteItems)
                                .swipeActions {}
                            },
                            footer: {
                                HStack {
                                    Text("You've reached the end of your adventure.")
                                        .font(.system(size: 13))
                                }
                                .padding(.bottom, bottomListPadding)
                            })
                    }
                } else {
                    HStack {
                        Text("No entries. Might be time to create one! :D")
                            .foregroundStyle(.gray)
                            .padding(50)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    if (selection.count > 0) {
                        Button(action: {}) {
                            Label("Done", systemImage: "checkmark")
                        }
                    }
                    Button(action: { isSettingsOpen = true }) {
                        Label("Settings", systemImage: "gear")
                    }
                    .sheet(
                        isPresented: $isSettingsOpen, onDismiss: { isSettingsOpen = false },
                        content: { SettingsView() })
                }
                if #available(iOS 26, *) {
                    ToolbarItem(placement: .bottomBar) {
                        Button(action: {
                            showInputSheet = true
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Add receipt")
                            }
                            .padding(5)
                        }
                    }
                }
            }
            .safeTabViewBottomAccessory(showInputSheet: $showInputSheet) {
                Button(action: { showInputSheet = true }) {
                    Label("Add receipt", systemImage: "pencil")
                }
            }
            .navigationTitle(appName ?? "Scontrino")
            .navigationBarTitleDisplayMode(.inline)
        } detail: {
            Text("Select an item")
        }
        .sheet(isPresented: $showInputSheet) {
            inputSheet
        }
        .font(.system(size: 16))
        .tint(.accent)
    }
    
    private func addItem() {
        //        playAHAP(filename: "printer-106935-cut.transient")
        //        isCreateButtonPressed = !isCreateButtonPressed
        withAnimation {
            let newItem = Item(uuid: UUID(), text: inputText, timestamp: Date())
            modelContext.insert(newItem)
            do {
                try modelContext.save()
                inputText = ""
                showInputSheet = false
            } catch {
                // Optionally log or handle the error
                print("Failed to save item: \(error)")
                // You might wish to show an error alert to the user here
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(entries[index])
            }
        }
    }
}

extension View {
    @ViewBuilder
    func safeTabViewBottomAccessory<Content: View>(
        showInputSheet: Binding<Bool>, @ViewBuilder content: () -> Content
    ) -> some View {
        if #available(iOS 26, *) {
            self
        } else {
            ZStack {
                self
                VStack {
                    Spacer()
                    HStack {
                        Button(action: { showInputSheet.wrappedValue = true }) {
                            Label("Add receipt", systemImage: "pencil").imageScale(.large)
                        }
                        .buttonStyle(SubmitButtonStyle())
                        .padding(.bottom, -4)
                        .shadow(radius: 4)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self)
}
