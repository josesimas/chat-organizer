//
//  LinkView.swift
//  Mgo
//
//  Created by Jose Dias on 11/12/2023.
//

import SwiftUI

struct LinkView: View {
    var text: String
    var action: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 5) {
            // Text that looks like a link
            Text(text)
                .foregroundColor(.accentColor)
                .underline()
                .onHover { hovering in
                    self.isHovering = hovering
                }
                .onTapGesture {
                    action() // Call the action closure
                }
        }
        .contentShape(Rectangle()) // Ensure the hover area includes the entire HStack
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.set() // Change cursor to pointing hand
            } else {
                NSCursor.arrow.set() // Revert cursor to default
            }
        }
    }
}

struct TitleLinkView: View {
    var text: String
    var iconName: String
    var action: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 5) {
            
            Text(text)
                .font(.system(size: 24))
                .foregroundColor(.accentColor)
                //.fontWeight(.bold)
                .onHover { hovering in
                    self.isHovering = hovering
                }
                .onTapGesture {
                    action() // Call the action closure
                }
        }
        .contentShape(Rectangle()) // Ensure the hover area includes the entire HStack
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.set() // Change cursor to pointing hand
            } else {
                NSCursor.arrow.set() // Revert cursor to default
            }
        }
    }
}

#Preview {
    LinkView(text: "Link", action: { })
}

