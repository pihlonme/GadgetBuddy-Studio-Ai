# GadgetBuddy Test Lab / Virtual Sandbox v0.1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a deterministic Swift-native Test Lab that runs GadgetBuddy scenarios through `CommandInterpreter -> SongCommand -> Challenger -> SandboxReport`, with six focused QA suites and FAST / CHALLENGE / FULL LAB CI checks.

**Architecture:** Add a small `TestLab` namespace inside `GadgetBuddyCore` containing scenario, expectation, trace, report, and runner types. Keep the runner side-effect-free and deterministic; fixture-driven tests and fixed chaos corpora exercise the same public API used by future modules.

**Tech Stack:** Swift Package Manager, Swift 6 language mode/tooling, Swift Testing, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-08-25-test-lab-sandbox-design.md`

## Global Constraints

- No network, file-system writes, MIDI, audio, or KORG Gadget side effects in production sandbox code.
- No random, clock, locale, or environment-dependent behavior.
- Existing Foundation v0.1 tests must remain green.
- `passed` means observed behavior matches the scenario expectation.
- Negative scenarios may pass only when the explicitly expected invalid behavior is observed.
- All future external adapters must remain behind injected/testable boundaries.

---

### Task 1: Sandbox domain contract

**Files:**
- Create: `Sources/GadgetBuddyCore/TestLab/SandboxProfile.swift`
- Create: `Sources/GadgetBuddyCore/TestLab/SandboxScenario.swift`
- Create: `Sources/GadgetBuddyCore/TestLab/SandboxReport.swift`
- Modify: `Sources/GadgetBuddyCore/Challenger.swift`
- Test: `Tests/GadgetBuddyCoreTests/TestLab/ContractGuardTests.swift`

**Interfaces:**
- Produces: `SandboxProfile`, `SandboxExpectation`, `SandboxScenario`, `SandboxTraceEvent`, `SandboxReport`.
- Produces: `ChallengerIssue: Codable` while retaining `Equatable, Sendable`.

- [ ] **Step 1: Write failing contract tests**

```swift
import Foundation
import Testing
@testable import GadgetBuddyCore

@Test func sandboxScenarioRoundTripsThroughJSON() throws {
    let scenario = SandboxScenario(
        id: "normal.techno.145.missing-key",
        name: "Techno prompt",
        profile: .fast,
        input: "Create techno at 145 BPM",
        expected: SandboxExpectation(intent: "create_song", genre: "techno", bpm: 145, key: nil, requiredMissingFields: ["key"], expectedToPass: true)
    )
    let data = try JSONEncoder().encode(scenario)
    #expect(try JSONDecoder().decode(SandboxScenario.self, from: data) == scenario)
}

@Test func challengerIssueRoundTripsThroughJSON() throws {
    let issue = ChallengerIssue.invalidBPM(500)
    let data = try JSONEncoder().encode(issue)
    #expect(try JSONDecoder().decode(ChallengerIssue.self, from: data) == issue)
}
```

- [ ] **Step 2: Run `swift test` and verify RED** — expected compile failure because Test Lab types/Codable conformance do not exist.
- [ ] **Step 3: Add the minimal domain types exactly as specified in the design and add `Codable` to `ChallengerIssue`.**
- [ ] **Step 4: Run `swift test` and verify GREEN.**
- [ ] **Step 5: Commit:** `feat: add Test Lab domain contract`

### Task 2: VirtualSandbox runner

**Files:**
- Create: `Sources/GadgetBuddyCore/TestLab/VirtualSandbox.swift`
- Test: `Tests/GadgetBuddyCoreTests/TestLab/SandboxIntegrationTests.swift`

**Interfaces:**
- Consumes: `SandboxScenario`, `SandboxReport`, `CommandInterpreter`, `Challenger`.
- Produces: `VirtualSandbox.run(_:) -> SandboxReport` and `VirtualSandbox.run(_:) -> [SandboxReport]`.

- [ ] **Step 1: Write failing integration tests** asserting trace order `["input", "interpreter", "challenger", "result"]`, matching positive scenario passes, expectation mismatch fails positive scenario, and a deliberate negative scenario passes only when observed invalidity matches expectation.
- [ ] **Step 2: Run focused integration tests and verify RED.**
- [ ] **Step 3: Implement minimal deterministic runner.** It must collect expectation mismatches as warning strings, compute `observedValid`, then `passed = expectedToPass ? observedValid : !observedValid`.
- [ ] **Step 4: Run focused tests plus full `swift test` and verify GREEN.**
- [ ] **Step 5: Commit:** `feat: add deterministic VirtualSandbox runner`

### Task 3: Fixture loader and regression corpus

**Files:**
- Create: `Tests/GadgetBuddyCoreTests/TestLab/FixtureLoader.swift`
- Create: `Tests/Fixtures/normal-prompts.json`
- Create: `Tests/Fixtures/adversarial-prompts.json`
- Create: `Tests/Fixtures/regression-prompts.json`
- Modify: `Package.swift`
- Test: `Tests/GadgetBuddyCoreTests/TestLab/RegressionTests.swift`

**Interfaces:**
- Produces: `FixtureLoader.load(_:) throws -> [SandboxScenario]`.

- [ ] **Step 1: Add fixture resources to the test target and write failing tests that load all three files and run every regression scenario through `VirtualSandbox`.**
- [ ] **Step 2: Run focused tests and verify RED because resources/loader are absent.**
- [ ] **Step 3: Add deterministic JSON fixtures and minimal loader using `Bundle.module`.**
- [ ] **Step 4: Verify all fixtures decode and all regression scenarios pass.**
- [ ] **Step 5: Commit:** `test: add deterministic sandbox fixtures`

### Task 4: Activate the six QA groups

**Files:**
- Create: `Tests/GadgetBuddyCoreTests/TestLab/ChallengerTests.swift`
- Create: `Tests/GadgetBuddyCoreTests/TestLab/RedTeamTests.swift`
- Create: `Tests/GadgetBuddyCoreTests/TestLab/ChaosTests.swift`
- Extend: `Tests/GadgetBuddyCoreTests/TestLab/ContractGuardTests.swift`
- Extend: `Tests/GadgetBuddyCoreTests/TestLab/RegressionTests.swift`
- Extend: `Tests/GadgetBuddyCoreTests/TestLab/SandboxIntegrationTests.swift`

**Interfaces:**
- Contract Guard: serialization, confidence range, missing-field declaration semantics.
- Challenger: invalid BPM/confidence/missing declarations and valid interpreter output.
- Red Team: adversarial fixtures plus contradiction/mixed-language/Unicode assertions.
- Regression Guard: committed regression fixture behavior.
- Integration Tester: complete pipeline and report/trace semantics.
- Fuzz / Chaos Tester: fixed corpus; no random generation.

- [ ] **Step 1: Add one failing test per QA group for behavior not covered by Tasks 1-3.**
- [ ] **Step 2: Run full suite and confirm RED failures are behavior-specific, not compile errors.**
- [ ] **Step 3: Make only the minimal production/test-utility changes needed to satisfy the six groups; do not broaden interpreter behavior unless a test exposes a genuine contract bug.**
- [ ] **Step 4: Run `swift test`; all Foundation and Test Lab suites must be GREEN.**
- [ ] **Step 5: Commit:** `test: activate GadgetBuddy QA test group`

### Task 5: Execution profiles and CI gates

**Files:**
- Create: `Tests/GadgetBuddyCoreTests/TestLab/ProfileTests.swift`
- Modify: `.github/workflows/ci.yml`
- Modify: `README.md`

**Interfaces:**
- FAST selects `.fast` scenarios plus contract/challenger/regression smoke coverage.
- CHALLENGE includes FAST plus `.challenge` adversarial/chaos coverage.
- FULL LAB runs all Test Lab and Foundation tests.

- [ ] **Step 1: Write failing profile-selection tests for FAST/CHALLENGE/FULL LAB scenario inclusion.**
- [ ] **Step 2: Verify RED.**
- [ ] **Step 3: Add minimal profile filtering helper in test support or production only if needed by public sandbox callers.**
- [ ] **Step 4: Update GitHub Actions to expose four jobs/checks: `foundation`, `test-lab-fast`, `test-lab-challenge`, `test-lab-full`. Each invokes deterministic Swift tests with explicit test filters/tags available in this package.**
- [ ] **Step 5: Document local commands and QA group responsibilities in README.**
- [ ] **Step 6: Run local full suite and validate workflow YAML structure.**
- [ ] **Step 7: Commit:** `ci: add Test Lab execution profiles`

### Task 6: Group activation/status ledger

**Files:**
- Create: `docs/TEST_LAB_STATUS.md`

**Interfaces:**
- Human-readable status for each QA group: mission, active artifact, current health, escalation rule, learning loop.

- [ ] **Step 1: Create a status table where every QA group maps to an executable test suite and CI surface.**
- [ ] **Step 2: Mark a group `ACTIVE` only when its referenced suite exists and passes locally.**
- [ ] **Step 3: Record issue handling policy: isolate failure, reproduce deterministically, add regression case, fix root cause, retain the learned regression fixture.**
- [ ] **Step 4: Commit:** `docs: add Test Lab group status ledger`

### Task 7: Final verification and PR

**Files:** no new production files expected.

- [ ] **Step 1: Run complete `swift test` from a clean build. Expected: zero failures.**
- [ ] **Step 2: Verify no Test Lab production path performs network, file writes, MIDI/audio, clock, random, or environment reads.**
- [ ] **Step 3: Review diff against the approved spec and acceptance criteria.**
- [ ] **Step 4: Push/commit all branch changes and open PR against `main`.**
- [ ] **Step 5: Wait for GitHub Actions checks; do not merge if any required check is red.**
- [ ] **Step 6: Merge only after the PR is mergeable and every Test Lab check is green.**
