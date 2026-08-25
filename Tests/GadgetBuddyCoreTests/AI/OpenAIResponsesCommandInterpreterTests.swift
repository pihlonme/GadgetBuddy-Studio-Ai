import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
@testable import GadgetBuddyCore

private actor RecordingTransport: OpenAIResponsesTransport {
    private(set) var capturedRequest: URLRequest?
    let responseData: Data
    let statusCode: Int

    init(responseData: Data, statusCode: Int = 200) {
        self.responseData = responseData
        self.statusCode = statusCode
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        capturedRequest = request
        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        return (responseData, response)
    }
}

private func completedResponse(outputText: String) throws -> Data {
    try JSONSerialization.data(withJSONObject: [
        "status": "completed",
        "output": [[
            "type": "message",
            "content": [["type": "output_text", "text": outputText]]
        ]]
    ])
}

@Test func openAIProviderBuildsResponsesStructuredOutputRequest() async throws {
    let output = #"{"intent":"create_song","genre":"techno","bpm":145,"key":"a minor","mood":["dark"],"structure":null,"references":[],"missingFields":[]}"#
    let transport = RecordingTransport(responseData: try completedResponse(outputText: output))
    let config = try OpenAICommandInterpreterConfiguration(apiKey: "test-secret")
    let provider = OpenAIResponsesCommandInterpreter(configuration: config, transport: transport)

    _ = try await provider.interpret("Create dark techno at 145 BPM in A minor")

    let request = try #require(await transport.capturedRequest)
    #expect(request.httpMethod == "POST")
    #expect(request.url?.absoluteString == "https://api.openai.com/v1/responses")
    #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-secret")
    #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

    let body = try #require(request.httpBody)
    let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
    #expect(json["model"] as? String == "gpt-5.6-luna")
    let text = try #require(json["text"] as? [String: Any])
    let format = try #require(text["format"] as? [String: Any])
    #expect(format["type"] as? String == "json_schema")
    #expect(format["name"] as? String == "song_command_extraction")
    #expect(format["strict"] as? Bool == true)
    let schema = try #require(format["schema"] as? [String: Any])
    #expect(schema["additionalProperties"] as? Bool == false)
}

@Test func openAIProviderDecodesOutputAndRecomputesContractFields() async throws {
    let output = #"{"intent":"create_song","genre":"techno","bpm":145,"key":null,"mood":["dark"],"structure":null,"references":[],"missingFields":[]}"#
    let transport = RecordingTransport(responseData: try completedResponse(outputText: output))
    let provider = OpenAIResponsesCommandInterpreter(
        configuration: try OpenAICommandInterpreterConfiguration(apiKey: "test-secret"),
        transport: transport
    )

    let command = try await provider.interpret("Create dark techno at 145 BPM")
    #expect(command.intent == "create_song")
    #expect(command.genre == "techno")
    #expect(command.bpm == 145)
    #expect(command.key == nil)
    #expect(command.missingFields == ["key"])
    #expect(command.confidence == 0.75)
}

@Test func openAIProviderRejectsHTTPFailure() async throws {
    let transport = RecordingTransport(responseData: Data(#"{"error":{"message":"bad request"}}"#.utf8), statusCode: 400)
    let provider = OpenAIResponsesCommandInterpreter(
        configuration: try OpenAICommandInterpreterConfiguration(apiKey: "test-secret"),
        transport: transport
    )

    do {
        _ = try await provider.interpret("Create techno")
        Issue.record("Expected HTTP error")
    } catch let error as OpenAICommandInterpreterError {
        #expect(error == .httpStatus(400, "bad request"))
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}

@Test func openAIProviderSurfacesRefusal() async throws {
    let refusal = try JSONSerialization.data(withJSONObject: [
        "status": "completed",
        "output": [["type": "message", "content": [["type": "refusal", "refusal": "Cannot comply"]]]]
    ])
    let transport = RecordingTransport(responseData: refusal)
    let provider = OpenAIResponsesCommandInterpreter(
        configuration: try OpenAICommandInterpreterConfiguration(apiKey: "test-secret"),
        transport: transport
    )

    do {
        _ = try await provider.interpret("Create techno")
        Issue.record("Expected refusal")
    } catch let error as OpenAICommandInterpreterError {
        #expect(error == .refusal("Cannot comply"))
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}

@Test func openAIConfigurationRejectsBlankAPIKey() {
    #expect(throws: OpenAICommandInterpreterError.invalidAPIKey) {
        _ = try OpenAICommandInterpreterConfiguration(apiKey: "   ")
    }
}

@Test func openAIProviderIgnoresNonMessageOutputItems() async throws {
    let output = #"{"intent":"create_song","genre":"techno","bpm":145,"key":null,"mood":[],"structure":null,"references":[],"missingFields":["key"]}"#
    let data = try JSONSerialization.data(withJSONObject: [
        "status": "completed",
        "output": [
            ["type": "reasoning", "id": "rs_123"],
            ["type": "message", "content": [["type": "output_text", "text": output]]]
        ]
    ])
    let transport = RecordingTransport(responseData: data)
    let provider = OpenAIResponsesCommandInterpreter(
        configuration: try OpenAICommandInterpreterConfiguration(apiKey: "test-secret"),
        transport: transport
    )

    let command = try await provider.interpret("Create techno at 145 BPM")
    #expect(command.genre == "techno")
    #expect(command.missingFields == ["key"])
}
