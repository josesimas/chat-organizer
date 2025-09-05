//
//  Mapper.swift
//  Mgo
//
//  Created by Jose Dias on 06/12/2023.
//

import Foundation

struct Mapper {
    
    static func Map(source: Folder) -> GroupItem {
        return GroupItem(id: source.id, name: source.name, path: source.path, created: Date(timeIntervalSince1970: TimeInterval(source.created)), groupItemCount: source.conversationCount)
    }
    
    static func Map(source: Tag) -> GroupItem {
        return GroupItem(id: source.id, name: source.name,  path: "", created: Date(timeIntervalSince1970: TimeInterval(source.created)), groupItemCount: source.conversationCount)
    }
}
