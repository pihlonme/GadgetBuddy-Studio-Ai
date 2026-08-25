import Testing
@testable import GadgetBuddyCore

@Test func redTeamAdversarialFixturesMatchExpectedBehavior() throws {
    let scenarios = try FixtureLoader.load("adversarial-prompts")
    #expect(VirtualSandbox().run(scenarios).allSatisfy { $0.passed })
}

@Test func redTeamMixedLanguageUnicodePromptRemainsStructured() {
    let scenario = SandboxScenario(
        id: "redteam.mixed-language-unicode",
        name: "Mixed Swedish English Unicode",
        profile: .challenge,
        input: "Skapa techno ca 145 bpm i A minor 🚨🎛️",
        expected: SandboxExpectation(intent: "create_song", genre: "techno", bpm: 145, key: "a minor")
    )
    let report = VirtualSandbox().run(scenario)
    #expect(report.passed)
    #expect(report.challengerIssues.isEmpty)
}

@Test func redTeamConflictingTemposDoNotCrashOrInventKey() {
    let command = CommandInterpreter().interpret("Create techno at 145 BPM and 150 BPM")
    #expect(command.bpm == 145)
    #expect(command.key == nil)
    #expect(command.missingFields.contains("key"))
    #expect(Challenger().validate(command).isEmpty)
}
