import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum OpenAICommandInterpreterError: Error, Equatable, Sendable {
    case invalidAPIKey
    case requestEncodingFailed
    case httpStatus(Int, String?)
    case incomplete(String?)
    case refusal(String)
    case missingOutputText
    case invalidStructuredOutput
    case invalidResponse
}

public struct OpenAICommandInterpreterConfiguration: Sendable {
    let apiKey: String
    public let model: String
    public let endpoint: URL

    public init(
        apiKey: String,
        model: String = "gpt-5.6-luna",
        endpoint: URL = URL(string: "https://api.openai.com/v1/responses")!
    ) throws {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw OpenAICommandInterpreterError.invalidAPIKey
        }
        self.apiKey = trimmed
        self.model = model
        self.endpoint = endpoint
    }
}

public struct OpenAIResponsesCommandInterpreter<Transport: OpenAIResponsesTransport>: CommandInterpretationProviding, Sendable {
    private let configuration: OpenAICommandInterpreterConfiguration
    private let transport: Transport

    public init(configuration: OpenAICommandInterpreterConfiguration, transport: Transport) {
        self.configuration = configuration
        self.transport = transport
    }

    public func interpret(_ input: String) async throws -> SongCommand {
        let request = try makeRequest(input: input)
        let (data, response) = try await transport.data(for: request)

        guard (200..<300).contains(response.statusCode) else {
            let message = (try? JSONDecoder().decode(APIErrorEnvelope.self, from: data))?.error?.message
            throw OpenAICommandInterpreterError.httpStatus(response.statusCode, message)
        }

        let envelope: ResponseEnvelope
        do {
            envelope = try JSONDecoder().decode(ResponseEnvelope.self, from: data)
        } catch {
            throw OpenAICommandInterpreterError.invalidResponse
        }

        if envelope.status == "incomplete" || envelope.status == "failed" || envelope.status == "cancelled" {
            throw OpenAICommandInterpreterError.incomplete(envelope.incompleteDetails?.reason ?? envelope.error?.message)
        }

        if let refusal = envelope.output
            .compactMap({ $0.content })
            .flatMap({ $0 })
            .first(where: { $0.type == "refusal" })?
            .refusal {
            throw OpenAICommandInterpreterError.refusal(refusal)
        }

        guard let outputText = envelope.output
            .compactMap({ $0.content })
            .flatMap({ $0 })
            .first(where: { $0.type == "output_text" })?
            .text else {
            throw OpenAICommandInterpreterError.missingOutputText
        }

        let extracted: ExtractedSongCommand
        do {
            extracted = try JSONDecoder().decode(ExtractedSongCommand.self, from: Data(outputText.utf8))
        } catch {
            throw OpenAICommandInterpreterError.invalidStructuredOutput
        }

        let missing = Self.coreMissingFields(intent: extracted.intent, genre: extracted.genre, bpm: extracted.bpm, key: extracted.key)
        let confidence = (4.0 - Double(missing.count)) / 4.0

        return SongCommand(
            intent: extracted.intent,
            genre: extracted.genre,
            bpm: extracted.bpm,
            key: extracted.key,
            mood: extracted.mood,
            structure: extracted.structure,
            references: extracted.references,
            confidence: confidence,
            missingFields: missing
        )
    }

    private func makeRequest(input: String) throws -> URLRequest {
        var request = URLRequest(url: configuration.endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "model": configuration.model,
            "instructions": Self.instructions,
            "input": input,
            "text": ["format": [
                "type": "json_schema",
                "name": "song_command_extraction",
                "description": "Explicit musical facts extracted from the user's request without guessing missing values.",
                "strict": true,
                "schema": Self.responseSchema
            ]]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        } catch {
            throw OpenAICommandInterpreterError.requestEncodingFailed
        }
        return request
    }

    private static var instructions: String { """
    You are GadgetBuddy's Command Interpreter. Extract only musical facts explicitly stated or unambiguously specified by the user. Never invent missing facts. Supported intent is create_song; if intent is not explicit, return null. BPM must be 40...240; otherwise return null. Use null for unknown scalar values, [] for unknown lists, and null for unknown structure. missingFields may contain only intent, genre, bpm, key. Do not add facts merely because they are typical for a genre.
    """ }

    private static var responseSchema: [String: Any] { [
        "type": "object",
        "additionalProperties": false,
        "properties": [
            "intent": ["type": ["string", "null"], "enum": ["create_song", NSNull()]],
            "genre": ["type": ["string", "null"]],
            "bpm": ["type": ["integer", "null"], "minimum": 40, "maximum": 240],
            "key": ["type": ["string", "null"]],
            "mood": ["type": "array", "items": ["type": "string"]],
            "structure": ["anyOf": [[
                "type": "object",
                "additionalProperties": false,
                "properties": [
                    "intro": ["type": ["string", "null"]],
                    "breakPresent": ["type": ["boolean", "null"]],
                    "drop": ["type": ["string", "null"]]
                ],
                "required": ["intro", "breakPresent", "drop"]
            ], ["type": "null"]]],
            "references": ["type": "array", "items": ["type": "string"]],
            "missingFields": ["type": "array", "items": ["type": "string", "enum": ["intent", "genre", "bpm", "key"]]]
        ],
        "required": ["intent", "genre", "bpm", "key", "mood", "structure", "references", "missingFields"]
    ] }

    private static func coreMissingFields(intent: String?, genre: String?, bpm: Int?, key: String?) -> [String] {
        var fields: [String] = []
        if intent == nil { fields.append("intent") }
        if genre == nil { fields.append("genre") }
        if bpm == nil { fields.append("bpm") }
        if key == nil { fields.append("key") }
        return fields
    }
}

private struct ExtractedSongCommand: Decodable {
    let intent: String?
    let genre: String?
    let bpm: Int?
    let key: String?
    let mood: [String]
    let structure: SongStructure?
    let references: [String]
    let missingFields: [String]
}

private struct ResponseEnvelope: Decodable {
    let status: String?
    let output: [OutputItem]
    let error: APIError?
    let incompleteDetails: IncompleteDetails?

    enum CodingKeys: String, CodingKey {
        case status, output, error
        case incompleteDetails = "incomplete_details"
    }
}

private struct OutputItem: Decodable {
    let content: [OutputContent]?
}

private struct OutputContent: Decodable {
    let type: String
    let text: String?
    let refusal: String?
}

private struct IncompleteDetails: Decodable {
    let reason: String?
}

private struct APIErrorEnvelope: Decodable {
    let error: APIError?
}

private struct APIError: Decodable {
    let message: String?
}
