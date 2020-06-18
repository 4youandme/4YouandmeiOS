//
//  AttributedTextStyle.swift
//  ForYouAndMe
//
//  Created by Leonardo Passeri on 11/06/2020.
//

import Foundation

struct AttributedTextStyle {
    let fontStyle: FontStyle
    let colorType: ColorType
    let textAlignment: NSTextAlignment
    let underlined: Bool
    
    init(fontStyle: FontStyle,
         colorType: ColorType,
         textAlignment: NSTextAlignment = .center,
         underlined: Bool = false) {
        self.fontStyle = fontStyle
        self.colorType = colorType
        self.textAlignment = textAlignment
        self.underlined = underlined
    }
}
