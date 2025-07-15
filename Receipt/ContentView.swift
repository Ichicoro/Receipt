//
//  ContentView.swift
//  Receipt
//
//  Created by Zelda on 15/07/25.
//

import SwiftUI
import SwiftData
import FocusOnAppear

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

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    var entries: [Item] { items.reversed() }
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showInputSheet = false
    @State private var inputText = ""
    @State private var showAreYouSureDialog = false
    
    @State private var isSettingsOpen = false
    
    @FocusState private var focusedInput
    
    var actualTextLength: Int { inputText.trimmingCharacters(in: .whitespacesAndNewlines).count }
    
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
                .tint(.secondary)
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
            Button("Cancel", role: .cancel) { }
                .tint(.accent)
        } message: {
            Text("You have unsaved input. Discard it?")
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(entries) { item in
                    VStack {
                        HStack {
                            Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                                .foregroundStyle(.background)
                                .frame(alignment: .leading)
                                .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                                .background(.accent)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                            
                        Text(item.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: {isSettingsOpen = true}) {
                        Label("Settings", systemImage: "gear")
                    }
                    .sheet(isPresented: $isSettingsOpen, onDismiss: { isSettingsOpen = false }, content: {
                        SettingsView()
                    })
                }
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
            .tabViewBottomAccessory {
                Button(action: { showInputSheet = true }) {
                    Label("Add Item", systemImage: "plus")
                }
            }
            .navigationTitle("Receipt")
            .navigationBarTitleDisplayMode(.inline)
        } detail: {
            Text("Select an item")
        }
        .sheet(isPresented: $showInputSheet) {
            inputSheet
        }
        .font(.custom("SpaceMono-Regular", size: 16))
    }

    private func addItem() {
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

#Preview {
    ContentView()
        .modelContainer(for: Item.self)
}

