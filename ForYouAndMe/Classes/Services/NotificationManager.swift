//
//  NotificationManager.swift
//  ForYouAndMe
//
//  Created by Leonardo Passeri on 15/10/2020.
//

import Foundation
import RxSwift
import FirebaseMessaging

protocol NotificationDeeplinkHandler: class {
    func receivedNotificationDeeplinkedOpenTaskId(forTaskId taskId: String)
    func receivedNotificationDeeplinkedOpenURL(forUrl url: URL)
    func receivedNotificationDeeplinkedOpenIntegrationApp(forIntegration integration: Integration)
}

protocol NotificationTokenHandler: class {
    func registerNotificationToken(token: String)
}

class NotificationManager: NSObject, NotificationService {
    
    private enum DeeplinkKey: String, CaseIterable {
        case taskId = "task_id"
        case url
        case openIntegrationApp = "open_app_integration"
    }
    
    private let notificationDeeplinkHandler: NotificationDeeplinkHandler
    private let notificationTokenHandler: NotificationTokenHandler
    
    init(withNotificationDeeplinkHandler notificationDeeplinkHandler: NotificationDeeplinkHandler,
         notificationTokenHandler: NotificationTokenHandler) {
        self.notificationDeeplinkHandler = notificationDeeplinkHandler
        self.notificationTokenHandler = notificationTokenHandler
        super.init()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
    }
    
    // MARK: - Private Methods
    
    private func processPushPayload(userInfo: [AnyHashable: Any]) {
        guard let deeplinkKey = DeeplinkKey.allCases.first(where: { nil != userInfo[$0.rawValue] }),
              let value = userInfo[deeplinkKey.rawValue] else {
            return
        }
        switch deeplinkKey {
        case .taskId:
            guard let valueString = value as? String else {
                return
            }
            self.notificationDeeplinkHandler.receivedNotificationDeeplinkedOpenTaskId(forTaskId: valueString)
        case .url:
            guard let valueString = value as? String, let deepLinkedUrl = URL(string: valueString) else {
                return
            }
            self.notificationDeeplinkHandler.receivedNotificationDeeplinkedOpenURL(forUrl: deepLinkedUrl)
        case .openIntegrationApp:
            guard let valueString = value as? String, let integration = Integration(rawValue: valueString) else {
                return
            }
            self.notificationDeeplinkHandler.receivedNotificationDeeplinkedOpenIntegrationApp(forIntegration: integration)
        }
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    
    // Receive displayed notifications for iOS 10 devices.
    // This method will be called when app received push notifications in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Not handled as soon as the push arrives in foreground. The alert is still shown and, if tapped, calls the callback below
        completionHandler([[.alert, .sound]])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        self.processPushPayload(userInfo: userInfo)
        completionHandler()
    }
}

extension NotificationManager: MessagingDelegate {
    // [START refresh_token]
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
        self.notificationTokenHandler.registerNotificationToken(token: fcmToken)
    }
    // [END refresh_token]
}
