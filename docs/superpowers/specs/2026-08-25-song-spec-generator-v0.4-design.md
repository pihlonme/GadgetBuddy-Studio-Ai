# Song Spec Generator v0.4 — Design

## Status
Design approved in chat on 2026-08-25. This document formalizes the architecture for user review before implementation.

## Mission
Transform a validated, complete `SongCommand` into a deterministic, explicit and testable `SongSpec` that describes how a song should be arranged before any KORG Gadget selection, MIDI generation, controller mapping or external side effect occurs.

Canonical flow:

`SongCommand -> SongSpecGenerator -> SongSpec -> SongSpecChallenger -> SongSpecSandboxReport`

Downstream flow after v0.4:

`SongSpec -> Gadget Planner -> Template Generator -> MIDI Generator -> Controller Mapper -> KORG Gadget 3`

## Scope

### In scope
- A stable `SongSpec` domain contract.
- Deterministic Song Spec generation.
- Validation through a dedicated `SongSpecChallenger`.
- Sandbox/report integration using the existing evidence-first Test Lab pattern.
- Explicit tracking of planning assumptions.
- Unit, contract, adversarial and regression tests.
- A dedicated CI gate for the Song Spec module.

### Out of scope
- Selecting specific KORG Gadgets.
- Generating notes, MIDI clips, automation or audio.
- Sending MIDI, clock, files or commands to KORG Gadget.
- Device/controller mapping.
- Live OpenAI generation inside v0.4.
- Widening the existing 40...240 BPM contract.
- Reinterpreting missing user intent.

## Architectural boundary
`SongCommand` expresses user intent. `SongSpec` expresses an executable production plan. `GadgetPlanner` will later choose concrete KORG devices to realize that plan.

The Song Spec Generator is not allowed to silently repair incomplete intent. A command with missing core fields does not enter generation.

## Input contract
A command is eligible only when all of the following are true:
- `intent == "create_song"`
- `genre != nil`
- `bpm != nil`
- `key != nil`
- `missingFields` contains none of the four core fields
- existing `Challenger.validate` returns no issues

If these conditions are not met, generation returns a typed error and no `SongSpec`.

Mood, references and structure remain optional intent modifiers.

## Chosen approach

### Approach A — Deterministic planner with explicit assumptions — CHOSEN
Use a compact rule-based planner that preserves explicit command facts and creates only documented planning defaults. Every non-user-specified planning choice is surfaced in `assumptions`.

Advantages:
- deterministic CI
- easy regression testing
- no network/credential dependency
- clear provenance between user facts and planning decisions
- stable foundation for future AI provider parity

Trade-off:
- musically less adaptive than a model-generated arrangement in early versions.

### Approach B — AI-first SongSpec generation — REJECTED FOR v0.4
Advantages: richer arrangements and faster genre adaptation.
Risks: harder determinism, new failure modes, model drift, schema validation complexity and weaker root-cause isolation while the domain contract is still forming.

### Approach C — Genre-template catalog — DEFERRED
Advantages: highly predictable musical results.
Risks: premature template proliferation and implicit genre assumptions before we have enough real project evidence.

Future versions may add B and C behind the same `SongSpecProviding` contract after the deterministic contract is stable.

## Domain model

### `SongSpec`
```swift
public struct SongSpec: Codable, Equatable, Sendable {
    public var genre: String
    public var bpm: Int
    public var key: String
    public var mood: [String]
    public var totalBars: Int
    public var sections: [SongSectionSpec]
    public var roles: [SongRoleSpec]
    public var transitions: [SongTransitionSpec]
    public var references: [String]
    public var assumptions: [String]
}
```

The contract intentionally does not duplicate `SongCommand.confidence`. Confidence currently measures interpreter completeness, not arrangement quality. v0.4 must not overload that semantic.

### `SongSectionSpec`
```swift
public struct SongSectionSpec: Codable, Equatable, Sendable {
    public var id: String
    public var kind: SongSectionKind
    public var startBar: Int
    public var bars: Int
    public var energy: Double
}
```

### `SongSectionKind`
Initial stable vocabulary:
- `intro`
- `development`
- `breakdown`
- `peak`
- `outro`

These names are deliberately production-neutral. User language such as `drop` maps to `peak`; explicit break information maps to `breakdown`.

### `SongRoleSpec`
```swift
public struct SongRoleSpec: Codable, Equatable, Sendable {
    public var role: SongRole
    public var purpose: String
    public var activeSectionIDs: [String]
}
```

Initial roles:
- `drums`
- `bass`
- `harmony`
- `lead`
- `fx`

The role contract describes musical responsibility, not an instrument or Gadget choice.

### `SongTransitionSpec`
```swift
public struct SongTransitionSpec: Codable, Equatable, Sendable {
    public var fromSectionID: String
    public var toSectionID: String
    public var intent: String
}
```

The transition `intent` is a production-level description such as `increase_energy`, `release_tension`, or `resolve`. It does not prescribe automation, samples, effects or MIDI.

## Deterministic baseline planning
For a complete command with no explicit structure, v0.4 creates a 64-bar baseline:
- intro: 8 bars, energy 0.20
- development: 16 bars, energy 0.45
- breakdown: 8 bars, energy 0.25
- peak: 24 bars, energy 0.90
- outro: 8 bars, energy 0.35

This is a planning default, not a claim about the user's intent. The assumption must be recorded as:
`"Used v0.4 64-bar electronic arrangement baseline because no explicit section lengths were supplied."`

If `SongCommand.structure.breakPresent == false`, the breakdown is removed and its bars are reassigned to development/peak while preserving 64 total bars.

If `breakPresent == true`, breakdown remains.

If `intro == "slow_build"`, intro expands from 8 to 16 bars and development is reduced by 8 bars.

If `drop == "high_energy"`, peak energy is 1.0.

Every structural change based directly on explicit command structure is not an assumption. Every default not present in the command is listed in `assumptions`.

## Role planning
All five role categories are created in v0.4. Their active sections are deterministic planning defaults and therefore recorded as a single explicit assumption.

Baseline activation:
- drums: intro, development, breakdown, peak, outro
- bass: development, peak, outro
- harmony: intro, development, breakdown, peak
- lead: development, peak
- fx: intro, development, breakdown, peak, outro

No role selects patches, synths, drum machines or effects.

## Transition planning
Transitions are generated only between adjacent sections and reference existing section IDs.

Baseline intent rules:
- intro -> development: `increase_energy`
- development -> breakdown: `release_tension`
- breakdown -> peak: `build_to_peak`
- development -> peak when no breakdown exists: `build_to_peak`
- peak -> outro: `resolve`

## Validation — `SongSpecChallenger`
The dedicated validator must detect at minimum:
- `invalidBPM(Int)` outside current 40...240 contract
- `invalidTotalBars(Int)` if <= 0
- `invalidSectionBars(sectionID, bars)` if <= 0
- `invalidEnergy(sectionID, energy)` outside 0...1
- `duplicateSectionID(String)`
- `nonContiguousSections`
- `sectionTotalMismatch(expected, actual)`
- `unknownRoleSection(role, sectionID)`
- `unknownTransitionSection(sectionID)`
- `nonAdjacentTransition(from, to)`
- `missingRequiredRole(SongRole)`

The validator does not judge artistic taste. It validates structural and contract correctness only.

## Generator API
```swift
public enum SongSpecGeneratorError: Error, Equatable, Sendable {
    case invalidCommand([ChallengerIssue])
    case incompleteCommand([String])
    case unsupportedIntent(String?)
}

public struct SongSpecGenerator: Sendable {
    public init()
    public func generate(from command: SongCommand) throws -> SongSpec
}
```

Validation order:
1. run existing `Challenger`
2. reject missing core fields
3. reject unsupported intent
4. generate deterministic plan
5. run `SongSpecChallenger`
6. return spec only when no SongSpec issues exist

## Future provider seam
v0.4 may define, but does not require using, this protocol:
```swift
public protocol SongSpecProviding: Sendable {
    func generate(from command: SongCommand) async throws -> SongSpec
}
```

The deterministic generator may later be wrapped by a provider adapter. Future OpenAI or template providers must still pass `SongSpecChallenger` before their output is accepted.

## Sandbox integration
Add a dedicated report rather than overloading `SandboxReport`, whose current payload is command-specific.

```swift
public struct SongSpecSandboxReport: Codable, Equatable, Sendable {
    public var inputCommand: SongCommand
    public var generatedSpec: SongSpec?
    public var issues: [SongSpecChallengerIssue]
    public var trace: [SandboxTraceEvent]
    public var passed: Bool
}
```

Trace stages:
1. `command`
2. `song-spec-generator`
3. `song-spec-challenger`
4. `result`

## Test strategy

### Contract Guard
- complete command generates a valid SongSpec
- incomplete command is rejected
- unsupported intent is rejected
- explicit command facts survive unchanged: genre, bpm, key, mood, references

### Arrangement tests
- baseline totals exactly 64 bars
- sections are contiguous
- slow-build adjustment preserves 64 bars
- no-break adjustment preserves 64 bars
- high-energy drop produces peak energy 1.0
- assumptions are present for defaults and absent for explicit command facts

### Challenger tests
Each issue type receives a focused failing fixture.

### Red Team
- duplicate IDs
- negative bars
- energy > 1
- transition to missing section
- role references missing section
- section gaps/overlaps
- total mismatch

### Regression Guard
Any discovered generator/challenger defect becomes a permanent regression test before merge.

### FULL LAB
Existing command tests remain unchanged and green. SongSpec tests are added without weakening the existing gates.

## CI
Add a `song-spec-contract` job:
- deterministic generator tests
- SongSpecChallenger tests
- SongSpec sandbox tests

`test-lab-full` continues to run the entire Swift test suite.

Required merge gates for v0.4:
- foundation
- ai-provider-contract
- ui-module
- test-lab-fast
- test-lab-challenge
- test-lab-full
- song-spec-contract

## Governance / Values Gate

### Truth
Planning defaults are labeled as assumptions rather than user facts.

### Possibility
The provider seam keeps future AI/template approaches open without coupling them to v0.4.

### One
`SongSpec` remains Gadget-agnostic so Gadget Planner, MIDI Generator and future integrations can consume one stable contract.

### Challenge
`SongSpecChallenger` is an independent structural gate and does not trust generator output.

### Learning
Every discovered defect becomes regression evidence.

### Safety
No network calls, secrets, hardware, KORG side effects or file export occur in v0.4.

### Ownership
- Domain & Generator Team: SongSpec and generator
- Challenger/Test Lab Team: validator, adversarial/regression coverage
- Core/Elite: contract and merge gate
- Gadget Planner Team: downstream consumer, not implemented in v0.4

Initial design gate outcome: `PASS_WITH_ACTIONS` until the written spec is approved and implementation evidence exists.

## Definition of Done
v0.4 is complete only when:
1. complete validated SongCommands deterministically produce valid SongSpecs
2. incomplete/invalid commands cannot silently become plans
3. assumptions are explicit
4. SongSpecChallenger rejects malformed specs
5. sandbox trace/report exists
6. all old and new CI gates pass
7. Values Gate is PASS
8. code is squash-merged to `main`
9. post-merge CI succeeds on the actual merge commit

## Explicit non-goals for the final merge
A v0.4 merge does not mean GadgetBuddy can yet create MIDI or control KORG Gadget. It means the system can reliably convert a validated musical command into a structured production plan for the next module.