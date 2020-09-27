//
//  SurveyQuestionPickerFactory.swift
//  ForYouAndMe
//
//  Created by Giuseppe Lapenta on 27/09/2020.
//

struct SurveyQuestionPickerFactory {
  
    static func getSurveyQuestionPicker(for question: SurveyQuestion) -> UIView {
        switch question.questionType {
        case .numerical:
            return SurveyQuestionNumerical(surveyQuestion: question)
        case .pickOne:
            return SurveyQuestionNumerical(surveyQuestion: question)
        case .pickMany:
            return SurveyQuestionNumerical(surveyQuestion: question)
        case .textInput:
            return SurveyQuestionNumerical(surveyQuestion: question)
        case .dateInput:
            return SurveyQuestionNumerical(surveyQuestion: question)
        case .scale:
            return SurveyQuestionNumerical(surveyQuestion: question)
        case .range:
            return SurveyQuestionNumerical(surveyQuestion: question)
        }
    }
}
