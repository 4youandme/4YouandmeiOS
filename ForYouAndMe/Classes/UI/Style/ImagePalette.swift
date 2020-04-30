//
//  ImagePalette.swift
//  ForYouAndMe
//
//  Created by Leonardo Passeri on 29/04/2020.
//

import UIKit

enum ImageName: String, CaseIterable {
    case failure
}

public class ImagePalette {
    
    static func image(withName name: ImageName) -> UIImage? {
        return UIImage(named: name.rawValue) ?? UIImage(named: name.rawValue, in: PodUtils.podDefaultResourceBundle, with: nil)
    }
    
    static func checkImageAvailabilityOnMainBundle() {
        ImageName.allCases.forEach { imageName in
            assert(UIImage(named: imageName.rawValue) != nil, "missing image: \(imageName.rawValue) in current main bundle")
        }
    }
}
