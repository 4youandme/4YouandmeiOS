//
//  Feed.swift
//  ForYouAndMe
//
//  Created by Leonardo Passeri on 23/07/2020.
//

import Foundation

enum Schedulable {
    case activity(activity: Activity)
    
    var schedulableType: String {
        switch self {
        case .activity: return "activity"
        }
    }
}

struct Feed {
    let id: String
    let type: String
    
    @DateValue<ISO8601Strategy>
    var fromDate: Date
    @DateValue<ISO8601Strategy>
    var toDate: Date
    
    @SchedulableDecodable
    var schedulable: Schedulable
}

extension Feed: JSONAPIMappable {
    static var includeList: String? = """
schedulable
"""
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case fromDate = "from"
        case toDate = "to"
        case schedulable
    }
}

enum FeedError: Error {
    case invalidSchedulable
}

@propertyWrapper
struct SchedulableDecodable: Decodable {
    
    var wrappedValue: Schedulable
    
    init(wrappedValue: Schedulable) {
        self.wrappedValue = wrappedValue
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let activity = try? container.decode(Activity.self), Schedulable.activity(activity: activity).schedulableType == activity.type {
            self.wrappedValue = .activity(activity: activity)
        } else {
            // TODO: Add all expected cases
            throw FeedError.invalidSchedulable
        }
    }
}
