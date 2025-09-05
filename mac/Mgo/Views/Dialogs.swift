//
//  Dialogs.swift
//  Mgo
//
//  Created by Jose Dias on 25/12/2023.
//

import SwiftUI

struct NewItemSheetView: View {
    let title: String
    @Binding var showModal: Bool
    let command: (_ text: String) -> Void
    
    @State private var text: String = ""
    
    @EnvironmentObject var dataModel: DataModel
    
    var body: some View {
        VStack {
            Text(title)
                .font(.system(size: 20))
                .padding()
            
            Spacer()
            
            TextField(title, text: $text)
                .onSubmit {
                    command(self.text)
                    showModal = false
                }
            
            Spacer()
            
            HStack {
                Button(i18n.string(key: "ok")) {
                    command(self.text)
                    showModal = false
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.extraLarge)
                .keyboardShortcut(.defaultAction)
                
                Button(i18n.string(key: "cancel")) {
                    showModal = false
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.extraLarge)
                .keyboardShortcut(.cancelAction)
            }
            .padding()
        }
        .frame(minWidth: 150, minHeight: 150)
        .padding(30)
    }
}

struct EditItemSheetView: View {
    let title: String
    @Binding var showModal: Bool
    @Binding var item: GroupItem
    let command: (_ item: GroupItem) -> Void
            
    var body: some View {
        VStack {
            Text(title)
                .font(.system(size: 20))
                .padding()
            Spacer()
            TextField(title, text: $item.name)
            .onSubmit {
                command(self.item)
                showModal = false
            }
            
            
            Spacer()
            
            HStack {
                Button(i18n.string(key: "ok")) {
                    command(self.item)
                    showModal = false
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.extraLarge)
                .keyboardShortcut(.defaultAction)
                
                Button(i18n.string(key: "cancel")) {
                    showModal = false
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.extraLarge)
                .keyboardShortcut(.cancelAction)
            }
            .padding()
        }
        .frame(minWidth: 150, minHeight: 150)
        .padding(30)
    }
}

struct ImageSheetView: View {
    let title: String
    @Binding var showModal: Bool
    @Binding var resourceName: String
    
    @State var btext: String = ""
            
    var body: some View {
        VStack {
            Text(title)
                .font(.system(size: 20))
                .padding()
            Spacer()
            Image(resourceName)
                .resizable()  // Makes the image resizable
                .aspectRatio(contentMode: .fit) // Maintains the aspect ratio
                .frame(width: 450)
                .shadow(radius: 3)
            
            HStack {
                Button(i18n.string(key: "close")) {
                    showModal = false
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.extraLarge)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(minWidth: 650, minHeight: 350)
        .padding(30)
    }
}

struct InfoSheetView: View {
    let title: String
    @Binding var showModal: Bool
    var item: String
    
    @State var btext: String = ""
            
    var body: some View {
        VStack {
            Text(title)
                .font(.system(size: 20))
                .padding()
            Spacer()
            ZStack(alignment: .topLeading) {
                        TextEditor(text: $btext)
                            .font(.system(size: 16))
                            .opacity(0.5)
                            .padding(8) // External padding to create the illusion of internal padding
                            .onAppear{
                                self.btext = item
                            }
                    }
                    .frame(width: 600, height: 300)
                    .border(Color.gray, width: 1)
            Spacer()
            Text("Please send any errors to support@gepsoft.com. Thank you.")
            Spacer()
            
            HStack {
                Button(i18n.string(key: "copy")) {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(self.item, forType: .string)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.extraLarge)
                
                Button(i18n.string(key: "close")) {
                    showModal = false
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.extraLarge)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(minWidth: 650, minHeight: 350)
        .padding(30)
    }
}

struct OnboardSheetView: View {
    @Binding var showModal: Bool
                
    var body: some View {
        VStack {
            OnboardingView()
            HStack {
                Button(i18n.string(key: "close")) {
                    showModal = false
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.extraLarge)
                .keyboardShortcut(.defaultAction)
            }
        }
        .frame(minWidth: 650, minHeight: 350)
        .padding(30)
    }
}

struct AllGroupItemsListView: View {
    @Binding var showModal: Bool
    var itemList: [GroupItem]
    let OnSelected: (GroupItem) -> Void
                
    var body: some View {
        VStack {
            Text("Click one")
                .padding(5)
                .padding(.bottom, 10)
            ScrollView {
                ForEach(itemList) { t in
                    HStack {
                        Button(t.name) {
                            OnSelected(t)
                            showModal = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .frame(minWidth: 100)

            Button(i18n.string(key: "cancel")) {
                showModal = false
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.extraLarge)
            .keyboardShortcut(.defaultAction)
            .padding()
        }
        .frame(minWidth: 350, minHeight: 450)
        .padding(30)
    }
}
