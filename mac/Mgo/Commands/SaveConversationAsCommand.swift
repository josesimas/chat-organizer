//
//  SaveConversationAsCommand.swift
//  Mgo
//
//  Created by Jose Dias on 05/01/2024.
//

import Foundation
import SwiftUI

struct SaveConversationAsCommand {
    
    public static func runAsHtml(dataModel: DataModel) {
        if dataModel.currentConversation != nil {
            
            let panel = NSSavePanel()
            panel.title = "Choose a location to save the conversation"
            panel.allowedContentTypes = [.html]
            panel.canCreateDirectories = true

            if panel.runModal() == .OK, let url = panel.url {

                let html = HtmlHelper.getConversationAsPlainHtml(
                    path: dataModel.path,
                    uuid: dataModel.currentConversation!.uuid,
                    showToolsAndSystem: true)
                
                saveToFile(data: html, fileURL: url)
            }
        }
    }
    
    public static func runAsMarkdown(dataModel: DataModel) {
        
        if dataModel.currentConversation != nil {
            
            let panel = NSSavePanel()
            panel.title = "Choose a location to save the conversation"
            panel.allowedContentTypes = [.text, .plainText]
            panel.canCreateDirectories = true

            if panel.runModal() == .OK, let url = panel.url {

                var msgArray: [String] = []
                for msg in dataModel.messages {
                    msgArray.append(msg.text)
                }
                saveToFile(data: msgArray.joined(separator: "\n"), fileURL: url)
            }
        }
        
        
    }
    
    private static func saveToFile(data: String, fileURL: URL) {
        do {
            try data.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Saved successfully to \(fileURL.path)")
        } catch {
            Info.add("Error saving to file: \(error)")
        }

    }
}
