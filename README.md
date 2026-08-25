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

## AI Command Interpreter v0.2

The AI path now sits behind the same domain contract:

`input -> CommandInterpretationProviding -> OpenAI Responses / deterministic provider -> SongCommand -> Challenger`

The production OpenAI adapter uses Responses API Structured Outputs with a strict JSON schema. The model extracts facts, but GadgetBuddy recomputes core `missingFields` and `confidence` locally before Challenger validation.

The default OpenAI model is `gpt-5.6-luna` and can be overridden in configuration. API credentials are runtime configuration only; no key belongs in Git or deterministic CI.

For provider-aware sandbox tests:

`SandboxScenario -> AsyncVirtualSandbox -> provider -> SongCommand -> Challenger -> SandboxReport`

See `docs/COMMAND_INTERPRETER_V0.2.md` for the contract and security boundary.

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

AI provider contract only:

```bash
swift test --filter 'GadgetBuddyCoreTests.(aiInterpreter|openAIProvider|openAIConfiguration|asyncSandbox)'
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

## Governance

GadgetBuddy adopts the canonical **Pihlonme Koncern Governance v0.1**. See [`GOVERNANCE.md`](GOVERNANCE.md) for the public project-facing contract and seven-question Values Gate.

The governance layer does not replace Test Lab or Challenger. Technical checks provide evidence; governance defines how the team handles truth, dissent, learning, safety, ownership and cross-project impact.

**One team. Infinite possibilities. Evidence over ego. Learn from everything.**

## Development principle

A failing test is treated as a useful signal: isolate it, reproduce it deterministically, fix the root cause, and retain the scenario as a regression case so the system learns from the failure.

## Next milestone

Build the first visual Song Command screen on top of the stable interpreter/provider contract, then connect explicit runtime API credential configuration in the app layer.
