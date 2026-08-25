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
- A generic async SongSpec provider abstraction before a second provider exists.
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

Recognized deterministic structure directives in v0.4 are exactly:
- `intro == "slow_build"`
- `breakPresent == true | false`
- `drop == "high_energy"`

Any non-nil `intro` or `drop` value outside that vocabulary is rejected with a typed `unsupportedStructureDirective` error. Explicit input is never silently discarded.

## Chosen approach

### Approach A — Deterministic planner with explicit assumptions — CHOSEN
Use a compact rule-based planner that preserves explicit command facts and creates only documented planning defaults. Every non-user-specified planning choice is surfaced in `assumptions`.

Advantages:
- deterministic CI
- easy regression testing
- no network/credential dependency
- clear provenance between user facts and planning decisions
- stable foundation for future provider parity

Trade-off:
- musically less adaptive than a model-generated arrangement in early versions.

### Approach B — AI-first SongSpec generation — REJECTED FOR v0.4
Advantages: richer arrangements and faster genre adaptation.
Risks: harder determinism, new failure modes, model drift, schema validation complexity and weaker root-cause isolation while the domain contract is still forming.

### Approach C — Genre-template catalog — DEFERRED
Advantages: highly predictable musical results.
Risks: premature template proliferation and implicit genre assumptions before enough real project evidence exists.

A provider abstraction is deliberately deferred until a second implementation exists. This keeps v0.4 YAGNI-compliant while preserving a clean generator boundary.

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

The contract also intentionally does not add a second `missingFields` semantic. Missing user-intent facts belong to `SongCommand` and block generation. Planning choices that are not user facts are represented as explicit `assumptions`. This avoids confusing “unknown user intent” with “planner default.”

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

`startBar` is 1-based. The first section must start at bar 1. Every next section must start at `previous.startBar + previous.bars`.

### `SongSectionKind`
```swift
public enum SongSectionKind: String, Codable, Equatable, Sendable {
    case intro
    case development
    case breakdown
    case peak
    case outro
}
```

These names are deliberately production-neutral. User language such as `drop` maps to `peak`; explicit break information maps to `breakdown`.

v0.4 contains at most one section of each kind and uses the kind raw value as the deterministic section ID: `intro`, `development`, `breakdown`, `peak`, `outro`.

### `SongRoleSpec`
```swift
public struct SongRoleSpec: Codable, Equatable, Sendable {
    public var role: SongRole
    public var purpose: String
    public var activeSectionIDs: [String]
}

public enum SongRole: String, Codable, Equatable, Sendable {
    case drums
    case bass
    case harmony
    case lead
    case fx
}
```

The role contract describes musical responsibility, not an instrument or Gadget choice.

### `SongTransitionSpec`
```swift
public struct SongTransitionSpec: Codable, Equatable, Sendable {
    public var fromSectionID: String
    public var toSectionID: String
    public var intent: String
}
```

The transition `intent` is a production-level description such as `increase_energy`, `release_tension`, `build_to_peak`, or `resolve`. It does not prescribe automation, samples, effects or MIDI.

## Deterministic baseline planning
For a complete command with no explicit structure, v0.4 creates this 64-bar planning baseline:
- intro: start 1, 8 bars, energy 0.20
- development: start 9, 16 bars, energy 0.45
- breakdown: start 25, 8 bars, energy 0.25
- peak: start 33, 24 bars, energy 0.90
- outro: start 57, 8 bars, energy 0.35

This is a planning default, not a claim about the user's intent. Baseline section lengths/energy must be represented in `assumptions`.

### Deterministic structure transforms
Transforms execute in this order:

1. **Break transform**
   - `breakPresent == true`: keep the 8-bar breakdown.
   - `breakPresent == false`: remove breakdown; add 4 bars to development and 4 bars to peak. Result before any intro transform: intro 8, development 20, peak 28, outro 8.
   - `breakPresent == nil`: keep baseline breakdown and record that breakdown presence was a planner default.

2. **Intro transform**
   - `intro == "slow_build"`: add 8 bars to intro and remove 8 bars from development.
   - `intro == nil`: no transform.
   - any other non-nil value: typed error; no spec.

3. **Peak-energy transform**
   - `drop == "high_energy"`: peak energy becomes 1.0.
   - `drop == nil`: keep baseline 0.90.
   - any other non-nil value: typed error; no spec.

4. **Recompute positions**
   - regenerate all `startBar` values sequentially from bar 1.
   - `totalBars` remains exactly 64 for every v0.4 generated spec.

Examples:
- baseline: 8 + 16 + 8 + 24 + 8 = 64
- no break: 8 + 20 + 28 + 8 = 64
- slow build with break: 16 + 8 + 8 + 24 + 8 = 64
- slow build without break: 16 + 12 + 28 + 8 = 64

Every structural transform based directly on explicit command structure is not labeled an assumption. Defaults that were not specified by the command are labeled as assumptions.

## Role planning
The deterministic generator emits five generic production roles so the next module has stable responsibility slots. This is a planner default, not a validator requirement and not a claim that every finished song must audibly contain all five roles.

Baseline activation:
- drums: intro, development, breakdown if present, peak, outro
- bass: development, peak, outro
- harmony: intro, development, breakdown if present, peak
- lead: development, peak
- fx: intro, development, breakdown if present, peak, outro

Default role activation is represented by one explicit assumption. No role selects patches, synths, drum machines or effects.

The validator checks role structure, not artistic necessity. A valid externally produced future `SongSpec` may contain fewer than five roles as long as it contains at least one role and all references are valid.

## Transition planning
Transitions are generated only between adjacent sections and reference existing section IDs.

Baseline intent rules:
- intro -> development: `increase_energy`
- development -> breakdown: `release_tension`
- breakdown -> peak: `build_to_peak`
- development -> peak when no breakdown exists: `build_to_peak`
- peak -> outro: `resolve`

## Validation — `SongSpecChallenger`
`SongSpecChallengerIssue` must conform to `Codable`, `Equatable`, and `Sendable` because issues are stored in sandbox reports.

The dedicated validator must detect at minimum:
- `invalidBPM(Int)` outside current 40...240 contract
- `invalidTotalBars(Int)` if <= 0
- `emptySections`
- `invalidSectionBars(sectionID, bars)` if <= 0
- `invalidStartBar(sectionID, startBar)` if < 1
- `invalidEnergy(sectionID, energy)` outside 0...1
- `duplicateSectionID(String)`
- `nonContiguousSections`
- `sectionTotalMismatch(expected, actual)`
- `emptyRoles`
- `duplicateRole(SongRole)`
- `unknownRoleSection(role, sectionID)`
- `unknownTransitionSection(sectionID)`
- `nonAdjacentTransition(from, to)`

The validator does not require a specific artistic role and does not judge musical taste. It validates structural and contract correctness only.

## Generator API
```swift
public enum SongSpecGeneratorError: Error, Equatable, Sendable {
    case invalidCommand([ChallengerIssue])
    case incompleteCommand([String])
    case unsupportedIntent(String?)
    case unsupportedStructureDirective(field: String, value: String)
    case generatedInvalidSpec([SongSpecChallengerIssue])
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
4. reject unsupported non-nil structure directives
5. generate deterministic plan
6. run `SongSpecChallenger`
7. return spec only when no SongSpec issues exist

No async provider protocol is added in v0.4. A future provider must return the same `SongSpec` contract and pass the same `SongSpecChallenger` before acceptance.

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

Trace stages are exactly:
1. `command`
2. `song-spec-generator`
3. `song-spec-challenger`
4. `result`

Generator errors are propagated as errors; malformed generated specs are represented by `generatedInvalidSpec` and never returned as accepted specs.

## Test strategy

### Contract Guard
- complete command generates a valid SongSpec
- incomplete command is rejected
- unsupported intent is rejected
- unsupported structure directives are rejected, not discarded
- explicit command facts survive unchanged: genre, bpm, key, mood, references

### Arrangement tests
- baseline totals exactly 64 bars
- first section begins at bar 1
- sections are contiguous
- slow-build adjustment preserves 64 bars
- no-break adjustment produces exact 8/20/28/8 layout
- slow-build + no-break produces exact 16/12/28/8 layout
- high-energy drop produces peak energy 1.0
- assumptions distinguish defaults from explicit command facts

### Role tests
- deterministic generator emits all five planner roles
- generated role references only existing sections
- no-break generation removes breakdown references from roles
- validator accepts a structurally valid spec with fewer than five roles

### Challenger tests
Each issue type receives a focused failing fixture.

### Red Team
- duplicate IDs
- negative/zero bars
- start bar 0
- energy > 1
- transition to missing section
- role references missing section
- duplicate roles
- section gaps/overlaps
- total mismatch
- unknown structure directive in input

### Regression Guard
Any discovered generator/challenger defect becomes a permanent regression test before merge.

### FULL LAB
Existing command and UI tests remain unchanged and green. SongSpec tests are added without weakening existing gates.

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
Planning defaults are labeled as assumptions rather than user facts. Unsupported explicit structure is rejected rather than hidden.

### Possibility
The stable SongSpec contract keeps future AI/template approaches open without prematurely adding unused provider machinery.

### One
`SongSpec` remains Gadget-agnostic so Gadget Planner, MIDI Generator and future integrations can consume one stable contract.

### Challenge
`SongSpecChallenger` is an independent structural gate and does not trust generator output or enforce artistic taste.

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
3. unsupported explicit structure cannot be silently discarded
4. assumptions are explicit
5. SongSpecChallenger rejects malformed specs without judging artistic taste
6. sandbox trace/report exists
7. all old and new CI gates pass
8. Values Gate is PASS
9. code is squash-merged to `main`
10. post-merge CI succeeds on the actual merge commit

## Explicit non-goals for the final merge
A v0.4 merge does not mean GadgetBuddy can yet create MIDI or control KORG Gadget. It means the system can reliably convert a validated musical command into a structured production plan for the next module.