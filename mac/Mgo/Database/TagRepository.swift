//
//  TagRepository.swift
//  Mgo
//
//  Created by Jose Dias on 01/01/2024.
//

import Foundation
import SQLite

struct TagRepository {
    var connection: Connection!
    
    func fetchAllTags() -> [Tag] {
        var tags: [Tag] = []

        let sql = """
        SELECT
            Tag.Id,
            Tag.Name,
            Tag.Created,
            COUNT(TagConversation.Id) AS NumberOfConversations
        FROM
            Tag
        LEFT JOIN
            TagConversation ON Tag.id = TagConversation.TagId
        GROUP BY
            Tag.Id, Tag.Name, Tag.Created;
        """

        do {
            for c in try connection.prepare(sql) {
                let tag = Tag(
                    id: c[0] as! Int64, // Assuming the first column is Id
                    name: c[1] as! String, // Assuming the second column is Name
                    created: c[2] as? Double ?? 0.0, // Assuming the third column is Created
                    conversationCount: c[3] as! Int64 // Assuming the fourth column is NumberOfConversations
                )
                tags.append(tag)
            }
        } catch {
            Info.add("fetchAllTags failed: \(error)")
        }

        return tags
    }
    
    public func addConversationsToTag(conversationIds: [Int64], tagId: Int64) {
        do {
            try connection.transaction {
                try connection.execute("PRAGMA journal_mode = MEMORY;")
                let statement = "INSERT OR IGNORE INTO TagConversation (Id, TagId, ConversationId) VALUES (NULL, ?, ?)"
                let stmt = try connection.prepare(statement)
                for id in conversationIds {
                    try stmt.run(tagId, id)
                }
            }
            Info.add("All conversations were successfully added to tag")
        } catch {
            Info.add("addConversationsToTag failed: \(error)")
        }
    }
    
    public func addConversationTag(tagName: String, conversationUuid: String) {
        let sql = "INSERT OR IGNORE INTO TagConversation (Id, TagId, ConversationId) VALUES (NULL, (SELECT Id FROM Tag WHERE Name = '\(tagName)'), (SELECT Id FROM Conversation WHERE Uuid = '\(conversationUuid)'))"
        DatabaseHelper.exec(connection, sql)
    }
    
    func getConversationTags(_ conversationId: Int64) -> [Tag] {
        var tags: [Tag] = []
        do {
            if let db = self.connection {
                let stmt = try db.prepare("SELECT t.Id, t.Name, t.Created FROM Tag t INNER JOIN TagConversation tc ON tc.TagId = t.Id INNER JOIN Conversation c ON tc.ConversationId = c.Id AND c.Id = \(conversationId)")
                for row in stmt {
                    tags.append(Tag(id: row[0] as! Int64, name: row[1] as! String, created: row[2] as! Double, conversationCount: 0))
                }
            }
        } catch {
            Info.add("getConversationTags failed: \(error)")
            
        }
        return tags
    }
    
    public func deleteTag(id: Int64) {
        do {
            try connection.execute("PRAGMA journal_mode = MEMORY;")
            let delStatement = try connection.prepare("DELETE FROM TagConversation WHERE TagId = ?")
            try delStatement.run(id)
            let delStatement2 = try connection.prepare("DELETE FROM Tag WHERE Id = ?")
            try delStatement2.run(id)
        } catch {
            Info.add("deleteFolder failed: \(error)")
        }
    }
    
    public func updateTagName(id: Int64, newName: String) {
        do {
            try connection.execute("PRAGMA journal_mode = MEMORY;")
            let statement = try connection.prepare("UPDATE Tag SET Name = ? WHERE Id = ?")
            try statement.run(newName, id)
        } catch {
            Info.add("updateTagName failed: \(error)")
        }
    }
    
    public func conversationHasTags(_ uuid: String) -> Bool {
        return DatabaseHelper.execScalar(connection, "SELECT COUNT(*) FROM TagConversation tc INNER JOIN Conversation c ON tc.ConversationId = c.Id AND c.Uuid = '\(uuid)'") > 0
    }
    
    public func conversationHasTags(_ id: Int64) -> Bool {
        return DatabaseHelper.execScalar(connection, "SELECT COUNT(*) FROM TagConversation tc INNER JOIN Conversation c ON tc.ConversationId = c.Id AND c.Id = '\(id)'") > 0
    }
    
    public func removeTagFromConversation(_ tagId: Int64, _ conversationId: Int64) {
        DatabaseHelper.exec(connection, "DELETE FROM TagConversation WHERE TagId = \(tagId) AND ConversationId = \(conversationId)")
    }
    
    public func addNewTag(name: String) -> Int64 {
        DatabaseHelper.exec(connection, "INSERT INTO Tag (Id, Name, Created) VALUES (NULL, '\(name.replacingOccurrences(of: "'", with: "''"))', \(Date().timeIntervalSince1970))")
        return DatabaseHelper.execScalar(connection, "SELECT MAX(Id) FROM Tag")
    }
    
    public func getAllConversationTags() -> [(tagName: String, conversationUuid: String)] {
        var tags: [(tagName: String, conversationUuid: String)] = []
        do {
            if let db = self.connection {
                let stmt = try db.prepare("SELECT t.Name, c.Uuid FROM Tag t INNER JOIN TagConversation tc ON tc.TagId = t.Id INNER JOIN Conversation c ON tc.ConversationId = c.Id")
                for row in stmt {
                    tags.append((tagName: row[0] as! String, conversationUuid: row[1] as! String))
                }
            }
        } catch {
            Info.add("getAllConversationTags failed: \(error)")
            
        }
        return tags
    }
    
}
