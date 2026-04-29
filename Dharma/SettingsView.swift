import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var auth = AuthManager.shared
    @EnvironmentObject private var onboarding: OnboardingManager

    @State private var showSignInSheet = false
    @State private var showSignOutConfirm = false
    @State private var showDeleteAccountConfirm = false
    @State private var showRedoOnboardingConfirm = false

    @AppStorage("userDarkMode") private var userDarkMode = false

    @ObservedObject private var krishnaService = KrishnaService.shared

    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "—"
    }

    private var messagesAtLimit: Bool {
        krishnaService.messagesSentToday >= KrishnaService.dailyMessageLimit
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
        .alert("Redo Onboarding", isPresented: $showRedoOnboardingConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Restart", role: .destructive) {
                onboarding.hasCompletedOnboarding = false
                dismiss()
            }
        } message: {
            Text("This will restart the onboarding flow. Your data will not be deleted.")
        }
        .alert("Delete Account", isPresented: $showDeleteAccountConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await auth.deleteAccount()
                    dismiss()
                }
            }
        } message: {
            Text("This will permanently delete your account, journals, goals, and all practice data. This cannot be undone.")
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("ACCOUNT")
            VStack(spacing: 0) {
                if auth.isSignedIn && !auth.isGuest {
                    VStack(alignment: .leading, spacing: DharmaSpacing.xs) {
                        Text(accountDisplayName)
                            .font(DharmaFont.heading(20))
                            .foregroundColor(.dharmaTextPrimary)
                        Text(auth.currentUser?.email ?? "Hidden email")
                            .font(DharmaFont.body(16))
                            .foregroundColor(.dharmaTextSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DharmaSpacing.lg)
                    .padding(.vertical, DharmaSpacing.md)

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
                                .font(DharmaFont.body(16))
                                .foregroundColor(.dharmaTextPrimary)
                            Spacer()
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 18))
                                .foregroundColor(.dharmaGold)
                        }
                        .padding(.horizontal, DharmaSpacing.lg)
                        .frame(minHeight: 60)
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
                                .font(DharmaFont.body(16))
                                .foregroundColor(.dharmaTextPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, DharmaSpacing.lg)
                        .frame(minHeight: 60)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Rectangle()
                        .fill(Color.dharmaDivider)
                        .frame(height: 1)

                    Button {
                        showDeleteAccountConfirm = true
                    } label: {
                        HStack {
                            Text("Delete Account")
                                .font(DharmaFont.body(16))
                                .foregroundColor(Color.red.opacity(0.8))
                            Spacer()
                        }
                        .padding(.horizontal, DharmaSpacing.lg)
                        .frame(minHeight: 60)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("Your progress isn't backed up")
                        .font(DharmaFont.body(16))
                        .foregroundColor(Color(hex: "C9821E"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, DharmaSpacing.lg)
                        .padding(.vertical, DharmaSpacing.md)

                    Rectangle()
                        .fill(Color.dharmaDivider)
                        .frame(height: 1)

                    Button {
                        showSignInSheet = true
                    } label: {
                        HStack {
                            Text("Sign in to save your progress")
                                .font(DharmaFont.body(16))
                                .foregroundColor(.dharmaTextPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.dharmaTextSecondary)
                        }
                        .padding(.horizontal, DharmaSpacing.lg)
                        .frame(minHeight: 60)
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
                .font(DharmaFont.title(40))
                .foregroundColor(.dharmaTextPrimary)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30, weight: .regular))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.dharmaGold)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, DharmaSpacing.lg)
        .padding(.top, DharmaSpacing.lg)
        .padding(.bottom, DharmaSpacing.md)
    }

    // MARK: - Section 1 — Appearance

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("APPEARANCE")
            VStack(spacing: 0) {
                HStack {
                    Text("Theme")
                        .font(DharmaFont.body(16))
                        .foregroundColor(.dharmaTextPrimary)
                    Spacer()
                    Picker("", selection: $userDarkMode) {
                        Text("Light").tag(false)
                        Text("Dark").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .tint(Color.dharmaGold)
                }
                .padding(.horizontal, DharmaSpacing.lg)
                .frame(minHeight: 60)
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
                        .font(DharmaFont.body(16))
                        .foregroundColor(.dharmaTextPrimary)
                    Spacer()
                    Text("\(krishnaService.messagesSentToday) of \(KrishnaService.dailyMessageLimit)")
                        .font(DharmaFont.body(16))
                        .foregroundColor(messagesAtLimit ? Color.dharmaTextSecondary : Color.dharmaGold)
                }
                .padding(.horizontal, DharmaSpacing.lg)
                .frame(minHeight: 60)
            }
            .glassCard(cornerRadius: DharmaRadius.md)
        }
    }

    // MARK: - Section 4 — Your Journey

    private var journeySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("YOUR JOURNEY")
            VStack(spacing: 0) {
                chevronRow(title: "Redo onboarding") {
                    showRedoOnboardingConfirm = true
                }
            }
            .glassCard(cornerRadius: DharmaRadius.md)
        }
    }

    private func chevronRow(title: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            HStack {
                Text(title)
                    .font(DharmaFont.body(16))
                    .foregroundColor(.dharmaTextPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.dharmaTextSecondary)
            }
            .padding(.horizontal, DharmaSpacing.lg)
            .frame(minHeight: 60)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section 5 — About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("ABOUT")
            VStack(spacing: 0) {
                chevronRow(title: "Privacy policy") {
                    if let url = URL(string: "https://maurya30.github.io/dharma-legal/privacy.html") {
                        UIApplication.shared.open(url)
                    }
                }

                Rectangle()
                    .fill(Color.dharmaDivider)
                    .frame(height: 1)

                chevronRow(title: "Terms of service") {
                    if let url = URL(string: "https://maurya30.github.io/dharma-legal/terms.html") {
                        UIApplication.shared.open(url)
                    }
                }

                Rectangle()
                    .fill(Color.dharmaDivider)
                    .frame(height: 1)

                chevronRow(title: "Rate Dharma") {
                    if let url = URL(string: "itms-apps://itunes.apple.com/app/id6761423523?action=write-review") {
                        UIApplication.shared.open(url)
                    }
                }

                Rectangle()
                    .fill(Color.dharmaDivider)
                    .frame(height: 1)

                chevronRow(title: "Send feedback") {
                    if let url = URL(string: "https://maurya30.github.io/dharma-legal/") {
                        UIApplication.shared.open(url)
                    }
                }

                Rectangle()
                    .fill(Color.dharmaDivider)
                    .frame(height: 1)

                HStack {
                    Text("Version")
                        .font(DharmaFont.body(16))
                        .foregroundColor(.dharmaTextPrimary)
                    Spacer()
                    Text(appVersion)
                        .font(DharmaFont.caption())
                        .foregroundColor(.dharmaTextSecondary)
                }
                .padding(.horizontal, DharmaSpacing.lg)
                .frame(minHeight: 60)
            }
            .glassCard(cornerRadius: DharmaRadius.md)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.dharmaGold)
            .tracking(1.4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, DharmaSpacing.sm)
    }
}

#Preview {
    SettingsView()
}
