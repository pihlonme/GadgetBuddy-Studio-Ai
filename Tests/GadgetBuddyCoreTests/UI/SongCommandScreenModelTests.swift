import Testing
@testable import GadgetBuddyCore
@testable import GadgetBuddyUI

private func completeCommand() -> SongCommand {
    SongCommand(
        intent: "create_song",
        genre: "techno",
        bpm: 145,
        key: "a minor",
        mood: ["dark"],
        structure: SongStructure(intro: "slow_build", breakPresent: true, drop: "high_energy"),
        references: [],
        confidence: 1.0,
        missingFields: []
    )
}

@Test func liveSessionProducesChallengerReport() async throws {
    let provider = AnyCommandInterpretationProvider { _ in completeCommand() }
    let report = try await LiveInterpretationSession(provider: provider).run("Create dark techno")

    #expect(report.passed)
    #expect(report.interpretedCommand.bpm == 145)
    #expect(report.challengerIssues.isEmpty)
    #expect(report.trace.map(\.stage) == ["input", "provider", "challenger", "result"])
}

@Test @MainActor func songCommandScreenModelRunsProvider() async {
    let provider = AnyCommandInterpretationProvider { _ in completeCommand() }
    let model = SongCommandScreenModel(prompt: "Create techno", deterministicProvider: provider)

    await model.interpret()

    #expect(model.errorMessage == nil)
    #expect(model.report?.passed == true)
    #expect(model.statusText == "Ready for next module")
}

@Test @MainActor func songCommandScreenModelRejectsEmptyPrompt() async {
    let model = SongCommandScreenModel(prompt: "   ")

    await model.interpret()

    #expect(model.report == nil)
    #expect(model.errorMessage == "Enter a music instruction before interpreting.")
}
