//
//  AppNavigator.swift
//  ForYouAndMe
//
//  Created by Leonardo Passeri on 24/04/2020.
//  Copyright © 2020 Balzo srl. All rights reserved.
//

import UIKit
import SVProgressHUD

protocol ActivitySectionCoordinator: class {
    func getStartingPage() -> UIViewController?
}

class AppNavigator {
    
    private var progressHudCount = 0
    
    private let repository: Repository
    private let analytics: AnalyticsService
    private let window: UIWindow
    
    private var currentActivityCoordinator: ActivitySectionCoordinator?
    
    init(withRepository repository: Repository, analytics: AnalyticsService, window: UIWindow) {
        self.repository = repository
        self.analytics = analytics
        self.window = window
        
        // Needed to block user interaction!! :S
        SVProgressHUD.setDefaultMaskType(.black)
    }
    
    // MARK: - Initialization
    
    func showSetupScreen() {
        self.window.rootViewController = LoadingViewController<()>(loadingMode: .initialSetup)
    }
    
    func showSetupCompleted() {
        self.onStartup()
    }
    
    // MARK: - Top level
    
    func onStartup() {
        
        // Convenient entry point to test each app module atomically,
        // without going through all the official flow
        #if DEBUG
        if let testSection = Constants.Test.Section {
            let testNavigationViewController = UINavigationController(rootViewController: UIViewController())
            
            testNavigationViewController.preventPopWithSwipe()
            self.window.rootViewController = testNavigationViewController
            
            switch testSection {
            case .introVideo: self.showIntroVideo(navigationController: testNavigationViewController)
            case .screeningSection: self.startScreeningSection(navigationController: testNavigationViewController)
            case .informedConsentSection: self.startInformedConsentSection(navigationController: testNavigationViewController)
            case .consentSection: self.startConsentSection(navigationController: testNavigationViewController)
            case .optInSection: self.startOptInSection(navigationController: testNavigationViewController)
            case .consentUserDataSection: self.startUserContentDataSection(navigationController: testNavigationViewController)
            case .wearablesSection: self.startWearablesSection(navigationController: testNavigationViewController)
            }
            return
        }
        #endif
        
        if self.repository.isLoggedIn {
            // TODO: Check if onboarding is completed
            print("TODO: Check if onboarding is completed")
            var onboardingCompleted = false
            #if DEBUG
            if let testOnboardingCompleted = Constants.Test.OnboardingCompleted {
                onboardingCompleted = testOnboardingCompleted
            }
            #endif
            if onboardingCompleted {
                self.goHome()
            } else {
                // If onboarding is not completed, log out (restart from the very beginning)
                self.logOut()
            }
        } else {
            self.goToWelcome()
        }
    }
    
    public func abortOnboardingWithWarning(presenter: UIViewController) {
        let cancelAction = UIAlertAction(title: StringsProvider.string(forKey: .onboardingAbortCancel),
                                         style: .cancel,
                                         handler: nil)
        let confirmAction = UIAlertAction(title: StringsProvider.string(forKey: .onboardingAbortConfirm),
                                          style: .destructive,
                                          handler: { [weak self] _ in self?.abortOnboarding() })
        presenter.showAlert(withTitle: StringsProvider.string(forKey: .onboardingAbortTitle),
                            message: StringsProvider.string(forKey: .onboardingAbortMessage),
                            actions: [cancelAction, confirmAction],
                            tintColor: ColorPalette.color(withType: .primary))
    }
    
    public func abortOnboarding() {
        self.goToWelcome()
    }
    
    // MARK: - Welcome
    
    public func goToWelcome() {
        let navigationViewController = UINavigationController(rootViewController: WelcomeViewController())
        navigationViewController.preventPopWithSwipe()
        self.window.rootViewController = navigationViewController
    }
    
    public func showIntro(presenter: UIViewController) {
        guard let navigationController = presenter.navigationController else {
            assertionFailure("Missing UINavigationController")
            return
        }
        navigationController.pushViewController(IntroViewController(), animated: true)
    }
    
    public func showSetupLater(presenter: UIViewController) {
        guard let navigationController = presenter.navigationController else {
            assertionFailure("Missing UINavigationController")
            return
        }
        navigationController.pushViewController(SetupLaterViewController(), animated: true)
    }
    
    public func goBackToWelcome(presenter: UIViewController) {
        guard let navigationController = presenter.navigationController else {
            assertionFailure("Missing UINavigationController")
            return
        }
        navigationController.popToExpectedViewController(ofClass: WelcomeViewController.self, animated: true)
    }
    
    // MARK: - Login
    
    public func showLogin(presenter: UIViewController) {
        guard let navigationController = presenter.navigationController else {
            assertionFailure("Missing UINavigationController")
            return
        }
        navigationController.pushViewController(PhoneVerificationViewController(), animated: true)
    }
    
    public func showCodeValidation(countryCode: String, phoneNumber: String, presenter: UIViewController) {
        guard let navigationController = presenter.navigationController else {
            assertionFailure("Missing UINavigationController")
            return
        }
        let codeValidationViewController = CodeValidationViewController(countryCode: countryCode, phoneNumber: phoneNumber)
        navigationController.pushViewController(codeValidationViewController, animated: true)
    }
    
    public func showPrivacyPolicy(presenter: UIViewController) {
        guard let url = URL(string: StringsProvider.string(forKey: .urlPrivacyPolicy)) else {
            assertionFailure("Invalid Url for privacy policy")
            return
        }
        self.openWebView(withTitle: "", url: url, presenter: presenter)
    }
    
    public func showTermsOfService(presenter: UIViewController) {
        guard let url = URL(string: StringsProvider.string(forKey: .urlTermsOfService)) else {
            assertionFailure("Invalid Url for terms of service")
            return
        }
        self.openWebView(withTitle: "", url: url, presenter: presenter)
    }
    
    public func onLoginCompleted(presenter: UIViewController) {
        guard let navigationController = presenter.navigationController else {
            assertionFailure("Missing UINavigationController")
            return
        }
        self.showIntroVideo(navigationController: navigationController)
    }
    
    // MARK: Intro Video
    
    public func showIntroVideo(navigationController: UINavigationController) {
        navigationController.pushViewController(IntroVideoViewController(), animated: true)
    }
    
    public func onIntroVideoCompleted(presenter: UIViewController) {
        guard let navigationController = presenter.navigationController else {
            assertionFailure("Missing UINavigationController")
            return
        }
        self.startScreeningSection(navigationController: navigationController)
    }
    
    // MARK: Screening Questions
    
    public func startScreeningSection(navigationController: UINavigationController) {
        navigationController.loadViewForRequest(self.repository.getScreeningSection()) { section -> UIViewController in
            let completionCallback: NavigationControllerCallback = { [weak self] navigationController in
                self?.startInformedConsentSection(navigationController: navigationController)
            }
            let coordinator = ScreeningSectionCoordinator(withSectionData: section,
                                                          navigationController: navigationController,
                                                          completionCallback: completionCallback)
            return coordinator.getStartingPage()
        }
    }
    
    // MARK: Informed Consent
    
    public func startInformedConsentSection(navigationController: UINavigationController) {
        navigationController.loadViewForRequest(self.repository.getInformedConsentSection()) { section -> UIViewController in
            let completionCallback: NavigationControllerCallback = { [weak self] navigationController in
                self?.startConsentSection(navigationController: navigationController)
            }
            let coordinator = InformedConsentSectionCoordinator(withSectionData: section,
                                                                navigationController: navigationController,
                                                                completionCallback: completionCallback)
            return coordinator.getStartingPage()
        }
    }
    
    // MARK: Consent
    
    public func startConsentSection(navigationController: UINavigationController) {
        navigationController.loadViewForRequest(self.repository.getConsentSection()) { section -> UIViewController in
            let completionCallback: NavigationControllerCallback = { [weak self] navigationController in
                self?.startOptInSection(navigationController: navigationController)
            }
            let coordinator = ConsentSectionCoordinator(withSectionData: section,
                                                        navigationController: navigationController,
                                                        completionCallback: completionCallback)
            return coordinator.getStartingPage()
        }
    }
    
    public func showReviewConsent(navigationController: UINavigationController) {
        navigationController.loadViewForRequest(self.repository.getConsentSection(),
                                                hidesBottomBarWhenPushed: true) { section -> UIViewController in
                                                    let data = InfoPageListData(title: section.title,
                                                                                subtitle: section.subtitle,
                                                                                body: section.body,
                                                                                startingPage: section.welcomePage,
                                                                                pages: section.pages,
                                                                                mode: .view)
                                                    return InfoPageListViewController(withData: data)
        }
    }
    
    // MARK: Opt-In
    
    public func startOptInSection(navigationController: UINavigationController) {
        navigationController.loadViewForRequest(self.repository.getOptInSection()) { section -> UIViewController in
            let completionCallback: NavigationControllerCallback = { [weak self] navigationController in
                self?.startUserContentDataSection(navigationController: navigationController)
            }
            let coordinator = OptInSectionCoordinator(withSectionData: section,
                                                      navigationController: navigationController,
                                                      completionCallback: completionCallback)
            return coordinator.getStartingPage()
        }
    }
    
    // MARK: Consent User Data
    
    public func startUserContentDataSection(navigationController: UINavigationController) {
        navigationController.loadViewForRequest(self.repository.getUserConsentSection()) { section -> UIViewController in
            let completionCallback: NavigationControllerCallback = { [weak self] navigationController in
                self?.startWearablesSection(navigationController: navigationController)
            }
            let coordinator = ConsentUserDataSectionCoordinator(withSectionData: section,
                                                                navigationController: navigationController,
                                                                completionCallback: completionCallback)
            return coordinator.getStartingPage()
        }
    }
    
    // MARK: Wearables
    
    public func startWearablesSection(navigationController: UINavigationController) {
        navigationController.loadViewForRequest(self.repository.getWearablesSection()) { section -> UIViewController in
            let completionCallback: NavigationControllerCallback = { [weak self] navigationController in
                self?.goHome()
            }
            let coordinator = WearablesSectionCoordinator(withSectionData: section,
                                                          navigationController: navigationController,
                                                          completionCallback: completionCallback)
            return coordinator.getStartingPage()
        }
    }
    
    public func showWearableLogin(loginUrl: URL, navigationController: UINavigationController) {
        let viewController = WearableLoginViewController(withTitle: "",
                                                         url: loginUrl,
                                                         onLoginSuccessCallback: { _ in
                                                            navigationController.popViewController(animated: true)
        },
                                                         onLoginFailureCallback: { _ in
                                                            navigationController.popViewController(animated: true)
        })
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)
    }
    
    // MARK: Home
    
    public func goHome() {
        let tabBarController = UITabBarController()
        
        // Basically, we want the content not to fall behind the tab bar
        tabBarController.tabBar.isTranslucent = false
        
        // Colors
        tabBarController.tabBar.tintColor = ColorPalette.color(withType: .primaryText)
        tabBarController.tabBar.barTintColor = ColorPalette.color(withType: .secondary)
        tabBarController.tabBar.unselectedItemTintColor = ColorPalette.color(withType: .secondaryMenu)
        
        // Remove top line
        tabBarController.tabBar.barStyle = .black
        
        // Add shadow
        tabBarController.tabBar.addShadowLinear(goingDown: false)
        
        var viewControllers: [UIViewController] = []
        
        let titleFont = FontPalette.fontStyleData(forStyle: .menu).font
        
        let feedViewController = FeedViewController()
        let feedNavigationController = UINavigationController(rootViewController: feedViewController)
        feedNavigationController.preventPopWithSwipe()
        feedNavigationController.tabBarItem.image = ImagePalette.templateImage(withName: .tabFeed)
        feedNavigationController.tabBarItem.title = StringsProvider.string(forKey: .tabFeed)
        feedNavigationController.tabBarItem.setTitleTextAttributes([.font: titleFont], for: .normal)
        viewControllers.append(feedNavigationController)
        
        let taskViewController = TaskViewController()
        let taskNavigationController = UINavigationController(rootViewController: taskViewController)
        taskNavigationController.preventPopWithSwipe()
        taskNavigationController.tabBarItem.image = ImagePalette.templateImage(withName: .tabTask)
        taskNavigationController.tabBarItem.title = StringsProvider.string(forKey: .tabTask)
        taskNavigationController.tabBarItem.setTitleTextAttributes([.font: titleFont], for: .normal)
        viewControllers.append(taskNavigationController)
        
        let userDataViewController = UserDataViewController()
        let userDataNavigationController = UINavigationController(rootViewController: userDataViewController)
        userDataNavigationController.preventPopWithSwipe()
        userDataNavigationController.tabBarItem.image = ImagePalette.templateImage(withName: .tabUserData)
        userDataNavigationController.tabBarItem.title = StringsProvider.string(forKey: .tabUserData)
        userDataNavigationController.tabBarItem.setTitleTextAttributes([.font: titleFont], for: .normal)
        viewControllers.append(userDataNavigationController)
        
        let studyInfoViewController = StudyInfoViewController()
        let studyInfoNavigationController = UINavigationController(rootViewController: studyInfoViewController)
        studyInfoNavigationController.preventPopWithSwipe()
        studyInfoNavigationController.tabBarItem.image = ImagePalette.templateImage(withName: .tabStudyInfo)
        studyInfoNavigationController.tabBarItem.title = StringsProvider.string(forKey: .tabStudyInfo)
        studyInfoNavigationController.tabBarItem.setTitleTextAttributes([.font: titleFont], for: .normal)
        viewControllers.append(studyInfoNavigationController)
        
        tabBarController.viewControllers = viewControllers
        tabBarController.selectedIndex = viewControllers.firstIndex(of: feedViewController) ?? 0
        self.window.rootViewController = tabBarController
    }
    
    public func switchToFeedTab(presenter: UIViewController) {
        guard let tabBarController = presenter.tabBarController else { return }
        guard let feedViewControllerIndex = tabBarController.viewControllers?.firstIndex(where: { viewController in
            (viewController as? UINavigationController)?.viewControllers.first is FeedViewController
        }) else { return }
        tabBarController.selectedIndex = feedViewControllerIndex
    }
    
    // MARK: Task
    
    public func startTaskSection(taskIdentifier: String, taskType: TaskType, taskOptions: TaskOptions?, presenter: UIViewController) {
        let completionCallback: NotificationCallback = { [weak self] in
            guard let self = self else { return }
            presenter.dismiss(animated: true, completion: nil)
            self.currentActivityCoordinator = nil
        }
        let coordinator: ActivitySectionCoordinator = {
            switch taskType {
            case .videoDiary:
                return VideoDiarySectionCoordinator(withTaskIdentifier: taskIdentifier,
                                                    completionCallback: completionCallback)
            default:
                return TaskSectionCoordinator(withTaskIdentifier: taskIdentifier,
                                              taskType: taskType,
                                              taskOptions: taskOptions,
                                              completionCallback: completionCallback)
            }
        }()
        guard let startingPage = coordinator.getStartingPage() else {
            assertionFailure("Couldn't get starting view controller for current task type")
            return
        }
        self.analytics.track(event: .recordScreen(screenName: taskIdentifier,
                                                         screenClass: String(describing: type(of: self))))

        startingPage.modalPresentationStyle = .fullScreen
        presenter.present(startingPage, animated: true, completion: nil)
        self.currentActivityCoordinator = coordinator
    }
    
    // MARK: About You
    
    public func showAboutYouPage(presenter: UIViewController) {
        
        // TODO: Load From Server
        let aboutYouViewController = AboutYouViewController()
        let navigationController = UINavigationController(rootViewController: aboutYouViewController)
        navigationController.modalPresentationStyle = .overFullScreen
        presenter.present(navigationController, animated: true, completion: nil)
    }
    
    public func showAppsAndDevices(navigationController: UINavigationController, title: String) {
        // TODO: Load From Server
        let devicesViewController = DevicesIntegrationViewController(withTitle: title)
        navigationController.pushViewController(devicesViewController, animated: true)
    }
    
    public func showUserInfoPage(navigationController: UINavigationController,
                                 title: String,
                                 userInfoParameters: [UserInfoParameter]) {
        let userInfoViewController = UserInfoViewController(withTitle: title, userInfoParameters: userInfoParameters)
        navigationController.pushViewController(userInfoViewController, animated: true)
    }
    
    public func showPermissions(navigationController: UINavigationController, title: String) {
        // TODO: Load From Server
        let permissionViewController = PermissionViewController(withTitle: title)
        navigationController.pushViewController(permissionViewController, animated: true)
    }
    
    // MARK: Progress HUD
    
    public func pushProgressHUD() {
        if self.progressHudCount == 0 {
            SVProgressHUD.show()
        }
        self.progressHudCount += 1
    }
    
    public func popProgressHUD() {
        if self.progressHudCount > 0 {
            self.progressHudCount -= 1
            if self.progressHudCount == 0 {
                SVProgressHUD.dismiss()
            }
        }
    }
    
    // MARK: - Misc
    
    public func logOut() {
        self.repository.logOut()
        self.goToWelcome()
    }
    
    public func canOpenExternalUrl(_ url: URL) -> Bool {
        return UIApplication.shared.canOpenURL(url)
    }
    
    public func openSettings() {
        if let settings = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settings)
        }
    }
    
    public func openExternalUrl(_ url: URL) {
        guard self.canOpenExternalUrl(url) else {
            print("Cannot open given url: \(url)")
            return
        }
        UIApplication.shared.open(url)
    }
    
    public func openWebView(withTitle title: String, url: URL, presenter: UIViewController) {
        let webViewViewController = WebViewViewController(withTitle: title, allowNavigation: true, url: url)
        let navigationViewController = UINavigationController(rootViewController: webViewViewController)
        navigationViewController.preventPopWithSwipe()
        presenter.present(navigationViewController, animated: true)
    }
    
    public func handleError(error: Error?,
                            presenter: UIViewController,
                            onDismiss: @escaping NotificationCallback = {},
                            onRetry: NotificationCallback? = nil,
                            dismissStyle: UIAlertAction.Style = .cancel) {
        SVProgressHUD.dismiss() // Safety dismiss
        guard let error = error else {
            presenter.showAlert(forError: nil, onDismiss: onDismiss, onRetry: onRetry, dismissStyle: dismissStyle)
            return
        }
        guard let alertError = error as? AlertError else {
            assertionFailure("Unexpected error type")
            presenter.showAlert(forError: nil, onDismiss: onDismiss, onRetry: onRetry, dismissStyle: dismissStyle)
            return
        }
        
        if false == self.handleUserNotLoggedError(error: error) {
            presenter.showAlert(forError: alertError, onDismiss: onDismiss, onRetry: onRetry, dismissStyle: dismissStyle)
        }
    }
    
    /// Check if the given error is a `Repository.userNotLoggedIn` error and, if so,
    /// perform a logout procedure.
    /// - Parameter error: the error to be checked
    /// - Returns: `true` if logout has been performed. `false` otherwise.
    public func handleUserNotLoggedError(error: Error?) -> Bool {
        if let error = error, case RepositoryError.userNotLoggedIn = error {
            print("Log out due to 'RepositoryError.userNotLoggedIn' error")
            // TODO: Show a user friendly popup to explain the user that he must login again.
            self.logOut()
            return true
        } else {
            return false
        }
    }
    
    // MARK: Study Info
    public func showInfoDetailPage(presenter: UIViewController, page: Page, isModal: Bool) {
        guard let navController = presenter.navigationController else {
            assertionFailure("Missing UINavigationController")
            return
        }
        
        let pageData = InfoDetailPageData(page: page, isModal: isModal)
        let pageViewController = InfoDetailPageViewController(withPageData: pageData)
        if isModal {
            presenter.modalPresentationStyle = .overFullScreen
        }
        pageViewController.hidesBottomBarWhenPushed = true
        navController.pushViewController(pageViewController, animated: true)
    }
}

// MARK: - Extension(UIViewController)

extension UIViewController {
    func showAlert(forError error: Error?,
                   onDismiss: @escaping NotificationCallback = {},
                   onRetry: NotificationCallback? = nil,
                   dismissStyle: UIAlertAction.Style = .cancel) {
        var actions: [UIAlertAction] = []
        let dismissAction = UIAlertAction(title: StringsProvider.string(forKey: .errorButtonClose),
                                          style: dismissStyle,
                                          handler: { _ in onDismiss() })
        actions.append(dismissAction)
        if let onRetry = onRetry {
            let retryAction = UIAlertAction(title: StringsProvider.string(forKey: .errorButtonRetry),
                                            style: .default,
                                            handler: { _ in onRetry() })
            actions.append(retryAction)
        }
        self.showAlert(withTitle: StringsProvider.string(forKey: .errorTitleDefault),
                       message: error?.localizedDescription ?? StringsProvider.string(forKey: .errorMessageDefault),
                       actions: actions,
                       tintColor: ColorPalette.color(withType: .primary))
    }
    
    func showAlert(withTitle title: String,
                   message: String,
                   dismissButtonText: String,
                   onDismiss: @escaping NotificationCallback = {}) {
        let dismissAction = UIAlertAction(title: dismissButtonText,
                                          style: .default,
                                          handler: { _ in onDismiss() })
        self.showAlert(withTitle: title,
                       message: message,
                       actions: [dismissAction],
                       tintColor: ColorPalette.color(withType: .primary))
    }
}
