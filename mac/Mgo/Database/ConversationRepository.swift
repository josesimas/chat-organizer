//
//  ConversationRepository.swift
//  Mgo
//
//  Created by Jose Dias on 01/01/2024.
//

import Foundation
import SQLite

struct ConversationRate {
    let conversationUuid: String
    let rate: Int64
}

struct ConversationRepository {
    var connection: Connection!
    
    public func fetchAllRatings() -> [ConversationRate] {
        let sql = "SELECT Uuid, Rate FROM Conversation"
        var rates: [ConversationRate] = []
        do {
            for c in try connection.prepare(sql) {
                let r = ConversationRate(
                    conversationUuid: c[0] as! String,
                    rate: c[1] as! Int64
                )
                rates.append(r)
            }
        } catch {
            Info.add("Fetch failed: \(error)")
        }
        return rates
    }
    
    public func fetchConversationsFiltered(filter: String, folderIdValue: Int64, tagIdValue: Int64, sortAscending: Bool) -> [SearchResultConversationViewModel] {
        
        if filter == "" && folderIdValue > 0 {
            return filterByFolder(folderId: folderIdValue, sortAscending: sortAscending)
        }
        if filter != "" && folderIdValue > 0 {
            return filterByFolderAndText(folderId: folderIdValue,sortAscending: sortAscending, filter: filter)
        }
        
        if filter == "" && tagIdValue > 0 {
            return filterByTag(tagId: tagIdValue, sortAscending: sortAscending)
        }
        if filter != "" && tagIdValue > 0 {
            return filterByTagAndText(tagId: tagIdValue, sortAscending: sortAscending, filter: filter)
        }
        
        //text only search
        let sqlOrderBy = sortAscending ? " ORDER BY c.Created" : " ORDER BY c.Created DESC"
        let sql = "\(getSearchSelect()) WHERE 1 \(getEscapedSqlLike(filter: filter)) \(sqlOrderBy)"
        return filterBySql(sql: sql)
    }
    
    private func filterBySql(sql: String) -> [SearchResultConversationViewModel] {
        var pairs: [SearchResultConversationViewModel] = []
        do {
            if let db = self.connection {
                let stmt = try db.prepare(sql)
                for row in stmt {
                    let createdValue: Double
                        if let createdInt = row[2] as? Double {
                            createdValue = Double(createdInt)
                        } else {
                            createdValue = 0.0
                        }
                    let updatedValue: Double
                        if let updatedInt = row[3] as? Double {
                            updatedValue = Double(updatedInt)
                        } else {
                            updatedValue = 0.0
                        }

                    let conversation = Conversation(id: row[0] as! Int64,
                                                    uuid: row[1] as! String,
                                                    created: createdValue,
                                                    updated: updatedValue,
                                                    title: row[4] as! String,
                                                    sourceId: row[5] as! Int64,
                                                    folderId: row[6] as! Int64,
                                                    rate: row[9] as! Int64)
                    
                    pairs.append(SearchResultConversationViewModel.fromModel(conversation: conversation, questionCount: row[7] as! Int64, blurb: row[8] as! String))
                }
            }
        } catch {
            Info.add("Fetch failed: \(error)")
        }
        return pairs
    }
    
    private func getEscapedSqlLike(filter: String) -> String {
        var sqlLike = ""
        //escape sql
        let escapedFilter = filter.replacingOccurrences(of: "'", with: "''")
        //multiple words
        if filter.contains(" ") {
            for f in escapedFilter.split(separator: " ").map(String.init) {
                sqlLike += " AND (c.Title LIKE '%\(f)%' OR m.Text LIKE '%\(f)%')"
            }
        }
        else {
            //single word
            sqlLike += " AND (c.Title LIKE '%\(escapedFilter)%' OR m.Text LIKE '%\(escapedFilter)%')"
        }
        return sqlLike
    }
    
    func getSearchSelect() -> String {
        return
"""
SELECT DISTINCT c.Id, c.Uuid, c.Created, c.Updated, c.Title, SourceId, c.FolderId, (SELECT COUNT(*) FROM Message m2 WHERE m2.ConversationId = c.Id) AS QuestionCount, (SELECT SUBSTR(Text, 1, 150) FROM Message m3 WHERE m3.ConversationId = c.Id AND m3.Text <> '' ORDER BY m3.Created LIMIT 1) AS Message, c.Rate
FROM Conversation c INNER JOIN Message m ON c.Id = m.ConversationId
"""
    }
    
    private func filterByFolder(folderId: Int64, sortAscending: Bool) -> [SearchResultConversationViewModel] {
        let sqlOrderBy = sortAscending ? " ORDER BY c.Created" : " ORDER BY c.Created DESC"
        let sql = "\(getSearchSelect()) WHERE c.FolderId = \(folderId) \(sqlOrderBy)"
        return filterBySql(sql: sql)
    }

    private func filterByFolderAndText(folderId: Int64, sortAscending: Bool, filter: String) -> [SearchResultConversationViewModel] {
        let sqlOrderBy = sortAscending ? " ORDER BY c.Created" : " ORDER BY c.Created DESC"
        let sql = "\(getSearchSelect()) WHERE c.FolderId = \(folderId) \(getEscapedSqlLike(filter: filter)) \(sqlOrderBy)"
        return filterBySql(sql: sql)
    }
    
    private func filterByTag(tagId: Int64, sortAscending: Bool) -> [SearchResultConversationViewModel] {
        let sqlOrderBy = sortAscending ? " ORDER BY c.Created" : " ORDER BY c.Created DESC"
        let sql = "\(getSearchSelect()) INNER JOIN TagConversation tc ON tc.ConversationId = c.Id WHERE tc.TagId = \(tagId) \(sqlOrderBy)"
        return filterBySql(sql: sql)
    }
    
    private func filterByTagAndText(tagId: Int64, sortAscending: Bool, filter: String) -> [SearchResultConversationViewModel] {
        let sqlOrderBy = sortAscending ? " ORDER BY c.Created" : " ORDER BY c.Created DESC"
        let sql = " \(getSearchSelect()) INNER JOIN TagConversation tc ON tc.ConversationId = c.Id WHERE tc.TagId = \(tagId) \(getEscapedSqlLike(filter: filter)) \(sqlOrderBy)"
        return filterBySql(sql: sql)
    }
    
    public func getConversationAsList(conversationUuid: String) -> [TextDatePair] {
        do {
            if let db = self.connection {
                let stmt = try db.prepare("""
SELECT DISTINCT m.Id, m.MessageUuId AS UUID, m.created, m.Text AS Text, r.Name AS Role
FROM Conversation c INNER JOIN Message m ON c.Id = m.ConversationId
INNER JOIN Role r ON r.Id = m.RoleId
WHERE c.UuId = '\(conversationUuid)' ORDER BY m.created
""")
                return stmt.map { 
                    row in
                        return TextDatePair(
                            id: row[0] as! Int64,
                            uuid: row[1] as! String,
                            created: row[2] as! Double,
                            text: row[3] as! String,
                            type: row[4] as! String
                        )
                }.sorted(by: { $0.created < $1.created })
            }
        } catch {
            Info.add("Fetch failed: \(error)")
        }
        return []
    }
                    
    public static func getConversationIdFromUuid(db: Connection, uuid: String) -> Int64 {
        do {
            let id = try db.scalar("SELECT Id FROM Conversation WHERE Uuid = ?", uuid) as! Int64? ?? 0
            return id
        } catch {
            Info.add("getConversationIdFromUuid failed: \(error)")
            return 0
        }
    }
    
    public func updateRate(conversationId: Int64, rate: Int64) {
        DatabaseHelper.exec(connection, "UPDATE Conversation SET Rate = \(rate) WHERE Id = \(conversationId)")
    }
    
    public func updateRate(conversationUuid: String, rate: Int64) {
        DatabaseHelper.exec(connection, "UPDATE Conversation SET Rate = \(rate) WHERE Uuid = '\(conversationUuid)'")
    }
    
    public func getConversationCount() -> Int64 {
        return DatabaseHelper.execScalar(connection, "SELECT COUNT(*) FROM Conversation")
    }
    
    public func getInboxCount() -> Int64 {
        return DatabaseHelper.execScalar(connection, "SELECT COUNT(*) FROM Conversation WHERE FolderId = 1")
    }
}
