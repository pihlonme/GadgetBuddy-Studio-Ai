import Foundation

public struct SandboxExpectation: Codable, Equatable, Sendable {
    public let intent: String?
    public let genre: String?
    public let bpm: Int?
    public let key: String?
    public let requiredMissingFields: [String]
    public let expectedToPass: Bool

    public init(
        intent: String? = nil,
        genre: String? = nil,
        bpm: Int? = nil,
        key: String? = nil,
        requiredMissingFields: [String] = [],
        expectedToPass: Bool = true
    ) {
        self.intent = intent
        self.genre = genre
        self.bpm = bpm
        self.key = key
        self.requiredMissingFields = requiredMissingFields
        self.expectedToPass = expectedToPass
    }
}

public struct SandboxScenario: Codable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let profile: SandboxProfile
    public let input: String
    public let expected: SandboxExpectation

    public init(id: String, name: String, profile: SandboxProfile, input: String, expected: SandboxExpectation) {
        self.id = id
        self.name = name
        self.profile = profile
        self.input = input
        self.expected = expected
    }
}
