//
//  UiThreadHelper.swift
//  Mgo
//
//  Created by Jose Dias on 17/12/2023.
//

import Foundation

struct UiThreadHelper {
    
    public static func invokeSafely(function: @escaping  () -> Void) {
        if Thread.isMainThread {
            function()
        } else {
            DispatchQueue.main.async {
                function()
            }
        }
    }
}

