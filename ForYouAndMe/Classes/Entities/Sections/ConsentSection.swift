//
//  ConsentSection.swift
//  ForYouAndMe
//
//  Created by Leonardo Passeri on 18/06/2020.
//

import Foundation

struct ConsentSection {
    let id: String
    let type: String

    let title: String
    let body: String
    let subtitle: String?
    let disagreeBody: String
    let disagreeButton: String
    let pages: [Page]
    let welcomePage: Page
}

extension ConsentSection: JSONAPIMappable {
    static var includeList: String? = """
pages.link_1,\
pages.link_2,\
pages.link_modal,\
welcome_page.link_1,\
welcome_page.link_2
"""
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case body
        case subtitle = "pages_subtitle"
        case disagreeBody = "disagree_modal_body"
        case disagreeButton = "disagree_modal_button"
        case pages
        case welcomePage = "welcome_page"
    }
}
