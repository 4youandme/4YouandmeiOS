//
//  ButtonStyles.swift
//  ForYouAndMe
//
//  Created by Leonardo Passeri on 30/04/2020.
//  Copyright © 2020 Balzo srl. All rights reserved.
//

import UIKit
import PureLayout

public class ButtonStyles {
    
    private static let defaultHeight: CGFloat = 52.0
    private static let defaultCornerRadius: CGFloat = defaultHeight / 2.0
    
    static let primaryStyle = Style<UIButton> { button in
        button.autoSetDimension(.height, toSize: defaultHeight)
        button.layer.cornerRadius = defaultCornerRadius
        button.backgroundColor = ColorPalette.color(withType: .primary)
        button.setTitleColor(ColorPalette.color(withType: .secondaryText), for: .normal)
        button.titleLabel?.font = FontPalette.fontStyleData(forStyle: .header2).font
        button.addShadowButton()
    }
    
    static let secondaryStyle = Style<UIButton> { button in
        button.autoSetDimension(.height, toSize: defaultHeight)
        button.layer.cornerRadius = defaultCornerRadius
        button.backgroundColor = ColorPalette.color(withType: .secondary)
        button.setTitleColor(ColorPalette.color(withType: .tertiaryText), for: .normal)
        button.titleLabel?.font = FontPalette.fontStyleData(forStyle: .header2).font
        button.addShadowButton()
    }
    
    static let loadingErrorStyle = Style<UIButton> { button in
        button.autoSetDimension(.height, toSize: defaultHeight)
        button.layer.cornerRadius = defaultCornerRadius
        button.backgroundColor = ColorPalette.loadingErrorPrimaryColor
        button.setTitleColor(ColorPalette.loadingErrorSecondaryColor, for: .normal)
        button.titleLabel?.font = FontPalette.fontStyleData(forStyle: .header2).font
        button.addShadowButton()
    }
}
