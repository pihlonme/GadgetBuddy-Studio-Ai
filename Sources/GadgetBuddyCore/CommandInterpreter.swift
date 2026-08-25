import Foundation

public struct CommandInterpreter: Sendable {
    public init() {}

    public func interpret(_ input: String) -> SongCommand {
        let normalized = input.lowercased()

        let intent = inferIntent(from: normalized)
        let genre = inferGenre(from: normalized)
        let bpm = inferBPM(from: normalized)
        let key = inferKey(from: normalized)
        let mood = inferMood(from: normalized)
        let structure = inferStructure(from: normalized)
        let references = inferReferences(from: input)

        var missing: [String] = []
        if intent == nil { missing.append("intent") }
        if genre == nil { missing.append("genre") }
        if bpm == nil { missing.append("bpm") }
        if key == nil { missing.append("key") }

        let totalCoreFields = 4.0
        let knownCoreFields = totalCoreFields - Double(missing.count)
        let confidence = max(0.0, min(1.0, knownCoreFields / totalCoreFields))

        return SongCommand(
            intent: intent,
            genre: genre,
            bpm: bpm,
            key: key,
            mood: mood,
            structure: structure,
            references: references,
            confidence: confidence,
            missingFields: missing
        )
    }

    private func inferIntent(from text: String) -> String? {
        let createWords = ["create", "make", "build", "skapa", "gör", "gora", "new song", "ny låt", "ny lat"]
        return createWords.contains(where: text.contains) ? "create_song" : nil
    }

    private func inferGenre(from text: String) -> String? {
        let genres = ["techno", "house", "trance", "drum and bass", "dnb", "ambient", "electro", "breakbeat"]
        return genres.first(where: text.contains)
    }

    private func inferBPM(from text: String) -> Int? {
        let patterns = [#"\b(\d{2,3})\s*bpm\b"#, #"\baround\s+(\d{2,3})\b"#, #"\bca\.?\s*(\d{2,3})\b"#]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text),
               let value = Int(text[range]),
               (40...240).contains(value) {
                return value
            }
        }
        return nil
    }

    private func inferKey(from text: String) -> String? {
        let pattern = #"\b([a-g](?:#|b)?\s*(?:major|minor|maj|min))\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[range])
    }

    private func inferMood(from text: String) -> [String] {
        let vocabulary = ["dark", "aggressive", "warehouse", "uplifting", "melodic", "hypnotic", "raw", "industrial", "euphoric"]
        return vocabulary.filter(text.contains)
    }

    private func inferStructure(from text: String) -> SongStructure? {
        let mentionsBreak = text.contains("break")
        let mentionsDrop = text.contains("drop") || text.contains("explode")
        let mentionsBuild = text.contains("build") || text.contains("bygga")
        guard mentionsBreak || mentionsDrop || mentionsBuild else { return nil }
        return SongStructure(
            intro: mentionsBuild ? "slow_build" : nil,
            breakPresent: mentionsBreak ? true : nil,
            drop: mentionsDrop ? "high_energy" : nil
        )
    }

    private func inferReferences(from original: String) -> [String] {
        guard let range = original.range(of: "reference", options: .caseInsensitive) else { return [] }
        let suffix = original[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        return suffix.isEmpty ? [] : [suffix]
    }
}
