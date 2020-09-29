//
//  SurveyQuestion.swift
//  ForYouAndMe
//
//  Created by Leonardo Passeri on 24/09/2020.
//

import Foundation
import RxSwift

enum SurveyQuestionType: String {
    case numerical = "numerical"
    case pickOne = "pick-one"
    case pickMany = "pick-many"
    case textInput = "text-input"
    case dateInput = "date-input"
    case scale = "scale"
    case range = "range"
}

struct SurveyQuestion {
    let id: String
    let type: String
    
    @EnumStringDecodable
    var questionType: SurveyQuestionType
    
    let body: String
    @ImageDecodable
    var image: UIImage?
    
    // Details
    var minimum: Double?
    var maximum: Double?
    var interval: Double?
    @NilIfEmptyString
    var minimumDisplay: String?
    @NilIfEmptyString
    var maximumDisplay: String?
    @NilIfEmptyString
    var minimumLabel: String?
    @NilIfEmptyString
    var maximumLabel: String?
    @NilIfEmptyString
    var placeholder: String?
    var maxCharacters: Int?
    @FailableDateValue<DateStrategy>
    var minimumDate: Date?
    @FailableDateValue<DateStrategy>
    var maximumDate: Date?
    
    // Options
    let options: [SurveyQuestionOption]?
    
    let targets: [SurveyTarget]?
}

extension SurveyQuestion: Decodable {
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case questionType = "question_type"
        case body
        case image
        case minimum = "min"
        case maximum = "max"
        case interval = "interval"
        case minimumDisplay = "min_display"
        case maximumDisplay = "max_display"
        case minimumLabel = "min_label"
        case maximumLabel = "max_label"
        case placeholder = "placeholder"
        case maxCharacters = "max_characters"
        case minimumDate = "min_date"
        case maximumDate = "max_date"
        case options
        case targets
    }
}

extension SurveyQuestion: Hashable, Equatable {
    static func == (lhs: SurveyQuestion, rhs: SurveyQuestion) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}