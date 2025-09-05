//
//  BreadcrumbsView.swift
//  Mgo
//
//  Created by Jose Dias on 15/12/2023.
//

import SwiftUI

struct BreadcrumbsView : View {
    @EnvironmentObject var dataModel: DataModel
    let conversationId: Int64
        
    private let letMaxTagVisible = 6
    @State private var showTagList = false
    
    var body: some View {
        HStack {
            if conversationId > 0 && Query.conversationHasTags(dataModel, conversationId) {
                // Limit the number of tags displayed to letMaxTagVisible
                let tags = Query.getConversationTags(databasePath: dataModel.path, conversationId: conversationId).reversed()
                
                ForEach(tags.prefix(letMaxTagVisible)) { t in
                    Button(action: {
                        Query.removeTagFromConversation(dataModel, t.id, conversationId)
                    }) {
                        HStack {
                            Text(t.name)
                                .foregroundColor(.secondary)
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .padding(5)
                    }
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 3))
                }
                if(tags.count > letMaxTagVisible) {
                    LinkView(text: "View all assigned...", action: {
                        showTagList = true
                    })
                    .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 0))
                }
            }
        }
        .frame(height: 25)
        .sheet(isPresented: $showTagList) {
            TagListView(conversationId: self.conversationId,showModal: $showTagList)
            }
    }

}

struct TagListView: View {
    @EnvironmentObject var dataModel: DataModel
    let conversationId: Int64
    @Binding var showModal: Bool
    
    var body: some View {
        VStack {
            Text("All the tags assigned to this conversation")
                .padding(5)
            ScrollView {
                ForEach(Query.getConversationTags(databasePath: dataModel.path, conversationId: conversationId)) { t in
                    HStack {
                        Spacer() 
                        Button(action: {
                            Query.removeTagFromConversation(dataModel, t.id, conversationId)
                        }) {
                            HStack {
                                Text(t.name)
                                    .foregroundColor(.secondary)
                                    .frame(minWidth: 100)
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .padding(5)
                        }
                        Spacer() // Add a Spacer after your content
                    }
                }
            }

            Button("Close") {
                showModal = false
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.extraLarge)
            .keyboardShortcut(.defaultAction)
            .padding()
        }
        .frame(minWidth: 350, minHeight: 450)
        .padding(30)
    }
}
