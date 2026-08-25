import Foundation

public struct LiveInterpretationSession<Provider: CommandInterpretationProviding>: Sendable {
    private let provider: Provider
    private let challenger: Challenger

    public init(provider: Provider, challenger: Challenger = Challenger()) {
        self.provider = provider
        self.challenger = challenger
    }

    public func run(_ input: String) async throws -> SandboxReport {
        let command = try await provider.interpret(input)
        let issues = challenger.validate(command)
        let trace = [
            SandboxTraceEvent(stage: "input", message: "Accepted live prompt"),
            SandboxTraceEvent(stage: "provider", message: "Produced SongCommand"),
            SandboxTraceEvent(stage: "challenger", message: issues.isEmpty ? "Contract valid" : "Detected \(issues.count) issue(s)"),
            SandboxTraceEvent(stage: "result", message: issues.isEmpty ? "Live interpretation accepted" : "Live interpretation rejected")
        ]

        return SandboxReport(
            scenarioID: "live.interpretation",
            input: input,
            interpretedCommand: command,
            challengerIssues: issues,
            warnings: [],
            trace: trace,
            passed: issues.isEmpty
        )
    }
}
