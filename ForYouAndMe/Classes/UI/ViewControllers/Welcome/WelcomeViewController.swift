//
//  WelcomeViewController.swift
//  ForYouAndMe
//
//  Created by Leonardo Passeri on 24/04/2020.
//  Copyright © 2020 Balzo srl. All rights reserved.
//

import UIKit
import PureLayout

public class WelcomeViewController: UIViewController {
    
    private let navigator: AppNavigator
    
    private lazy var continueButton: UIButton = {
        let button = UIButton()
        button.apply(style: ButtonTextStyleCategory.secondaryBackground(customHeight: nil).style)
        button.setTitle(StringsProvider.string(forKey: .welcomeStartButton), for: .normal)
        button.addTarget(self, action: #selector(self.showIntro), for: .touchUpInside)
        return button
    }()
    
    init() {
        self.navigator = Services.shared.navigator
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addGradientView(GradientView(type: .primaryBackground))

        let stackView = UIStackView()
        stackView.axis = .vertical
        self.view.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewSafeArea(with: UIEdgeInsets(top: 100.0,
                                                                     left: Constants.Style.DefaultHorizontalMargins,
                                                                     bottom: 100.0,
                                                                     right: Constants.Style.DefaultHorizontalMargins))

        stackView.addHeaderImage(image: ImagePalette.image(withName: .fyamLogoSpecific))
        stackView.addBlankSpace(space: 64.0)
        stackView.addHeaderImage(image: ImagePalette.image(withName: .mainLogo))
        stackView.addArrangedSubview(UIView())
        stackView.addArrangedSubview(self.continueButton)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.apply(style: NavigationBarStyles.primaryStyle)

        self.continueButton.alpha = 0
        UIView.animate(withDuration: 0.8, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
            guard let self = self else { return }
            self.continueButton.alpha = 1
        }, completion: nil)
    }
    
    // MARK: Actions
    
    @objc private func showIntro() {
        self.navigator.showIntro(presenter: self)
    }
}
