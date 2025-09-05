//
//  ViewExtensions.swift
//  Mgo
//
//  Created by Jose Dias on 28/12/2023.
//

import SwiftUI

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
