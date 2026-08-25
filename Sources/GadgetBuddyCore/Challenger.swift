import Foundation

public enum ChallengerIssue: Equatable, Sendable {
    case invalidBPM(Int)
    case invalidConfidence(Double)
    case missingFieldNotDeclared(String)
}

public struct Challenger: Sendable {
    public init() {}

    public func validate(_ command: SongCommand) -> [ChallengerIssue] {
        var issues: [ChallengerIssue] = []
        if let bpm = command.bpm, !(40...240).contains(bpm) {
            issues.append(.invalidBPM(bpm))
        }
        if !(0...1).contains(command.confidence) {
            issues.append(.invalidConfidence(command.confidence))
        }

        let fieldMap: [(String, Bool)] = [
            ("intent", command.intent == nil),
            ("genre", command.genre == nil),
            ("bpm", command.bpm == nil),
            ("key", command.key == nil)
        ]
        for (field, isMissing) in fieldMap where isMissing && !command.missingFields.contains(field) {
            issues.append(.missingFieldNotDeclared(field))
        }
        return issues
    }
}
