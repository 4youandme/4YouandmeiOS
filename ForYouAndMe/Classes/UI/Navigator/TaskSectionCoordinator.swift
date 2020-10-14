//
//  TaskSectionCoordinator.swift
//  ForYouAndMe
//
//  Created by Leonardo Passeri on 17/07/2020.
//

import Foundation
import ResearchKit
import RxSwift

class TaskSectionCoordinator: NSObject, ActivitySectionCoordinator {
    
    var navigationController: UINavigationController {
        guard let navigationController = self.internalNavigationController else {
            assertionFailure("Missing navigation controller")
            return UINavigationController()
        }
        return navigationController
    }
    private weak var internalNavigationController: UINavigationController?
    
    // MARK: - ActivitySectionCoordinator
    var activityPresenter: UIViewController? { return self.navigationController }
    let taskIdentifier: String
    let navigator: AppNavigator
    let repository: Repository
    let completionCallback: NotificationCallback
    let disposeBag = DisposeBag()
    
    private let taskType: TaskType
    private let taskOptions: TaskOptions?
    private let welcomePage: Page?
    private let successPage: Page?
    
    init(withTaskIdentifier taskIdentifier: String,
         taskType: TaskType,
         taskOptions: TaskOptions?,
         welcomePage: Page?,
         successPage: Page?,
         completionCallback: @escaping NotificationCallback) {
        self.taskIdentifier = taskIdentifier
        self.taskType = taskType
        self.taskOptions = taskOptions
        self.welcomePage = welcomePage ?? taskType.welcomePage
        self.successPage = successPage ?? taskType.successPage
        self.completionCallback = completionCallback
        self.navigator = Services.shared.navigator
        self.repository = Services.shared.repository
        super.init()
    }
    
    // MARK: - Public Methods
    
    public func getStartingPage() -> UIViewController? {
        let navigationController: UINavigationController? = {
            if let welcomeViewController = self.getWelcomeViewController() {
                return UINavigationController(rootViewController: welcomeViewController)
            } else if let taskViewController = self.getTaskViewController(showInstructionPage: true, showConclusionPage: true) {
                let navigationController = UINavigationController(rootViewController: taskViewController)
                navigationController.navigationBar.apply(style: NavigationBarStyleCategory.secondary(hidden: true).style)
                return navigationController
            } else {
                return nil
            }
        }()
        self.internalNavigationController = navigationController
        return navigationController
    }
    
    // MARK: - Private Methods
    
    private func getWelcomeViewController() -> UIViewController? {
        let welcomePage = self.welcomePage
        guard let page = welcomePage else {
            return nil
        }
        let infoPageData = InfoPageData(page: page,
                                        addAbortOnboardingButton: false,
                                        addCloseButton: true,
                                        allowBackwardNavigation: false,
                                        bodyTextAlignment: .left,
                                        bottomViewStyle: .horizontal,
                                        customImageHeight: nil)
        return InfoPageViewController(withPageData: infoPageData, coordinator: self)
    }
    
    private func getSuccessViewController() -> UIViewController? {
        let successPage = self.successPage
        guard let page = successPage else {
            return nil
        }
        let infoPageData = InfoPageData(page: page,
                                        addAbortOnboardingButton: false,
                                        addCloseButton: false,
                                        allowBackwardNavigation: false,
                                        bodyTextAlignment: .center,
                                        bottomViewStyle: .singleButton,
                                        customImageHeight: 140.0)
        return InfoPageViewController(withPageData: infoPageData, coordinator: self)
    }
    
    private func getTaskViewController(showInstructionPage: Bool, showConclusionPage: Bool) -> UIViewController? {
        guard let task = self.taskType.createTask(withIdentifier: self.taskIdentifier,
                                                  options: self.taskOptions,
                                                  showIstructions: showInstructionPage,
                                                  showConclusion: showConclusionPage) else {
            assertionFailure("Couldn't find ORKTask for given task")
            return nil
        }
        
        self.customizeTaskUI()
        
        // Create and setup task controller
        let taskViewController = ORKTaskViewController(task: task, taskRun: nil)
        taskViewController.navigationBar.apply(style: NavigationBarStyleCategory.secondary(hidden: true).style)
        taskViewController.delegate = self
        taskViewController.view.tintColor = ColorPalette.color(withType: .primary)
        taskViewController.outputDirectory = Constants.Task.taskResultURL
        taskViewController.view.backgroundColor = ColorPalette.color(withType: .secondary)
        
        return taskViewController
    }
    
    private func customizeTaskUI() {
        // Setup Colors
        ORKColorSetColorForKey(ORKCheckMarkTintColorKey, ColorPalette.color(withType: .primary))
        ORKColorSetColorForKey(ORKAlertActionTintColorKey, ColorPalette.color(withType: .primary))
        ORKColorSetColorForKey(ORKBlueHighlightColorKey, ColorPalette.color(withType: .primary))
        ORKColorSetColorForKey(ORKToolBarTintColorKey, ColorPalette.color(withType: .primary))
        ORKColorSetColorForKey(ORKBackgroundColorKey, ColorPalette.color(withType: .secondary))
        ORKColorSetColorForKey(ORKResetDoneButtonKey, ColorPalette.color(withType: .primary))
        ORKColorSetColorForKey(ORKDoneButtonPressedKey, ColorPalette.color(withType: .primary))
        ORKColorSetColorForKey(ORKBulletItemTextColorKey, ColorPalette.color(withType: .primary))
        ORKColorSetColorForKey(ORKAuxiliaryImageTintColorKey, ColorPalette.color(withType: .primary))
        ORKColorSetColorForKey(ORKTopContentImageViewBackgroundColorKey, ColorPalette.color(withType: .secondary))
        
        // Setup Layout
        ORKBorderedButtonCornerRadius = 25.0
        ORKBorderedButtonShouldApplyDefaultShadow = true
    }
    
    private func cancelTask() {
        self.rotateToPortrait()
        self.deleteTaskResult(path: Constants.Task.taskResultURL)
        self.completionCallback()
    }
    
    private func handleError(error: Error?, presenter: UIViewController) {
        if let error = error {
            print("TaskSectionCoordinator - Error: \(error)")
        }
        self.navigator.handleError(error: nil, presenter: presenter, onDismiss: { [weak self] in
            self?.cancelTask()
        })
    }
    
    private func sendResult(taskResult: ORKTaskResult, presenter: UIViewController) {
        guard let taskNetworkResult = self.taskType.getNetworkResultData(taskResult: taskResult) else {
            assertionFailure("Couldn't transform result data to expected network representation")
            self.navigator.handleError(error: nil, presenter: presenter, onDismiss: { [weak self] in
                self?.cancelTask()
            })
            return
        }
        self.navigator.pushProgressHUD()
        self.repository.sendTaskResult(taskId: self.taskIdentifier, taskResult: taskNetworkResult)
            .subscribe(onSuccess: { [weak self] in
                guard let self = self else { return }
                self.navigator.popProgressHUD()
                self.deleteTaskResult(path: Constants.Task.taskResultURL)
                self.showSuccess()
                }, onError: { [weak self] error in
                    guard let self = self else { return }
                    self.navigator.popProgressHUD()
                    self.navigator.handleError(error: error,
                                               presenter: presenter,
                                               onDismiss: { [weak self] in
                                                self?.cancelTask()
                        },
                                               onRetry: { [weak self] in
                                                self?.sendResult(taskResult: taskResult, presenter: presenter)
                    }, dismissStyle: .destructive)
            }).disposed(by: self.disposeBag)
    }
    
    private func showSuccess() {
        if let successViewController = self.getSuccessViewController() {
            self.navigationController.pushViewController(successViewController, animated: true)
        } else {
            self.completionCallback()
        }
    }
    
    private func delay(_ delay: Double, closure: @escaping () -> Void ) {
        let delayTime = DispatchTime.now() + delay
        let dispatchWorkItem = DispatchWorkItem(block: closure)
        DispatchQueue.main.asyncAfter(deadline: delayTime, execute: dispatchWorkItem)
    }
    
    private func deleteTaskResult(path: URL) {
        let outputDirectory = path
        do {
            try FileManager.default.removeItem(atPath: outputDirectory.path)
        } catch let error {
            debugPrint(error)
        }
    }
}

extension TaskSectionCoordinator: ORKTaskViewControllerDelegate {
    func taskViewController(_ taskViewController: ORKTaskViewController,
                            didFinishWith reason: ORKTaskViewControllerFinishReason,
                            error: Error?) {
        switch reason {
        case .completed:
            print("TaskSectionCoordinator - Task Completed")
            self.sendResult(taskResult: taskViewController.result, presenter: taskViewController)
        case .discarded:
            print("TaskSectionCoordinator - Task Discarded")
            self.cancelTask()
        case .failed:
            print("TaskSectionCoordinator - Task Failed")
            self.handleError(error: error, presenter: taskViewController)
        case .saved:
            print("TaskSectionCoordinator - Task Saved")
            self.cancelTask()
        @unknown default:
            print("TaskSectionCoordinator - Unhandled case")
            self.handleError(error: error, presenter: taskViewController)
        }
    }
    
    func taskViewController(_ taskViewController: ORKTaskViewController,
                            stepViewControllerWillAppear stepViewController: ORKStepViewController) {
        // TODO: Check this against all cases
        
        if stepViewController.step?.identifier == "WaitStepIndeterminate" ||
            stepViewController.step?.identifier == "WaitStep" ||
            stepViewController.step?.identifier == "LoginWaitStep" {
            delay(5.0, closure: { () -> Void in
                if let stepViewController = stepViewController as? ORKWaitStepViewController {
                    stepViewController.goForward()
                }
            })
        }
    }
}

extension TaskSectionCoordinator: PagedSectionCoordinator {
    var pages: [Page] {
        var pages: [Page] = []
        if let welcomePage = self.welcomePage {
            pages.append(welcomePage)
        }
        if let successPage = self.successPage {
            pages.append(successPage)
        }
        return pages
    }
    
    func performCustomPrimaryButtonNavigation(page: Page) -> Bool {
        if self.successPage?.id == page.id {
            self.completionCallback()
            return true
        }
        return false
    }
    
    func onUnhandledPrimaryButtonNavigation(page: Page) {
        guard let taskViewController = self.getTaskViewController(showInstructionPage: true, showConclusionPage: true) else {
            assertionFailure("Missing expected task controller")
            return
        }
        self.internalNavigationController?.pushViewController(taskViewController, animated: true)
        self.internalNavigationController?.navigationBar.apply(style: NavigationBarStyleCategory.secondary(hidden: true).style)
    }
    
    func onUnhandledSecondaryButtonNavigation(page: Page) {
        self.deleteTaskResult(path: Constants.Task.taskResultURL)
        self.delayActivity()
    }
}
