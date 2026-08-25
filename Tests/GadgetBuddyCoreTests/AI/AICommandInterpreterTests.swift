import Foundation
import Testing
@testable import GadgetBuddyCore

private struct StubProvider: CommandInterpretationProviding {
    let command: SongCommand
    func interpret(_ input: String) async throws -> SongCommand { command }
}

@Test func aiInterpreterAcceptsValidProviderOutput() async throws {
    let command = SongCommand(intent: "create_song", genre: "techno", bpm: 145, key: "a minor", mood: ["dark"], structure: nil, references: [], confidence: 1, missingFields: [])
    let result = try await AICommandInterpreter(provider: StubProvider(command: command)).interpret("make dark techno")
    #expect(result == command)
}

@Test func aiInterpreterRejectsProviderOutputThatViolatesContract() async {
    let invalid = SongCommand(intent: "create_song", genre: nil, bpm: 145, key: nil, mood: [], structure: nil, references: [], confidence: 0.5, missingFields: [])
    do {
        _ = try await AICommandInterpreter(provider: StubProvider(command: invalid)).interpret("make techno")
        Issue.record("Expected validation failure")
    } catch let error as AICommandInterpreterError {
        #expect(error == .validationFailed([.missingFieldNotDeclared("genre"), .missingFieldNotDeclared("key")]))
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}
