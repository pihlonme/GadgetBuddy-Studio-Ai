import Testing
@testable import GadgetBuddyCore

@Test func sandboxRunsPositiveScenarioWithDeterministicTrace() {
    let scenario = SandboxScenario(
        id: "integration.techno",
        name: "Integration techno",
        profile: .fast,
        input: "Create techno at 145 BPM in A minor",
        expected: SandboxExpectation(intent: "create_song", genre: "techno", bpm: 145, key: "a minor", expectedToPass: true)
    )
    let report = VirtualSandbox().run(scenario)
    #expect(report.passed)
    #expect(report.warnings.isEmpty)
    #expect(report.challengerIssues.isEmpty)
    #expect(report.trace.map(\.stage) == ["input", "interpreter", "challenger", "result"])
}

@Test func sandboxFailsPositiveScenarioWhenExpectationMismatches() {
    let scenario = SandboxScenario(
        id: "integration.mismatch",
        name: "Expected mismatch",
        profile: .fast,
        input: "Create techno at 145 BPM",
        expected: SandboxExpectation(intent: "create_song", genre: "techno", bpm: 150, requiredMissingFields: ["key"], expectedToPass: true)
    )
    let report = VirtualSandbox().run(scenario)
    #expect(!report.passed)
    #expect(report.warnings.contains(where: { $0.contains("bpm") }))
}

@Test func sandboxRecognizesExpectedNegativeScenario() {
    let scenario = SandboxScenario(
        id: "integration.expected-negative",
        name: "Expected invalid expectation",
        profile: .challenge,
        input: "Create techno at 145 BPM",
        expected: SandboxExpectation(intent: "create_song", genre: "techno", bpm: 999, requiredMissingFields: ["key"], expectedToPass: false)
    )
    let report = VirtualSandbox().run(scenario)
    #expect(report.passed)
    #expect(report.warnings.contains(where: { $0.contains("bpm") }))
}

@Test func sandboxRunsScenarioBatchInInputOrder() {
    let scenarios = [
        SandboxScenario(id: "one", name: "One", profile: .fast, input: "Create techno at 145 BPM", expected: SandboxExpectation(intent: "create_song", genre: "techno", bpm: 145, requiredMissingFields: ["key"])),
        SandboxScenario(id: "two", name: "Two", profile: .fast, input: "Make something dark", expected: SandboxExpectation(intent: "create_song", requiredMissingFields: ["genre", "bpm", "key"]))
    ]
    let reports = VirtualSandbox().run(scenarios)
    #expect(reports.map(\.scenarioID) == ["one", "two"])
    #expect(reports.allSatisfy { $0.passed })
}
