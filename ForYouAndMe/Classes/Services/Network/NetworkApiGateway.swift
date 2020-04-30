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
import Reachability

struct UnhandledError: Mappable {
    init(map: Mapper) throws { throw MapperError.customError(field: nil, message: "Trying to map unhandled error") }
}

class NetworkApiGateway: ApiGateway {
    
    let reachability: ReachabilityService
    let studyId: String
    
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
    
    // MARK: - Service Protocol Implementation
    
    public init(studyId: String, reachability: ReachabilityService) {
        self.studyId = studyId
        self.reachability = reachability
        self.setupDefaultProvider()
    }
    
    func setupDefaultProvider() {
        self.defaultProvider = MoyaProvider(endpointClosure: self.endpointMapping, plugins: [self.loggerPlugin])
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
    
    func send(request: ApiRequest) -> Single<Void> {
        return self.send(request: request, errorType: UnhandledError.self)
    }
    
    func send<T: Mappable>(request: ApiRequest) -> Single<T> {
        return self.send(request: request, errorType: UnhandledError.self)
    }
       
    func send<T: Mappable>(request: ApiRequest) -> Single<T?> {
        return self.send(request: request, errorType: UnhandledError.self)
    }
       
    func send<T: Mappable>(request: ApiRequest) -> Single<[T]> {
        return self.send(request: request, errorType: UnhandledError.self)
    }
       
    func sendExcludeInvalid<T: Mappable>(request: ApiRequest) -> Single<[T]> {
        return self.sendExcludeInvalid(request: request, errorType: UnhandledError.self)
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
    
    func sendShared<E: Mappable>(request: ApiRequest, errorType: E.Type) -> Single<Response> {
        return self.defaultProvider.rx.request(request.serviceRequest)
        .filterSuccess(api: self, request: request, errorType: errorType)
    }
}

fileprivate extension PrimitiveSequence where Trait == SingleTrait, Element: Mappable {

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

fileprivate extension PrimitiveSequence where Trait == SingleTrait, Element == Response {
    
    func filterSuccess<ErrorType: Mappable>(api: NetworkApiGateway,
                                            request: ApiRequest,
                                            errorType: ErrorType.Type) -> Single<Element> {
        return self
            .do(onError: {
                print("Network Error: \($0.localizedDescription)")
            })
            .catchError({ (error) -> Single<Element> in
                // Handle network availability
                if api.reachability.isCurrentlyReachable {
                    return Single.error(ApiError.network)
                } else {
                    return Single.error(ApiError.connectivity)
                }
            })
            .flatMap { (response) -> Single<Element> in
                if 200 ... 299 ~= response.statusCode {
                    // Uncomment this to print the whole response data
                    //                print("Network Body: \(String(data: response.data, encoding: .utf8) ?? "")")
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
}

// MARK: - TargetType Protocol Implementation
extension DefaultService: TargetType {
    
    var baseURL: URL { return URL(string: Constants.Network.ApiBaseUrlStr)! }
    
    func getPath(forStudyId studyId: String) -> String {
        switch self {
        // Misc
        case .getGlobalConfig:
            return "/v1/studies/\(studyId)/configuration"
        }
    }
    
    // Need this to conform to TargetType protocol. getPath(forStudyId) is used instead
    var path: String { "" }
    
    var method: Moya.Method {
        switch self {
        case .getGlobalConfig:
            return .get
        }
    }
    
    var sampleData: Data {
        switch self {
        // Misc
        case .getGlobalConfig: return Bundle.getTestData(from: "TestGetGlobalConfig")
        }
    }
    
    var task: Task {
        switch self {
        case .getGlobalConfig:
            return .requestPlain
        }
    }
    
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}
