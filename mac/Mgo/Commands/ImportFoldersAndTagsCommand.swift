//
//  ImportFoldersCommand.swift
//  Mgo
//
//  Created by Jose Dias on 01/01/2024.
//

import Foundation
import Cocoa

struct ImportFoldersAndTagsCommand {
    
    public static func runForRatings(toPath: String, completion: () -> Void) {
        
        if let url = getSourceDatabase() {
            let dmSource = DatabaseManager(databasePath: url.absoluteString)
            
            let sourceRatings = dmSource.getConversationRepo().fetchAllRatings()
            let dm = DatabaseManager(databasePath: toPath)
            let cr = dm.getConversationRepo()
            for rating in sourceRatings {
                cr.updateRate(conversationUuid: rating.conversationUuid, rate: rating.rate)
            }
            completion()
        }
    }
    
    public static func runForFolderNames(toPath: String, completion: () -> Void) {
        
        if let url = getSourceDatabase() {
            let dmSource = DatabaseManager(databasePath: url.absoluteString)
            addFolders(dmSource: dmSource, toPath: toPath)
            completion()
        }
    }
    
    private static func addFolders(dmSource: DatabaseManager, toPath: String) {
        
        let sourceFolders = dmSource.getFolderRepo().fetchAllFolders()
        let dm = DatabaseManager(databasePath: toPath)
        let fr = dm.getFolderRepo()
        for folder in sourceFolders {
            _ = fr.addNewFolder(path: folder.path, name: folder.name)
        }
    }
    
    public static func runForFolderNamesAndLinks(toPath: String, completion: () -> Void) {
        
        if let url = getSourceDatabase() {
            
            let srcDm = DatabaseManager(databasePath: url.absoluteString)
            addFolders(dmSource: srcDm, toPath: toPath)
            let srcConvos = srcDm.getFolderRepo().getConversationFolderPaths()
            
            let dm = DatabaseManager(databasePath: toPath)
            let fr = dm.getFolderRepo()
            for convo in srcConvos {
                fr.addConversationsToFolder(conversationUuid: convo.conversationUuid, folderPath: convo.path, folderName: convo.name)
            }
            completion()
        }
    }
        
    public static func runForTagNames(toPath: String, completion: () -> Void) {
        
        if let url = getSourceDatabase() {
            let dmSource = DatabaseManager(databasePath: url.absoluteString)
            addTags(dmSource, toPath)
            completion()
        }
    }
    
    public static func runForTagNamesAndLinks(toPath: String, completion: () -> Void) {
        
        if let url = getSourceDatabase() {
            let dmSource = DatabaseManager(databasePath: url.absoluteString)
            addTags(dmSource, toPath)
            let srcTagConversations = dmSource.getTagRepo().getAllConversationTags()
            
            let dm = DatabaseManager(databasePath: toPath)
            let fr = dm.getTagRepo()
            for convo in srcTagConversations {
                fr.addConversationTag(tagName: convo.tagName, conversationUuid: convo.conversationUuid)
            }
            completion()
        }
    }
    
    private static func addTags(_ dmSource: DatabaseManager, _ toPath: String) {
        let sourceTags = dmSource.getTagRepo().fetchAllTags()
        
        let dm = DatabaseManager(databasePath: toPath)
        let tr = dm.getTagRepo()
        for folder in sourceTags {
            _ = tr.addNewTag(name: folder.name)
        }
    }
    
    private static func getSourceDatabase() -> URL? {
        
        let panel = NSOpenPanel()
        panel.title = "From file"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        
        let delegate = CustomOpenPanelDelegate()
        panel.delegate = delegate
        
        if panel.runModal() == .OK {
            if let url = panel.url {
               return url
            }
        }
        return nil
    }
}
