//
//  ApiGateway.swift
//  ForYouAndMe
//
//  Created by Leonardo Passeri on 24/04/2020.
//  Copyright © 2020 Balzo srl. All rights reserved.
//

import Foundation
import RxSwift
import Mapper
import Japx

enum DefaultService {
    // Misc
    case getGlobalConfig
    // Login
    case submitPhoneNumber(phoneNumber: String)
    case verifyPhoneNumber(phoneNumber: String, validationCode: String)
    // Screening Section
    case getScreeningSection
    // Informed Consent Section
    case getInformedConsentSection
    // Consent Section
    case getConsentSection
    // Opt In Section
    case getOptInSection
    case sendOptInPermission(permissionId: String, granted: Bool)
    // User Consent Section
    case getUserConsentSection
    case createUserConsent(email: String?, firstName: String?, lastName: String?, signatureImage: UIImage?)
    case updateUserConsent(email: String?, firstName: String?, lastName: String?, signatureImage: UIImage?)
    case verifyEmail(validationCode: String)
    case resendConfirmationEmail
}

struct ApiRequest {
    
    let serviceRequest: DefaultService
    
    init(serviceRequest: DefaultService) {
        self.serviceRequest = serviceRequest
    }
}

enum ApiError: Error {

    case internalError
    case cannotParseData
    case network
    case connectivity
    case errorCode(Int, String)
    case error(Int, Any)
    case userUnauthorized
}

protocol ApiGateway {
    
    func send<E: Mappable>(request: ApiRequest, errorType: E.Type) -> Single<()>
    
    // Mappable entities (Model Mapper)
    func send<T: Mappable, E: Mappable>(request: ApiRequest, errorType: E.Type) -> Single<T>
    func send<T: Mappable, E: Mappable>(request: ApiRequest, errorType: E.Type) -> Single<T?>
    func send<T: Mappable, E: Mappable>(request: ApiRequest, errorType: E.Type) -> Single<[T]>
    func sendExcludeInvalid<T: Mappable, E: Mappable>(request: ApiRequest, errorType: E.Type) -> Single<[T]>
    
    // JSONAPIMappable entities (Japx)
    func send<T: JSONAPIMappable, E: Mappable>(request: ApiRequest, errorType: E.Type) -> Single<T>
    func send<T: JSONAPIMappable, E: Mappable>(request: ApiRequest, errorType: E.Type) -> Single<T?>
    func send<T: JSONAPIMappable, E: Mappable>(request: ApiRequest, errorType: E.Type) -> Single<[T]>
    
    func isLoggedIn() -> Bool
    func logOut()
}

extension ApiGateway {
    func send(request: ApiRequest) -> Single<()> {
        return self.send(request: request, errorType: ResponseError.self)
    }
    
    // Mappable entities (Model Mapper)
    func send<T: Mappable>(request: ApiRequest) -> Single<T> {
        return self.send(request: request, errorType: ResponseError.self)
    }

    func send<T: Mappable>(request: ApiRequest) -> Single<T?> {
        return self.send(request: request, errorType: ResponseError.self)
    }

    func send<T: Mappable>(request: ApiRequest) -> Single<[T]> {
        return self.send(request: request, errorType: ResponseError.self)
    }

    func sendExcludeInvalid<T: Mappable>(request: ApiRequest) -> Single<[T]> {
        return self.sendExcludeInvalid(request: request, errorType: ResponseError.self)
    }
    
    // JSONAPIMappable entities (Japx)
    func send<T: JSONAPIMappable>(request: ApiRequest) -> Single<T> {
        return self.send(request: request, errorType: ResponseError.self)
    }
    
    func send<T: JSONAPIMappable>(request: ApiRequest) -> Single<T?> {
        return self.send(request: request, errorType: ResponseError.self)
    }
    
    func send<T: JSONAPIMappable>(request: ApiRequest) -> Single<[T]> {
        return self.send(request: request, errorType: ResponseError.self)
    }
}
