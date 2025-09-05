//
//  MgoApp.swift
//  Mgo
//
//  Created by Jose Dias on 01/12/2023.
//
import SwiftUI
import UniformTypeIdentifiers

@main
struct MgoApp: App {    
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
        
    @StateObject private var dataModel = DataModel()

    @State private var openNewFileDialog: Bool = false
    @State private var openFileDialog: Bool = false
       
    @State private var showInfo: Bool = false
    @State private var showOnboard: Bool = false
    @State var showTagList: Bool = false
    @State var showFolderList: Bool = false
    
    @State private var itemForEditing: GroupItem = GroupItem(id: 0, name: "", path: "/", created: Date())
    @State private var addToNewFolder: Bool = false
    @State private var showNewSubFolderDialog: Bool = false
    @State private var showEditFolderDialog: Bool = false
    
    @State private var addNewTag: Bool = false
    @State private var addToNewTag: Bool = false
    @State private var showEditTagDialog: Bool = false
    
    @State var showAddTagDialog: Bool = false
    
        
    var body: some Scene {
        WindowGroup {
            ContentView(showLog: $showInfo,
                        showOnboard: $showOnboard,
                        showTagList: $showTagList,
                        showFolderList: $showFolderList)
                .environmentObject(dataModel)
                .onAppear {
                    //remove the tab menu items
                    NSWindow.allowsAutomaticWindowTabbing = false
                    
                    if let jsonString = UserDefaults.standard.string(forKey: "RecentFiles"),
                       let jsonData = jsonString.data(using: .utf8) {
                        do {
                            dataModel.recentFiles = try JSONDecoder().decode([String].self, from: jsonData)
                            if dataModel.recentFiles.count > 0 {
                                let result = BookmarksHelper.accessDbUsingBookmark(key: dataModel.recentFiles[0], loadDatabase: { url in
                                    LoadDatabaseCommand.run(dataModel: dataModel, url: url)
                                })
                                if !result {
                                    AlertHelper.showError(message: "File \(dataModel.recentFiles[0]) not found.")
                                    dataModel.recentFiles.remove(at: 0)
                                }
                            }
                        } catch {
                            Info.add("Failed to decode recent files: \(error)")
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                    BookmarksHelper.stopAccessingBookmark()
                }
                .sheet(isPresented: $showNewSubFolderDialog) {
                    CommonTagAndFolderViews.newSubFolderSheetView(dataModel: dataModel, showModal: $showNewSubFolderDialog)
                }
                .sheet(isPresented: $showEditFolderDialog) {
                    CommonTagAndFolderViews.editFolderSheetView(dataModel: dataModel, showModal: $showEditFolderDialog, item: $itemForEditing)
                }
                .sheet(isPresented: $addToNewFolder) {
                    CommonTagAndFolderViews.addToNewFolderSheetView(dataModel: dataModel, showModal: $addToNewFolder)
                }
                .sheet(isPresented: $addNewTag) {
                    CommonTagAndFolderViews.newTagSheetView(dataModel: dataModel, showModal: $addNewTag)
                }
                .sheet(isPresented: $addToNewTag) {
                    CommonTagAndFolderViews.addToNewTagSheetView(dataModel: dataModel, showModal: $addToNewTag)
                }
                .sheet(isPresented: $showEditTagDialog) {
                    CommonTagAndFolderViews.editTagSheetView(dataModel: dataModel, showModal: $showEditTagDialog, item: $itemForEditing)
                }
        }
        
        .commands {
            //extend file menu
           CommandGroup(replacing: .newItem) {
               Button("New...") {
                   UiThreadHelper.invokeSafely {
                       NewDatabaseCommand.run(onFinish: { url in
                           LoadDatabaseCommand.run(dataModel: dataModel, url: url)
                       })
                   }
               }
               .keyboardShortcut("n", modifiers: [.command])
               
               Button("Open...") {
                   OpenDatabaseCommand.run(dataModel: dataModel, onFinish: { url in
                       if let u = url {
                           LoadDatabaseCommand.run(dataModel: dataModel, url: u)
                       }
                   })
               }
               .keyboardShortcut("o", modifiers: [.command])
               
               Button("Save as...") {
                   SaveDatabaseAsCommand.run(databasePathToBackup: dataModel.path, onFinish: { url in
                            LoadDatabaseCommand.run(dataModel: dataModel, url: url)
                        })
                   }
                    .keyboardShortcut("a", modifiers: [.command])
                    .disabled(!dataModel.hasDatabaseOpen)
               
               Divider()
                                             
               if !dataModel.recentFiles.isEmpty {
                   ForEach(Array(dataModel.recentFiles.enumerated()), id: \.element) { index, file in
                          let f = URL(fileURLWithPath: file).lastPathComponent.removingPercentEncoding ?? URL(fileURLWithPath: file).lastPathComponent
                          Button("\(index + 1). \(f)") {
                              let result = BookmarksHelper.accessDbUsingBookmark(key: dataModel.recentFiles[index], loadDatabase: { url in
                                  LoadDatabaseCommand.run(dataModel: dataModel, url: url)
                              })
                              if !result {
                                  AlertHelper.showError(message: "File \(dataModel.recentFiles[index]) not found.")
                                  dataModel.recentFiles.remove(at: index)
                              }
                          }
                      }
                }
           }
            
           //extend the View menu
           CommandGroup(after: CommandGroupPlacement.toolbar) {
               Button("View log") {
                    UiThreadHelper.invokeSafely {
                        Info.add("Show log")
                        showInfo = true
                    }
                }
                .keyboardShortcut("l", modifiers: [.command])
                Divider()
            }
                        
            CommandMenu("Conversations") {
                                
                Button("Copy current as HTML") {
                    CopyConversationAsCommand.runAsHtml(dataModel: dataModel)
                }
                .disabled(!dataModel.hasDatabaseOpen)
                
                Button("Copy current as Text") {
                    CopyConversationAsCommand.runAsMarkdown(dataModel: dataModel)
                }
                .disabled(!dataModel.hasDatabaseOpen)
                
                Divider()
                
                Button("Save current as HTML file...") {
                    SaveConversationAsCommand.runAsHtml(dataModel: dataModel)
                }
                .disabled(!dataModel.hasDatabaseOpen)
                
                Button("Save current as Text file...") {
                    SaveConversationAsCommand.runAsMarkdown(dataModel: dataModel)
                }
                .disabled(!dataModel.hasDatabaseOpen)
                
             }
            
            CommandMenu("Import") {
                Button("Conversations from OpenAI...") {
                    UiThreadHelper.invokeSafely {
                            ImportChatGptCommand.run(dataModel: dataModel, onFinish: {path in
                                UiThreadHelper.invokeSafely {
                                    LoadDatabaseCommand.run(dataModel: dataModel)
                                }
                        })
                    }
                }
                .keyboardShortcut("i", modifiers: [.command])
                .disabled(!dataModel.hasDatabaseOpen)
                
                /*Button("WhatsApp chat...") {
                    UiThreadHelper.invokeSafely {
                            ImportWhatsAppCommand.run(dataModel: dataModel, onFinish: {path in
                                UiThreadHelper.invokeSafely {
                                    LoadDatabaseCommand.run(dataModel: dataModel)
                                }
                        })
                    }
                }
                .keyboardShortcut("i", modifiers: [.command])
                .disabled(!dataModel.hasDatabaseOpen)
                */
                Divider()
                
                Button("Import rates...") {
                    ImportFoldersAndTagsCommand.runForRatings(toPath: dataModel.path, completion: {
                        UiThreadHelper.invokeSafely {
                            Query.filterConversations(dataModel)
                        }
                    })
                 }
                .disabled(!dataModel.hasDatabaseOpen)
                
                Divider()
                
                Button("Import folders...") {
                    ImportFoldersAndTagsCommand.runForFolderNames(toPath: dataModel.path, completion: {
                        UiThreadHelper.invokeSafely {
                            Query.reloadFolders(dataModel)
                        }
                    })
                 }
                .disabled(!dataModel.hasDatabaseOpen)
                
                Button("Import folders and assign conversations...") {
                    ImportFoldersAndTagsCommand.runForFolderNamesAndLinks(toPath: dataModel.path, completion: {
                        UiThreadHelper.invokeSafely {
                            Query.reloadFolders(dataModel)
                            Query.filterConversations(dataModel)
                        }
                    })
                 }
                .disabled(!dataModel.hasDatabaseOpen)
                
                Divider()
                                
                Button("Import tags...") {
                    ImportFoldersAndTagsCommand.runForTagNames(toPath: dataModel.path, completion: {
                        UiThreadHelper.invokeSafely {
                            Query.reloadTags(dataModel)
                        }
                    })
                 }
                .disabled(!dataModel.hasDatabaseOpen)
                
                Button("Import tags and assign conversations...") {
                    ImportFoldersAndTagsCommand.runForTagNamesAndLinks(toPath: dataModel.path, completion: {
                        UiThreadHelper.invokeSafely {
                            Query.reloadTags(dataModel)
                            Query.filterConversations(dataModel)
                        }
                    })
                 }
                .disabled(!dataModel.hasDatabaseOpen)
            }
            
            CommandMenu("Search") {
                               
                Button("Move results to new folder...") {
                    addToNewFolder = true
                 }
                .disabled(dataModel.searchTerm.isEmpty)
                
                Button("Move results to existing folder...") {
                    showFolderList = true
                 }
                 .disabled(dataModel.searchTerm.isEmpty)
                
                Divider()
                
                Button("Add results to new tag...") {
                    addToNewTag = true
                 }
                 .disabled(!dataModel.hasDatabaseOpen)
                
                Button("Add results to existing tag...") {
                    showTagList = true
                 }
                 .disabled(!dataModel.hasDatabaseOpen)
             }
            
            CommandMenu("Folders & Tags") {
                
                Button("New folder...") {
                    showNewSubFolderDialog = true
                 }
                .disabled(!dataModel.hasDatabaseOpen)
                
                Button("Rename selected folder...") {
                    if let f = dataModel.selectedFolder {
                        itemForEditing = f
                        showEditFolderDialog = true
                    }
                 }
                .disabled(!dataModel.canEditSelectedFolder)
                
                Divider()
                
                Button("New tag...") {
                    showAddTagDialog = true
                 }
                .disabled(!dataModel.hasDatabaseOpen)
                
                Button("Rename selected tag...") {
                    if let t = dataModel.selectedTag {
                        itemForEditing = t
                        showEditTagDialog = true
                    }
                 }
                .disabled(dataModel.selectedTag == nil)
                
                
             }
                        
            CommandMenu("Tools") {
                Button("Clear log") {
                    Info.clear()
                 }
                Button("Reset recent file list") {
                     UiThreadHelper.invokeSafely {
                         BookmarksHelper.clearAllBookmarks()
                         UserDefaults.standard.removeObject(forKey: "RecentFiles")
                     }
                 }
             }
            
            //Help menu
            CommandGroup(replacing: CommandGroupPlacement.help) {
                Button("How to import conversations...") {
                     UiThreadHelper.invokeSafely {
                         Info.add("Show help")
                         showOnboard = true
                     }
                 }
                
                Divider()

                Button("Terms of Use (EULA)") {
                   NSWorkspace.shared.open(URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                }
                
                Button("Privacy Policy") {
                   NSWorkspace.shared.open(URL(string: "https://chat-organizer.com/privacy.html")!)
                }
                                
                Divider()
                Button("Visit our website...") {
                   NSWorkspace.shared.open(URL(string: "https://chat-organizer.com/")!)
                }
             }
       }
    }
}


class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
