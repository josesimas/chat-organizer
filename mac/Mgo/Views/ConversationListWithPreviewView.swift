//
//  ConversationListWithPreviewView.swift
//  PrompManager
//
//  Created by Jose Dias on 20/12/2023.
//

import SwiftUI

struct ConversationListWithPreviewView: View {
    @EnvironmentObject var dataModel: DataModel
    
    @State private var listViewWidth: CGFloat = 500 // Initial width of listView
    @State private var searchInWebPage: String = ""
    
    var body: some View {

        GeometryReader { geometry in
            HStack(spacing: 0) {
                masterView()
                    .frame(width: listViewWidth)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))
                                        
                dividerView(geometry: geometry)

                ConversationDetailView()
                    .frame(width: geometry.size.width - listViewWidth - 10) // Subtract divider width
            }
        }
    }
    
    func masterView() -> some View {
        
        VStack {            
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(dataModel.filteredConversations) { item in
                        ConversationListItemView(
                            text: item.title,
                            blurb: item.blurb,
                            selected: item.conversation.uuid == dataModel.currentConversation?.uuid,
                            folderName: dataModel.folders.first(where: { g in g.id == item.conversation.folderId})?.name ?? "",
                            created: item.createdDate,
                            questionCount: item.questionCount)
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
        .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 0))
    }
    
    func dividerView(geometry: GeometryProxy) -> some View {
        Divider()
            .frame(width: 2) // Width of the draggable divider
            .background(Color(nsColor: NSColor.windowBackgroundColor)) // macOS system color
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Adjust listViewWidth based on drag
                        let newWidth = listViewWidth + value.translation.width
                        if newWidth >= 450 {
                            listViewWidth = min(max(newWidth, 50), geometry.size.width - 50) // Minimum and maximum limits
                        }
                    }
            )
            .onHover { hovering in
                if hovering {
                    NSCursor.resizeLeftRight.set()
                } else {
                    NSCursor.arrow.set()
                }
            }
    }

}

struct ConversationListItemView: View {
    let text: String
    let blurb: String
    let selected: Bool
    let folderName: String
    let created: Date
    let questionCount: Int64

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Image(systemName: "doc")
                    .resizable()
                    .frame(width: 17, height: 20)
                    .if(selected) { view in
                        view.foregroundColor(.indigo)
                    }
                    .padding(EdgeInsets(top: 2, leading: 0, bottom: 0, trailing: 0))
                Text(text)
                    .font(.system(size: 18))
                    .if(selected) { view in
                        view.foregroundColor(.indigo)
                    }
            }
            .padding(EdgeInsets(top: 15, leading: 15, bottom: 0, trailing: 0))
            Spacer()
            Text(blurb.count < 150 ? blurb : "\(blurb)...")
                .font(.system(size: 10))
                .padding(EdgeInsets(top: 3, leading: 15, bottom: 0, trailing: 0))
            Spacer()
            HStack {
                Text(folderName)
                Spacer()
                Text("\(questionCount) questions")
                Spacer()
                Text(i18n.string(key: "created.colon"))
                Text(DateHelpers.formattedDate(date: created))
            }
            .foregroundColor(.secondary)
            .padding(EdgeInsets(top: 0, leading: 15, bottom: 15, trailing: 15))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 150)
        .background(.background)
        .cornerRadius(10)
        .if(selected) { view in
            view.shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 0)
        }
        .padding(EdgeInsets(top: 15, leading: 8, bottom: 0, trailing: 7))
    }
}

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
