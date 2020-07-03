//
//  ImagePalette.swift
//  ForYouAndMe
//
//  Created by Leonardo Passeri on 29/04/2020.
//  Copyright © 2020 Balzo srl. All rights reserved.
//

import UIKit

enum ImageName: String, CaseIterable {
    case setupFailure = "setupFailure"
    case failure = "failure"
    case fyamLogoSpecific = "fyam_logo_specific"
    case fyamLogoGeneric = "fyam_logo_generic"
    case mainLogo = "main_logo"
    case nextButtonPrimary = "next_button_primary"
    case backButtonPrimary = "back_button_primary"
    case nextButtonSecondary = "next_button_secondary"
    case closeButton = "close_button"
    case clearButton = "clear_button"
    case checkmark = "checkmark"
    case edit = "edit"
}

enum TemplateImageName: String, CaseIterable {
    case backButtonNavigation = "back_button_navigation"
    case checkboxOutline = "checkbox_outline"
    case checkboxFilled = "checkbox_filled"
    case radioButtonFilled = "radio_button_filled"
    case radioButtonOutline = "radio_button_outline"
}

public class ImagePalette {
    
    static func image(withName name: ImageName) -> UIImage? {
        return Self.image(withName: name.rawValue)
    }
    
    static func templateImage(withName name: TemplateImageName) -> UIImage? {
        return Self.image(withName: name.rawValue)?.withRenderingMode(.alwaysTemplate)
    }
    
    private static func image(withName name: String) -> UIImage? {
        if let image = UIImage(named: name) {
            return image
        } else if let podBundle = PodUtils.getPodResourceBundle(withName: Constants.Resources.DefaultBundleName) {
            return UIImage(named: name, in: podBundle, with: nil)
        } else {
            return nil
        }
    }
    
    static func checkImageAvailability() {
        ImageName.allCases.forEach { imageName in
            assert(ImagePalette.image(withName: imageName) != nil, "missing image: \(imageName.rawValue)")
        }
        TemplateImageName.allCases.forEach { imageName in
            assert(ImagePalette.templateImage(withName: imageName) != nil, "missing template image: \(imageName.rawValue)")
        }
    }
}
