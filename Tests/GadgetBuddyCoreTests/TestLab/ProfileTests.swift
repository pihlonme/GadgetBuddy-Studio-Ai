import Testing
@testable import GadgetBuddyCore

private func allFixtureScenarios() throws -> [SandboxScenario] {
    try FixtureLoader.load("normal-prompts")
        + FixtureLoader.load("adversarial-prompts")
        + FixtureLoader.load("regression-prompts")
}

@Test func fastProfileIncludesOnlyFastScenarios() throws {
    #expect(SandboxProfile.fast.includes(.fast))
    #expect(!SandboxProfile.fast.includes(.challenge))
    #expect(!SandboxProfile.fast.includes(.fullLab))

    let selected = try allFixtureScenarios().filter { SandboxProfile.fast.includes($0.profile) }
    #expect(!selected.isEmpty)
    #expect(selected.allSatisfy { $0.profile == .fast })
    #expect(VirtualSandbox().run(selected).allSatisfy { $0.passed })
}

@Test func challengeProfileIncludesFastAndChallengeScenarios() throws {
    #expect(SandboxProfile.challenge.includes(.fast))
    #expect(SandboxProfile.challenge.includes(.challenge))
    #expect(!SandboxProfile.challenge.includes(.fullLab))

    let selected = try allFixtureScenarios().filter { SandboxProfile.challenge.includes($0.profile) }
    #expect(selected.contains(where: { $0.profile == .fast }))
    #expect(selected.contains(where: { $0.profile == .challenge }))
    #expect(VirtualSandbox().run(selected).allSatisfy { $0.passed })
}

@Test func fullLabProfileIncludesEveryScenarioProfile() throws {
    for profile in SandboxProfile.allCases {
        #expect(SandboxProfile.fullLab.includes(profile))
    }

    let selected = try allFixtureScenarios().filter { SandboxProfile.fullLab.includes($0.profile) }
    let all = try allFixtureScenarios()
    #expect(selected.count == all.count)
    #expect(VirtualSandbox().run(selected).allSatisfy { $0.passed })
}
