//
//  Master.swift
//  Mgo
//
//  Created by Jose Dias on 28/12/2023.
//

import SwiftUI

struct MasterView: View {
    @EnvironmentObject var dataModel: DataModel
    
    var body: some View {
        VStack {
            
            if dataModel.filteredConversations.isEmpty {
                Group {
                    if dataModel.searchTerm.isEmpty {
                        Text("No conversations found")
                    } else {
                        if let f = dataModel.selectedFolder {
                            Text("No conversations found for the search \(dataModel.searchTerm) in the folder \(f.name)")
                        } else {
                            if let t = dataModel.selectedTag {
                                Text("No conversations found for the search \(dataModel.searchTerm) in the tag \(t.name)")
                            } else {
                                Text("No conversations found")
                            }
                        }
                    }
                }
                .font(.system(size: 14))
                .padding(.top, 50)
                Spacer()
            }
            else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(dataModel.filteredConversations) { item in
                            ConversationListItemView(
                                text: item.title,
                                blurb: item.blurb,
                                selected: item.conversation.uuid == dataModel.currentConversation?.uuid,
                                folderName: dataModel.folders.first(where: { g in g.id == item.conversation.folderId})?.name ?? "",
                                created: item.createdDate,
                                questionCount: item.questionCount,
                                rate: item.rate,
                                updateConversationRate: { rate in
                                    UpdateConversationRateCommand.run(dataModel, id: item.id, rate: Int64(rate))
                                })
                                .onTapGesture {
                                    dataModel.currentConversation = item.conversation
                                }
                                .onHover { hovering in
                                    if hovering {
                                        NSCursor.pointingHand.set() // Change cursor to pointing hand
                                    } else {
                                        NSCursor.arrow.set() // Revert cursor to default
                                    }
                                }
                                .onDrag({
                                    if NSEvent.modifierFlags.contains(.shift) {
                                        let ids = dataModel.filteredConversations.map({ String($0.id) })
                                        return NSItemProvider(object: ids.joined(separator: ",") as NSString)
                                       } else {
                                           return NSItemProvider(object: String(item.id) as NSString)
                                       }
                                })
                        }
                    }
                }
            }
        }
        .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 0))
    }
}
