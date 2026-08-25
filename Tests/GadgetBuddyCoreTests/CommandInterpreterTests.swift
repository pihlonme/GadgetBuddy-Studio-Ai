import Testing
@testable import GadgetBuddyCore

@Test func parsesTechnoPromptAndMarksMissingKey() {
    let command = CommandInterpreter().interpret(
        "Create dark aggressive warehouse techno around 145 BPM, build slowly and explode after the break."
    )

    #expect(command.intent == "create_song")
    #expect(command.genre == "techno")
    #expect(command.bpm == 145)
    #expect(command.key == nil)
    #expect(command.mood.contains("dark"))
    #expect(command.mood.contains("aggressive"))
    #expect(command.mood.contains("warehouse"))
    #expect(command.structure?.breakPresent == true)
    #expect(command.structure?.drop == "high_energy")
    #expect(command.missingFields == ["key"])
    #expect(command.confidence == 0.75)
}

@Test func neverInventsMissingMusicalFacts() {
    let command = CommandInterpreter().interpret("Make something dark")
    #expect(command.genre == nil)
    #expect(command.bpm == nil)
    #expect(command.key == nil)
    #expect(command.missingFields.contains("genre"))
    #expect(command.missingFields.contains("bpm"))
    #expect(command.missingFields.contains("key"))
}

@Test func challengerAcceptsInterpreterOutput() {
    let command = CommandInterpreter().interpret("Create techno at 145 BPM in A minor")
    #expect(Challenger().validate(command).isEmpty)
}
