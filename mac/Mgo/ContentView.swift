//
//  ContentView.swift
//  Mgo
//
//  Created by Jose Dias on 01/12/2023.
//
import SwiftUI

enum DetailMode {
    case view
    case edit
    case browse
}

struct ContentView: View {
    @EnvironmentObject var dataModel: DataModel
    @Environment(\.colorScheme) var colorScheme
        
    @Binding var showLog: Bool
    @Binding var showOnboard: Bool
    @Binding var showTagList: Bool
    @Binding var showFolderList: Bool
    
    @State private var mode: DetailMode = DetailMode.view
    
    @State private var listViewWidth: CGFloat = 500 // Initial width of listView
    @State private var searchInWebPage: String = ""
        
    @StateObject private var webViewState = WebViewState(urlString: "https://gepsoft.com")

    var body: some View {
        
        NavigationView {
            SidebarView()
                .toolbar{
                    ToolbarItem(placement: .navigation) {
                                        Button(action: toggleSidebar) {
                                            Image(systemName: "sidebar.left")
                                        }
                                    }
                }
                .frame(minWidth: 250)
            
            VStack {
                if dataModel.hasDatabaseOpen && !dataModel.isDatabaseEmpty {
                    if dataModel.isLoading {
                        Text("Loading conversations...")
                        ProgressView()
                    }
                    else {
                        GeometryReader { geometry in
                            HStack(spacing: 0) {
                                MasterView()
                                    .frame(width: listViewWidth)
                                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))
                                                     
                                DividerView(listViewWidth: $listViewWidth, geometrySizeWidth: geometry.size.width)

                                ZStack {
                                    if mode == .view {
                                        ConversationDetailView()
                                            .transition(.opacity)
                                    } else if mode == .edit {
                                        ConversationDetailEditView(conversation: $dataModel.currentConversation)
                                            .transition(.opacity)
                                    } else if mode == .browse {
                                        WebView(webView: webViewState.webView)
                                                .transition(.opacity)
                                    }
                                }
                                .frame(width: geometry.size.width - listViewWidth - 10)
                                .animation(Animation.easeInOut(duration: 0.3), value: mode) // Change duration here
                                
                            }
                        }
                    }
                }
                else {
                    //the app just started or all databases are closed
                    OnboardingView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    HStack {
                        SearchBarView(searchText: $dataModel.searchTerm, placeholder: i18n.string(key: "search.conversations"))
                            .padding(.leading, 5)
                            .disabled(!dataModel.hasDatabaseOpen)
                        Circle()
                            .fill(Color.clear)
                            .stroke(Color.gray, lineWidth: 1)
                            .frame(width: 25, height: 25) // Set the size of the circle
                            .overlay(
                                Text(String(dataModel.filteredConversations.count)) // Place the number as text on top of the circle
                                    .font(.system(size: 8)) // Set the font size to 10
                                    .foregroundColor(.gray) // Set the text color
                            )
                        Spacer()
                        Image(systemName: "arrow.up.arrow.down")
                            .resizable()
                            .disabled(!dataModel.hasDatabaseOpen)
                            .frame(width: 15, height: 15)
                            .foregroundColor(.secondary)
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 80))
                            .onHover { hovering in
                                if !dataModel.hasDatabaseOpen {
                                    return
                                }
                                if hovering {
                                    NSCursor.pointingHand.set() // Change cursor to pointing hand
                                } else {
                                    NSCursor.arrow.set() // Revert cursor to default
                                }
                            }
                            .onTapGesture {
                                if dataModel.hasDatabaseOpen {
                                    dataModel.toggleConversationSort()
                                }
                            }
                    }
                    .frame(minWidth: 490)
                }

                // Second custom toolbar item
                ToolbarItem(placement: .automatic) {
                    HStack {
                        
                        toobarModeImageView(icon: "doc.text", square: false, foregroundColor: mode == DetailMode.view ? .indigo : .secondary, onTap: { mode = DetailMode.view })
                        toobarModeImageView(icon: "doc.text.fill", square: false, foregroundColor: mode == DetailMode.edit ? .indigo : .secondary, onTap: { mode = DetailMode.edit })
                            .padding(.trailing, 15)
                        
                        Divider()
                            .padding(.trailing, 15)
                        
                        Image(systemName: dataModel.showToolsAndSystem ? "wrench.and.screwdriver.fill" : "wrench.and.screwdriver")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .padding(.trailing, 15)
                            .disabled(!dataModel.hasDatabaseOpen)
                            .onTapGesture {
                                dataModel.showToolsAndSystem.toggle()
                            }
                            .onHover { hovering in
                                if hovering && dataModel.hasDatabaseOpen {
                                    NSCursor.pointingHand.set() // Change cursor to pointing hand
                                } else {
                                    NSCursor.arrow.set() // Revert cursor to default
                                }
                            }
                        //toobarModeImageView(icon: "safari", square: true, foregroundColor: mode == DetailMode.browse ? .indigo : .secondary, onTap: { mode = DetailMode.browse })
                        
                    }
                }
            }
            .sheet(isPresented: $showLog) {
                InfoSheetView(title: "Log contents", showModal: $showLog, item: Info.toString())
            }
            .sheet(isPresented: $showOnboard) {
                OnboardSheetView(showModal: $showOnboard)
            }
            .sheet(isPresented: $showTagList) {
                AllGroupItemsListView(showModal: $showTagList,
                                      itemList: dataModel.tags.sorted(by: { $0.name < $1.name }),
                                OnSelected: { gi in
                    
                    if dataModel.filteredConversations.count == dataModel.folders[0].groupItemCount {
                        if AlertHelper.showQuestion(title: "Move to tag", message: "Are you sure you want to add all conversations to this tag?") == false {
                            return
                        }
                    }
                    
                    AddSearchToTagCommand.run(conversations: dataModel.filteredConversations,
                                              tagId: gi.id,
                                              databasePath: dataModel.path,
                                              onFinish: {
                        UiThreadHelper.invokeSafely(function: {
                            Query.reloadTags(dataModel)
                        })
                    })
                })
            }
            .sheet(isPresented: $showFolderList) {
                AllGroupItemsListView(showModal: $showFolderList,
                                      itemList: dataModel.folders.filter { $0.id > 0 }.sorted(by: { $0.name < $1.name }),
                                OnSelected: { gi in
                    
                    if dataModel.filteredConversations.count == dataModel.folders[0].groupItemCount {
                        if AlertHelper.showQuestion(title: "Move to folder", message: "Are you sure you want to move all conversations to this folder?") == false {
                            return
                        }
                    }
                    AddSearchToFolderCommand.run(conversations: dataModel.filteredConversations,
                                              folderId: gi.id,
                                              databasePath: dataModel.path,
                                              onFinish: {
                        UiThreadHelper.invokeSafely(function: {
                            Query.reloadFolders(dataModel)
                            Query.filterConversations(dataModel)
                        })
                    })
                })
            }
            .navigationTitle(dataModel.AppTitle)
        }
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
    
    func toobarModeImageView(icon: String, square: Bool, foregroundColor: Color, onTap: @escaping () -> Void) -> some View {
        
        Image(systemName: icon)
            .resizable()
            .disabled(!dataModel.hasDatabaseOpen)
            .if (square) { view in
                view.frame(width: 25, height: 25)
            }
            .if (!square) { view in
                view.frame(width: 20, height: 25)
            }
            .foregroundColor(foregroundColor)
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 3))
            .onHover { hovering in
                if hovering && dataModel.hasDatabaseOpen {
                    NSCursor.pointingHand.set() // Change cursor to pointing hand
                } else {
                    NSCursor.arrow.set() // Revert cursor to default
                }
            }
            .onTapGesture {
                onTap()
            }
    }
}

