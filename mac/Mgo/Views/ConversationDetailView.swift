//
//  ConversationDetailView.swift
//  Mgo
//
//  Created by Jose Dias on 14/12/2023.
//

import SwiftUI

struct ConversationDetailView: View {
    @EnvironmentObject var dataModel: DataModel
        
    var body: some View {
        VStack {
            if dataModel.currentConversation != nil {
                let html = HtmlHelper.getConversationAsHtml(
                    path: dataModel.path,
                    uuid: dataModel.currentConversation!.uuid,
                    searchString: dataModel.searchTerm,
                    showToolsAndSystem: dataModel.showToolsAndSystem)
                                
                HtmlView(urlString: "", htmlContent: html)
                    .cornerRadius(10)
                    .padding(EdgeInsets(top: 15, leading: 7, bottom: 0, trailing: 12))
                    
                Spacer()
                if dataModel.currentConversationHasTags() {
                    HStack {
                        BreadcrumbsView(conversationId: dataModel.currentConversation?.id ?? 0)
                            .padding(EdgeInsets(top: 3, leading: 0, bottom: 10, trailing: 10))
                        Spacer()
                    }
                    .padding(EdgeInsets(top: 0, leading: 7, bottom: 0, trailing: 0))
                }
            }
        }
    }
}

