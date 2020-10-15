//
//  CamcogSectionCoordinator.swift
//  ForYouAndMe
//
//  Created by Giuseppe Lapenta on 09/10/2020.
//

import Foundation
import RxSwift

class CamcogSectionCoordinator: NSObject, ActivitySectionCoordinator {
    
    var navigationController: UINavigationController = UINavigationController()
    
    // MARK: - ActivitySectionCoordinator
    var activityPresenter: UIViewController? { return self.navigationController }
    let completionCallback: NotificationCallback
    let taskIdentifier: String
    let navigator: AppNavigator
    let repository: Repository
    let disposeBag = DisposeBag()
    
    private let welcomePage: Page?
    
    init(withTaskIdentifier taskIdentifier: String,
         completionCallback: @escaping NotificationCallback,
         welcomePage: Page?) {
        self.taskIdentifier = taskIdentifier
        self.welcomePage = welcomePage
        self.completionCallback = completionCallback
        self.navigator = Services.shared.navigator
        self.repository = Services.shared.repository
        super.init()
    }
    
    // MARK: - Public Methods
    
    public func getStartingPage() -> UIViewController? {
        if let welcomeViewController = self.getWelcomeViewController() {
            return welcomeViewController
        } else {
            return self.getCamCogViewController()
        }
    }
    
    private func getWelcomeViewController() -> UIViewController? {
        guard let welcomePage = self.welcomePage else {
            return nil
        }
        let data = InfoPageData(page: welcomePage,
                                addAbortOnboardingButton: false,
                                addCloseButton: true,
                                allowBackwardNavigation: false,
                                bodyTextAlignment: .left,
                                bottomViewStyle: .horizontal,
                                customImageHeight: nil)
        
        let welcomeViewController = InfoPageViewController(withPageData: data,
                                                          coordinator: self)
        
        self.navigationController.viewControllers = [welcomeViewController]
        return navigationController
    }
    
    private func getCamCogViewController() -> UIViewController {
        
        let url = URL(string: "\(Constants.Network.BaseUrl)/camcog/tasks/\(self.taskIdentifier)")!
        return IntegrationLoginViewController(withTitle: "",
                                              url: url,
                                              allowBackwardNavigation: false,
                                              onLoginSuccessCallback: { viewController in
                                                viewController.dismiss(animated: true, completion: nil)
                                              }, onLoginFailureCallback: { viewController in
                                                viewController.dismiss(animated: true, completion: nil)
                                              })
    }
}

extension CamcogSectionCoordinator: PagedSectionCoordinator {
    
    var pages: [Page] {
        if let welcomePage = self.welcomePage {
            return [welcomePage]
        } else {
            return []
        }
    }
    
    func onUnhandledPrimaryButtonNavigation(page: Page) {
        let camcogViewController = self.getCamCogViewController()
        self.navigationController.pushViewController(camcogViewController, animated: true)
    }
    
    func onUnhandledSecondaryButtonNavigation(page: Page) {
        self.delayActivity()
    }
}
