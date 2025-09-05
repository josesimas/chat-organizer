//
//  DateHelpers.swift
//  Mgo
//
//  Created by Jose Dias on 11/12/2023.
//

import Foundation

struct DateHelpers {

    static func dateFromTimestamp(_ timestamp: Double) -> Date {
        return Date(timeIntervalSince1970: timestamp)
    }
    
    static func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM dd yyyy, HH:mm"
        return formatter.string(from: date)
    }
}


