//
//  NewDatabaseCommand.swift
//  Mgo
//
//  Created by Jose Dias on 17/12/2023.
//

import SwiftUI
import UniformTypeIdentifiers

struct NewDatabaseCommand {
    
    static func run(onFinish: @escaping (_ url: URL) -> Void) {
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType(filenameExtension: getFileExtension()) ?? UTType.data]
        savePanel.nameFieldStringValue = "ChatOrganizer." + getFileExtension()
        
        if savePanel.runModal() == .OK {
            
            if let url = savePanel.url {
                
                if BookmarksHelper.isBookmarkInUse {
                    BookmarksHelper.stopAccessingBookmark()
                }
                            
                if copyDatabaseFile(to: url) {
                    BookmarksHelper.saveBookmarkData(key: url.absoluteString, for: url)
                    RecentFiles.add(url: url)
                    onFinish(url)
                }
            }
        }
    }
        
    private static func copyDatabaseFile(to url: URL) -> Bool {
        guard let bundledDBPath = Bundle.main.path(forResource: "pm", ofType: "db") else {
            Info.add("Unable to find 'pm.db' in the bundle.")
            return false
        }

        let fileManager = FileManager.default

        do {
            
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
                Info.add("Existing file removed at \(url.path)")
            }
            
            try fileManager.copyItem(atPath: bundledDBPath, toPath: url.path)
            Info.add("Database file copied successfully from \(bundledDBPath) to \(url.path)")
            return true
        } catch {
            Info.add("Error copying database file: \(error)")
            return false
        }
    }
    
    

    
}
