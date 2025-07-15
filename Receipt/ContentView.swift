//
//  ContentView.swift
//  Receipt
//
//  Created by Zelda on 15/07/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    @State private var showInputSheet = false
    @State private var inputText = ""
    @State private var showAreYouSureDialog = false
    
    @FocusState private var focusedInput: Bool
    
    var actualTextLength: Int { inputText.trimmingCharacters(in: .whitespacesAndNewlines).count }
    
    func pressCancel() {
        if inputText.trimmingCharacters(in: .whitespaces).count > 0 {
            showAreYouSureDialog = true
        } else {
            showInputSheet = false
            inputText = ""
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items.reversed()) { item in
                    VStack {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(1)
                            .background(.black)
                        Text(item.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {}) {
                        Label("Settings", systemImage: "gear")
                    }
                }
                
                ToolbarItem(placement: .bottomBar, content: {
                    Button(action: {
                        showInputSheet = true
                        focusedInput = true
                    }) {
                        Label("Add Item", systemImage: "plus")
                    }
                })
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
            VStack(spacing: 20) {
                TextField("What to print", text: $inputText, axis: .vertical)
                    .focused($focusedInput)
                    .onTapGesture {
                        if (!focusedInput) {
                            focusedInput = true
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .onAppear(perform: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                            focusedInput = true
                        })
                    })
                .scrollDismissesKeyboard(.never)
                .multilineTextAlignment(.leading)
                .padding(20)
                .background()
                .cornerRadius(20)

                HStack(spacing: 16) {
                    Button(action: {
                        pressCancel()
                    }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .tint(actualTextLength > 0 ? .red : .secondary)
                    .buttonStyle(.bordered)
                    .controlSize(.extraLarge)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    
                    Button(action: {
                        addItem()
                    }) {
                        Text("Add Item")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .tint(.black)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.extraLarge)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .disabled(actualTextLength == 0)
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
            } message: {
                Text("You have unsaved input. Discard it?")
            }
        }
        .font(.custom("SpaceMono-Regular", size: 16))
        .onChange(of: showInputSheet) { _, newValue in
            // Side effect when showInputSheet changes
            if newValue {
                focusedInput = true
            } else {
                inputText = ""
            }
        }
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
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self)
}

