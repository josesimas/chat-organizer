//
//  UpdateConversationRateCommand.swift
//  Mgo
//
//  Created by Jose Dias on 06/01/2024.
//

import Foundation

struct UpdateConversationRateCommand {
    
    public static func run(_ dataModel: DataModel, id: Int64, rate: Int64) {
        let dm = DatabaseManager(databasePath: dataModel.path)
        dm.getConversationRepo().updateRate(conversationId: id, rate: rate)
    }
}
