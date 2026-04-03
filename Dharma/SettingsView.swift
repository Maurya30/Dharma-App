import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var auth = AuthManager.shared

    @State private var showSignInSheet = false
    @State private var showSignOutConfirm = false

    @AppStorage("userDarkMode") private var userDarkMode = false
    @AppStorage("dharma_notify_daily_verse") private var notifyDailyVerse = true
    @AppStorage("dharma_notify_streak") private var notifyStreak = true
    @AppStorage("dharma_notify_festival") private var notifyFestival = true

    @ObservedObject private var krishnaService = KrishnaService.shared

    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "—"
    }

    private var messagesAtLimit: Bool {
        krishnaService.messagesSentToday >= KrishnaService.dailyMessageLimit
    }

    private var premiumButtonLabelColor: Color {
        colorScheme == .dark ? Color.dharmaTextPrimary : Color.dharmaBackground
    }

    private var accountDisplayName: String {
        let n = auth.currentUser?.fullName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return n.isEmpty ? "Apple User" : n
    }

    var body: some View {
        ZStack {
            Color.clear
                .dharmaBackground()

            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(spacing: DharmaSpacing.lg) {
                        accountSection
                        appearanceSection
                        krishnaSection
                        notificationsSection
                        journeySection
                        aboutSection
                    }
                    .padding(DharmaSpacing.lg)
                }
            }
        }
        // Keep in sync with the theme picker: fullScreenCover does not always inherit
        // root `preferredColorScheme` updates immediately, so the sheet can look stuck until dismiss.
        .preferredColorScheme(userDarkMode ? .dark : .light)
        .onAppear {
            krishnaService.refreshMessageUsageFromPersistence()
        }
        .sheet(isPresented: $showSignInSheet) {
            SignInView(onFinished: { showSignInSheet = false })
        }
        .alert("Sign out?", isPresented: $showSignOutConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Sign out", role: .destructive) {
                auth.signOut()
            }
        } message: {
            Text("Your local data stays on this device until you sign in again.")
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("ACCOUNT")
            VStack(spacing: 0) {
                if auth.isSignedIn && !auth.isGuest {
                    VStack(alignment: .leading, spacing: DharmaSpacing.xs) {
                        Text(accountDisplayName)
                            .font(DharmaFont.heading(16))
                            .foregroundColor(.dharmaTextPrimary)
                        Text(auth.currentUser?.email ?? "Hidden email")
                            .font(DharmaFont.body(14))
                            .foregroundColor(.dharmaTextSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DharmaSpacing.md)
                    .padding(.vertical, DharmaSpacing.sm)

                    Rectangle()
                        .fill(Color.dharmaDivider)
                        .frame(height: 1)

                    Button {
                        Task {
                            await auth.syncToCloud()
                        }
                    } label: {
                        HStack {
                            Text("Sync now")
                                .font(DharmaFont.body())
                                .foregroundColor(.dharmaTextPrimary)
                            Spacer()
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.dharmaGold)
                        }
                        .padding(.horizontal, DharmaSpacing.md)
                        .frame(minHeight: 52)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Rectangle()
                        .fill(Color.dharmaDivider)
                        .frame(height: 1)

                    Button {
                        showSignOutConfirm = true
                    } label: {
                        HStack {
                            Text("Sign out")
                                .font(DharmaFont.body())
                                .foregroundColor(.dharmaTextPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, DharmaSpacing.md)
                        .frame(minHeight: 52)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("Your progress isn't backed up")
                        .font(DharmaFont.body())
                        .foregroundColor(Color(hex: "C9821E"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, DharmaSpacing.md)
                        .padding(.vertical, DharmaSpacing.sm)

                    Rectangle()
                        .fill(Color.dharmaDivider)
                        .frame(height: 1)

                    Button {
                        showSignInSheet = true
                    } label: {
                        HStack {
                            Text("Sign in to save your progress")
                                .font(DharmaFont.body())
                                .foregroundColor(.dharmaTextPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(DharmaFont.body(14))
                                .foregroundColor(.dharmaTextSecondary)
                        }
                        .padding(.horizontal, DharmaSpacing.md)
                        .frame(minHeight: 52)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .glassCard(cornerRadius: DharmaRadius.md)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Settings")
                .font(DharmaFont.title(34))
                .foregroundColor(.dharmaTextPrimary)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.dharmaGold)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, DharmaSpacing.lg)
        .padding(.top, DharmaSpacing.md)
        .padding(.bottom, DharmaSpacing.sm)
    }

    // MARK: - Section 1 — Appearance

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("APPEARANCE")
            VStack(spacing: 0) {
                HStack {
                    Text("Theme")
                        .font(DharmaFont.body())
                        .foregroundColor(.dharmaTextPrimary)
                    Spacer()
                    Picker("", selection: $userDarkMode) {
                        Text("Light").tag(false)
                        Text("Dark").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .tint(Color.dharmaGold)
                }
                .padding(.horizontal, DharmaSpacing.md)
                .frame(minHeight: 52)
            }
            .glassCard(cornerRadius: DharmaRadius.md)
        }
    }

    // MARK: - Section 2 — Krishna AI

    private var krishnaSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("KRISHNA AI")
            VStack(spacing: 0) {
                HStack {
                    Text("Messages today")
                        .font(DharmaFont.body())
                        .foregroundColor(.dharmaTextPrimary)
                    Spacer()
                    Text("\(krishnaService.messagesSentToday) of \(KrishnaService.dailyMessageLimit)")
                        .font(DharmaFont.body())
                        .foregroundColor(messagesAtLimit ? Color.dharmaTextSecondary : Color.dharmaGold)
                }
                .padding(.horizontal, DharmaSpacing.md)
                .frame(minHeight: 52)

                Rectangle()
                    .fill(Color.dharmaDivider)
                    .frame(height: 1)

                Button {
                    // Placeholder — premium upgrade
                } label: {
                    Text("Upgrade to Premium")
                        .font(DharmaFont.heading(16))
                        .foregroundColor(premiumButtonLabelColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DharmaSpacing.sm)
                        .background(Color.dharmaGold)
                        .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.md, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, DharmaSpacing.md)
                .padding(.vertical, DharmaSpacing.sm)
                .frame(minHeight: 52)
            }
            .glassCard(cornerRadius: DharmaRadius.md)
        }
    }

    // MARK: - Section 3 — Notifications

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("NOTIFICATIONS")
            VStack(spacing: 0) {
                toggleRow(title: "Daily verse reminder", binding: $notifyDailyVerse)

                Rectangle()
                    .fill(Color.dharmaDivider)
                    .frame(height: 1)

                toggleRow(title: "Streak reminder", binding: $notifyStreak)

                Rectangle()
                    .fill(Color.dharmaDivider)
                    .frame(height: 1)

                toggleRow(title: "Festival alerts", binding: $notifyFestival)
            }
            .glassCard(cornerRadius: DharmaRadius.md)
        }
    }

    private func toggleRow(title: String, binding: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(DharmaFont.body())
                .foregroundColor(.dharmaTextPrimary)
            Spacer()
            Toggle("", isOn: binding)
                .labelsHidden()
                .tint(Color.dharmaGold)
        }
        .padding(.horizontal, DharmaSpacing.md)
        .frame(minHeight: 52)
    }

    // MARK: - Section 4 — Your Journey

    private var journeySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("YOUR JOURNEY")
            VStack(spacing: 0) {
                chevronRow(title: "Manage goals")

                Rectangle()
                    .fill(Color.dharmaDivider)
                    .frame(height: 1)

                chevronRow(title: "Export journal")

                Rectangle()
                    .fill(Color.dharmaDivider)
                    .frame(height: 1)

                chevronRow(title: "Redo onboarding")
            }
            .glassCard(cornerRadius: DharmaRadius.md)
        }
    }

    private func chevronRow(title: String) -> some View {
        Button {
            // Placeholder
        } label: {
            HStack {
                Text(title)
                    .font(DharmaFont.body())
                    .foregroundColor(.dharmaTextPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(DharmaFont.body(14))
                    .foregroundColor(.dharmaTextSecondary)
            }
            .padding(.horizontal, DharmaSpacing.md)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section 5 — About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("ABOUT")
            VStack(spacing: 0) {
                chevronRow(title: "Privacy policy")

                Rectangle()
                    .fill(Color.dharmaDivider)
                    .frame(height: 1)

                chevronRow(title: "Terms of service")

                Rectangle()
                    .fill(Color.dharmaDivider)
                    .frame(height: 1)

                chevronRow(title: "Rate Dharma")

                Rectangle()
                    .fill(Color.dharmaDivider)
                    .frame(height: 1)

                chevronRow(title: "Send feedback")

                Rectangle()
                    .fill(Color.dharmaDivider)
                    .frame(height: 1)

                HStack {
                    Text("Version")
                        .font(DharmaFont.body())
                        .foregroundColor(.dharmaTextPrimary)
                    Spacer()
                    Text(appVersion)
                        .font(DharmaFont.caption())
                        .foregroundColor(.dharmaTextSecondary)
                }
                .padding(.horizontal, DharmaSpacing.md)
                .frame(minHeight: 52)

                Rectangle()
                    .fill(Color.dharmaDivider)
                    .frame(height: 1)

                HStack {
                    Text("Device Token")
                        .font(DharmaFont.body())
                        .foregroundColor(.dharmaTextPrimary)
                    Spacer()
                    Text(UserDefaults.standard.string(forKey: "apnsDeviceToken") ?? "Not registered")
                        .font(DharmaFont.caption())
                        .foregroundColor(.dharmaTextSecondary)
                }
                .padding(.horizontal, DharmaSpacing.md)
                .frame(minHeight: 52)
            }
            .glassCard(cornerRadius: DharmaRadius.md)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(DharmaFont.caption())
            .foregroundColor(.dharmaGold)
            .tracking(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, DharmaSpacing.xs)
    }
}

#Preview {
    SettingsView()
}
