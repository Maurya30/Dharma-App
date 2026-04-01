import Foundation
import SwiftUI

/// Builds `AttributedString` with tappable links for scripture citations that exist in `ScriptureStore`
/// (Bhagavad Gita, Upanishads, Rig Veda).
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
        let matches = findAllResolvableMatches(in: plain, items: items)
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

    private static func normalizeReferenceKey(_ s: String) -> String {
        let collapsed = s.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return collapsed.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// `Ch. 1 · Verse 1` or `Ch. 1.1 · Verse 1.1.1`
    private static func parseUpanishadSubtitle(_ subtitle: String) -> (chapter: String, verse: String)? {
        let pattern = #"Ch\.\s*(.+?)\s*·\s*Verse\s*(.+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let r = regex.firstMatch(in: subtitle, options: [], range: NSRange(subtitle.startIndex..., in: subtitle)),
              let chR = Range(r.range(at: 1), in: subtitle),
              let vR = Range(r.range(at: 2), in: subtitle)
        else { return nil }
        let ch = String(subtitle[chR]).trimmingCharacters(in: .whitespacesAndNewlines)
        let v = String(subtitle[vR]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ch.isEmpty, !v.isEmpty else { return nil }
        return (ch, v)
    }

    /// Map normalized keys → item (later keys overwrite if duplicate; same verse only).
    private static func buildUpanishadLookup(from items: [ScriptureItem]) -> [String: ScriptureItem] {
        var map: [String: ScriptureItem] = [:]
        for item in items where item.category == .upanishads {
            guard let (ch, v) = parseUpanishadSubtitle(item.subtitle) else { continue }
            map[normalizeReferenceKey("\(item.source) \(v)")] = item
            if !v.contains(".") {
                map[normalizeReferenceKey("\(item.source) \(ch).\(v)")] = item
            }
        }
        return map
    }

    private static func uniqueUpanishadSources(from items: [ScriptureItem]) -> [String] {
        let names = Set(items.filter { $0.category == .upanishads }.map(\.source))
        return names.sorted { $0.count > $1.count }
    }

    private static func findGitaMatches(in text: String, items: [ScriptureItem], occupied: inout [Range<String.Index>]) -> [Match] {
        var result: [Match] = []
        let patterns = [
            #"(?i)Bhagavad\s+Gita\s+(\d+)\.(\d+)"#,
            #"(?i)\bGita\s+(\d+)\.(\d+)\b"#
        ]
        for pattern in patterns {
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

    private static func findRigVedaMatches(in text: String, items: [ScriptureItem], occupied: inout [Range<String.Index>]) -> [Match] {
        var result: [Match] = []
        let pattern = #"(?i)\bRig\s+Veda\s+(\d+(?:\.\d+)*)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return result }
        let nsText = text as NSString
        let full = NSRange(location: 0, length: nsText.length)
        regex.enumerateMatches(in: text, options: [], range: full) { match, _, _ in
            guard let match, match.numberOfRanges >= 2 else { return }
            let fullRange = match.range(at: 0)
            guard let swiftFull = Range(fullRange, in: text) else { return }
            if occupied.contains(where: { $0.overlaps(swiftFull) }) { return }
            let ref = nsText.substring(with: match.range(at: 1))
            let source = "Rig Veda \(ref)"
            guard let item = items.first(where: { $0.source == source }) else { return }
            result.append(Match(range: swiftFull, item: item))
            occupied.append(swiftFull)
        }
        return result
    }

    private static func findUpanishadMatches(in text: String, lookup: [String: ScriptureItem], sources: [String], occupied: inout [Range<String.Index>]) -> [Match] {
        var result: [Match] = []
        guard !sources.isEmpty else { return result }
        let alternation = sources.map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|")
        let pattern = "(?i)(\(alternation))\\s*[,\\.:\\s;\\-–—]*\\s*(\\d+(?:\\.\\d+)*)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return result }
        let nsText = text as NSString
        let full = NSRange(location: 0, length: nsText.length)
        regex.enumerateMatches(in: text, options: [], range: full) { match, _, _ in
            guard let match, match.numberOfRanges >= 3 else { return }
            let fullRange = match.range(at: 0)
            guard let swiftFull = Range(fullRange, in: text) else { return }
            if occupied.contains(where: { $0.overlaps(swiftFull) }) { return }
            let name = nsText.substring(with: match.range(at: 1))
            let nums = nsText.substring(with: match.range(at: 2))
            let key = normalizeReferenceKey("\(name) \(nums)")
            guard let item = lookup[key] else { return }
            result.append(Match(range: swiftFull, item: item))
            occupied.append(swiftFull)
        }
        return result
    }

    /// Prefer longer spans when citations overlap (e.g. nested wording).
    private static func resolveOverlaps(in text: String, matches: [Match]) -> [Match] {
        let sorted = matches.sorted {
            let len0 = text.distance(from: $0.range.lowerBound, to: $0.range.upperBound)
            let len1 = text.distance(from: $1.range.lowerBound, to: $1.range.upperBound)
            if len0 != len1 { return len0 > len1 }
            return $0.range.lowerBound < $1.range.lowerBound
        }
        var kept: [Match] = []
        for m in sorted {
            if kept.contains(where: { $0.range.overlaps(m.range) }) { continue }
            kept.append(m)
        }
        return kept.sorted { $0.range.lowerBound < $1.range.lowerBound }
    }

    private static func findAllResolvableMatches(in text: String, items: [ScriptureItem]) -> [Match] {
        var occupied: [Range<String.Index>] = []
        var all: [Match] = []
        all.append(contentsOf: findGitaMatches(in: text, items: items, occupied: &occupied))
        all.append(contentsOf: findRigVedaMatches(in: text, items: items, occupied: &occupied))
        let upLookup = buildUpanishadLookup(from: items)
        let upSources = uniqueUpanishadSources(from: items)
        all.append(contentsOf: findUpanishadMatches(in: text, lookup: upLookup, sources: upSources, occupied: &occupied))
        return resolveOverlaps(in: text, matches: all)
    }
}
