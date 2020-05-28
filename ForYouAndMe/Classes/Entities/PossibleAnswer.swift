//
//  PossibleAnswer.swift
//  ForYouAndMe
//
//  Created by Leonardo Passeri on 28/05/2020.
//

import Foundation

struct PossibleAnswer {
    let id: String
    let type: String

    let text: String
    let correct: Bool
}

extension PossibleAnswer: JSONAPIMappable {}
