//
//  KrypticGrindApp.swift
//  KrypticGrind
//
//  Created by akhil on 29/06/25.
//

import SwiftUI
import UserNotifications

@main
struct KrypticGrindApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    
    init() {
        NotificationManager.shared.requestAuthorization()
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
        }
    }
}

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    private override init() { super.init() }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }
}
