import Foundation

public struct SongStructure: Codable, Equatable, Sendable {
    public var intro: String?
    public var breakPresent: Bool?
    public var drop: String?

    public init(intro: String? = nil, breakPresent: Bool? = nil, drop: String? = nil) {
        self.intro = intro
        self.breakPresent = breakPresent
        self.drop = drop
    }
}

public struct SongCommand: Codable, Equatable, Sendable {
    public var intent: String?
    public var genre: String?
    public var bpm: Int?
    public var key: String?
    public var mood: [String]
    public var structure: SongStructure?
    public var references: [String]
    public var confidence: Double
    public var missingFields: [String]

    public init(
        intent: String?,
        genre: String?,
        bpm: Int?,
        key: String?,
        mood: [String],
        structure: SongStructure?,
        references: [String],
        confidence: Double,
        missingFields: [String]
    ) {
        self.intent = intent
        self.genre = genre
        self.bpm = bpm
        self.key = key
        self.mood = mood
        self.structure = structure
        self.references = references
        self.confidence = confidence
        self.missingFields = missingFields
    }
}
