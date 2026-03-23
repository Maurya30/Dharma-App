import Foundation
import SwiftUI

/// Builds `AttributedString` with tappable links for Bhagavad Gita citations that exist in `ScriptureStore`.
enum VerseReferenceLinker {
    static let urlScheme = "dharma-verse"

    /// `dharma-verse://open?id=<uuid>`
    static func url(for item: ScriptureItem) -> URL? {
        URL(string: "\(urlScheme)://open?id=\(item.id.uuidString)")
    }

    /// Parse `dharma-verse://open?id=` and return the UUID if valid.
    static func verseId(from url: URL) -> UUID? {
        guard url.scheme == urlScheme, url.host == "open" else { return nil }
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        guard let value = items?.first(where: { $0.name == "id" })?.value else { return nil }
        return UUID(uuidString: value)
    }

    /// Plain text for display when streaming or when attribution fails.
    static func attributedString(from plain: String, items: [ScriptureItem]) -> AttributedString {
        let matches = findResolvableGitaMatches(in: plain, items: items)
        guard !matches.isEmpty else {
            return AttributedString(plain)
        }

        var output = AttributedString()
        var current = plain.startIndex

        for match in matches.sorted(by: { $0.range.lowerBound < $1.range.lowerBound }) {
            let range = match.range
            let item = match.item
            if current < range.lowerBound {
                output += AttributedString(String(plain[current..<range.lowerBound]))
            }
            var segment = AttributedString(String(plain[range]))
            if let url = url(for: item) {
                segment.link = url
            }
            output += segment
            current = range.upperBound
        }

        if current < plain.endIndex {
            output += AttributedString(String(plain[current...]))
        }

        return output
    }

    // MARK: - Matching

    private struct Match {
        let range: Range<String.Index>
        let item: ScriptureItem
    }

    /// High confidence: "Bhagavad Gita 2.47". Secondary: "Gita 2.47" word-bounded.
    private static let patterns: [(String, Bool)] = [
        (#"(?i)Bhagavad\s+Gita\s+(\d+)\.(\d+)"#, true),
        (#"(?i)\bGita\s+(\d+)\.(\d+)\b"#, false),
    ]

    private static func findResolvableGitaMatches(in text: String, items: [ScriptureItem]) -> [Match] {
        var result: [Match] = []
        var occupied: [Range<String.Index>] = []

        for (pattern, _) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { continue }
            let nsText = text as NSString
            let full = NSRange(location: 0, length: nsText.length)

            regex.enumerateMatches(in: text, options: [], range: full) { match, _, _ in
                guard let match, match.numberOfRanges >= 3 else { return }
                let fullRange = match.range(at: 0)
                guard let swiftFull = Range(fullRange, in: text) else { return }
                if occupied.contains(where: { $0.overlaps(swiftFull) }) { return }

                let ch = nsText.substring(with: match.range(at: 1))
                let v = nsText.substring(with: match.range(at: 2))
                let source = "Bhagavad Gita \(ch).\(v)"
                guard let item = items.first(where: { $0.source == source }) else { return }

                result.append(Match(range: swiftFull, item: item))
                occupied.append(swiftFull)
            }
        }

        return result
    }
}
