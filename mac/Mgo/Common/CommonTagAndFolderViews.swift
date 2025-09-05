//
//  CommonViews.swift
//  Mgo
//
//  Created by Jose Dias on 08/01/2024.
//

import SwiftUI

struct CommonTagAndFolderViews {

    public static func newFolderSheetView(dataModel: DataModel, showModal: Binding<Bool>) -> some View {
        NewItemSheetView(title: i18n.string(key: "new.folder"), showModal: showModal, command: { text in
            if text != "" {
                _ = Command.addNewFolder(dataModel, name: text)
            }
        })
    }
    
    public static func newSubFolderSheetView(dataModel: DataModel, showModal: Binding<Bool>) -> some View {
        NewItemSheetView(title: i18n.string(key: "new.folder"), showModal: showModal, command: { text in
            if text != "" {
                var newPath = "/"
                if let c = dataModel.selectedFolder {
                    if c.id > 1 {
                        newPath = c.path + c.name + "/"
                    }
                }
                Command.addSubFolder(dataModel, path: newPath, name: text)
            }
        })
    }
    
    public static func editFolderSheetView(dataModel: DataModel, showModal: Binding<Bool>, item: Binding<GroupItem>) -> some View {
        EditItemSheetView(title: i18n.string(key: "edit.folder"),
                          showModal: showModal,
                          item: item,
                          command: { item in
            if item.id > 1 && item.name != "" {
                UiThreadHelper.invokeSafely {
                    Command.updateFolderName(dataModel, id: item.id, newName: item.name)
                    dataModel.selectedFolder = item
                }
            }
        })
    }
    
    public static func addToNewFolderSheetView(dataModel: DataModel, showModal: Binding<Bool>) -> some View {
        NewItemSheetView(title: i18n.string(key: "new.folder"), showModal: showModal, command: { text in
            if text != "" {
                let newId = Command.addNewFolder(dataModel, name: text)
                
                AddSearchToFolderCommand.run(conversations: dataModel.filteredConversations,
                                          folderId: newId,
                                          databasePath: dataModel.path,
                                          onFinish: {
                    UiThreadHelper.invokeSafely(function: {
                        Query.reloadFolders(dataModel)
                        Query.filterConversations(dataModel)
                    })
                })
            }
        })
    }
    
    // TAGS /*****************/
    
    public static func newTagSheetView(dataModel: DataModel, showModal: Binding<Bool>) -> some View {
        NewItemSheetView(title: i18n.string(key: "new.tag"), showModal: showModal, command: { text in
            if text != "" {
                let _ = Command.addNewTag(dataModel, name: text)
            }
        })
    }
    
    public static func editTagSheetView(dataModel: DataModel, showModal: Binding<Bool>, item: Binding<GroupItem>) -> some View {
        EditItemSheetView(title: i18n.string(key: "edit.tag"),
                          showModal: showModal,
                          item: item,
                          command: { item in
              if item.id > 0 && item.name != "" {
                  UiThreadHelper.invokeSafely {
                      Command.updateTagName(dataModel, id: item.id, newName: item.name)
                      dataModel.selectedTag = item
                  }
              }
          })
    }
    
    public static func addToNewTagSheetView(dataModel: DataModel, showModal: Binding<Bool>) -> some View {
        NewItemSheetView(title: i18n.string(key: "new.tag"), showModal: showModal, command: { text in
            if text != "" {
                let newId = Command.addNewTag(dataModel, name: text)
                
                AddSearchToTagCommand.run(conversations: dataModel.filteredConversations,
                                          tagId: newId,
                                          databasePath: dataModel.path,
                                          onFinish: {
                    UiThreadHelper.invokeSafely(function: {
                        Query.reloadTags(dataModel)
                        Query.filterConversations(dataModel)
                    })
                })
            }
        })
    }
    
    
}
