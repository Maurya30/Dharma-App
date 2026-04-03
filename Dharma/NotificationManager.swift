import Foundation
import UIKit
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private static let deviceTokenKey = "apnsDeviceToken"
    private static let sadhanaMorningId = "sadhana_morning"
    private let registerURL = BackendConfig.baseURL.appendingPathComponent("register-device")

    private init() {}

    /// Daily 7:00 local notification for Sadhana; body uses first 80 chars of verse.
    func scheduleSadhanaNotification(verseText: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.sadhanaMorningId])

        let prefix = String(verseText.prefix(80))
        let body = prefix + "..."

        let content = UNMutableNotificationContent()
        content.title = "ॐ Your Sadhana awaits"
        content.body = body

        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: Self.sadhanaMorningId, content: content, trigger: trigger)

        center.add(request) { error in
            if let error {
                print("Sadhana notification schedule failed: \(error.localizedDescription)")
            }
        }
    }

    /// Request permission, register for remote notifications, persist token when received.
    func setup() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    /// Hex string, UserDefaults (same storage as `@AppStorage("apnsDeviceToken")`), POST to backend.
    func saveDeviceToken(_ token: Data) {
        let hexToken = token.map { String(format: "%02x", $0) }.joined()
        print("APNS TOKEN: \(hexToken)")
        UserDefaults.standard.set(hexToken, forKey: Self.deviceTokenKey)

        var request = URLRequest(url: registerURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = ["token": hexToken, "platform": "ios"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        Task.detached {
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    print("register-device failed: HTTP \(http.statusCode)")
                }
            } catch {
                print("register-device error: \(error.localizedDescription)")
            }
        }
    }
}
