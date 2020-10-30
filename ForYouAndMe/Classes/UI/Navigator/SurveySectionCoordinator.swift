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
    
    deinit {
        print("SurveySectionCoordinator - deinit")
    }
    
    // MARK: - Public Methods
    
    public func getStartingPage() -> UIViewController {
        
        let infoPageData = InfoPageData(page: self.sectionData.welcomePage,
                                addAbortOnboardingButton: false,
                                addCloseButton: false,
                                allowBackwardNavigation: false,
                                bodyTextAlignment: .left,
                                bottomViewStyle: .singleButton,
                                customImageHeight: nil,
                                defaultButtonFirstLabel: nil,
                                defaultButtonSecondLabel: nil)
        
        return InfoPageViewController(withPageData: infoPageData, coordinator: self)
    }
    
    // MARK: - Private Methods
    
    private func showQuestions() {
        if let question = self.sectionData.validQuestions.first {
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
        guard let questionIndex = self.sectionData.validQuestions.firstIndex(where: { $0.id == question.id }) else {
            assertionFailure("Missing question in question array")
            return
        }
        let pageData = SurveyQuestionPageData(question: question,
                                              questionNumber: questionIndex + 1,
                                              totalQuestions: self.sectionData.validQuestions.count)
        let viewController = SurveyQuestionViewController(withPageData: pageData, coordinator: self)
        self.navigationController.pushViewController(viewController, animated: true)
    }
    
    private func showNextSurveyQuestion(questionId: String) {
        guard let questionIndex = self.sectionData.validQuestions.firstIndex(where: { $0.id == questionId }) else {
            assertionFailure("Missing question in question array")
            return
        }
        
        let nextQuestionIndex = questionIndex + 1
        if nextQuestionIndex == self.sectionData.validQuestions.count {
            self.showSuccess()
        } else {
            let nextQuestion = self.sectionData.validQuestions[nextQuestionIndex]
            self.showQuestion(nextQuestion)
        }
    }
}

extension SurveySectionCoordinator: PagedSectionCoordinator {
    
    var isOnboarding: Bool { true }
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
                numericValue = minimum - 1
            }
            if let maximum = result.question.maximum, (result.answer as? String) == Constants.Survey.NumericTypeMaxValue {
                numericValue = maximum + 1
            }
            if let numericValue = numericValue {
                matchingTarget = result.question.targets?.getTargetMatchingCriteria(forNumber: numericValue)
            }
        case .pickOne:
            if let optionsIdentifiers = result.optionsIdentifiers {
                matchingTarget = result.question.targets?.getTargetMatchingCriteria(forOptionsIdentifiers: optionsIdentifiers)
            }
        case .pickMany:
            if let optionsIdentifiers = result.optionsIdentifiers {
                matchingTarget = result.question.targets?.getTargetMatchingCriteria(forOptionsIdentifiers: optionsIdentifiers)
            }
        case .textInput:
            break
        case .dateInput:
            break
        case .scale:
            if let numericValue = result.numericValue {
                matchingTarget = result.question.targets?.getTargetMatchingCriteria(forNumber: numericValue)
            }
        case .range:
            if let numericValue = result.numericValue {
                matchingTarget = result.question.targets?.getTargetMatchingCriteria(forNumber: numericValue)
            }
        }
        
        if let matchingTarget = matchingTarget {
            if matchingTarget.questionId == Constants.Survey.TargetQuit {
                self.showSuccess()
            } else {
                guard let question = self.sectionData.validQuestions.first(where: { $0.id == matchingTarget.questionId }) else {
                    assertionFailure("Missing valid question in question array")
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
