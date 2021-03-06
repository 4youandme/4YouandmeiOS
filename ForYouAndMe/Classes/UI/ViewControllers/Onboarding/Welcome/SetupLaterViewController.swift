//
//  SetupLaterViewController.swift
//  ForYouAndMe
//
//  Created by Leonardo Passeri on 07/05/2020.
//  Copyright © 2020 Balzo srl. All rights reserved.
//

import Foundation
import PureLayout

public class SetupLaterViewController: UIViewController {
    
    private let navigator: AppNavigator
    private let analytics: AnalyticsService
    
    private lazy var confirmButtonView: GenericButtonView = {
        let view = GenericButtonView(withTextStyleCategory: .primaryBackground(), height: IntroViewController.bottomViewHeight)
        view.setButtonText(StringsProvider.string(forKey: .setupLaterConfirmButton))
        view.addTarget(target: self, action: #selector(self.confirmButtonPressed))
        return view
    }()
    
    init() {
        self.navigator = Services.shared.navigator
        self.analytics = Services.shared.analytics
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addGradientView(GradientView(type: .primaryBackground))
        
        // ScrollView
        let scrollStackView = ScrollStackView(axis: .vertical, horizontalInset: Constants.Style.DefaultHorizontalMargins)
        self.view.addSubview(scrollStackView)
        scrollStackView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)
        scrollStackView.stackView.addBlankSpace(space: 16.0)
        
        scrollStackView.stackView.addHeaderImage(image: ImagePalette.image(withName: .fyamLogoGeneric))
        scrollStackView.stackView.addBlankSpace(space: 40.0)
        scrollStackView.stackView.addLabel(withText: StringsProvider.string(forKey: .setupLaterBody),
                                           fontStyle: .paragraph,
                                           colorType: .secondaryText,
                                           textAlignment: .left)
        self.view.addSubview(self.confirmButtonView)
        self.confirmButtonView.autoPinEdgesToSuperviewSafeArea(with: UIEdgeInsets.zero, excludingEdge: .top)
        
        scrollStackView.scrollView.autoPinEdge(.bottom, to: .top, of: self.confirmButtonView)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.analytics.track(event: .recordScreen(screenName: AnalyticsScreens.setupLater.rawValue,
                                                  screenClass: String(describing: type(of: self))))
        self.navigationController?.navigationBar.apply(style: NavigationBarStyleCategory.primary(hidden: false).style)
        self.addCustomBackButton()
    }
    
    // MARK: Actions
    
    @objc private func confirmButtonPressed() {
        self.navigator.goBackToWelcome(presenter: self)
    }
}
