import Foundation

public struct SandboxTraceEvent: Codable, Equatable, Sendable {
    public let stage: String
    public let message: String

    public init(stage: String, message: String) {
        self.stage = stage
        self.message = message
    }
}

public struct SandboxReport: Codable, Equatable, Sendable {
    public let scenarioID: String
    public let input: String
    public let interpretedCommand: SongCommand
    public let challengerIssues: [ChallengerIssue]
    public let warnings: [String]
    public let trace: [SandboxTraceEvent]
    public let passed: Bool

    public init(
        scenarioID: String,
        input: String,
        interpretedCommand: SongCommand,
        challengerIssues: [ChallengerIssue],
        warnings: [String],
        trace: [SandboxTraceEvent],
        passed: Bool
    ) {
        self.scenarioID = scenarioID
        self.input = input
        self.interpretedCommand = interpretedCommand
        self.challengerIssues = challengerIssues
        self.warnings = warnings
        self.trace = trace
        self.passed = passed
    }
}
