//
//  TextDatePair.swift
//  Mgo
//
//  Created by Jose Dias on 11/12/2023.
//

import Foundation

struct TextDatePair: Identifiable {
    let id: Int64
    let uuid: String
    let created: Double
    let text: String
    let type: String
}

struct MessageViewModel: Identifiable {
    let id: Int64
    let uuid: String
    let created: Double
    var text: String  {
        didSet {
            // This code will be executed every time 'text' changes
            changed = true
        }
    }
    let type: String
    var selected: Bool = false
    var changed: Bool = false
    
    public static func fromTextDatePair(tdp: TextDatePair) -> MessageViewModel {
        return MessageViewModel(id: tdp.id, uuid: tdp.uuid, created: tdp.created, text: tdp.text, type: tdp.type)
    }
}
