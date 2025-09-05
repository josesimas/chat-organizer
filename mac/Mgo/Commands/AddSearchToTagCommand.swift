//
//  AddSearchToTagCommand.swift
//  Mgo
//
//  Created by Jose Dias on 27/12/2023.
//

import Foundation

struct AddSearchToTagCommand {
    
    static func run(conversations: [SearchResultConversationViewModel], tagId: Int64, databasePath: String, onFinish: @escaping () -> Void) {
        Task {
            let dm = DatabaseManager(databasePath: databasePath)
            dm.getTagRepo().addConversationsToTag(conversationIds: conversations.map({ c in return c.id }), tagId: tagId)
            onFinish()
        }
    }
}


