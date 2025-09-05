//
//  AddSearchToFolderCommand.swift
//  Mgo
//
//  Created by Jose Dias on 27/12/2023.
//

import Foundation

struct AddSearchToFolderCommand {
    
    static func run(conversations: [SearchResultConversationViewModel], folderId: Int64, databasePath: String, onFinish: @escaping () -> Void) {
        Task {
            let dm = DatabaseManager(databasePath: databasePath)
            dm.getFolderRepo().addConversationsToFolder(conversationIds: conversations.map({ c in return c.id }), folderId: folderId)
            onFinish()
        }
    }
}
