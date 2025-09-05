//
//  SearchResultConversationViewModel.swift
//  Mgo
//
//  Created by Jose Dias on 11/12/2023.
//

import Foundation

struct SearchResultConversationViewModel: Identifiable {
    let id: Int64
    let uuid: String
    let created: Double
    let updated: Double
    let title: String
    let conversation: Conversation
    let questionCount: Int64
    let blurb: String
    let rate: Int64
    
    public var createdDate: Date {
        return DateHelpers.dateFromTimestamp(created)
    }
    public var updatedDate: Date {
        return DateHelpers.dateFromTimestamp(updated)
    }
        
    static func fromModel(conversation: Conversation, questionCount: Int64, blurb: String) -> SearchResultConversationViewModel {
        return SearchResultConversationViewModel(
            id: conversation.id,
            uuid: conversation.uuid,
            created: conversation.created,
            updated: conversation.updated,
            title: conversation.title,
            conversation: conversation,
            questionCount: questionCount,
            blurb: String(blurb.prefix(150)),
            rate: conversation.rate
        )
    }
}
