import Testing
@testable import GadgetBuddyCore

private func command(
    intent: String? = "create_song",
    genre: String? = "techno",
    bpm: Int? = 145,
    key: String? = "a minor",
    confidence: Double = 1.0,
    missingFields: [String] = []
) -> SongCommand {
    SongCommand(
        intent: intent,
        genre: genre,
        bpm: bpm,
        key: key,
        mood: [],
        structure: nil,
        references: [],
        confidence: confidence,
        missingFields: missingFields
    )
}

@Test func challengerRejectsOutOfRangeBPM() {
    #expect(Challenger().validate(command(bpm: 500)).contains(.invalidBPM(500)))
}

@Test func challengerRejectsOutOfRangeConfidence() {
    #expect(Challenger().validate(command(confidence: 1.2)).contains(.invalidConfidence(1.2)))
}

@Test func challengerRequiresMissingFieldDeclarations() {
    #expect(Challenger().validate(command(genre: nil)).contains(.missingFieldNotDeclared("genre")))
}

@Test func challengerAcceptsDeclaredMissingFields() {
    #expect(Challenger().validate(command(genre: nil, missingFields: ["genre"])).isEmpty)
}
