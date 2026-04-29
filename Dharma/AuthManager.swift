import AuthenticationServices
import Combine
import Foundation

struct DharmaUser: Codable {
    let userId: String
    let fullName: String?
    let email: String?
}

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isSignedIn: Bool = false
    @Published var isGuest: Bool = false
    @Published var currentUser: DharmaUser?
    @Published var isLoading: Bool = false
    @Published var lastOfferingSummary: String = ""
    @Published var hasPendingSync = false

    private static let sessionTokenKey = "auth_session_token"
    private static let userIdKey = "auth_user_id"
    private static let isGuestKey = "auth_is_guest"
    private static let fullNameKey = "auth_full_name"
    private static let emailKey = "auth_email"
    private static let lastOfferingSummaryKey = "last_offering_summary"

    private var didRestoreThisLaunch = false
    private var cancellables = Set<AnyCancellable>()
    private let network = NetworkMonitor.shared

    private init() {
        let guest = UserDefaults.standard.bool(forKey: Self.isGuestKey)
        let token = UserDefaults.standard.string(forKey: Self.sessionTokenKey) ?? ""
        let uid = UserDefaults.standard.string(forKey: Self.userIdKey) ?? ""
        let name = UserDefaults.standard.string(forKey: Self.fullNameKey)
        let email = UserDefaults.standard.string(forKey: Self.emailKey)
        let offeringSummary = UserDefaults.standard.string(forKey: Self.lastOfferingSummaryKey) ?? ""

        isGuest = guest
        isSignedIn = !guest && !token.isEmpty && !uid.isEmpty
        if isSignedIn {
            currentUser = DharmaUser(userId: uid, fullName: name, email: email)
        } else {
            currentUser = nil
        }
        lastOfferingSummary = offeringSummary

        network.$isConnected
            .receive(on: RunLoop.main)
            .sink { [weak self] connected in
                guard let self, connected, self.hasPendingSync else { return }
                self.hasPendingSync = false
                Task { await self.syncToCloud() }
            }
            .store(in: &cancellables)
    }

    func getAuthHeader() -> String? {
        guard let token = UserDefaults.standard.string(forKey: Self.sessionTokenKey), !token.isEmpty else {
            return nil
        }
        return "Bearer \(token)"
    }

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async {
        guard let tokenData = credential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8) else {
            return
        }

        let fullName: String? = {
            guard let name = credential.fullName else { return nil }
            let formatter = PersonNameComponentsFormatter()
            let s = formatter.string(from: name).trimmingCharacters(in: .whitespacesAndNewlines)
            return s.isEmpty ? nil : s
        }()

        let email = credential.email

        isLoading = true
        defer { isLoading = false }

        do {
            var payload: [String: Any] = ["identityToken": identityToken]
            if let fullName { payload["fullName"] = fullName }
            if let email { payload["email"] = email }

            let url = BackendConfig.baseURL.appendingPathComponent("auth/apple")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }

            let decoded = try JSONDecoder().decode(AppleAuthResponse.self, from: data)

            let resolvedName = fullName ?? UserDefaults.standard.string(forKey: Self.fullNameKey)
            let resolvedEmail = email ?? UserDefaults.standard.string(forKey: Self.emailKey)

            UserDefaults.standard.set(decoded.sessionToken, forKey: Self.sessionTokenKey)
            UserDefaults.standard.set(decoded.userId, forKey: Self.userIdKey)
            UserDefaults.standard.set(false, forKey: Self.isGuestKey)
            if let resolvedName { UserDefaults.standard.set(resolvedName, forKey: Self.fullNameKey) }
            if let resolvedEmail { UserDefaults.standard.set(resolvedEmail, forKey: Self.emailKey) }

            isSignedIn = true
            isGuest = false
            currentUser = DharmaUser(
                userId: decoded.userId,
                fullName: resolvedName,
                email: resolvedEmail
            )

            await syncToCloud()
        } catch {
            _ = error
        }
    }

    func continueAsGuest() {
        hasPendingSync = false
        isGuest = true
        isSignedIn = false
        currentUser = nil
        UserDefaults.standard.set(true, forKey: Self.isGuestKey)
        UserDefaults.standard.removeObject(forKey: Self.sessionTokenKey)
        UserDefaults.standard.removeObject(forKey: Self.userIdKey)
        UserDefaults.standard.removeObject(forKey: Self.fullNameKey)
        UserDefaults.standard.removeObject(forKey: Self.emailKey)
    }

    func signOut() {
        hasPendingSync = false
        UserDefaults.standard.removeObject(forKey: Self.sessionTokenKey)
        UserDefaults.standard.removeObject(forKey: Self.userIdKey)
        UserDefaults.standard.removeObject(forKey: Self.fullNameKey)
        UserDefaults.standard.removeObject(forKey: Self.emailKey)
        UserDefaults.standard.set(true, forKey: Self.isGuestKey)

        isSignedIn = false
        isGuest = true
        currentUser = nil
    }

    func clearAllLocalData() {
        let defaults = UserDefaults.standard
        let authKeys = [
            Self.sessionTokenKey, Self.userIdKey, Self.isGuestKey, Self.fullNameKey, Self.emailKey,
            Self.lastOfferingSummaryKey
        ]
        for key in authKeys {
            defaults.removeObject(forKey: key)
        }

        defaults.removeObject(forKey: "selectedGoals")
        defaults.removeObject(forKey: "hasCompletedGoalSelection")
        defaults.removeObject(forKey: "dharma_goal_paths")

        let streakKeys = [
            "sm_streak", "sm_longest", "sm_total_verses", "sm_last_practice", "sm_active_days",
            "sm_week_start", "sm_active_days_month", "sm_month_start", "sm_acknowledged",
            "sm_insight_text", "sm_insight_date", "sm_shield"
        ]
        for key in streakKeys {
            defaults.removeObject(forKey: key)
        }

        let scriptureKeys = [
            "dharma_favourites", "dharma_read_verses", "dharma_last_read", "dharma_last_read_by_category",
            "dharma_last_practice_date", "dharma_streak"
        ]
        for key in scriptureKeys {
            defaults.removeObject(forKey: key)
        }

        let onboardingKeys = [
            "dharma_onboarding_done", "dharma_user_name", "dharma_intention", "dharma_pace",
            "dharma_onboarding_profile", "dharma_tutorial_done"
        ]
        for key in onboardingKeys {
            defaults.removeObject(forKey: key)
        }

        defaults.removeObject(forKey: "krishna_messages_calendar_day")
        defaults.removeObject(forKey: "krishna_messages_count_today")

        let sadhanaKeys = [
            "sadhana_darshan_date", "sadhana_bhavana_date", "sadhana_seva_date", "sadhana_streak",
            "sadhana_last_completion_date", "sadhana_total_acts", "sadhana_notification_verse_hash",
            "sadhana_bhavana_input", "sadhana_bhavana_krishna", "sadhana_darshan_verse_id", "sadhana_darshan_input"
        ]
        for key in sadhanaKeys {
            defaults.removeObject(forKey: key)
        }

        defaults.removeObject(forKey: "apnsDeviceToken")
        defaults.removeObject(forKey: "userDarkMode")
        defaults.removeObject(forKey: "sadhana_open_krishna")

        if let group = UserDefaults(suiteName: "group.com.maurya.Dharma") {
            for key in ["widget_verse", "widget_all_verses", "widget_favourites", "widget_content_type", "userDarkMode"] {
                group.removeObject(forKey: key)
            }
        }

        lastOfferingSummary = ""
    }

    func deleteAccount() async {
        guard let authHeader = getAuthHeader() else { return }

        let url = BackendConfig.baseURL.appendingPathComponent("user/delete")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return }

            hasPendingSync = false
            clearAllLocalData()
            JournalStore.shared.deleteAllEntries()
            GoalPathManager.shared.clearAllPaths()
            isSignedIn = false
            isGuest = true
            currentUser = nil
            UserDefaults.standard.set(true, forKey: Self.isGuestKey)
            UserDefaults.standard.removeObject(forKey: Self.sessionTokenKey)
        } catch {
            _ = error
        }
    }

    func syncToCloud() async {
        guard isSignedIn, !isGuest, let auth = getAuthHeader() else { return }
        guard network.isConnected else {
            hasPendingSync = true
            return
        }

        do {
            let pathData = try JSONEncoder().encode(GoalPathManager.shared.paths)
            let pathJSON = try JSONSerialization.jsonObject(with: pathData)

            var syncBody: [String: Any] = [
                "goals": GoalsManager.shared.selectedGoals,
                "favourites": ScriptureStore.shared.favouriteUUIDStrings,
                "streakDays": StreakManager.shared.currentStreak,
                "totalPoints": StreakManager.shared.totalVersesRead,
                "goalPathProgress": pathJSON,
                "sadhanaStreak": SadhanaManager.shared.streakDays,
                "sadhanaTotalActs": SadhanaManager.shared.totalActsCompleted,
                "lastOfferingSummary": lastOfferingSummary
            ]
            if let title = latestEarnedTitle() {
                syncBody["sanskritTitle"] = title
            } else {
                syncBody["sanskritTitle"] = NSNull()
            }

            let syncURL = BackendConfig.baseURL.appendingPathComponent("user/sync")
            var syncRequest = URLRequest(url: syncURL)
            syncRequest.httpMethod = "POST"
            syncRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            syncRequest.setValue(auth, forHTTPHeaderField: "Authorization")
            syncRequest.httpBody = try JSONSerialization.data(withJSONObject: syncBody)

            let (_, syncResp) = try await URLSession.shared.data(for: syncRequest)
            guard let http = syncResp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }

            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            let journals: [[String: Any]] = JournalStore.shared.entries.map { entry in
                [
                    "verseId": entry.verseId,
                    "verseSource": entry.verseSource,
                    "reflection": entry.noteText,
                    "createdAt": iso.string(from: entry.date)
                ]
            }

            let journalURL = BackendConfig.baseURL.appendingPathComponent("user/journal/sync")
            var journalRequest = URLRequest(url: journalURL)
            journalRequest.httpMethod = "POST"
            journalRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            journalRequest.setValue(auth, forHTTPHeaderField: "Authorization")
            journalRequest.httpBody = try JSONSerialization.data(withJSONObject: ["journals": journals])

            let (_, jResp) = try await URLSession.shared.data(for: journalRequest)
            guard let jHttp = jResp as? HTTPURLResponse, (200...299).contains(jHttp.statusCode) else {
                throw URLError(.badServerResponse)
            }
            hasPendingSync = false
        } catch {
            _ = error
        }
    }

    func restoreFromCloud() async {
        guard isSignedIn, !isGuest, let auth = getAuthHeader() else { return }

        do {
            let dataURL = BackendConfig.baseURL.appendingPathComponent("user/data")
            var dataRequest = URLRequest(url: dataURL)
            dataRequest.setValue(auth, forHTTPHeaderField: "Authorization")

            let (data, dataResp) = try await URLSession.shared.data(for: dataRequest)
            guard let dHttp = dataResp as? HTTPURLResponse, (200...299).contains(dHttp.statusCode) else {
                throw URLError(.badServerResponse)
            }

            if let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let profile = obj["profile"] as? [String: Any],
                   let pid = profile["id"] as? String {
                    if let name = profile["full_name"] as? String { UserDefaults.standard.set(name, forKey: Self.fullNameKey) }
                    if let em = profile["email"] as? String { UserDefaults.standard.set(em, forKey: Self.emailKey) }
                    currentUser = DharmaUser(
                        userId: pid,
                        fullName: profile["full_name"] as? String ?? UserDefaults.standard.string(forKey: Self.fullNameKey),
                        email: profile["email"] as? String ?? UserDefaults.standard.string(forKey: Self.emailKey)
                    )
                }

                if let ud = obj["userData"] as? [String: Any] {
                    if let g = ud["goals"] as? [String] {
                        GoalsManager.shared.replaceFromCloud(selectedGoals: g, hasCompletedSelection: true)
                    }
                    if let fav = ud["favourites"] as? [String] {
                        ScriptureStore.shared.applyFavouriteUUIDsFromCloud(fav)
                    }
                    if let sd = ud["streak_days"] as? Int, let tp = ud["total_points"] as? Int {
                        StreakManager.shared.applyFromCloud(streakDays: sd, totalVersesRead: tp)
                    }
                    if let gp = ud["goal_path_progress"] {
                        let pathData = try JSONSerialization.data(withJSONObject: gp)
                        let paths = try JSONDecoder().decode([GoalPath].self, from: pathData)
                        GoalPathManager.shared.replaceFromCloud(paths)
                    }
                    if let ss = ud["sadhana_streak"] as? Int, let ta = ud["sadhana_total_acts"] as? Int {
                        SadhanaManager.shared.applyFromCloud(streakDays: ss, totalActs: ta)
                    }
                    if let summary = ud["last_offering_summary"] as? String, !summary.isEmpty {
                        saveOfferingSummary(summary)
                    }
                }
            }

            let journalURL = BackendConfig.baseURL.appendingPathComponent("user/journal")
            var jRequest = URLRequest(url: journalURL)
            jRequest.setValue(auth, forHTTPHeaderField: "Authorization")

            let (jData, jResp) = try await URLSession.shared.data(for: jRequest)
            guard let jHttp = jResp as? HTTPURLResponse, (200...299).contains(jHttp.statusCode) else {
                throw URLError(.badServerResponse)
            }

            let jObj = try JSONSerialization.jsonObject(with: jData) as? [String: Any]
            let rows = jObj?["journals"] as? [[String: Any]] ?? []
            let items = ScriptureStore.shared.items
            let decoded = try rows.map { row -> JournalEntry in
                try journalEntry(fromJSONObject: row, scriptureItems: items)
            }
            JournalStore.shared.replaceFromCloud(decoded)
        } catch {
            _ = error
        }
    }

    func restoreFromCloudOnLaunchIfNeeded() async {
        guard isSignedIn, !isGuest, !didRestoreThisLaunch else { return }
        didRestoreThisLaunch = true
        await restoreFromCloud()
    }

    private func latestEarnedTitle() -> String? {
        let titles = GoalPathManager.shared.paths.flatMap(\.earnedTitles)
        guard let t = titles.max(by: { $0.earnedDate < $1.earnedDate }) else { return nil }
        return t.title
    }

    func saveOfferingSummary(_ summary: String) {
        lastOfferingSummary = summary
        UserDefaults.standard.set(summary, forKey: Self.lastOfferingSummaryKey)
        Task {
            await syncToCloud()
        }
    }

    private func journalEntry(fromJSONObject row: [String: Any], scriptureItems: [ScriptureItem]) throws -> JournalEntry {
        let verseId = row["verse_id"] as? String ?? ""
        let verseSource = row["verse_source"] as? String
        let reflection = row["reflection"] as? String ?? ""

        let date: Date = {
            if let s = row["created_at"] as? String {
                let f = ISO8601DateFormatter()
                f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let d = f.date(from: s) { return d }
                f.formatOptions = [.withInternetDateTime]
                return f.date(from: s) ?? Date()
            }
            return Date()
        }()

        let match = scriptureItems.first { $0.id.uuidString == verseId }
            ?? scriptureItems.first { $0.source == verseSource }

        let verseRef = match.map { $0.source } ?? (verseSource ?? "")
        let verseSrc = verseSource ?? match?.source ?? ""
        let english = match?.textEnglish ?? ""

        return JournalEntry(
            id: UUID(),
            verseId: verseId,
            verseReference: verseRef,
            verseSource: verseSrc,
            verseEnglish: english,
            noteText: reflection,
            date: date,
            spokenWithKrishna: false,
            goalContext: nil
        )
    }
}

// MARK: - API types

private struct AppleAuthResponse: Decodable {
    let userId: String
    let isNewUser: Bool
    let sessionToken: String
}

