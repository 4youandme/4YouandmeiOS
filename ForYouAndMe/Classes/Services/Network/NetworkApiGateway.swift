//
//  NetworkApiGateway.swift
//  ForYouAndMe
//
//  Created by Leonardo Passeri on 24/04/2020.
//  Copyright © 2020 Balzo srl. All rights reserved.
//

import Foundation
import Moya
import Moya_ModelMapper
import RxSwift
import Mapper
import Japx
import Reachability

protocol NetworkStorage: class {
    var accessToken: String? { get set }
}

struct UnhandledError: Mappable {
    init(map: Mapper) throws { throw MapperError.customError(field: nil, message: "Trying to map unhandled error") }
}

class NetworkApiGateway: ApiGateway {
    
    var defaultProvider: MoyaProvider<DefaultService>!
    
    lazy var loggerPlugin: PluginType = {
        let formatter = NetworkLoggerPlugin.Configuration.Formatter(requestData: Data.JSONRequestDataFormatter,
                                                                    responseData: Data.JSONRequestDataFormatter)
        let logOptions: NetworkLoggerPlugin.Configuration.LogOptions = Constants.Test.NetworkLogVerbose
            ? .verbose
            : .default
        let config = NetworkLoggerPlugin.Configuration(formatter: formatter, logOptions: logOptions)
        return NetworkLoggerPlugin(configuration: config)
    }()
    
    lazy var accessTokenPlugin: PluginType = {
        let tokenClosure: (AuthorizationType) -> String = { authorizationType in
            switch authorizationType {
            case .basic: return ""
            case .bearer: return self.storage.accessToken ?? ""
            case .custom: return ""
            }
        }
        let accessTokenPlugin = AccessTokenPlugin(tokenClosure: tokenClosure)
        
        return accessTokenPlugin
    }()
    
    fileprivate let storage: NetworkStorage
    fileprivate let reachability: ReachabilityService
    
    private let studyId: String
    
    // MARK: - Service Protocol Implementation
    
    public init(studyId: String, reachability: ReachabilityService, storage: NetworkStorage) {
        self.studyId = studyId
        self.reachability = reachability
        self.storage = storage
        self.setupDefaultProvider()
    }
    
    func setupDefaultProvider() {
        self.defaultProvider = MoyaProvider(endpointClosure: self.endpointMapping, plugins: [self.loggerPlugin, self.accessTokenPlugin])
    }
    
    func endpointMapping(forTarget target: DefaultService) -> Endpoint {
        let targetPath = target.getPath(forStudyId: self.studyId)
        let url: URL = {
            if targetPath.isEmpty {
                return target.baseURL
            } else {
                return target.baseURL.appendingPathComponent(targetPath)
            }
        }()
        return Endpoint(url: url.absoluteString,
                        sampleResponseClosure: {.networkResponse(200, target.sampleData)},
                        method: target.method,
                        task: target.task,
                        httpHeaderFields: target.headers)
    }
    
    // MARK: - ApiGateway Protocol Implementation
    
    func isLoggedIn() -> Bool {
        return self.storage.accessToken != nil
    }
    
    func logOut() {
        self.storage.accessToken = nil
    }
    
    func send<E: Mappable>(request: ApiRequest, errorType: E.Type) -> Single<()> {
        self.sendShared(request: request, errorType: errorType)
            .map { _ in return () }
    }
    
    func send<T: Mappable, E: Mappable>(request: ApiRequest, errorType: E.Type) -> Single<T> {
        self.sendShared(request: request, errorType: errorType)
            .map(to: T.self)
            .handleMapError()
    }
    
    func send<T: Mappable, E: Mappable>(request: ApiRequest, errorType: E.Type) -> Single<T?> {
        self.sendShared(request: request, errorType: errorType)
            .mapOptional(to: T.self)
    }
    
    func send<T: Mappable, E: Mappable>(request: ApiRequest, errorType: E.Type) -> Single<[T]> {
        self.sendShared(request: request, errorType: errorType)
            .map(to: [T].self)
            .catchError({ (error) in
            if let error = error as? ApiError {
                // Network or Server Error
                return Single.error(error)
            } else {
                debugPrint("Response map error: \(error)")
                return Single.error(ApiError.cannotParseData)
            }
        })
    }
    
    func sendExcludeInvalid<T: Mappable, E: Mappable>(request: ApiRequest, errorType: E.Type) -> Single<[T]> {
        self.sendShared(request: request, errorType: errorType)
            .do(onSuccess: { items in
                #if DEBUG
                do { try _ = items.map(to: [T].self) } catch {
                    debugPrint("Response map error: \(error)")
                }
                #endif
            })
            .compactMap(to: [T].self)
    }
    
    func send<T: JSONAPIMappable, E: Mappable>(request: ApiRequest, errorType: E.Type) -> Single<T> {
        self.sendShared(request: request, errorType: errorType)
        .mapCodableJSONAPI(includeList: T.includeList, keyPath: T.keyPath)
        .handleMapError()
    }
    
    func send<T: JSONAPIMappable, E: Mappable>(request: ApiRequest, errorType: E.Type) -> Single<T?> {
        self.sendShared(request: request, errorType: errorType)
            .mapCodableJSONAPI(includeList: T.includeList, keyPath: T.keyPath)
            .handleMapError()
            .catchError { error in
                if case ApiError.cannotParseData = error {
                    return Single.just(nil)
                } else {
                    return Single.error(error)
                }
        }
    }
    
    func send<T: JSONAPIMappable, E: Mappable>(request: ApiRequest, errorType: E.Type) -> Single<[T]> {
        self.sendShared(request: request, errorType: errorType)
            .mapCodableJSONAPI(includeList: T.includeList, keyPath: T.keyPath)
            .handleMapError()
    }
    
    // MARK: - Private Methods
    
    private func sendShared<E: Mappable>(request: ApiRequest, errorType: E.Type) -> Single<Response> {
        return self.defaultProvider.rx.request(request.serviceRequest)
            .filterSuccess(api: self, request: request, errorType: errorType)
    }
}

// MARK: - Extension (Single<T>)

fileprivate extension PrimitiveSequence where Trait == SingleTrait {

    func handleMapError() -> Single<Element> {
        return catchError({ (error) -> Single<Element> in
            if let error = error as? ApiError {
                // Network or Server Error
                return Single.error(error)
            } else {
                debugPrint("Response map error: \(error)")
                return Single.error(ApiError.cannotParseData)
            }
        })
    }
}

// MARK: - Extension (Single<Response>)

fileprivate extension PrimitiveSequence where Trait == SingleTrait, Element == Response {
    
    func filterSuccess<ErrorType: Mappable>(api: NetworkApiGateway,
                                            request: ApiRequest,
                                            errorType: ErrorType.Type) -> Single<Element> {
        return self
            .do(onError: {
                print("Network Error: \($0.localizedDescription)")
            })
            .catchError({ (error) -> Single<Response> in
                // Handle network availability
                if api.reachability.isCurrentlyReachable {
                    return Single.error(ApiError.network)
                } else {
                    return Single.error(ApiError.connectivity)
                }
            })
            .flatMap { response -> Single<Element> in
                if 200 ... 299 ~= response.statusCode {
                    // Uncomment this to print the whole response data
                    //                print("Network Body: \(String(data: response.data, encoding: .utf8) ?? "")")
                    self.handleAccessToken(response: response, storage: api.storage)
                    return Single.just(response)
                } else {
                    if response.statusCode >= 500 {
                        return Single.error(ApiError.network)
                    } else if 400 ... 499 ~= response.statusCode {
                        if let serverError = ServerErrorCode(rawValue: response.statusCode) {
                            switch serverError {
                            case .unauthorized:
                                return Single.error(ApiError.userUnauthorized)
                            }
                        } else if let error = try? response.map(to: errorType) {
                            return Single.error(ApiError.error(response.statusCode, error))
                        } else {
                            return Single.error(ApiError.errorCode(response.statusCode, String(data: response.data, encoding: .utf8) ?? ""))
                        }
                    }
                }
                // Its an error and can't decode error details from server, push generic message
                return Single.error(ApiError.network)
        }
    }
    
    private func handleAccessToken(response: Response, storage: NetworkStorage) {
        if var accessToken = response.response?.allHeaderFields["Authorization"] as? String {
            accessToken = accessToken.replacingOccurrences(of: "Bearer ", with: "")
            storage.accessToken = accessToken
        }
    }
}

// MARK: - TargetType Protocol Implementation
extension DefaultService: TargetType, AccessTokenAuthorizable {
    
    var baseURL: URL { return URL(string: Constants.Network.ApiBaseUrlStr)! }
    
    func getPath(forStudyId studyId: String) -> String {
        switch self {
        // Misc
        case .getGlobalConfig:
            return "/v1/studies/\(studyId)/configuration"
        // Login
        case .submitPhoneNumber:
            return "/v1/studies/\(studyId)/auth/verify_phone_number"
        case .verifyPhoneNumber:
            return "/v1/studies/\(studyId)/auth/login"
        // Screening Section
        case .getScreeningSection:
            return "/v1/studies/\(studyId)/screening"
        // Informed Consent Section
        case .getInformedConsentSection:
            return "/v1/studies/\(studyId)/informed_consent"
        }
    }
    
    // Need this to conform to TargetType protocol. getPath(forStudyId) is used instead
    var path: String { "" }
    
    var method: Moya.Method {
        switch self {
        case .getGlobalConfig,
             .getScreeningSection,
             .getInformedConsentSection:
            return .get
        case .submitPhoneNumber,
             .verifyPhoneNumber:
            return .post
        }
    }
    
    var sampleData: Data {
        switch self {
        // Misc
        case .getGlobalConfig: return Bundle.getTestData(from: "TestGetGlobalConfig")
        // Login
        case .submitPhoneNumber: return "{}".utf8Encoded
        case .verifyPhoneNumber: return "{}".utf8Encoded
        // Screening Section
        case .getScreeningSection: return Bundle.getTestData(from: "TestGetScreeningSection")
        // Informed Consent Section
        case .getInformedConsentSection:
            if Constants.Test.InformedConsentWithoutQuestions {
                return Bundle.getTestData(from: "TestGetInformedConsentSectionNoQuestions")
            } else {
                return Bundle.getTestData(from: "TestGetInformedConsentSection")
            }
        }
    }
    
    var task: Task {
        switch self {
        case .getGlobalConfig,
             .getScreeningSection,
             .getInformedConsentSection:
            return .requestPlain
        case .submitPhoneNumber(let phoneNumber):
            var params: [String: Any] = [:]
            params["phone_number"] = phoneNumber
            return .requestParameters(parameters: ["user": params], encoding: JSONEncoding.default)
        case .verifyPhoneNumber(let phoneNumber, let secureCode):
            var params: [String: Any] = [:]
            params["phone_number"] = phoneNumber
            params["verification_code"] = secureCode
            return .requestParameters(parameters: ["user": params], encoding: JSONEncoding.default)
        }
    }
    
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
    
    var authorizationType: AuthorizationType? {
        switch self {
        case .getGlobalConfig,
             .submitPhoneNumber,
             .verifyPhoneNumber:
            return .none
        case .getScreeningSection,
             .getInformedConsentSection:
            return .bearer
        }
    }
}
