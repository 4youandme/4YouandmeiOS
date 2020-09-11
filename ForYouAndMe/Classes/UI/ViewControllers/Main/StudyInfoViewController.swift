//
//  StudyInfoViewController.swift
//  ForYouAndMe
//
//  Created by Leonardo Passeri on 22/07/2020.
//

import Foundation

import UIKit

class StudyInfoViewController: UIViewController {
    
    private let navigator: AppNavigator

    private lazy var scrollStackView: ScrollStackView = {
        let scrollStackView = ScrollStackView(axis: .vertical, horizontalInset: 0.0)
        return scrollStackView
    }()
    
    init() {
       self.navigator = Services.shared.navigator
       super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
           fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = ColorPalette.color(withType: .secondary)
        
        // Header View
        let headerView = StudyInfoHeaderView()
        self.view.addSubview(headerView)
        headerView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        
        // ScrollStackView
        self.view.addSubview(self.scrollStackView)
        self.scrollStackView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        self.scrollStackView.autoPinEdge(.top, to: .bottom, of: headerView, withOffset: 30)
        
        let contactInformation = GenericListItemView(withTitle: "Contact Information"/*StringsProvider.string(forKey: .studyInfoContactItem)*/,
            templateImageName: .studyInfoContact,
            colorType: .primary,
            gestureCallback: { [weak self] in
                let page = Page(id: "contact", title: "Contact", body: Constants.Misc.LoremIpsum)
                self?.showPage(page: page, isModal: false)
        })
        self.scrollStackView.stackView.addArrangedSubview(contactInformation)
        
        let rewardsView = GenericListItemView(withTitle: "Rewards"/*StringsProvider.string(forKey: .studyInfoRewardsItem)*/,
            templateImageName: .studyInfoRewards,
            colorType: .primary,
            gestureCallback: { [weak self] in
                let page = Page(id: "rewards", title: "Rewards", body: Constants.Misc.LoremIpsum)
                self?.showPage(page: page, isModal: false)
        })
        self.scrollStackView.stackView.addArrangedSubview(rewardsView)
        
        let faqView = GenericListItemView(withTitle: "FAQ Page"/*StringsProvider.string(forKey: .studyInfoFaqItem)*/,
            templateImageName: .studyInfoFAQ,
            colorType: .primary,
            gestureCallback: { [weak self] in
                let page = Page(id: "faq", title: "FAQ", body: Constants.Misc.LoremIpsum)
                self?.showPage(page: page, isModal: false)
        })
        self.scrollStackView.stackView.addArrangedSubview(faqView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.apply(style: NavigationBarStyleCategory.primary(hidden: true).style)
    }
    
    private func showPage(page: Page, isModal: Bool) {
        self.navigator.showInfoPage(presenter: self, page: page, isModal: isModal)
    }
}
