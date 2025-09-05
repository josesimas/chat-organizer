//
//  RecentFiles.swift
//  Mgo
//
//  Created by Jose Dias on 18/12/2023.
//

import Foundation

struct RecentFiles {
    
    private static var recent: [URL] = []
    
    static func add(url: URL){
        UserDefaults.standard.set(url, forKey: "LastOpenedDbUrl")
    }
    
}
