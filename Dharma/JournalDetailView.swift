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
                        Text("Today's verse")
                            .font(DharmaFont.caption(10))
                            .foregroundColor(.dharmaGold)
                            .textCase(.uppercase)
                            .tracking(0.6)

                        Text(entry.verseEnglish)
                            .font(.system(size: 14, design: .serif))
                            .foregroundColor(.dharmaTextPrimary)
                            .lineSpacing(5)

                        Text(entry.verseReference)
                            .font(.system(size: 11, design: .serif))
                            .foregroundColor(.dharmaGold)
                            .italic()
                    }

                    if !entry.verseEnglish.isEmpty {
                        Divider()
                            .background(Color.dharmaGold.opacity(0.3))
                    }

                    Text("Your reflection")
                        .font(DharmaFont.caption(10))
                        .foregroundColor(.dharmaGold)
                        .textCase(.uppercase)
                        .tracking(0.6)

                    Text(entry.noteText)
                        .font(.system(size: 14, design: .serif))
                        .foregroundColor(.dharmaTextPrimary)
                        .lineSpacing(5)

                    if !entry.krishnaResponse.isEmpty {
                        Divider()
                            .background(Color.dharmaGold.opacity(0.3))
                        HStack(alignment: .top, spacing: 6) {
                            Text("✦")
                                .font(.system(size: 12))
                                .foregroundColor(.dharmaGold)
                            Text(entry.krishnaResponse)
                                .font(.system(size: 13, design: .serif))
                                .italic()
                                .foregroundColor(.dharmaTextPrimary)
                                .lineSpacing(4)
                        }
                    }

                    if entry.source != "manual", !entry.sourceLabel.isEmpty {
                        Text("from \(entry.sourceLabel)")
                            .font(DharmaFont.caption(12))
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
                                .font(DharmaFont.heading(15))
                                .foregroundColor(.dharmaGold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, DharmaSpacing.sm)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, DharmaSpacing.sm)
                    }
                }
                .padding(DharmaSpacing.md)
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
                            .font(.system(size: 22))
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
