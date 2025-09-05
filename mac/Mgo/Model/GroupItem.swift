//
//  GroupItem.swift
//  Mgo
//
//  Created by Jose Dias on 04/12/2023.
//

import Foundation

struct GroupItem: Identifiable, Hashable {
    var id: Int64
    var name: String
    var path: String
    var created: Date
    var groupItemCount: Int64 = 0
    
    var indentedName: String {
        get {
            if path == "/" || path == "" {
                return name
            }
            else {
                return "> \(name)"
            }
        }
    }
    
    var icon: String {
        get {
            switch id {
            case 0:
                return "star"
            case 1:
                return "tray"
            default:
                return path == "/" ? "doc" : "doc.on.doc"
            }
        }
    }
    
    var depth: CGFloat {
        get {
            let indent = CGFloat(path.components(separatedBy: "/").count - 2) * 15
            return indent
        }
    }
}


