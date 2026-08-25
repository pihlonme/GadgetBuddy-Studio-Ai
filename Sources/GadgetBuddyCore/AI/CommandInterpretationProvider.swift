import Foundation

public protocol CommandInterpretationProviding: Sendable {
    func interpret(_ input: String) async throws -> SongCommand
}

public struct DeterministicCommandInterpretationProvider: CommandInterpretationProviding, Sendable {
    private let interpreter: CommandInterpreter

    public init(interpreter: CommandInterpreter = CommandInterpreter()) {
        self.interpreter = interpreter
    }

    public func interpret(_ input: String) async throws -> SongCommand {
        interpreter.interpret(input)
    }
}
