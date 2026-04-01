import Combine
import Foundation
import SwiftUI

/// Routes push notification taps to the correct tab and sub-destination.
@MainActor
final class NotificationNavigationState: ObservableObject {
    static let shared = NotificationNavigationState()

    @Published var selectedTab: Int = 0
    /// Resolved in ContentView using `ScriptureStore` when only `verseSource` is known.
    @Published var pendingVerseSource: String?
    /// When set, ContentView presents this verse (Library tab).
    @Published var pendingScriptureItemId: UUID?
    /// Calendar: scroll to this date (yyyy-MM-dd) and highlight festivals on that day.
    @Published var pendingFestivalDate: String?
    @Published var pendingFestivalName: String?
    /// Journey: open goal path map for this goal id (matches `GoalsManager` goal string).
    @Published var pendingGoalIdForPathMap: String?

    func resetPendingDetail() {
        pendingScriptureItemId = nil
        pendingVerseSource = nil
    }

    func resetFestivalHighlight() {
        pendingFestivalDate = nil
        pendingFestivalName = nil
    }

    func applyPushPayload(_ userInfo: [AnyHashable: Any]) {
        var data: [String: Any] = [:]
        for (k, v) in userInfo {
            guard let key = k as? String, key != "aps" else { continue }
            data[key] = v
        }
        guard let type = data["type"] as? String else { return }

        switch type {
        case "verse":
            selectedTab = 1
            if let src = data["verseSource"] as? String, !src.isEmpty {
                pendingVerseSource = src
            } else if let vid = data["verseId"] as? String, let uuid = UUID(uuidString: vid) {
                pendingScriptureItemId = uuid
            }
        case "festival":
            pendingFestivalDate = data["festivalDate"] as? String
            pendingFestivalName = data["festivalName"] as? String
            selectedTab = 3
        case "goal":
            if let gid = data["goalId"] as? String {
                pendingGoalIdForPathMap = gid
            } else {
                pendingGoalIdForPathMap = GoalsManager.shared.selectedGoals.first
            }
            selectedTab = 2
        case "streak", "weekly", "brahma_muhurta":
            selectedTab = 0
        default:
            break
        }
    }
}
