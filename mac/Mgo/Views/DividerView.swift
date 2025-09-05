//
//  DividerView.swift
//  Mgo
//
//  Created by Jose Dias on 28/12/2023.
//

import SwiftUI

struct DividerView: View {
    @Binding var listViewWidth: CGFloat
    var geometrySizeWidth: CGFloat
    
    var body: some View  {
        Divider()
            .frame(width: 2) // Width of the draggable divider
            .background(Color(nsColor: NSColor.windowBackgroundColor)) // macOS system color
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Adjust listViewWidth based on drag
                        let newWidth = listViewWidth + value.translation.width
                        if newWidth >= 450 {
                            listViewWidth = min(max(newWidth, 50), geometrySizeWidth - 50) // Minimum and maximum limits
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
