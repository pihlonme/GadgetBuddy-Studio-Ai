import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol OpenAIResponsesTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public struct URLSessionOpenAIResponsesTransport: OpenAIResponsesTransport, Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAICommandInterpreterError.invalidResponse
        }
        return (data, httpResponse)
    }
}
