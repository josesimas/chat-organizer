//
//  DatabaseManager.swift
//  Mgo
//
//  Created by Jose Dias on 06/12/2023.
//

import Foundation
import SQLite

class DatabaseManager {
    var connection: Connection!
    
    public var isReady: Bool = false

    init(databasePath: String) {
            do {
                connection = try Connection(databasePath)
                isReady = true
            } catch {
                Info.add("Unable to open database. \(error.localizedDescription)")
            }
        }
    
    func saveAs(_ path: String) -> Bool {
        do {
            // Create a new connection for the backup database
            let target = try Connection(path)

            // Set the journal mode of the backup database to MEMORY or OFF
            try target.execute("PRAGMA journal_mode = MEMORY;")

            // Perform the backup
            let backup = try self.connection.backup(usingConnection: target)
            try backup.step()

            return true
        } catch {
            Info.add("Backup failed: \(error)")
        }
        return false
    }
    
    func getAssistantName(conversationUuid: String) -> String {
        let sql =
"""
SELECT DISTINCT m.AssistantDetails FROM Conversation c INNER JOIN Message m ON m.ConversationId = c.Id
WHERE m.AssistantDetails <> "" AND c.Uuid = '\(conversationUuid)' LIMIT 1
"""
        do {
            if let db = self.connection {
                let stmt = try db.prepare(sql)
                for row in stmt {
                    let slug = row[0] as! String
                    if slug == "gpt-4" {
                        return "ChatGPT 4"
                    }
                    if slug == "gpt-4-gizmo" {
                        return "Custom ChatGPT 4"
                    }
                    if slug == "text-davinci-002-render-sha" {
                        return "ChatGPT 3.5"
                    }
                    if slug == "gpt-4-browsing" {
                        return "ChatGPT 4 with browsing"
                    }
                    return slug
                }
            }
        } catch {
            Info.add("getAssistantName failed: \(error)")
            
        }
        return ""
    }
    
    public static func databaseIsEmpty(databasePath: String) -> Bool {
        do {
            let db = try Connection(databasePath)
            let conversationTable = Table("conversation")
            let count = try db.scalar(conversationTable.count)
            return count == 0
        } catch {
            Info.add("Error checking database: \(error)")
            return false
        }
    }
        
    public static func messageExists(db: Connection, uuid: String) -> Bool {
        do {
            let count = try db.scalar("SELECT COUNT(*) FROM Message WHERE MessageUuid = ?", uuid) as! Int64
            return count > 0
        } catch {
            Info.add("conversationExists failed: \(error)")
            return false
        }
    }
    
    public func getFolderRepo() -> FolderRepository {
        return FolderRepository(connection: connection)
    }
    
    public func getTagRepo() -> TagRepository {
        return TagRepository(connection: connection)
    }
    
    public func getConversationRepo() -> ConversationRepository {
        return ConversationRepository(connection: connection)
    }
    
    public func getMessageRepo() -> MessageRepository {
        return MessageRepository(connection: connection)
    }
}


