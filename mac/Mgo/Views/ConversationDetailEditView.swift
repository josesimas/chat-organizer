//
//  ConversationListWithEditView.swift
//  Mgo
//
//  Created by Jose Dias on 28/12/2023.
//

import SwiftUI

struct ConversationDetailEditView: View {
    @EnvironmentObject var dataModel: DataModel
    @Binding var conversation: Conversation?
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        
        VStack {
            ScrollView {
                VStack(spacing: 0) {
                    HStack {
                        Text(Query.getAssistantName(dataModel))
                            .padding(.leading, 20)
                            .padding(.top, 10)
                        Spacer()
                    }
                    ForEach(Array(dataModel.messages.enumerated()), id: \.offset) { index, message in
                        
                        if dataModel.showToolsAndSystem == false && (message.type == "TOOL" || message.type == "SYSTEM") {
                            //don't show tool and system messages if not explicitly set by the user
                        }
                        else {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(message.type)
                                        .fontWeight(.bold)
                                        .font(.system(size: 15))
                                        .padding(.leading, 5)
                                    Spacer()
                                    
                                    /*HStack {
                                        Image(systemName: message.selected ? "checkmark.square.fill" : "square")
                                            .resizable()
                                            .foregroundColor( message.selected  ? .blue : .gray)
                                            .frame(width: 20, height: 20)
                                            .onTapGesture {
                                                dataModel.messages[index].selected.toggle()
                                            }
                                    }*/
                                }
                                
                                ZStack(alignment: .topLeading) {
                                    TextEditor(text: $dataModel.messages[index].text)
                                        .font(.system(size: 16))
                                        .padding(8) // External padding to create the illusion of internal padding
                                }
                                .background(backgroundColor)
                                .border(Color.gray, width: 1)
                                
                                HStack {
                                    Button(i18n.string(key: "save")) {
                                        Command.updateMessageText(dataModel, messageId: dataModel.messages[index].id, newText: dataModel.messages[index].text)
                                        dataModel.messages[index].changed = false
                                    }
                                    .disabled(dataModel.messages[index].changed == false)
                                    .controlSize(.extraLarge)
                                    Spacer()
                                }
                                
                            }
                        }
                        
                    }
                    .padding()
                }
            }
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? .black.opacity(0.5) : .white
        }
}
