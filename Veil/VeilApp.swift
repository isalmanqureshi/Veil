//
//  VeilApp.swift
//  Veil
//
//  Created by Salman Qureshi on 2/5/26.
//

import SwiftUI
import UIKit

final class VeilAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task { @MainActor in
            PushNotificationCoordinator.bridge().didRegisterForRemoteNotifications(deviceToken: deviceToken)
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Task { @MainActor in
            PushNotificationCoordinator.bridge().didFailToRegisterForRemoteNotifications(error: error)
        }
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Task { @MainActor in
            PushNotificationCoordinator.bridge().handleRemoteNotification(userInfo: userInfo, completion: completionHandler)
        }
    }
}

@main
struct VeilApp: App {
    @UIApplicationDelegateAdaptor(VeilAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}
