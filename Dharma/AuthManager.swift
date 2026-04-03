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

    private static let sessionTokenKey = "auth_session_token"
    private static let userIdKey = "auth_user_id"
    private static let isGuestKey = "auth_is_guest"
    private static let fullNameKey = "auth_full_name"
    private static let emailKey = "auth_email"

    private var didRestoreThisLaunch = false

    private init() {
        let guest = UserDefaults.standard.bool(forKey: Self.isGuestKey)
        let token = UserDefaults.standard.string(forKey: Self.sessionTokenKey) ?? ""
        let uid = UserDefaults.standard.string(forKey: Self.userIdKey) ?? ""
        let name = UserDefaults.standard.string(forKey: Self.fullNameKey)
        let email = UserDefaults.standard.string(forKey: Self.emailKey)

        isGuest = guest
        isSignedIn = !guest && !token.isEmpty && !uid.isEmpty
        if isSignedIn {
            currentUser = DharmaUser(userId: uid, fullName: name, email: email)
        } else {
            currentUser = nil
        }
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
            print("Sign in with Apple failed: \(error)")
        }
    }

    func continueAsGuest() {
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
        UserDefaults.standard.removeObject(forKey: Self.sessionTokenKey)
        UserDefaults.standard.removeObject(forKey: Self.userIdKey)
        UserDefaults.standard.removeObject(forKey: Self.fullNameKey)
        UserDefaults.standard.removeObject(forKey: Self.emailKey)
        UserDefaults.standard.set(true, forKey: Self.isGuestKey)

        isSignedIn = false
        isGuest = true
        currentUser = nil
    }

    func syncToCloud() async {
        guard isSignedIn, !isGuest, let auth = getAuthHeader() else { return }

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
                "sadhanaTotalActs": SadhanaManager.shared.totalActsCompleted
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
        } catch {
            print("Cloud sync failed: \(error)")
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
            print("Restore from cloud failed: \(error)")
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

