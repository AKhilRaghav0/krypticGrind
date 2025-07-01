import Foundation
import UserNotifications
import SwiftUI
#if canImport(ActivityKit)
import ActivityKit
#endif

class NotificationManager {
    static let shared = NotificationManager()
    private init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("[NotificationManager] Notification permission error: \(error)")
            }
            print("[NotificationManager] Notification permission granted: \(granted)")
        }
    }
    
    func scheduleNotification(title: String, body: String, date: Date, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(date.timeIntervalSinceNow, 1), repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        print("[NotificationManager] Scheduling notification: title=\(title), body=\(body), date=\(date), identifier=\(identifier)")
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[NotificationManager] Failed to schedule notification: \(error)")
            } else {
                print("[NotificationManager] Notification scheduled successfully for identifier: \(identifier)")
            }
        }
    }
    
    func testNotification() {
        print("[NotificationManager] Test notification triggered")
        scheduleNotification(title: "Test Notification", body: "This is a test notification from KrypticGrind!", date: Date().addingTimeInterval(5), identifier: "test_notification")
    }
    
    #if canImport(ActivityKit)
    private var currentActivity: Activity<ContestCountdownAttributes>? = nil
    
    func startContestLiveActivity(contest: CFContest) {
        print("[LiveActivity] Attempting to start Live Activity...")
        print("[LiveActivity] Device: \(UIDevice.current.model), iOS: \(UIDevice.current.systemVersion)")
        guard let startDate = contest.startDate else {
            print("[LiveActivity] No startDate for contest, cannot start Live Activity.")
            return
        }
        let endDate = contest.endDate ?? startDate.addingTimeInterval(TimeInterval(contest.durationSeconds))
        let attributes = ContestCountdownAttributes(contestName: contest.name)
        let state = ContestCountdownAttributes.ContentState(startDate: startDate, endDate: endDate)
        if #available(iOS 16.1, *) {
            do {
                currentActivity = try Activity<ContestCountdownAttributes>.request(attributes: attributes, contentState: state, pushType: nil)
                print("[LiveActivity] Live Activity started successfully.")
            } catch {
                print("[LiveActivity] Failed to start Live Activity: \(error)")
            }
        } else {
            print("[LiveActivity] Live Activities are not supported on this iOS version.")
        }
    }
    
    func endContestLiveActivity() {
        Task {
            await currentActivity?.end(dismissalPolicy: .immediate)
        }
    }
    
    func testLiveActivity() {
        print("[LiveActivity] Test Live Activity triggered")
        let now = Date()
        let end = now.addingTimeInterval(3 * 60) // 3 minutes from now
        let attributes = ContestCountdownAttributes(contestName: "Test Live Activity")
        let state = ContestCountdownAttributes.ContentState(startDate: now, endDate: end)
        if #available(iOS 16.1, *) {
            do {
                currentActivity = try Activity<ContestCountdownAttributes>.request(attributes: attributes, contentState: state, pushType: nil)
                print("[LiveActivity] Test Live Activity started successfully.")
            } catch {
                print("[LiveActivity] Failed to start Test Live Activity: \(error)")
            }
        } else {
            print("[LiveActivity] Live Activities are not supported on this iOS version.")
        }
    }
    #endif
}

#if canImport(ActivityKit)
// ContestCountdownAttributes is defined in ContestLiveActivityWidgetLiveActivity.swift
#endif 