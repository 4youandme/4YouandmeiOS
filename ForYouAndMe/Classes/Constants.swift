//
//  Constants.swift
//  ForYouAndMe
//
//  Created by Leonardo Passeri on 24/04/2020.
//  Copyright © 2020 Balzo srl. All rights reserved.
//

import Foundation
import AVFoundation

struct Constants {
    struct Test {
        static let NetworkStubsEnabled = false
        static let NetworkStubsDelay = 0.3
        static let NetworkLogVerbose = true
        
        static let StartingOnboardingSection: OnboardingSection? = nil
        static let OnboardingCompleted: Bool = true
        
        static let InformedConsentWithoutQuestions: Bool = false
        static let CheckGlobalStrings: Bool = false
        static let CheckGlobalColors: Bool = false
    }
    struct Network {
        static var BaseUrl: String { ProjectInfo.ApiBaseUrl }
        static var StudyId: String { ProjectInfo.StudyId }
        static let ApiBaseUrlStr = "\(BaseUrl)/api"
    }
    
    struct Style {
        static let DefaultHorizontalMargins: CGFloat = 24.0
        static let DefaultFooterHeight: CGFloat = 134.0
        static let DefaultTextButtonHeight: CGFloat = 52.0
        static let FeedCellButtonHeight: CGFloat = 44.0
        static let EditButtonHeight: CGFloat = 26.0
        static let DefaultBottomMargin: CGFloat = 20.0
        static let SurveyPickerDefaultHeight: CGFloat = 300.0
    }
    struct Resources {
        static let DefaultBundleName: String = "ForYouAndMe"
        static let IntroVideoUrl: URL? = {
            guard let videoPathString = Bundle.main.path(forResource: "StudyVideo", ofType: "mp4") else {
                assertionFailure("Missing Study Video File")
                return nil
            }
            return URL(fileURLWithPath: videoPathString)
        }()
        static let AppVersion: String? = {
            guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                  let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else {
                assertionFailure("Missing Info Plist")
                return nil
            }
            return "Version: \(version) (\(buildNumber))"
        }()
    }
    struct Misc {
        static let EnableGlobalConfigCache = false
        static let PhoneValidationCodeDigitCount: Int = 6
        static let EmailValidationCodeDigitCount: Int = 6
        static let FeedPageSize: Int? = 20
        static let VideoDiaryMaxDurationSeconds: TimeInterval = 120.0
        static let VideoDiaryCaptureSessionPreset: AVCaptureSession.Preset = .hd1280x720
        // Server limit is 20 but AVAssetExportSession.fileLengthLimit can be exceeded by 1 or 2 MB
        static let VideoDiaryMaxFileSize: Int64 = 1024 * 1024 * 18
        
        static let DeviceDataUploadConfig = BatchEventUploaderConfig(identifier: BatchEventUploaderIdentifier.deviceData.rawValue,
                                                                     defaultRecordInterval: 1.0 * 60.0 * 60.0,
                                                                     uploadInterval: nil,
                                                                     uploadRetryInterval: 1.0 * 60.0 * 60.0,
                                                                     bufferLimit: 100,
                                                                     enableDebugLog: false)
        static var DefaultLocationPermission: Permission { Permission.locationWhenInUse }
        
        static let TrackRelativeLocation: Bool = true
        static let WaitingTimeForLocation: DispatchTimeInterval = .seconds(10)
        static let MaxValidLocationAge: TimeInterval = 15.0
        static let PinCodeSuffix: String = ProjectInfo.PinCodeSuffix
    }
    
    struct Url {
        static var BaseUrl: String { ProjectInfo.OauthBaseUrl }
        static let ApiOAuthIntegrationBaseUrl: URL = URL(string: "\(BaseUrl)/users/integration_oauth")!
        static let ApiOAuthDeauthorizationBaseUrl: URL = URL(string: "\(BaseUrl)/users/deauthenticate")!
        static let OuraStoreUrl: URL = URL(string: "itms-apps://apps.apple.com/it/app/oura/id1043837948")!
        static let OuraAppSchema: URL = URL(string: "oura://")!
        static let FitbitStoreUrl: URL = URL(string: "itms-apps://apps.apple.com/us/app/fitbit-health-fitness/id462638897")!
        static let FitbitAppSchema: URL = URL(string: "fitbit://")!
        static let GarminStoreUrl: URL = URL(string: "itms-apps://apps.apple.com/us/app/garmin-connect/id583446403")!
        static let GarminAppSchema: URL = URL(string: "gcm-ciq://")!
        static let InstagramStoreUrl: URL = URL(string: "itms-apps://apps.apple.com/us/app/instagram/id389801252")!
        static let InstagramAppSchema: URL = URL(string: "instagram://")!
        static let RescueTimeStoreUrl: URL = URL(string: "itms-apps://apps.apple.com/us/app/rescuetime/id966285407")!
        static let RescueTimeAppSchema: URL = URL(string: "rescuetime://")!
        static let TwitterStoreUrl: URL = URL(string: "itms-apps://apps.apple.com/us/app/twitter/id333903271")!
        static let TwitterAppSchema: URL = URL(string: "twitter://")!
    }
    
    struct Task {
        static let FileResultMimeType = "application/json"
        
        static let TaskResultURL: URL = {
            let documentsDirectoryString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            var resultDirectory = URL(fileURLWithPath: documentsDirectoryString, isDirectory: true)
            resultDirectory.appendPathComponent(FilePath.taskResult.rawValue)
            return resultDirectory
        }()
        
        static let VideoResultURL: URL = {
            let documentsDirectoryString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            var resultDirectory = URL(fileURLWithPath: documentsDirectoryString, isDirectory: true)
            resultDirectory.appendPathComponent(FilePath.videoResult.rawValue)
            return resultDirectory
        }()
    }
    
    struct Survey {
        static let TargetQuit: String = "exit"
        static let NumericTypeMinValue: String = "min_display"
        static let NumericTypeMaxValue: String = "max_display"
        static let ScaleTypeDefaultInterval: Int = 1
    }
    
    struct UserInfo {
        // TODO: Wipe out this awful thing when the backend is ready for something more generic...
        static let FeedTitleParameterIdentifier = "1"
        static let DefaultUserInfoParameters: [UserInfoParameter] = {
            let userInfoParameters: [UserInfoParameter] = [
                UserInfoParameter(identifier: Self.FeedTitleParameterIdentifier,
                                  name: "Your due date",
                                  value: nil,
                                  type: .date,
                                  items: [])
//                UserInfoParameter(identifier: "2",
//                                  name: "Your baby's gender",
//                                  value: nil,
//                                  type: .items,
//                                  items: [
//                                    UserInfoParameterItem(identifier: "1", value: "It's a Boy!"),
//                                    UserInfoParameterItem(identifier: "2", value: "It's a Girl!")
//                ]),
//                UserInfoParameter(identifier: "3",
//                                  name: "Your baby's name",
//                                  value: nil,
//                                  type: .string,
//                                  items: [])
            ]
            return userInfoParameters
        }()
    }
}

enum FilePath: String {
    case taskResult = "TaskResult"
    case videoResult = "VideoResult"
}

enum BatchEventUploaderIdentifier: String {
    case deviceData
}
