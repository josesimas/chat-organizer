//
//  SidebarView.swift
//  Mgo
//
//  Created by Jose Dias on 01/12/2023.
//

import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var dataModel: DataModel
        
    @State private var showNewFolderDialog: Bool = false
    @State private var showEditFolderDialog: Bool = false
    @State private var showAddSubFolderDialog: Bool = false
    
    @State private var itemForEditing: GroupItem = GroupItem(id: 0, name: "", path: "/", created: Date())
    
    @State private var showNewTagDialog: Bool = false
    @State private var showEditTagDialog: Bool = false
    
    @State private var previousFolderId: Int64 = 0
        
    @State private var previousTagId: Int64 = 0
    
    var body: some View {
        VStack(alignment: .leading) {
            Section(header: sectionHeader(icon: "folder", title: i18n.string(key: "folders"), onTapGesture: {
                if dataModel.hasDatabaseOpen {
                    showNewFolderDialog = true
                }
            })) {
                SidebarSectionListView(groups: $dataModel.folders,
                                       selectedGroup: $dataModel.selectedFolder,
                                       onTap: filterByFolder,
                                       onAddToFolder: onAddToFolder,
                                       onEdit: onEditFolder, 
                                       onAddSubFolder: onAddSubFolder,
                                       onMoveToRootFolder: onMoveToRootFolder,
                                       onDelete: onDeleteFolder,
                                       minIdForEditing: 1,
                                       hasSubItems: true)
            }
            .padding(EdgeInsets(top: -10, leading: 10, bottom: 20, trailing: 5))
            .sheet(isPresented: $showNewFolderDialog) {
                CommonTagAndFolderViews.newFolderSheetView(dataModel: dataModel, showModal: $showNewFolderDialog)
            }
            .sheet(isPresented: $showAddSubFolderDialog) {
                CommonTagAndFolderViews.newSubFolderSheetView(dataModel: dataModel, showModal: $showAddSubFolderDialog)                
            }
            .sheet(isPresented: $showEditFolderDialog) {
                CommonTagAndFolderViews.editFolderSheetView(dataModel: dataModel, showModal: $showEditFolderDialog, item: $itemForEditing)                
            }
            
            Section(header: sectionHeader(icon: "tag", title: i18n.string(key: "tags"), onTapGesture: {
                if dataModel.hasDatabaseOpen {
                    showNewTagDialog = true
                }
            })) {
                SidebarSectionListView(groups: $dataModel.tags,
                                       selectedGroup: $dataModel.selectedTag,
                                       onTap: filterByTag,
                                       onAddToFolder: onAddToTag,
                                       onEdit: onEditTag,
                                       onAddSubFolder: { r in return },
                                       onMoveToRootFolder: { r in return },
                                       onDelete: onDeleteTag,
                                       minIdForEditing: 0)
            }
            .padding(EdgeInsets(top: -10, leading: 10, bottom: 20, trailing: 5))
            .sheet(isPresented: $showNewTagDialog) {
                CommonTagAndFolderViews.newTagSheetView(dataModel: dataModel, showModal: $showNewTagDialog)
            }
            .sheet(isPresented: $showEditTagDialog) {
                CommonTagAndFolderViews.editTagSheetView(dataModel: dataModel, showModal: $showEditTagDialog, item: $itemForEditing)
            }
        }
        .frame(minWidth: 100)
        .padding(EdgeInsets(top: 30, leading: 0, bottom: 0, trailing: 0))
    }

    private func onAddToFolder(_ conversationIds: [Int64], _ folderId: Int64) {
        Command.addConversationsToFolder(dataModel, conversationIds: conversationIds, folderId: folderId)
    }
    
    private func onAddToTag (_ conversationIds: [Int64], _ tagId: Int64) {
        Command.addConversationToTag(dataModel, conversationIds: conversationIds, tagId: tagId)
    }
    
    func filterByTag(tag: GroupItem) {
        if self.previousTagId != tag.id {
            dataModel.selectedTag = tag
            self.previousTagId = tag.id
            Query.filterConversations(dataModel)
            dataModel.selectedFolder = nil
            self.previousFolderId = -1
        }
    }
    
    func filterByFolder(folder: GroupItem) {
        if self.previousFolderId != folder.id {
            dataModel.selectedFolder = folder
            self.previousFolderId = folder.id
            Query.filterConversations(dataModel)
            dataModel.selectedTag = nil
            self.previousTagId = -1
        }
    }
    
    func onEditFolder(folder: GroupItem) {
        itemForEditing = folder
        showEditFolderDialog = true
    }

    func onAddSubFolder(folder: GroupItem) {
        itemForEditing = folder
        showAddSubFolderDialog = true
    }
    
    func onMoveToRootFolder(folder: GroupItem) {
        Command.moveFolderToRoot(dataModel, from: folder.id)
    }
    
    func onDeleteFolder(folder: GroupItem) {
        if AlertHelper.showQuestion(title: "Delete", message: "Are you sure you want to delete this folder? This action cannot be undone.") {
            Command.deleteFolder(dataModel, id: folder.id, path: folder.path + folder.name + "/")
        }
    }
    
    func onEditTag(folder: GroupItem) {
        itemForEditing = folder
        showEditTagDialog = true
    }
    
    func onDeleteTag(folder: GroupItem) {
        if AlertHelper.showQuestion(title: "Delete", message: "Are you sure you want to delete this tag? This action cannot be undone.") {
            Command.deleteTag(dataModel, id: folder.id)
        }
    }
    
    func sectionHeader(icon: String, title: String, onTapGesture: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: icon)
                .resizable()
                .foregroundColor(.indigo)
                .frame(width: 20, height: 20)
            Text(title)
                .font(.system(size: 20))
                .foregroundColor(.indigo)
            Spacer()
            Image(systemName: "plus.circle")
                .resizable()
                .foregroundColor(.indigo)
                .frame(width: 20, height: 20)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
                .onTapGesture {
                    onTapGesture()
                }
                .onHover { hovering in
                    if !dataModel.hasDatabaseOpen {
                        return
                    }
                    if hovering {
                        NSCursor.pointingHand.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }
        }
    }
}


#Preview {
    SidebarView()
        .environmentObject(DataModel())
}
