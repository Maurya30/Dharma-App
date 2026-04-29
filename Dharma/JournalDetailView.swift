import SwiftUI

struct JournalDetailView: View {
    let entry: JournalEntry
    var onDismiss: () -> Void

    @EnvironmentObject private var notificationNav: NotificationNavigationState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DharmaSpacing.lg) {
                    if entry.source == "sadhana" || entry.source == "goalPath" {
                        HStack {
                            JournalEntrySourceTag(entry: entry)
                            Spacer()
                        }
                    }

                    if !entry.verseEnglish.isEmpty {
                        VStack(alignment: .leading, spacing: DharmaSpacing.md) {
                            Text("Today's verse")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.dharmaGold)
                                .textCase(.uppercase)
                                .tracking(1.4)

                            VerseBody(
                                translation: entry.verseEnglish,
                                source: entry.verseReference
                            )
                        }
                        .saffronLeftBar()
                    }

                    if !entry.verseEnglish.isEmpty {
                        Divider()
                            .background(Color.dharmaGold.opacity(0.3))
                    }

                    Text("Your reflection")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.dharmaGold)
                        .textCase(.uppercase)
                        .tracking(1.4)

                    Text(entry.noteText)
                        .font(.system(size: 17, design: .serif))
                        .foregroundColor(.dharmaTextPrimary)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)

                    if !entry.krishnaResponse.isEmpty {
                        Divider()
                            .background(Color.dharmaGold.opacity(0.3))
                        HStack(alignment: .top, spacing: 10) {
                            Text("✦")
                                .font(.system(size: 16))
                                .foregroundColor(.dharmaGold)
                            Text(entry.krishnaResponse)
                                .font(.system(size: 17, design: .serif))
                                .italic()
                                .foregroundColor(.dharmaTextPrimary)
                                .lineSpacing(5)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if entry.source != "manual", !entry.sourceLabel.isEmpty {
                        Text("from \(entry.sourceLabel)")
                            .font(DharmaFont.caption(14))
                            .foregroundColor(.dharmaTextMuted)
                            .padding(.top, DharmaSpacing.sm)
                    }

                    if entry.source == "goalPath", let gid = entry.goalContext, !gid.isEmpty {
                        Button {
                            onDismiss()
                            notificationNav.selectedTab = 2
                            notificationNav.pendingGoalIdForPathMap = gid
                        } label: {
                            Text("View goal path →")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.dharmaGold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.dharmaGold.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, DharmaSpacing.sm)
                    }
                }
                .padding(DharmaSpacing.lg)
                .padding(.bottom, DharmaSpacing.xl)
            }
            .scrollContentBackground(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.dharmaGold)
                    }
                }
            }
            .transparentNavigationBar()
            .dharmaBackground()
        }
    }
}
