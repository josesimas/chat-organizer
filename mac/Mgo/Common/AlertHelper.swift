//
//  MessageBox.swift
//  Mgo
//
//  Created by Jose Dias on 17/12/2023.
//

import Foundation
import SwiftUI

struct AlertHelper {
    
    static func showError(message: String) {
        UiThreadHelper.invokeSafely {
            let alert = NSAlert()
            alert.messageText = "Error"
            alert.informativeText = message
            alert.addButton(withTitle: "OK")
            alert.alertStyle = .warning
            
            if let icon = NSImage(named: NSImage.Name("ErrorImage")) {
                alert.icon = icon
            }
            alert.runModal()
        }        
    }
    
    static func showInfo(message: String) {
        let alert = NSAlert()
        alert.messageText = "Information"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .informational
        
        if let icon = NSImage(named: NSImage.Name("ErrorImage")) {
            alert.icon = icon
        }
        alert.runModal()
    }
    
    static func showQuestion(title: String, message: String, style: NSAlert.Style = .critical) -> Bool {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message

        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = style
        
        if let icon = NSImage(named: NSImage.Name("ErrorImage")) {
            alert.icon = icon
        }
        
        let response = alert.runModal()
        return response == .alertFirstButtonReturn
    }
}
