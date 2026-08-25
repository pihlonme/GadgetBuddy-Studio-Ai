import Testing
@testable import GadgetBuddyCore

@Test func fixtureSetsLoadAndRegressionScenariosPass() throws {
    #expect(try !FixtureLoader.load("normal-prompts").isEmpty)
    #expect(try !FixtureLoader.load("adversarial-prompts").isEmpty)
    let regression = try FixtureLoader.load("regression-prompts")
    #expect(!regression.isEmpty)
    #expect(VirtualSandbox().run(regression).allSatisfy { $0.passed })
}

@Test func normalFixtureCorpusPassesInSandbox() throws {
    let scenarios = try FixtureLoader.load("normal-prompts")
    #expect(VirtualSandbox().run(scenarios).allSatisfy { $0.passed })
}
