# GadgetBuddy Studio AI

AI-assisted music workflow tooling for KORG Gadget 3.

## Foundation v0.1

The first vertical slice is deliberately small:

`free text / transcript -> Command Interpreter -> SongCommand -> Challenger validation`

The interpreter does **not invent missing facts**. Missing core fields are explicitly returned in `missingFields`.

### Current SongCommand contract

- `intent`
- `genre`
- `bpm`
- `key`
- `mood`
- `structure`
- `references`
- `confidence`
- `missingFields`

## Test Lab / Virtual Sandbox v0.1

Every change is exercised through a deterministic, side-effect-free Swift sandbox before downstream integration:

`SandboxScenario -> CommandInterpreter -> SongCommand -> Challenger -> SandboxReport`

The active QA group has six roles:

- **Contract Guard** — domain/serialization and contract invariants.
- **Challenger** — invalid values and missing-field declarations.
- **Red Team** — adversarial, mixed-language, Unicode, and conflicting prompts.
- **Regression Guard** — committed fixture behavior that must stay stable.
- **Integration Tester** — complete pipeline, trace, and pass/fail semantics.
- **Fuzz / Chaos Tester** — fixed deterministic edge corpus; no random input.

### Run locally

Full suite:

```bash
swift test
```

Foundation only:

```bash
swift test --filter 'GadgetBuddyCoreTests.(parsesTechnoPromptAndMarksMissingKey|neverInventsMissingMusicalFacts|challengerAcceptsInterpreterOutput)'
```

FAST profile:

```bash
swift test --filter 'GadgetBuddyCoreTests.(fastProfile|sandboxScenario|sandboxReport|challengerIssue|interpreterAlways|challengerRejects|challengerRequires|challengerAcceptsDeclared|fixtureSets|normalFixture|sandboxRuns|sandboxFails|sandboxRecognizes)'
```

CHALLENGE profile:

```bash
swift test --filter 'GadgetBuddyCoreTests.(challengeProfile|fastProfile|redTeam|chaos|sandboxScenario|sandboxReport|challengerIssue|interpreterAlways|challengerRejects|challengerRequires|challengerAcceptsDeclared|fixtureSets|normalFixture|sandboxRuns|sandboxFails|sandboxRecognizes)'
```

FULL LAB is the complete `swift test` suite.

## Development principle

A failing test is treated as a useful signal: isolate it, reproduce it deterministically, fix the root cause, and retain the scenario as a regression case so the system learns from the failure.

## Next milestone

Introduce an AI-backed interpreter behind the same stable `SongCommand` contract and exercise it through Test Lab before adding the first visual Song Command UI.
