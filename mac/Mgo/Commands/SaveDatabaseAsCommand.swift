//
//  BackupCommand.swift
//  Mgo
//
//  Created by Jose Dias on 17/12/2023.
//

import SwiftUI
import UniformTypeIdentifiers

struct SaveDatabaseAsCommand {
    
    static func run(databasePathToBackup: String, onFinish: @escaping (_ url: URL) -> Void) {
        let saveTo = showBackupPanel()
        guard let destinationUrl = saveTo else {
            return
        }
        saveBackup(fromPath: databasePathToBackup, to: destinationUrl)
        onFinish(destinationUrl)
    }
    
    private static func showBackupPanel() -> URL? {
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: getFileExtension()) ?? UTType.data]
        panel.title = "Choose a location to save the file"
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "NewName." + getFileExtension() // Default file name
       
        if panel.runModal() == .OK, let url = panel.url {
            if BookmarksHelper.isBookmarkInUse {
                BookmarksHelper.stopAccessingBookmark()
            }
            BookmarksHelper.saveBookmarkData(key: url.absoluteString, for: url)
            RecentFiles.add(url: url)
            return url
        }
        return nil
    }
    
    private static func saveBackup(fromPath: String, to url: URL) {
        let dm = DatabaseManager(databasePath: fromPath)
        if dm.saveAs(url.absoluteString) == false {
            
            AlertHelper.showError(message: "Error creating backup, please try to save it to a different location.")
        }
    }
}
