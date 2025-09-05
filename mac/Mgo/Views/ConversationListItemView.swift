//
//  ConversationListItemView.swift
//  Mgo
//
//  Created by Jose Dias on 28/12/2023.
//
import SwiftUI

struct ConversationListItemView: View {
    let text: String
    let blurb: String
    let selected: Bool
    let folderName: String
    let created: Date
    let questionCount: Int64
    let rate: Int64
    var updateConversationRate: (_ newRate: Int64) -> Void
    
    @State private var internalRate: Int64 = 0

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
                Spacer()
                HStack {
                    ForEach(0..<5) { i in
                        Image(systemName: "star.fill")
                            .foregroundColor(getColor(i))
                            .frame(width: 15)
                            .onHover { hovering in
                                if hovering {
                                    NSCursor.pointingHand.set()
                                } else {
                                    NSCursor.arrow.set()
                                }
                            }
                            .onTapGesture {
                                if i == 0 && internalRate == 1 {
                                    internalRate = 0
                                    updateConversationRate(internalRate)
                                    return
                                }
                                internalRate = Int64(i) + 1
                                updateConversationRate(internalRate)
                            }
                    }
                }
                .padding(.trailing, 15)
            }
            .onAppear() {
                internalRate = rate
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
    
    func getColor(_ i : Int) -> Color {
        if i < internalRate && internalRate > 0 {
            return Color.yellow
        }
        return Color.gray
    }
}
