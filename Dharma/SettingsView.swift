import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

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

    var body: some View {
        ZStack {
            Color.clear
                .dharmaBackground()

            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(spacing: DharmaSpacing.lg) {
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
        .onAppear {
            krishnaService.refreshMessageUsageFromPersistence()
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
