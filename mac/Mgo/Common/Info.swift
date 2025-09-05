//
//  Info.swift
//  Mgo
//
//  Created by Jose Dias on 26/12/2023.
//

import Foundation

struct Info {
    private static var messages: [String] = []
    
    public static func add(_ msg: String) {
        messages.append("\(Date()): \(msg)")
        print(msg)
    }
    
    public static func toString() -> String {
        return messages.joined(separator: "\n")
    }
    
    public static func clear() {
        messages = []
    }
}
