//
//  Date+Extensions.swift
//  ForYouAndMe
//
//  Created by Leonardo Passeri on 24/04/2020.
//  Copyright © 2020 Balzo srl. All rights reserved.
//

import Foundation

public let dateTimeFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
public let dateFormat = "yyyy-MM-dd"
public let timeFormat = "hh:mm a"
public let utc = "UTC"
public let dayTime = "HH"
public let dayShort = "EEE"
public let shortDate = "MMM dd\nyyyy"

public extension Date {
    func string(withFormat format: String, timeZone: TimeZone? = nil, locale: Locale? = nil) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        if let timeZone = timeZone {
            dateFormatter.timeZone = timeZone
        }
        if let locale = locale {
            dateFormatter.locale = locale
        }
        return dateFormatter.string(from: self)
    }
    
    static func currentDateInMilliSeconds() -> Double {
        return round(Date().timeIntervalSince1970 * 1000)
    }
    
    func getDate(for days: Int) -> Date {
        let date = Calendar.current.date(byAdding: .day, value: days, to: self)
        return date ?? Date()
    }
    
    func getDates(for days: Int, interval: Int, format: String = dayShort) -> [String] {
        var arrayOfDates = [String]()
        arrayOfDates.append(self.string(withFormat: format))
        for index in 1...interval {
            arrayOfDates.append(self.getDate(for: (-index * days)).string(withFormat: format))
        }
        return arrayOfDates.reversed()
    }
}

public extension String {
    func date(withFormat format: String, timeZone: TimeZone? = nil, locale: Locale? = nil) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        if let timeZone = timeZone {
            dateFormatter.timeZone = timeZone
        }
        if let locale = locale {
            dateFormatter.locale = locale
        }
        return dateFormatter.date(from: self)
    }
}
