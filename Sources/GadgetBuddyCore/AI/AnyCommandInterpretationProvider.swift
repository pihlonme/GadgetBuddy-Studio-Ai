import Foundation

public struct AnyCommandInterpretationProvider: CommandInterpretationProviding, Sendable {
    private let operation: @Sendable (String) async throws -> SongCommand

    public init<Provider: CommandInterpretationProviding>(_ provider: Provider) {
        self.operation = { input in
            try await provider.interpret(input)
        }
    }

    public init(operation: @escaping @Sendable (String) async throws -> SongCommand) {
        self.operation = operation
    }

    public func interpret(_ input: String) async throws -> SongCommand {
        try await operation(input)
    }
}
