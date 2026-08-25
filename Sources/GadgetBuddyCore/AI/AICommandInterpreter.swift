import Foundation

public enum AICommandInterpreterError: Error, Equatable, Sendable {
    case validationFailed([ChallengerIssue])
}

public struct AICommandInterpreter<Provider: CommandInterpretationProviding>: Sendable {
    private let provider: Provider
    private let challenger: Challenger

    public init(provider: Provider, challenger: Challenger = Challenger()) {
        self.provider = provider
        self.challenger = challenger
    }

    public func interpret(_ input: String) async throws -> SongCommand {
        let command = try await provider.interpret(input)
        let issues = challenger.validate(command)
        guard issues.isEmpty else {
            throw AICommandInterpreterError.validationFailed(issues)
        }
        return command
    }
}
