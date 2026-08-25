import Foundation
import Testing
@testable import GadgetBuddyCore

@Test func sandboxScenarioRoundTripsThroughJSON() throws {
    let scenario = SandboxScenario(
        id: "normal.techno.145.missing-key",
        name: "Techno prompt",
        profile: .fast,
        input: "Create techno at 145 BPM",
        expected: SandboxExpectation(
            intent: "create_song",
            genre: "techno",
            bpm: 145,
            key: nil,
            requiredMissingFields: ["key"],
            expectedToPass: true
        )
    )
    let data = try JSONEncoder().encode(scenario)
    #expect(try JSONDecoder().decode(SandboxScenario.self, from: data) == scenario)
}

@Test func challengerIssueRoundTripsThroughJSON() throws {
    let issue = ChallengerIssue.invalidBPM(500)
    let data = try JSONEncoder().encode(issue)
    #expect(try JSONDecoder().decode(ChallengerIssue.self, from: data) == issue)
}

@Test func sandboxReportRoundTripsThroughJSON() throws {
    let scenario = SandboxScenario(
        id: "contract.report",
        name: "Report contract",
        profile: .fast,
        input: "Create techno at 145 BPM",
        expected: SandboxExpectation(intent: "create_song", genre: "techno", bpm: 145, requiredMissingFields: ["key"])
    )
    let report = VirtualSandbox().run(scenario)
    let data = try JSONEncoder().encode(report)
    #expect(try JSONDecoder().decode(SandboxReport.self, from: data) == report)
}

@Test func interpreterAlwaysReturnsBoundedConfidence() {
    for input in ["", "Make something dark", "Create techno at 145 BPM in A minor"] {
        #expect((0.0...1.0).contains(CommandInterpreter().interpret(input).confidence))
    }
}
