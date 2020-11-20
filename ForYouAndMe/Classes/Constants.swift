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
        
        static let StartingOnboardingSection: OnboardingSection? = nil //.introVideo
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
    }
    struct Misc {
        static let EnableGlobalConfigCache = false
        static let PhoneValidationCodeDigitCount: Int = 6
        static let EmailValidationCodeDigitCount: Int = 6
        static let VideoDiaryMaxDurationSeconds: TimeInterval = 120.0
        static let VideoDiaryCaptureSessionPreset: AVCaptureSession.Preset = .hd1280x720
    }
    
    struct Url {
        static var BaseUrl: String { ProjectInfo.OauthBaseUrl }
        static let ApiOAuthIntegrationBaseUrl: URL = URL(string: "\(BaseUrl)/users/integration_oauth")!
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
        static let fileResultMimeType = "application/json"
        
        static let taskResultURL: URL = {
            let documentsDirectoryString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            var resultDirectory = URL(fileURLWithPath: documentsDirectoryString, isDirectory: true)
            resultDirectory.appendPathComponent(FilePath.taskResult.rawValue)
            return resultDirectory
        }()
        
        static let videoResultURL: URL = {
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
                                  items: []),
                UserInfoParameter(identifier: "2",
                                  name: "Your baby's gender",
                                  value: nil,
                                  type: .items,
                                  items: [
                                    UserInfoParameterItem(identifier: "1", value: "It's a Boy!"),
                                    UserInfoParameterItem(identifier: "2", value: "It's a Girl!")
                ]),
                UserInfoParameter(identifier: "3",
                                  name: "Your baby's name",
                                  value: nil,
                                  type: .string,
                                  items: [])
            ]
            return userInfoParameters
        }()
    }
}

enum FilePath: String {
    case taskResult = "TaskResult"
    case videoResult = "VideoResult"
}
