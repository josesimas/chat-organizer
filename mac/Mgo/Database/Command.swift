//
//  Command.swift
//  Mgo
//
//  Created by Jose Dias on 28/12/2023.
//

import Foundation


struct Command {
        
    public static func addConversationsToFolder(_ dataModel: DataModel, conversationIds: [Int64], folderId: Int64) {
        let dm = DatabaseManager(databasePath: dataModel.path)
        dm.getFolderRepo().addConversationsToFolder(conversationIds: conversationIds, folderId: folderId)
        Query.reloadFoldersInternal(dataModel, dm)
        
        for id in conversationIds {
            dataModel.filteredConversations.removeAll(where: { $0.id == id })
        }
    }
    
    public static func addConversationToTag(_ dataModel: DataModel, conversationIds: [Int64], tagId: Int64) {
        let dm = DatabaseManager(databasePath: dataModel.path)
        dm.getTagRepo().addConversationsToTag(conversationIds: conversationIds, tagId: tagId)
        Query.reloadTagsInternal(dataModel, dm)
    }
    
    public static func addNewFolder(_ dataModel: DataModel, name: String) -> Int64 {
        let dm = DatabaseManager(databasePath: dataModel.path)
        let newId = dm.getFolderRepo().addNewFolder(name: name)
        Query.reloadFoldersInternal(dataModel, dm)
        return newId
    }

    public static func addSubFolder(_ dataModel: DataModel, path: String, name: String) {
        let dm = DatabaseManager(databasePath: dataModel.path)
        _ = dm.getFolderRepo().addNewFolder(path: path, name: name)
        Query.reloadFoldersInternal(dataModel, dm)
    }
    
    public static func addNewTag(_ dataModel: DataModel,name: String) -> Int64 {
        let dm = DatabaseManager(databasePath: dataModel.path)
        let newId = dm.getTagRepo().addNewTag(name: name)
        Query.reloadTagsInternal(dataModel, dm)
        return newId
    }
    
    public static func updateFolderName(_ dataModel: DataModel, id: Int64, newName: String) {
        let dm = DatabaseManager(databasePath: dataModel.path)
        dm.getFolderRepo().updateFolderName(id: id, newName: newName)
        Query.reloadFoldersInternal(dataModel, dm)
    }
    
    public static func deleteFolder(_ dataModel: DataModel, id: Int64, path: String) {
        let dm = DatabaseManager(databasePath: dataModel.path)
        dm.getFolderRepo().deleteFolder(id: id, path: path)
        Query.reloadFoldersInternal(dataModel, dm)
    }
    
    public static func updateTagName(_ dataModel: DataModel, id: Int64, newName: String) {
        let dm = DatabaseManager(databasePath: dataModel.path)
        dm.getTagRepo().updateTagName(id: id, newName: newName)
        Query.reloadTagsInternal(dataModel, dm)
    }
    
    public static func deleteTag(_ dataModel: DataModel, id: Int64) {
        let dm = DatabaseManager(databasePath: dataModel.path)
        dm.getTagRepo().deleteTag(id: id)
        Query.reloadTagsInternal(dataModel, dm)
    }
    
    public static func updateMessageText(_ dataModel: DataModel, messageId: Int64, newText: String) {
        let dm = DatabaseManager(databasePath: dataModel.path)
        dm.getMessageRepo().updateMessageText(messageId: messageId, text: newText)
    }
    
    public static func moveFolder(_ dataModel: DataModel, from: Int64, to: Int64) {
        if from == 0 {
            return
        }
        if to == 0 || to == 1 {
            moveFolderToRoot(dataModel, from: from)
            return
        }
        let dm = DatabaseManager(databasePath: dataModel.path)
        let fr = dm.getFolderRepo()
        let fromFolder = fr.getFolder(byId: from)
        let toFolder = fr.getFolder(byId: to)
        
        if movingParentToOwnChild(from: fromFolder, to: toFolder) {
            return
        }
        
        let newPath = toFolder.path + toFolder.name + "/"
        fr.updateFolderPath(id: from, newPath: newPath)
        
        let childrenNewPath = newPath + fromFolder.name + "/"
        fr.moveFolderChildrenToPath(oldParentPath: fromFolder.path + fromFolder.name + "/", newParentPath: childrenNewPath)
        
        Query.reloadFoldersInternal(dataModel, dm)
    }
    
    private static func movingParentToOwnChild(from: Folder, to: Folder) -> Bool {
        //moving root to another root
        if (from.path == to.path) && to.path == "/" {
            return false
        }
        return to.path.prefix(from.path.count) == from.path
    }
    
    public static func moveFolderToRoot(_ dataModel: DataModel, from: Int64) {
        let dm = DatabaseManager(databasePath: dataModel.path)
        let fr = dm.getFolderRepo()
        let fromFolder = fr.getFolder(byId: from)
                
        let newPath = "/"
        fr.updateFolderPath(id: from, newPath: newPath)
        
        let childrenNewPath = newPath + fromFolder.name + "/"
        fr.moveFolderChildrenToPath(oldParentPath: fromFolder.path + fromFolder.name + "/", newParentPath: childrenNewPath)
        
        Query.reloadFoldersInternal(dataModel, dm)
    }
}
