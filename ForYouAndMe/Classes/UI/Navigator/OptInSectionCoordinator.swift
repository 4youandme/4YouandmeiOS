//
//  OptInSectionCoordinator.swift
//  ForYouAndMe
//
//  Created by Leonardo Passeri on 23/06/2020.
//

import Foundation
import RxSwift

class OptInSectionCoordinator {
    
    public unowned var navigationController: UINavigationController
    
    private let repository: Repository
    private let navigator: AppNavigator
    
    private let sectionData: OptInSection
    private let completionCallback: NavigationControllerCallback
    
    private let disposeBag = DisposeBag()
    
    private let healthService: HealthService
    
    var answers: [Question: PossibleAnswer] = [:]
    
    init(withSectionData sectionData: OptInSection,
         navigationController: UINavigationController,
         completionCallback: @escaping NavigationControllerCallback) {
        self.repository = Services.shared.repository
        self.navigator = Services.shared.navigator
        self.healthService = Services.shared.healthService
        self.sectionData = sectionData
        self.navigationController = navigationController
        self.completionCallback = completionCallback
    }
    
    // MARK: - Public Methods
    
    public func getStartingPage() -> UIViewController {
        let infoPageData = InfoPageData(page: self.sectionData.welcomePage,
                                        addAbortOnboardingButton: false,
                                        addCloseButton: false,
                                        allowBackwardNavigation: false,
                                        bodyTextAlignment: .center,
                                        bottomViewStyle: .singleButton,
                                        customImageHeight: nil,
                                        defaultButtonFirstLabel: nil,
                                        defaultButtonSecondLabel: nil)
        return InfoPageViewController(withPageData: infoPageData, coordinator: self)
    }
    
    // MARK: - Private Methods
    
    private func showSuccess() {
        guard let successPage = self.sectionData.successPage else {
            assertionFailure("Missing expected success page")
            return
        }
        let infoPageData = InfoPageData.createResultPageData(withPage: successPage)
        let viewController = InfoPageViewController(withPageData: infoPageData, coordinator: self)
        self.navigationController.pushViewController(viewController, animated: true)
    }
    
    private func showOptInPermission(_ optInPermission: OptInPermission) {
        let viewController = OptInPermissionViewController(withOptInPermission: optInPermission, coordinator: self)
        self.navigationController.pushViewController(viewController, animated: true)
    }
}

extension OptInSectionCoordinator: PagedSectionCoordinator {
    
    var pages: [Page] { self.sectionData.pages }
    
    func performCustomPrimaryButtonNavigation(page: Page) -> Bool {
        if self.sectionData.successPage?.id == page.id {
            self.completionCallback(self.navigationController)
            return true
        }
        return false
    }
    
    func onUnhandledPrimaryButtonNavigation(page: Page) {
        if let firstOptInPermission = self.sectionData.optInPermissions.first {
            self.showOptInPermission(firstOptInPermission)
        } else {
            self.completionCallback(self.navigationController)
        }
    }
}

extension OptInSectionCoordinator: OptInPermissionCoordinator {
    func onOptInPermissionSet(optInPermission: OptInPermission, granted: Bool) {
        
        guard granted || false == optInPermission.isMandatory else {
            let message = optInPermission.mandatoryText ?? StringsProvider.string(forKey: .onboardingOptInMandatoryDefault)
            self.navigationController.showAlert(withTitle: StringsProvider.string(forKey: .onboardingOptInMandatoryTitle),
                                                message: message,
                                                dismissButtonText: StringsProvider.string(forKey: .onboardingOptInMandatoryClose))
            return
        }
        
        let systemPermissionRequests: Single<()> = optInPermission.systemPermissions
            .reduce(Single.just(())) { (result, systemPermission) in
                switch systemPermission {
                case .health: return result.flatMap { self.healthService.requestPermissionDefaultMeasurements().catchErrorJustReturn(()) }
                case .location: return result.flatMap {
                    let permission: Permission = .locationWhenInUse
                    return permission.request().catchErrorJustReturn(())
                }
                }
            }
        
        systemPermissionRequests
            .do(onSuccess: { self.navigator.pushProgressHUD() })
            .flatMap { self.repository.sendOptInPermission(permission: optInPermission, granted: granted) }
            .subscribe(onSuccess: { [weak self] () in
                guard let self = self else { return }
                self.navigator.popProgressHUD()
                
                guard let permissionIndex = self.sectionData.optInPermissions.firstIndex(where: { $0.id == optInPermission.id }) else {
                    assertionFailure("Missing Permission with give ID")
                    return
                }
                
                let nextPermissionIndex = permissionIndex + 1
                if nextPermissionIndex < self.sectionData.optInPermissions.count {
                    self.showOptInPermission(self.sectionData.optInPermissions[nextPermissionIndex])
                } else {
                    self.showSuccess()
                }
                }, onError: { [weak self] error in
                    guard let self = self else { return }
                    self.navigator.popProgressHUD()
                    self.navigator.handleError(error: error, presenter: self.navigationController)
            }).disposed(by: self.disposeBag)
    }
}
