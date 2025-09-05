//
//  SearchBarView.swift
//  Mgo
//
//  Created by Jose Dias on 14/12/2023.
//

import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String
    var placeholder: String
    
    @FocusState private var isTextFieldFocused: Bool
    @State private var placeholderState: String
    
    init(searchText: Binding<String>, placeholder: String) {
       self._searchText = searchText
       self.placeholder = placeholder
       self._placeholderState = State(initialValue: placeholder)
   }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Group {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                HStack {
                    TextField(placeholderState, text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.leading, 20)
                        .focused($isTextFieldFocused)
                        .onChange(of: isTextFieldFocused) {
                            if isTextFieldFocused {
                                placeholderState = ""
                            } else {
                                placeholderState = placeholder
                            }
                        }
                    Spacer()
                    if self.searchText != "" {
                        Button(action: {
                            self.searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 5)
                    }
                }
            }
            .padding(7)
        }
        .frame(width: 250)
        .frame(maxWidth: 250)
        .border(Color(nsColor: NSColor.disabledControlTextColor), width: 1)
    }
}

