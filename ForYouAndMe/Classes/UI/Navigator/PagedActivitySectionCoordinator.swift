//
//  PagedActivitySectionCoordinator.swift
//  ForYouAndMe
//
//  Created by Leonardo Passeri on 23/10/2020.
//

import UIKit

struct PagedSectionData {
    let welcomePage: Page
    let successPage: Page?
    let pages: [Page]
}

protocol PagedActivitySectionCoordinator: ActivitySectionCoordinator, PagedSectionCoordinator {
    var internalNavigationController: UINavigationController? { get set }
    var pagedSectionData: PagedSectionData { get }
    var coreViewController: UIViewController? { get }
}

extension PagedActivitySectionCoordinator {
    var pages: [Page] { self.pagedSectionData.pages }
    
    func performCustomPrimaryButtonNavigation(page: Page) -> Bool {
        if self.pagedSectionData.successPage?.id == page.id {
            self.completionCallback()
            return true
        }
        return false
    }
    
    func performCustomSecondaryButtonNavigation(page: Page) -> Bool {
        if self.pagedSectionData.welcomePage.id == page.id {
            self.delayActivity()
            return true
        }
        return false
    }
    
    func onUnhandledPrimaryButtonNavigation(page: Page) {
        guard let coreViewController = self.coreViewController else {
            assertionFailure("Missing Core View Controller")
            if let activityPresenter = self.activityPresenter {
                self.navigator.handleError(error: nil, presenter: activityPresenter)
            }
            return
        }
        self.navigationController.pushViewController(coreViewController, animated: true)
    }
    
    var navigationController: UINavigationController {
        guard let navigationController = self.internalNavigationController else {
            assertionFailure("Missing navigation controller")
            return UINavigationController()
        }
        return navigationController
    }
    
    func getStartingPage() -> UIViewController {
        let data = InfoPageData(page: self.pagedSectionData.welcomePage,
                                addAbortOnboardingButton: false,
                                addCloseButton: true,
                                allowBackwardNavigation: false,
                                bodyTextAlignment: .left,
                                bottomViewStyle: .horizontal,
                                customImageHeight: nil)
        
        let welcomeViewController = InfoPageViewController(withPageData: data,
                                                          coordinator: self)
        let navigationController = UINavigationController(rootViewController: welcomeViewController)
        self.internalNavigationController = navigationController
        return navigationController
    }
    
    func showSuccessPage() {
        if let successPage = self.pagedSectionData.successPage {
            let data = InfoPageData.createResultPageData(withPage: successPage)
            let successViewController = InfoPageViewController(withPageData: data,
                                                              coordinator: self)
            self.navigationController.pushViewController(successViewController, animated: true)
        } else {
            self.completionCallback()
        }
    }
}
