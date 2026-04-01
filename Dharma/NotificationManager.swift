import Foundation
import UIKit
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private static let deviceTokenKey = "apnsDeviceToken"
    private let registerURL = BackendConfig.baseURL.appendingPathComponent("register-device")

    private init() {}

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
