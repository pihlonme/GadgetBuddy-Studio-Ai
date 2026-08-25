import Foundation

public struct AsyncVirtualSandbox<Provider: CommandInterpretationProviding>: Sendable {
    private let provider: Provider
    private let challenger: Challenger

    public init(provider: Provider, challenger: Challenger = Challenger()) {
        self.provider = provider
        self.challenger = challenger
    }

    public func run(_ scenario: SandboxScenario) async throws -> SandboxReport {
        var trace: [SandboxTraceEvent] = [
            SandboxTraceEvent(stage: "input", message: "Accepted scenario \(scenario.id)")
        ]

        let command = try await provider.interpret(scenario.input)
        trace.append(SandboxTraceEvent(stage: "interpreter", message: "Produced SongCommand"))

        let issues = challenger.validate(command)
        trace.append(SandboxTraceEvent(stage: "challenger", message: issues.isEmpty ? "No issues" : "Detected \(issues.count) issue(s)"))

        let warnings = expectationWarnings(command: command, expected: scenario.expected)
        let requiredMissingFieldsPresent = scenario.expected.requiredMissingFields.allSatisfy(command.missingFields.contains)
        let observedValid = issues.isEmpty && warnings.isEmpty && requiredMissingFieldsPresent
        let passed = scenario.expected.expectedToPass ? observedValid : !observedValid

        trace.append(SandboxTraceEvent(stage: "result", message: passed ? "Scenario matched expectation" : "Scenario did not match expectation"))

        return SandboxReport(
            scenarioID: scenario.id,
            input: scenario.input,
            interpretedCommand: command,
            challengerIssues: issues,
            warnings: warnings,
            trace: trace,
            passed: passed
        )
    }

    public func run(_ scenarios: [SandboxScenario]) async throws -> [SandboxReport] {
        var reports: [SandboxReport] = []
        reports.reserveCapacity(scenarios.count)
        for scenario in scenarios {
            reports.append(try await run(scenario))
        }
        return reports
    }

    private func expectationWarnings(command: SongCommand, expected: SandboxExpectation) -> [String] {
        var warnings: [String] = []
        compare("intent", actual: command.intent, expected: expected.intent, requiredMissingFields: expected.requiredMissingFields, warnings: &warnings)
        compare("genre", actual: command.genre, expected: expected.genre, requiredMissingFields: expected.requiredMissingFields, warnings: &warnings)
        compare("bpm", actual: command.bpm, expected: expected.bpm, requiredMissingFields: expected.requiredMissingFields, warnings: &warnings)
        compare("key", actual: command.key, expected: expected.key, requiredMissingFields: expected.requiredMissingFields, warnings: &warnings)
        for field in expected.requiredMissingFields where !command.missingFields.contains(field) {
            warnings.append("missingFields does not declare \(field)")
        }
        return warnings
    }

    private func compare<T: Equatable>(
        _ field: String,
        actual: T?,
        expected: T?,
        requiredMissingFields: [String],
        warnings: inout [String]
    ) {
        if let expected {
            if actual != expected {
                warnings.append("\(field) expected \(String(describing: expected)) but observed \(String(describing: actual))")
            }
        } else if requiredMissingFields.contains(field), actual != nil {
            warnings.append("\(field) expected to be missing but observed \(String(describing: actual))")
        }
    }
}
