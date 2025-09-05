//
//  DatabaseHelper.swift
//  Mgo
//
//  Created by Jose Dias on 01/01/2024.
//

import Foundation
import SQLite

struct DatabaseHelper {
    
    public static func exec(_ connection: Connection?, _ sql: String) {
        do {
            if let db = connection {
                try db.execute("PRAGMA journal_mode = MEMORY;")
                try db.run(sql)
            }
        } catch {
            Info.add("Exec failed: \(error)")
        }
    }
    
    public static func execScalar(_ connection: Connection?, _ sql: String) -> Int64 {
        do {
            if let db = connection {
                try db.execute("PRAGMA journal_mode = MEMORY;")
                let count = try db.scalar(sql) as! Int64
                return count
                
            }
        } catch {
            Info.add("\(sql) failed: \(error)")
        }
        return 0
    }
}
