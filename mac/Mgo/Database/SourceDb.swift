//
//  Source.swift
//  Mgo
//
//  Created by Jose Dias on 06/12/2023.
//

import Foundation

struct Source {
    let id: Int64
    let name: String
    let uri: String?
    var conversations: [Conversation]
}

struct Conversation: Identifiable {
    let id: Int64
    let uuid: String
    let created: Double
    let updated: Double
    let title: String
    let sourceId: Int64
    let folderId: Int64
    let rate: Int64
}

struct Message {
    let id: Int64
    let conversationId: Int64
    let messageUuid: String
    let created: Double
    let roleId: Int64
    let text: String?
    let assistantDetails: String?
}

struct Folder {
    let id: Int64
    let name: String
    let path: String
    let created: Double
    var conversationCount: Int64
}

struct Tag {
    let id: Int64
    let name: String
    let created: Double
    var conversationCount: Int64
}

struct TagConversation {
    let id: Int64
    let tagId: Int64
    let conversationId: Int64
}

