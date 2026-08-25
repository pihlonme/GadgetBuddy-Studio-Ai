# GadgetBuddy Test Lab / Virtual Sandbox v0.1 Design

**Date:** 2026-08-25  
**Status:** Design approved in chat; written specification pending final user review  
**Repository:** `pihlonme/GadgetBuddy-Studio-Ai`

## 1. Goal

Create a permanent, deterministic test layer for GadgetBuddy Studio AI so every change can be exercised in an isolated virtual environment before it reaches downstream modules or `main`.

The v0.1 sandbox validates the existing vertical slice:

`text / transcript -> CommandInterpreter -> SongCommand -> Challenger -> SandboxReport`

It must be fast enough for every pull request, deterministic enough for regression testing, and extensible enough to host Song Spec Generator, Gadget Planner, MIDI Generator, and Controller Mapper later without replacing the sandbox API.

## 2. Scope

### Included in v0.1

- In-process Swift sandbox with no network, file-system, MIDI, audio, or KORG Gadget side effects.
- Scenario model for named, reproducible test cases.
- Structured sandbox report containing input, interpreted command, Challenger issues, warnings, trace events, and pass/fail status.
- Three execution profiles: `fast`, `challenge`, and `fullLab`.
- Six logical QA groups represented by focused automated test suites.
- Deterministic regression fixtures stored in the repository.
- CI gates that run sandbox tests on pull requests.
- Existing Foundation v0.1 tests remain valid and green.

### Explicitly not included in v0.1

- Calling an external AI provider.
- Launching KORG Gadget 3.
- Sending real MIDI.
- Creating audio files.
- Docker, virtual machines, or a separate helper process.
- Performance/load benchmarking beyond keeping the suite suitable for normal PR CI.

## 3. Architecture Decision

Use an **in-process Swift-native sandbox** inside `GadgetBuddyCore`.

This is preferred for v0.1 because the current product core is a Swift Package, the active modules are pure deterministic logic, and the primary requirement is rapid feedback during development. Process/container isolation would add complexity without isolating any real external side effects yet.

Isolation is enforced by architecture: the sandbox accepts pure inputs and invokes only injected/testable components. Future adapters that touch AI, MIDI, files, or Gadget must sit behind protocols before they are permitted inside Test Lab.

## 4. Core Types

### `SandboxProfile`

```swift
public enum SandboxProfile: String, Codable, Sendable {
    case fast
    case challenge
    case fullLab
}
```

- `fast`: contract, normal-path, and regression smoke scenarios.
- `challenge`: fast scenarios plus adversarial/edge-case scenarios.
- `fullLab`: all v0.1 scenarios. In v0.1 it still ends after Challenger because downstream production modules do not exist yet.

### `SandboxScenario`

```swift
public struct SandboxScenario: Codable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let profile: SandboxProfile
    public let input: String
    public let expected: SandboxExpectation
}
```

Scenario IDs are stable human-readable identifiers such as `normal.techno.145.missing-key` and must not depend on array order.

### `SandboxExpectation`

```swift
public struct SandboxExpectation: Codable, Equatable, Sendable {
    public let intent: String?
    public let genre: String?
    public let bpm: Int?
    public let key: String?
    public let requiredMissingFields: [String]
    public let expectedToPass: Bool
}
```

Expectations intentionally cover contract-critical values, not every incidental field. This keeps regression fixtures stable while allowing non-contract enrichment to evolve.

### `SandboxTraceEvent`

```swift
public struct SandboxTraceEvent: Codable, Equatable, Sendable {
    public let stage: String
    public let message: String
}
```

Required v0.1 stages are `input`, `interpreter`, `challenger`, and `result`.

### `SandboxReport`

```swift
public struct SandboxReport: Codable, Equatable, Sendable {
    public let scenarioID: String
    public let input: String
    public let interpretedCommand: SongCommand
    public let challengerIssues: [ChallengerIssue]
    public let warnings: [String]
    public let trace: [SandboxTraceEvent]
    public let passed: Bool
}
```

`passed` is true only when:

1. Challenger returns no issues.
2. All contract-critical expectations match.
3. Required missing fields are declared.
4. `expectedToPass` agrees with the observed result.

To make reports Codable, `ChallengerIssue` must become `Codable` while preserving its existing equality and Sendable behavior.

## 5. Sandbox Runner

`VirtualSandbox` owns one `CommandInterpreter` and one `Challenger` by default and exposes:

```swift
public func run(_ scenario: SandboxScenario) -> SandboxReport
public func run(_ scenarios: [SandboxScenario]) -> [SandboxReport]
```

The runner is deterministic: identical scenarios against identical code must produce identical reports. v0.1 contains no random behavior, clock reads, environment reads, or external calls.

The runner never mutates global state and never writes output to disk. CI and future UI layers may serialize returned reports themselves.

## 6. Test Group

The test group is represented by six independent suites with distinct failure responsibilities.

### Contract Guard

Protects the `SongCommand` contract and sandbox model serialization. It checks stable field semantics, confidence range, and missing-field declaration rules.

### Challenger

Checks invalid BPM, invalid confidence, missing-field declarations, and that valid interpreter output remains accepted.

### Red Team

Feeds incomplete, contradictory, mixed-language, Unicode-heavy, punctuation-heavy, and intentionally misleading prompts into the sandbox. Its purpose is to find incorrect assumptions, crashes, and invented facts.

### Regression Guard

Loads committed fixtures and asserts previously accepted contract-critical outputs remain unchanged. A deliberate behavior change requires an explicit fixture update in the same PR.

### Integration Tester

Runs complete v0.1 scenarios through Interpreter -> Challenger -> SandboxReport and verifies trace order plus final pass/fail semantics.

### Fuzz / Chaos Tester

Uses a fixed built-in corpus, not nondeterministic random generation, for v0.1. Cases include empty input, whitespace-only input, long input, emoji, Swedish/English mixtures, repeated tokens, extreme numeric text, and nonsensical text. The suite must never crash and must not invent unsupported musical facts.

## 7. Fixtures

Fixtures live under:

```text
Tests/Fixtures/
  normal-prompts.json
  adversarial-prompts.json
  regression-prompts.json
```

All fixture files use the `SandboxScenario` schema. They are source-controlled and reviewed like code.

Fixture policy:

- `normal-prompts.json`: representative expected usage.
- `adversarial-prompts.json`: Red Team and edge cases.
- `regression-prompts.json`: bugs or behavior that must never regress after being fixed.

No fixture may depend on network state, device state, locale, current date/time, or random seeds.

## 8. Execution Profiles

### FAST

Runs on every pull request and includes:

- existing Foundation tests;
- Contract Guard;
- Challenger tests;
- normal fixture smoke tests;
- regression fixtures.

### CHALLENGE

Runs the FAST coverage plus adversarial and chaos corpus tests.

### FULL LAB

Runs all v0.1 suites and all fixtures. Until downstream modules exist, FULL LAB terminates at `SandboxReport`. Later modules will attach through injected protocols without changing scenario IDs or report fundamentals.

## 9. CI

GitHub Actions keeps the existing `swift test` gate and adds named test-lab invocations so failures are attributable to a profile.

Required PR checks after implementation:

1. Swift package build/test succeeds.
2. FAST profile succeeds.
3. CHALLENGE profile succeeds.
4. FULL LAB succeeds.

A failing Test Lab check blocks merge by project policy. GitHub branch-protection configuration is not part of v0.1 because repository settings may require a separate administrative change; the workflow itself must expose the checks needed for protection.

## 10. Error and Failure Semantics

- A malformed fixture fails the test suite; it is never silently skipped.
- A Challenger issue is recorded in `challengerIssues` and causes the scenario to fail unless the scenario explicitly has `expectedToPass == false` and the contract expectation matches the intended negative case.
- A mismatch between expected and observed contract-critical fields creates a warning and causes failure.
- Empty/unknown prompts return structured commands with missing fields; they must not crash.
- Sandbox internal programming errors fail tests normally rather than being converted into false-positive reports.

## 11. File Structure

Planned production files:

```text
Sources/GadgetBuddyCore/TestLab/
  SandboxProfile.swift
  SandboxScenario.swift
  SandboxReport.swift
  VirtualSandbox.swift
```

Planned tests:

```text
Tests/GadgetBuddyCoreTests/TestLab/
  ContractGuardTests.swift
  ChallengerTests.swift
  RegressionTests.swift
  RedTeamTests.swift
  SandboxIntegrationTests.swift
  ChaosTests.swift
  FixtureLoader.swift
```

Fixtures:

```text
Tests/Fixtures/
  normal-prompts.json
  adversarial-prompts.json
  regression-prompts.json
```

Existing files modified:

```text
Sources/GadgetBuddyCore/Challenger.swift
Package.swift
.github/workflows/ci.yml
README.md
```

## 12. Acceptance Criteria

Test Lab / Virtual Sandbox v0.1 is complete when all of the following are true:

1. All three existing Foundation v0.1 tests still pass unchanged or with only module-path refactoring that does not alter their assertions.
2. `VirtualSandbox` can run one or many `SandboxScenario` values and return deterministic `SandboxReport` values.
3. The six QA suites exist and exercise their stated responsibilities.
4. Normal, adversarial, and regression fixture sets load successfully from source-controlled JSON.
5. Empty, malformed musical intent, mixed-language, Unicode, and extreme-number inputs do not crash the sandbox.
6. Unsupported musical facts are not invented.
7. Contract expectation mismatches fail their scenario.
8. FAST, CHALLENGE, and FULL LAB test commands are available in CI.
9. The feature PR is not merged until all GitHub Actions checks are green.

## 13. Extension Boundary

Future production modules integrate through explicit protocols/adapters. The sandbox remains the coordinator and report generator rather than absorbing module-specific business logic.

When an AI-backed interpreter is introduced, Test Lab will run both deterministic fixtures and provider-independent contract tests against an injected interpreter interface. Live provider calls, if ever used in CI, must be a separate opt-in suite and may not replace deterministic tests.
