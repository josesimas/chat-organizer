//
//  FolderRepository.swift
//  Mgo
//
//  Created by Jose Dias on 01/01/2024.
//

import Foundation
import SQLite

struct FolderRepository {
    var connection: Connection!
    
    func fetchAllFolders() -> [Folder] {
        var folders: [Folder] = []

        let sql = """
        SELECT
            Folder.Id,
            Folder.Name,
            Folder.Path,
            Folder.Created,
            COUNT(Conversation.Id) AS NumberOfConversations,
            REPLACE(Folder.Path, '/', '') || Folder.Name AS ORDERBY
        FROM
            Folder
        LEFT JOIN
            Conversation ON Folder.Id = Conversation.FolderId
        WHERE Folder.Id > 1
        GROUP BY
            Folder.Id, Folder.Name, Folder.Created
        ORDER BY ORDERBY;
        """

        do {
            for c in try connection.prepare(sql) {
                let folder = Folder(
                    id: c[0] as! Int64,
                    name: c[1] as! String,
                    path: c[2] as! String,
                    created: c[3] as? Double ?? 0.0,
                    conversationCount: c[4] as! Int64
                )
                folders.append(folder)
            }
        } catch {
            Info.add("Fetch failed: \(error)")
        }

        return folders
    }
    
    public func getInboxFolderCount() -> Int64 {
        return DatabaseHelper.execScalar(connection, "SELECT COUNT(*) FROM Conversation WHERE FolderId = 1")
    }
    
    public func getConversationCount() -> Int64 {
        return DatabaseHelper.execScalar(connection, "SELECT COUNT(*) FROM Conversation")
    }
    
    public func getFolders(withNamePrefix: String) -> [Folder] {
        let sql = """
        SELECT
            Folder.Id,
            Folder.Name,
            Folder.Created,
            COUNT(Conversation.Id) AS NumberOfConversations,
            REPLACE(Folder.Path, '/', '') || Folder.Name AS ORDERBY
        FROM
            Folder
        LEFT JOIN
            Conversation ON Folder.Id = Conversation.FolderId
        WHERE Folder.Name LIKE '\(withNamePrefix).%'
        GROUP BY
            Folder.Id, Folder.Name, Folder.Created
        ORDER BY ORDERBY;
        """
        var folders: [Folder] = []
        do {
            for c in try connection.prepare(sql) {
                let folder = Folder(
                    id: c[0] as! Int64,
                    name: c[1] as! String,
                    path: c[2] as! String,
                    created: c[3] as? Double ?? 0.0,
                    conversationCount: c[4] as! Int64
                )
                folders.append(folder)
            }
        } catch {
            Info.add("getFolder withNamePrefix failed: \(error)")
        }
        return folders
    }
    
    public func updateFolderName(id: Int64, newName: String) {
        do {
            try connection.execute("PRAGMA journal_mode = MEMORY;")
            let statement = try connection.prepare("UPDATE Folder SET Name = ? WHERE Id = ?")
            try statement.run(newName, id)
            
        } catch {
            Info.add("updateFolderName failed: \(error)")
        }
    }
    
    public func updateFolderPath(id: Int64, newPath: String) {
        do {
            try connection.execute("PRAGMA journal_mode = MEMORY;")
            let statement = try connection.prepare("UPDATE Folder SET Path = ? WHERE Id = ?")
            try statement.run(newPath, id)
            
        } catch {
            Info.add("updateFolderPath failed: \(error)")
        }
    }
    
    public func moveFolderChildrenToPath(oldParentPath: String, newParentPath: String) {
        do {
            try connection.execute("PRAGMA journal_mode = MEMORY;")
            let statement = try connection.prepare(
            """
        UPDATE Folder
        SET Path = '\(newParentPath)' || SUBSTR(Path, LENGTH('\(oldParentPath)') + 1)
        WHERE Path LIKE '\(oldParentPath)%';
        """)
            try statement.run()
            
        } catch {
            Info.add("moveFolderPath failed: \(error)")
        }
    }
    
    public func updateFolderName(id: Int64, oldName: String, newName: String) {
        
        if let oldPrefix = oldName.range(of: ".", options: .backwards) {
            let newPrefix = oldName.prefix(upTo: oldPrefix.lowerBound)
            
            //replace the prefix with the new prefix for all folders under this one
            let children = getFolders(withNamePrefix: String(newPrefix))
            do {
                try connection.transaction {
                    try connection.execute("PRAGMA journal_mode = MEMORY;")
                    let statement = "UPDATE Folder SET Name = ? WHERE Id = ?"
                    let stmt = try connection.prepare(statement)
                    for child in children {
                        let lastName = child.name.components(separatedBy: ".").last ?? ""
                        if lastName != "" {
                            try stmt.run(newName + "." + lastName, child.id)
                        }
                    }
                    let stmt2 = try connection.prepare("UPDATE Folder SET Name = ? WHERE Id = ?")
                    try stmt2.run(newName, id)
                }
            }
            catch {
                Info.add("updateFolderName2 failed: \(error)")
            }
        }
    }
    
    public func addNewFolder(name: String) -> Int64 {
        return addNewFolder(path: "/", name: name)
    }
    
    public func addNewFolder(path: String, name: String) -> Int64 {
        let safeName = name.replacingOccurrences(of: "/", with: "").replacingOccurrences(of: "'", with: "''")
        DatabaseHelper.exec(connection, "INSERT INTO Folder (Id, Name, Path, Created) VALUES (NULL, '\(safeName)', '\(path)', \(Date().timeIntervalSince1970))")
        return DatabaseHelper.execScalar(connection, "SELECT MAX(Id) FROM Folder")
    }
    
    public func addConversationsToFolder(conversationIds: [Int64], folderId: Int64) {
        do {
            try connection.transaction {
                try connection.execute("PRAGMA journal_mode = MEMORY;")
                let statement = "UPDATE Conversation SET FolderId = ? WHERE Id = ?"
                let stmt = try connection.prepare(statement)
                for id in conversationIds {
                    try stmt.run(folderId, id)
                }
            }
            Info.add("All conversations were successfully added to tag")
        } catch {
            Info.add("addConversationsToFolder failed: \(error)")
        }
    }
    
    public func addConversationsToFolder(conversationUuid: String, folderPath: String, folderName: String) {
        let sql =
"""
    UPDATE Conversation
    SET FolderId = f.Id
    FROM Folder f
    WHERE f.Path = '\(folderPath)' AND f.Name = '\(folderName)'
    AND Conversation.Uuid = '\(conversationUuid)'
"""
        DatabaseHelper.exec(connection, sql)
    }
    
    public func deleteFolder(id: Int64, path: String) {
        do {
            try connection.execute("PRAGMA journal_mode = MEMORY;")
            let updateConvs = try connection.prepare("UPDATE Conversation SET FolderId = 1 WHERE FolderId = ?")
            try updateConvs.run(id)
                        
            let delFolder = try connection.prepare("DELETE FROM Folder WHERE Id = ?")
            try delFolder.run(id)
            
            let delChildren = try connection.prepare("DELETE FROM Folder WHERE Path LIKE '\(path)%'")
            try delChildren.run()
            
        } catch {
            Info.add("deleteFolder failed: \(error)")
        }
    }
    
    public func getFolder(byId: Int64) -> Folder {
        let sql = """
        SELECT
            Folder.Id,
            Folder.Name,
            Folder.Path,
            Folder.Created,
            COUNT(Conversation.Id) AS NumberOfConversations
        FROM
            Folder
        LEFT JOIN
            Conversation ON Folder.Id = Conversation.FolderId
        WHERE Folder.Id = \(byId)
        GROUP BY
            Folder.Id, Folder.Name, Folder.Created
        ORDER BY Folder.Name;
        """

        do {
            for c in try connection.prepare(sql) {
                let folder = Folder(
                    id: c[0] as! Int64,
                    name: c[1] as! String,
                    path: c[2] as! String,
                    created: c[3] as? Double ?? 0.0,
                    conversationCount: c[4] as! Int64
                )
                return folder
            }
        } catch {
            Info.add("getFolder failed: \(error)")
        }
        return Folder(id: 0, name: "", path: "/", created: 0, conversationCount: 0)
    }
    
    public func getChildren(of: Int64, withPath: String) -> [Int64] {
        let sql =
        """
SELECT
    Folder.Id
FROM
    Folder
WHERE Folder.Id > 1 AND Path LIKE '\(withPath)%'
"""
        var ids: [Int64] = []
        do {
            for c in try connection.prepare(sql) {
                ids.append(c[0] as! Int64)
            }
            return ids
        } catch {
            Info.add("getChildren failed: \(error)")
        }
        return []
    }
    
    public func getConversationFolderPaths() -> [(name: String, path: String, conversationUuid: String)] {
        let sql = "SELECT F.name, f.Path, c.Uuid FROM Conversation c INNER JOIN Folder f ON c.FolderId = f.Id WHERE f.Id > 1"
        var pairs = [(name: String, path: String, conversationUuid: String)]()
        do {
            for row in try connection.prepare(sql) {
                if let name = row[0] as? String, let path = row[1] as? String, let uuid = row[2] as? String {
                    pairs.append((name: name, path: path, conversationUuid: uuid))
                }
            }
            return pairs
        } catch {
            Info.add("getConversationFolderPaths failed: \(error)")
            return [] 
        }
    }
}
