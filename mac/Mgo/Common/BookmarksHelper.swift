//
//  BookmarksHelper.swift
//  Mgo
//
//  Created by Jose Dias on 18/12/2023.
//

import Foundation

struct BookmarksHelper {
    
    private static var globalUrl: URL? = nil
    public static var isBookmarkInUse = false;
        
    static func saveBookmarkData(key: String, for url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(bookmarkData, forKey: createKey(key))
        } catch {
            Info.add("Error creating bookmark: \(error)")
        }
    }
    
    static func accessDbUsingBookmark(key: String, loadDatabase: (_ url: URL) -> Void) -> Bool {
        guard let bookmarkData = UserDefaults.standard.data(forKey: createKey(key)) else {
            return false
        }
        var isStale = false
        do {
            globalUrl = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            
            if isStale {
                let result = OpenDatabaseCommand.renewLastDbBookmark()
                if result {
                    globalUrl = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                } else {
                    return false
                }                
            }
            
            if globalUrl!.startAccessingSecurityScopedResource() {
                loadDatabase(globalUrl!)
            }
            isBookmarkInUse = true
        } catch {
            Info.add("Error accessing bookmark: \(error)")
            return false
        }
        return true
    }
    static func saveLastDbBookmarkData(for url: URL) {
        saveBookmarkData(key: "LastOpenedDb", for: url)
    }
    
    static func accessLastDbUsingBookmark(loadDatabase: (_ url: URL) -> Void) {
        _ = accessDbUsingBookmark(key: "LastOpenedDb", loadDatabase: loadDatabase)
    }
    
    static func lastDbExists() -> Bool {
        let lastDb = UserDefaults.standard.url(forKey: createKey("LastOpenedDbUrl"))
        return lastDb != nil                                               
    }
    
    static func createKey(_ key: String) -> String {
        return "BOOKMARK: \(key)"
    }
    
    static func stopAccessingBookmark() {
        globalUrl?.stopAccessingSecurityScopedResource()
        isBookmarkInUse = false
    }
    
    static func clearAllBookmarks() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            if key.starts(with: "BOOKMARK:") {
                Info.add(key)
                defaults.removeObject(forKey: key)
            }
        }
    }
}
