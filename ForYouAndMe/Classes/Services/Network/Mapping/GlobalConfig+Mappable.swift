//
//  GlobalConfig+Mappable.swift
//  ForYouAndMe
//
//  Created by Leonardo Passeri on 29/04/2020.
//  Copyright © 2020 Balzo srl. All rights reserved.
//

import Foundation
import Mapper

extension GlobalConfig: Mappable {
    init(map: Mapper) throws {
        try self.colorMap = map.from("color_palette")
        try self.stringMap = map.from("strings")
        try self.countryCodes = map.from("country_codes", transformation: Mapper.errorIfEmpty)
        try self.integrationDatas = map.from("supported_integrations", transformation: Mapper.extractIntegrationData)
        try self.onboardingSections = self.stringMap.extractOnboardingSections()
    }
}

extension Mapper {
    func from(_ field: String) throws -> ColorMap {
        let dict: [String: String] = try self.from(field)
        
        let colorMap: ColorMap = try dict.reduce([:]) { (result, pair) in
            guard let color = UIColor(hexString: pair.value) else {
                throw MapperError.customError(field: field, message: "Color Value '\(pair.value)' is not convertible to HEX color")
            }
            var result = result
            if let stringKey = ColorType(rawValue: pair.key) {
                result[stringKey] = color
            }
            return result
        }
        
        var check = false
        #if DEBUG
        check = Constants.Test.CheckGlobalColors
        #endif
        if check {
            let keys = colorMap.keys
            try ColorType.allCases.forEach { colorType in
                if false == keys.contains(colorType) {
                    throw MapperError.customError(field: field, message: "Color '\(colorType)' is missing in global config")
                }
            }
        }
        
        return colorMap
    }
    
    func from(_ field: String) throws -> StringMap {
        let dict: [String: String] = try self.from(field)
        
        let stringMap: StringMap = dict.reduce([:]) { (result, pair) in
            var result = result
            if let stringKey = StringKey(rawValue: pair.key) {
                result[stringKey] = pair.value
            }
            return result
        }
        
        var check = false
        #if DEBUG
        check = Constants.Test.CheckGlobalStrings
        #endif
        if check {
            let keys = stringMap.keys
            try StringKey.allCases.forEach { stringKey in
                if false == keys.contains(stringKey) {
                    throw MapperError.customError(field: field, message: "String '\(stringKey)' is missing in global config")
                }
            }
        }
        
        return stringMap
    }
    
    static func extractIntegrationData(object: Any?) throws -> [IntegrationData] {
        guard let integrationDatasOuterDict = object as? [String: Any] else {
            throw MapperError.convertibleError(value: object, type: [IntegrationData].self)
        }
        
        return integrationDatasOuterDict.compactMap { integrationDataOuterDictPair in
            let name = integrationDataOuterDictPair.key
            guard let integrationDataInnerDict = integrationDataOuterDictPair.value as? [String: Any] else {
                print("GlobalConfig - Missing integration inner data for integration '\(name)'")
                return nil
            }
            guard let oAuthAvailable = integrationDataInnerDict["oauth"] as? Bool else {
                print("GlobalConfig - Missing ouath data as Boolean for integration '\(name)'")
                return nil
            }
            return IntegrationData(name: name, oAuthAvailable: oAuthAvailable)
        }
    }
}

fileprivate extension StringMap {
    func extractOnboardingSections() throws -> [OnboardingSection] {
        guard let onboardingSectionListString = self[.onboardingSectionList] else {
            let errorMessage = "Missing list of onboarding section (key '\(StringKey.onboardingSectionList.rawValue)')"
            throw MapperError.customError(field: "strings", message: errorMessage)
        }
        let onboardingSectionStrings = onboardingSectionListString.split(separator: ";")
        return onboardingSectionStrings.compactMap { OnboardingSection(rawValue: String($0)) }
    }
}
