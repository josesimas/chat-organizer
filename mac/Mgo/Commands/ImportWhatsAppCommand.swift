//
//  ImportWhatsAppCommand.swift
//  Mgo
//
//  Created by Jose Dias on 31/05/2024.
//

import SwiftUI

struct ImportWhatsAppCommand {
    static func run(dataModel: DataModel, onFinish: @escaping (_ path: String) -> Void){
        
        let panel = NSOpenPanel()
        panel.title = "Select the WhatsApp zip file"
        panel.allowedContentTypes = [.zip, .json]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK {
            
            dataModel.isLoading = true
            
            if let url = panel.url {
                Task {
                    if url.pathExtension == "zip" {
                        guard let chatTempFolder = WhatsApp.extractChatFilesFromZip(sourceURL: url) else { return }
                        WhatsApp.importChat(zipPath: url, tempFolder: chatTempFolder, databasePath: dataModel.path)
                        onFinish(dataModel.path)
                    }
                }
            }
        }
        else {
            UiThreadHelper.invokeSafely {
                dataModel.isLoading = false
            }
        }
    }
}
