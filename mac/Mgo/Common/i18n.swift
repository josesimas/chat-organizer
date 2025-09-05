//
//  i18n.swift
//  Mgo
//
//  Created by Jose Dias on 01/12/2023.
//

import Foundation

struct i18n {
    static let appName = "PromptManager"
    
    static func string(key: String) -> String {
        switch key {
            case "save": return "Save"
            case "menu": return "Menu"
            case "open": return "Open"
            case "copy": return "Copy"
            case "close": return "Close"
            case "folders": return "Folders"
            case "tags": return "Tags"
            case "recent": return "Recent"
            case "created.colon": return "Created:"
            case "select": return "Select"
            case "new.folder": return "New Folder"
            case "new.tag": return "New Tag"
            case "ok": return "OK"
            case "cancel": return "Cancel"
            case "all.conversations": return "All Conversations"
            case "inbox.conversations": return "Inbox"
            case "search.conversations": return "Search selected folder or tag"
            case "edit.tag": return "Rename tag"
            case "edit.folder": return "Rename folder"
            case "search.conversation": return "Search conversation"
            case "privacy": return getPP()
            default:
                return key
        }
    }
    
    private static func getPP() -> String {
        """
<html>
<body>
<div class="container"">

        <h2>Introduction</h2>
    
        <p>This Privacy Statement outlines how Gepsoft, Lda ("we," "us," or "our") collects, uses, shares, and protects your personal information in relation to the use of our application, \(getAppName()) (the "App"). We are committed to protecting your privacy and ensuring the security of your personal information. By downloading and using \(getAppName()), you agree to the practices described in this Privacy Statement.</p>
    
        <h2>Information We Collect</h2>
    
        <ol>
            <li><strong>User Provided Information:</strong> We don't collect any user information.</li>
    
            <li><strong>Automatically Collected Information:</strong> The App saves any error that may arise while using it. This information is NOT transmitted to us although you have the option to email it us if you so desire.</li>
    
            <li><strong>Usage Analytics:</strong> The App doesn't collect any data concerning usage or interaction although the App Store and Apple may collect information we don't control.</li>
        </ol>
    
        <h2>How We Use Your Information</h2>
    
        <p>We may use the information you send ut for the following purposes:</p>
    
        <ol>
            <li>To provide, maintain, and improve the App's functionality and user experience.</li>
    
            <li>To send you important updates, notifications, and information related to the App.</li>
    
            <li>To respond to your inquiries, comments, or support requests.</li>
    
            <li>To comply with legal obligations and protect our rights.</li>
        </ol>
    
        <h2>Sharing of Your Information</h2>
    
        <p>We may share your personal information with third parties under the following circumstances:</p>
    
        <ol>
            <li>With your consent.</li>
    
            <li>To comply with legal requirements or to protect our rights, privacy, safety, or property.</li>
        </ol>
    
        <h2>Data Retention</h2>
    
        <p>We will retain your personal information for as long as necessary to fulfill the purposes outlined in this Privacy Statement or as required by applicable laws and regulations.</p>
    
        <h2>Security</h2>
    
        <p>We are committed to protecting your personal information and have implemented reasonable security measures to safeguard it. However, no method of transmission over the internet or electronic storage is 100% secure, so we cannot guarantee absolute security.</p>
    
        <h2>Your Choices</h2>
    
        <p>You can review, update, or delete your personal information by contacting us at support@gepsoft.com.</p>
    
        <h2>Changes to this Privacy Statement</h2>
    
        <p>We may update this Privacy Statement from time to time to reflect changes in our practices or for other operational, legal, or regulatory reasons. We will notify you of any significant changes by posting an updated Privacy Statement on our website or within the App.</p>
    
        <h2>Contact Us</h2>
    
        <p>If you have any questions, concerns, or requests regarding this Privacy Statement or your personal information, please contact us at support@gepsoft.com.</p>
    
        <p>By using \(getAppName()), you acknowledge and consent to the terms and practices described in this Privacy Statement.</p>
    
        <p>January, 2024</p>
    </div>

</body>
</html>
"""
    }
}
