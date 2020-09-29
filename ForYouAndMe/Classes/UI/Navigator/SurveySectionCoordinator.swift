//
//  SurveySectionCoordinator.swift
//  ForYouAndMe
//
//  Created by Leonardo Passeri on 24/09/2020.
//

import Foundation

class SurveySectionCoordinator {
    
    typealias SurveySectionCallback = (UINavigationController, SurveyTask, [SurveyResult]) -> Void
    
    public unowned var navigationController: UINavigationController
    
    private let sectionData: SurveyTask
    private let completionCallback: SurveySectionCallback
    
    private var results: [SurveyResult] = []
    
    init(withSectionData sectionData: SurveyTask,
         navigationController: UINavigationController,
         completionCallback: @escaping SurveySectionCallback) {
        self.sectionData = sectionData
        self.navigationController = navigationController
        self.completionCallback = completionCallback
    }
    
    // MARK: - Public Methods
    
    public func getStartingPage(showCloseButton: Bool) -> UIViewController {
        let infoPageData = InfoPageData.createWelcomePageData(withPage: self.sectionData.welcomePage, showCloseButton: showCloseButton)
        return InfoPageViewController(withPageData: infoPageData, coordinator: self)
    }
    
    // MARK: - Private Methods
    
    private func showQuestions() {
        if let question = self.sectionData.questions.first {
            self.showQuestion(question)
        } else {
            assertionFailure("Missing questions for current survey")
            self.showSuccess()
        }
    }
    
    private func showSuccess() {
        if let successPage = self.sectionData.successPage {
            let infoPageData = InfoPageData.createResultPageData(withPage: successPage)
            let viewController = InfoPageViewController(withPageData: infoPageData, coordinator: self)
            self.navigationController.pushViewController(viewController, animated: true)
        } else {
            self.completionCallback(self.navigationController, self.sectionData, self.results)
        }
    }
    
    private func showQuestion(_ question: SurveyQuestion) {
        guard let questionIndex = self.sectionData.questions.firstIndex(where: { $0.id == question.id }) else {
            assertionFailure("Missing question in question array")
            return
        }
        let pageData = SurveyQuestionPageData(question: question,
                                              questionNumber: questionIndex + 1,
                                              totalQuestions: self.sectionData.questions.count)
        let viewController = SurveyQuestionViewController(withPageData: pageData, coordinator: self)
        self.navigationController.pushViewController(viewController, animated: true)
    }
    
    private func showNextSurveyQuestion(questionId: String) {
        guard let questionIndex = self.sectionData.questions.firstIndex(where: { $0.id == questionId }) else {
            assertionFailure("Missing question in question array")
            return
        }
        
        let nextQuestionIndex = questionIndex + 1
        if nextQuestionIndex == self.sectionData.questions.count {
            self.showSuccess()
        } else {
            let nextQuestion = self.sectionData.questions[nextQuestionIndex]
            self.showQuestion(nextQuestion)
        }
    }
}

extension SurveySectionCoordinator: PagedSectionCoordinator {
    
    var pages: [Page] { self.sectionData.pages }
    
    func performCustomPrimaryButtonNavigation(page: Page) -> Bool {
        if self.sectionData.successPage?.id == page.id {
            self.completionCallback(self.navigationController, self.sectionData, self.results)
            return true
        }
        return false
    }
    
    func onUnhandledPrimaryButtonNavigation(page: Page) {
        self.showQuestions()
    }
}

extension SurveySectionCoordinator: SurveyQuestionViewCoordinator {
    func onSurveyQuestionAnsweredSuccess(result: SurveyResult) {
        
        guard result.isValid else {
            assertionFailure("Result validation failed")
            self.showNextSurveyQuestion(questionId: result.question.id)
            return
        }
        
        if let resultIndex = self.results.firstIndex(where: { $0.question == result.question }) {
            self.results[resultIndex] = result
        } else {
            self.results.append(result)
        }
        
        // Skip logic
        var matchingTarget: SurveyTarget?
        switch result.question.questionType {
        case .numerical:
            var numericValue = result.numericValue
            if let minimum = result.question.minimum, (result.answer as? String) == Constants.Survey.NumericTypeMinValue {
                numericValue = minimum - 1.0
            }
            if let maximum = result.question.maximum, (result.answer as? String) == Constants.Survey.NumericTypeMaxValue {
                numericValue = maximum + 1.0
            }
            if let numericValue = numericValue {
                matchingTarget = result.question.targets?.getTargetMatchingCriteria(forNumber: numericValue)
            }
        case .pickOne:
            if let optionsIdentifiers = result.optionsIdentifiers {
                matchingTarget = result.question.options?
                    .first(where: { optionsIdentifiers.contains($0.id) && $0.targets?.first != nil })?.targets?.first
            }
        case .pickMany:
            if let optionsIdentifiers = result.optionsIdentifiers {
                matchingTarget = result.question.options?
                    .first(where: { optionsIdentifiers.contains($0.id) && $0.targets?.first != nil })?.targets?.first
            }
        case .textInput:
            self.showNextSurveyQuestion(questionId: result.question.id)
        case .dateInput:
            self.showNextSurveyQuestion(questionId: result.question.id)
        case .scale:
            if let numericValue = result.numericValue {
                matchingTarget = result.question.targets?.getTargetMatchingCriteria(forNumber: numericValue)
            }
        case .range:
            if let rangeValue = result.range {
                matchingTarget = result.question.targets?.getTargetMatchingCriteria(forRange: rangeValue)
            }
        }
        
        if let matchingTarget = matchingTarget {
            if matchingTarget.questionId == Constants.Survey.TargetQuit {
                self.showSuccess()
            } else {
                guard let question = self.sectionData.questions.first(where: { $0.id == matchingTarget.questionId }) else {
                    assertionFailure("Missing question in question array")
                    self.showNextSurveyQuestion(questionId: result.question.id)
                    return
                }
                self.showQuestion(question)
            }
        } else {
            self.showNextSurveyQuestion(questionId: result.question.id)
        }
    }
    
    func onSurveyQuestionSkipped(questionId: String) {
        self.showNextSurveyQuestion(questionId: questionId)
    }
}

extension SurveyResult {
    var isValid: Bool {
        switch self.question.questionType {
        case .numerical:
            guard let stringValue = self.answer as? String else { return false }
            if stringValue == Constants.Survey.NumericTypeMinValue {
                return true
            } else if stringValue == Constants.Survey.NumericTypeMaxValue {
                return true
            } else if let intValue = Int(stringValue) {
                if let minimum = self.question.minimum, intValue < Int(minimum) {
                    return false
                }
                if let maximum = self.question.maximum, intValue > Int(maximum) {
                    return false
                }
                return true
            }
            return false
        case .pickOne:
            guard let options = self.question.options else { return false }
            guard let optionIdentifier = self.answer as? String else { return false }
            return options.contains(where: { $0.id == optionIdentifier })
        case .pickMany:
            guard let options = self.question.options else { return false }
            guard let optionIdentifiers = self.answer as? [String] else { return false }
            return optionIdentifiers.allSatisfy(options.map { $0.id }.contains)
        case .textInput:
            guard let text = self.answer as? String else { return false }
            if let maxCharacters = self.question.maxCharacters, text.count > maxCharacters { return false }
            return !text.isEmpty
        case .dateInput:
            guard let dateStr = self.answer as? String else { return false }
            guard let date = DateStrategy.dateFormatter.date(from: dateStr) else { return false }
            if let minimumDate = self.question.minimumDate, date < minimumDate { return false }
            if let maximumDate = self.question.maximumDate, date > maximumDate { return false }
            return true
        case .scale:
            guard let value = self.answer as? Double else { return false }
            if let minimum = self.question.minimum, value < minimum { return false }
            if let maximum = self.question.maximum, value > maximum { return false }
            if let interval = self.question.interval, value.truncatingRemainder(dividingBy: interval) != 0 { return false }
            return true
        case .range:
            guard let value = self.answer as? [Double], value.count == 2 else { return false }
            let lowerBound = value[0]
            let upperBound = value[1]
            guard lowerBound < upperBound else { return false }
            if let minimum = self.question.minimum, lowerBound < minimum { return false }
            if let maximum = self.question.maximum, lowerBound > maximum { return false }
            if let interval = self.question.interval, lowerBound.truncatingRemainder(dividingBy: interval) != 0 { return false }
            if let minimum = self.question.minimum, upperBound < minimum { return false }
            if let maximum = self.question.maximum, upperBound > maximum { return false }
            if let interval = self.question.interval, upperBound.truncatingRemainder(dividingBy: interval) != 0 { return false }
            return true
        }
    }
    
    var numericValue: Double? {
        switch self.question.questionType {
        case .numerical:
            guard let stringValue = self.answer as? String else { return nil }
            guard let intValue = Int(stringValue) else { return nil }
            return Double(intValue)
        case .pickOne: return nil
        case .pickMany: return nil
        case .textInput: return nil
        case .dateInput: return nil
        case .scale: return self.answer as? Double
        case .range: return nil
        }
    }
    
    var optionsIdentifiers: [String]? {
        switch self.question.questionType {
        case .numerical: return nil
        case .pickOne:
            guard let optionIdentifier = self.answer as? String else { return nil }
            return [optionIdentifier]
        case .pickMany: return self.answer as? [String]
        case .textInput: return nil
        case .dateInput: return nil
        case .scale: return nil
        case .range: return nil
        }
    }
    
    var range: ClosedRange<Double>? {
        switch self.question.questionType {
        case .numerical: return nil
        case .pickOne: return nil
        case .pickMany: return nil
        case .textInput: return nil
        case .dateInput: return nil
        case .scale: return nil
        case .range:
            guard let value = self.answer as? [Double], value.count == 2 else { return nil }
            let lowerBound = value[0]
            let upperBound = value[1]
            return ClosedRange(uncheckedBounds: (lower: lowerBound, upper: upperBound))
        }
    }
}

extension Array where Element == SurveyTarget {
    func getTargetMatchingCriteria(forNumber number: Double) -> SurveyTarget? {
        self.first { target in
            guard let criteria = target.criteria else {
                assertionFailure("Missing expected criteria")
                return true
            }
            switch criteria {
            case .range:
                if let minimum = target.minimum, number < minimum { return false }
                if let maximum = target.maximum, number > maximum { return false }
                return true
            }
        }
    }
    func getTargetMatchingCriteria(forRange range: ClosedRange<Double>) -> SurveyTarget? {
        self.first { target in
            guard let criteria = target.criteria else {
                assertionFailure("Missing expected criteria")
                return true
            }
            switch criteria {
            case .range:
                if let minimum = target.minimum, range.lowerBound < minimum { return false }
                if let maximum = target.maximum, range.lowerBound > maximum { return false }
                if let minimum = target.minimum, range.upperBound < minimum { return false }
                if let maximum = target.maximum, range.upperBound > maximum { return false }
                return true
            }
        }
    }
}