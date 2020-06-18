//
//  ConsentCoordinator.swift
//  ForYouAndMe
//
//  Created by Leonardo Passeri on 18/06/2020.
//

import Foundation

class ConsentCoordinator {
    
    public unowned var navigationController: UINavigationController
    
    private let sectionData: ConsentSection
    private let completionCallback: NavigationControllerCallback
    
    init(withSectionData sectionData: ConsentSection,
         navigationController: UINavigationController,
         completionCallback: @escaping NavigationControllerCallback) {
        self.sectionData = sectionData
        self.navigationController = navigationController
        self.completionCallback = completionCallback
    }
    
    // MARK: - Public Methods
    
    public func getStartingPage() -> UIViewController {
        let data = AcceptanceData(title: self.sectionData.title,
                                  subtitle: self.sectionData.subtitle,
                                  body: self.sectionData.body,
                                  startingPage: self.sectionData.welcomePage,
                                  pages: self.sectionData.pages)
        return AcceptanceViewController(withData: data, coordinator: self)
    }
    
    // MARK: - Private Methods
    
    private func showUserDataFlow() {
        // TODO: Show page to get user's first name and last name
        print("TODO: Show page to get user's first name and last name")
        self.navigationController.showAlert(withTitle: "Work in progress", message: "User Data Flow coming soon")
    }
}

extension ConsentCoordinator: AcceptanceCoordinator {
    func onAgreeButtonPressed() {
        self.showUserDataFlow()
    }
    
    func onDisagreeButtonPressed() {
        // TODO: Show confirmation popup
        print("TODO: Show confirmation popup")
    }
}
