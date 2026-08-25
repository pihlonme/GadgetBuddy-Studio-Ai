import Testing
@testable import GadgetBuddyCore

@Test func chaosCorpusNeverCrashesAndNeverInventsAKey() {
    let corpus = [
        "",
        "   ",
        "🎛️🎚️🔥",
        String(repeating: "techno ", count: 1500),
        "Create techno at 999999 BPM",
        "gör något helt obegripligt 🫠",
        String(repeating: "145 ", count: 1000)
    ]

    for input in corpus {
        let command = CommandInterpreter().interpret(input)
        #expect(command.key == nil)
        #expect((0.0...1.0).contains(command.confidence))
        #expect(Challenger().validate(command).isEmpty)
    }
}

@Test func chaosWhitespaceOnlyInputDeclaresEveryCoreFieldMissing() {
    let command = CommandInterpreter().interpret(" \n\t ")
    #expect(command.missingFields == ["intent", "genre", "bpm", "key"])
}
