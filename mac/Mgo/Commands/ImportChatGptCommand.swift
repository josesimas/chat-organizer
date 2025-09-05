//
//  ImportCommand.swift
//  Mgo
//
//  Created by Jose Dias on 17/12/2023.
//

import SwiftUI

struct ImportChatGptCommand {
    static func run(dataModel: DataModel, onFinish: @escaping (_ path: String) -> Void){
        
        let panel = NSOpenPanel()
        panel.title = "Select the OpenAI zip file"
        panel.allowedContentTypes = [.zip, .json]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK {
            
            dataModel.isLoading = true
            
            if let url = panel.url {
                Task {
                    if url.pathExtension == "zip" {
                        guard let json = ChatGpt.extractJsonFileFromZip(sourceURL: url) else { return }
                        let conversations = ChatGpt.loadJson(from: json)
                        ChatGpt.importConversations(conversations: conversations, databasePath: dataModel.path)
                    }
                    else {
                        guard let json = ChatGpt.readJsonFile(sourceURL: url) else { return }
                        let conversations = ChatGpt.loadJson(from: json)
                        ChatGpt.importConversations(conversations: conversations, databasePath: dataModel.path)
                    }
                    onFinish(dataModel.path)
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


