import Testing
@testable import GadgetBuddyCore

private struct SandboxProvider: CommandInterpretationProviding {
    let command: SongCommand
    func interpret(_ input: String) async throws -> SongCommand { command }
}

@Test func asyncSandboxRunsAIProviderThroughSameContractGate() async throws {
    let command = SongCommand(intent: "create_song", genre: "techno", bpm: 145, key: nil, mood: ["dark"], structure: nil, references: [], confidence: 0.75, missingFields: ["key"])
    let sandbox = AsyncVirtualSandbox(provider: SandboxProvider(command: command))
    let scenario = SandboxScenario(
        id: "ai.techno.missing-key",
        name: "AI provider contract",
        profile: .fast,
        input: "Create dark techno at 145 BPM",
        expected: SandboxExpectation(intent: "create_song", genre: "techno", bpm: 145, key: nil, requiredMissingFields: ["key"], expectedToPass: true)
    )

    let report = try await sandbox.run(scenario)
    #expect(report.passed)
    #expect(report.trace.map(\.stage) == ["input", "interpreter", "challenger", "result"])
    #expect(report.challengerIssues.isEmpty)
}

@Test func asyncSandboxFailsWhenAIProviderBreaksExpectedContract() async throws {
    let command = SongCommand(intent: "create_song", genre: "house", bpm: 145, key: nil, mood: [], structure: nil, references: [], confidence: 0.75, missingFields: ["key"])
    let sandbox = AsyncVirtualSandbox(provider: SandboxProvider(command: command))
    let scenario = SandboxScenario(
        id: "ai.genre-mismatch",
        name: "Genre mismatch",
        profile: .challenge,
        input: "Create techno at 145 BPM",
        expected: SandboxExpectation(intent: "create_song", genre: "techno", bpm: 145, key: nil, requiredMissingFields: ["key"], expectedToPass: true)
    )

    let report = try await sandbox.run(scenario)
    #expect(!report.passed)
    #expect(report.warnings.contains(where: { $0.contains("genre expected techno") }))
}
