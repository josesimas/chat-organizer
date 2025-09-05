//
//  OpenDatabaseCommand.swift
//  Mgo
//
//  Created by Jose Dias on 17/12/2023.
//

import SwiftUI
import Cocoa

class CustomOpenPanelDelegate: NSObject, NSOpenSavePanelDelegate {
    func panel(_ sender: Any, shouldEnable url: URL) -> Bool {
        return url.pathExtension.lowercased() == getFileExtension()
    }
}

struct OpenDatabaseCommand {
    
    static func run(dataModel: DataModel, onFinish: @escaping (_ url: URL?) -> Void) {
        
        let panel = NSOpenPanel()
        panel.title = "Open"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        
        let delegate = CustomOpenPanelDelegate()
        panel.delegate = delegate
        
        if panel.runModal() == .OK {
            UiThreadHelper.invokeSafely {
                dataModel.isLoading = true
            }
            if let url = panel.url {
                if BookmarksHelper.isBookmarkInUse {
                    BookmarksHelper.stopAccessingBookmark()
                }
                BookmarksHelper.saveBookmarkData(key: url.absoluteString, for: url)
                RecentFiles.add(url: url)
                onFinish(url)
                UiThreadHelper.invokeSafely {
                    dataModel.isLoading = false
                }
            }
        }
        else {
            UiThreadHelper.invokeSafely {
                dataModel.isLoading = false
            }
        }
    }
    
    static func renewLastDbBookmark() -> Bool {
        
        let panel = NSOpenPanel()
        panel.title = "Open"
        panel.allowedContentTypes = [.data]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                BookmarksHelper.saveBookmarkData(key: url.absoluteString, for: url)
                return true
            }
        }
        return false
    }
}
