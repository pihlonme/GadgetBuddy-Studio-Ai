import Combine
import Foundation
import GadgetBuddyCore

public enum SongCommandProviderMode: String, CaseIterable, Identifiable, Sendable {
    case deterministic = "Deterministic"
    case ai = "AI"

    public var id: String { rawValue }
}

@MainActor
public final class SongCommandScreenModel: ObservableObject {
    @Published public var prompt: String
    @Published public var providerMode: SongCommandProviderMode
    @Published public private(set) var report: SandboxReport?
    @Published public private(set) var isRunning = false
    @Published public private(set) var errorMessage: String?

    private let deterministicProvider: AnyCommandInterpretationProvider
    private let aiProvider: AnyCommandInterpretationProvider?

    public init(
        prompt: String = "Create dark aggressive warehouse techno around 145 BPM, build slowly and explode after the break.",
        deterministicProvider: AnyCommandInterpretationProvider = AnyCommandInterpretationProvider(DeterministicCommandInterpretationProvider()),
        aiProvider: AnyCommandInterpretationProvider? = nil
    ) {
        self.prompt = prompt
        self.providerMode = .deterministic
        self.deterministicProvider = deterministicProvider
        self.aiProvider = aiProvider
    }

    public var availableModes: [SongCommandProviderMode] {
        aiProvider == nil ? [.deterministic] : [.deterministic, .ai]
    }

    public var aiAvailable: Bool { aiProvider != nil }

    public var statusText: String {
        guard let report else { return "Ready" }
        guard report.passed else { return "Blocked by Challenger" }
        return report.interpretedCommand.missingFields.isEmpty ? "Ready for next module" : "Needs input"
    }

    public func interpret() async {
        let input = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else {
            report = nil
            errorMessage = "Enter a music instruction before interpreting."
            return
        }

        guard let provider = selectedProvider else {
            report = nil
            errorMessage = "AI provider is not configured in this host."
            providerMode = .deterministic
            return
        }

        isRunning = true
        errorMessage = nil
        defer { isRunning = false }

        do {
            report = try await LiveInterpretationSession(provider: provider).run(input)
        } catch {
            report = nil
            errorMessage = "Interpretation failed: \(String(describing: error))"
        }
    }

    private var selectedProvider: AnyCommandInterpretationProvider? {
        switch providerMode {
        case .deterministic:
            return deterministicProvider
        case .ai:
            return aiProvider
        }
    }
}
