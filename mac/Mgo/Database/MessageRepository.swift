//
//  MessageRepository.swift
//  Mgo
//
//  Created by Jose Dias on 01/01/2024.
//

import Foundation
import SQLite

struct MessageRepository {
    var connection: Connection!
    
    public func updateMessageText(messageId: Int64, text: String) {
        do {
            try connection.execute("PRAGMA journal_mode = MEMORY;")
            let statement = try connection.prepare("UPDATE Message SET Text = ? WHERE Id = ?")
            try statement.run(text, messageId)
        } catch {
            Info.add("updateMessageText failed: \(error)")
        }
    }
}
