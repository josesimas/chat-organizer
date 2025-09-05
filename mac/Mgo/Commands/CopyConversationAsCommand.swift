//
//  SaveConversationAsCommand.swift
//  Mgo
//
//  Created by Jose Dias on 05/01/2024.
//

import Foundation
import AppKit

struct CopyConversationAsCommand {
    
    public static func runAsHtml(dataModel: DataModel) {        
        if dataModel.currentConversation != nil {
            let html = HtmlHelper.getConversationAsPlainHtml(
                path: dataModel.path,
                uuid: dataModel.currentConversation!.uuid,
                showToolsAndSystem: true)
            
            copyTextToClipboard(text: html)
        }
    }
    
    public static func runAsMarkdown(dataModel: DataModel) {
        
        var msgArray: [String] = []
        for msg in dataModel.messages {
            msgArray.append(msg.text)
        }
        copyTextToClipboard(text: msgArray.joined(separator: "\n"))
    }
    
    static func copyTextToClipboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
