import SwiftUI

struct ChapterListView: View {
    @EnvironmentObject var store: ScriptureStore

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(store.chapterInfos) { chapter in
                    NavigationLink(destination: ChapterVerseListView(chapter: chapter.chapterNumber)) {
                        ChapterRow(chapter: chapter, store: store)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(DharmaSpacing.md)
            .padding(.bottom, DharmaSpacing.xl)
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Bhagavad Gita")
        .navigationBarTitleDisplayMode(.large)
        .dharmaBackground()
    }
}

struct ChapterRow: View {
    let chapter: GitaChapterInfo
    @ObservedObject var store: ScriptureStore

    private var readCount: Int {
        store.readCountForChapter(chapter.chapterNumber)
    }

    private var progress: Double {
        chapter.versesCount > 0 ? Double(readCount) / Double(chapter.versesCount) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text("\(chapter.chapterNumber)")
                    .font(.system(size: 28, weight: .medium, design: .serif))
                    .foregroundColor(.dharmaGold)
                    .frame(width: 40, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text(chapter.nameTranslation)
                        .font(DharmaFont.heading(16))
                        .foregroundColor(.dharmaTextPrimary)

                    Text(chapter.nameMeaning)
                        .font(DharmaFont.caption(12))
                        .foregroundColor(.dharmaGold)
                        .italic()
                }

                Spacer()

                Text("\(chapter.versesCount) verses")
                    .font(DharmaFont.caption(11))
                    .foregroundColor(.dharmaTextMuted)
            }

            Text(chapter.chapterSummary.components(separatedBy: ".").prefix(2).joined(separator: ".") + ".")
                .font(DharmaFont.body(13))
                .foregroundColor(.dharmaTextSecondary)
                .lineLimit(3)
                .lineSpacing(3)

            if readCount > 0 {
                HStack(spacing: 8) {
                    ProgressView(value: progress)
                        .tint(.dharmaGold)

                    Text("\(readCount)/\(chapter.versesCount)")
                        .font(DharmaFont.caption(10))
                        .foregroundColor(.dharmaTextMuted)
                }
            }
        }
        .padding(DharmaSpacing.md)
        .background(Color.dharmaSurface)
        .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DharmaRadius.md)
                .strokeBorder(Color.dharmaCardBorder, lineWidth: 1)
        )
    }
}

struct ChapterVerseListView: View {
    let chapter: Int
    @EnvironmentObject var store: ScriptureStore

    private var chapterInfo: GitaChapterInfo? {
        store.chapterInfos.first { $0.chapterNumber == chapter }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DharmaSpacing.lg) {
                if let info = chapterInfo {
                    VStack(alignment: .leading, spacing: DharmaSpacing.sm) {
                        Text("Chapter \(info.chapterNumber) · \(info.nameMeaning)")
                            .font(DharmaFont.caption(12))
                            .foregroundColor(.dharmaGold)
                            .italic()

                        Text(info.chapterSummary)
                            .font(DharmaFont.body(14))
                            .foregroundColor(.dharmaTextSecondary)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(DharmaSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.dharmaSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: DharmaRadius.md)
                            .strokeBorder(Color.dharmaCardBorder, lineWidth: 1)
                    )
                }

                ForEach(store.versesForChapter(chapter)) { item in
                    NavigationLink(destination: ScriptureDetailView(item: item, store: store)) {
                        ScriptureCardView(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(DharmaSpacing.md)
            .padding(.bottom, DharmaSpacing.xl)
        }
        .scrollContentBackground(.hidden)
        .navigationTitle(chapterInfo?.nameTranslation ?? "Chapter \(chapter)")
        .navigationBarTitleDisplayMode(.large)
        .dharmaBackground()
    }
}
