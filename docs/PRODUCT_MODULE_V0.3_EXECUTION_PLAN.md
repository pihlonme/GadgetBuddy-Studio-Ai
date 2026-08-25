# Product Module v0.3 — Expert Panel Execution Plan

## Mission
Deliver one working vertical product slice that turns a music prompt into a visible, validated `SongCommand` on iPad/macOS and in a browser-accessible QA mirror, without breaking the stable Core contract.

## Q&A / retrospective before implementation

### What has worked?
1. Contract first: `SongCommand` is stable before UI work.
2. Deterministic Test Lab before live integrations.
3. Challenger validation between modules.
4. Feature branch -> independent CI -> merge gate.
5. Runtime-only secrets; no credentials in Git or deterministic CI.

### What has caused friction?
1. Connector permissions initially blocked GitHub writes; integration capability must be verified before relying on it.
2. Fixture resource lookup once crashed; external/resource boundaries need explicit failure paths.
3. Responses output can contain non-message items; API adapters must tolerate valid envelope variation.
4. Planning and implementation were previously mixed; specs, acceptance criteria and actual verified state must remain distinct.

### What should we preserve?
- Stable domain model.
- No invented musical facts.
- Deterministic regression corpus.
- Evidence-before-merge.
- Gated hardware-dependent work.

### What changes now?
- Add a production/live interpretation session that uses the same Challenger boundary but does not require predeclared test expectations.
- Add reusable SwiftUI presentation in a separate target.
- Keep macOS 13 / iOS 16 deployment compatibility; use `ObservableObject` instead of raising deployment targets just for newer Observation APIs.
- Add a browser QA mirror as a non-canonical external system-test surface.

## Expert panel / teams

### CORE / Elite Review Board
Owns architecture, contract changes, merge decision and cross-team dependency resolution.
Definition of done: no undocumented contract drift; all required CI gates green; PR mergeable.

### Team A — Domain & AI Contract
Owns `GadgetBuddyCore`, provider abstraction, live session, Challenger semantics, OpenAI boundary.
Deliverables:
- `AnyCommandInterpretationProvider`
- `LiveInterpretationSession`
- live-session tests

### Team B — iOS / iPadOS UI
Owns touch-first SwiftUI screen, accessibility, narrow layouts and state lifecycle.
Deliverables:
- prompt editor
- provider selector
- Interpret action
- structured result view
- missing-field guidance
- confidence and validation state
- trace view

### Team C — macOS UI
Owns keyboard/mouse behavior, resizable-window behavior and macOS 13 compatibility.
Deliverables:
- same reusable SwiftUI screen
- standalone macOS demo executable
- no AppKit-specific fork unless required

### Team D — Test Lab / Challenger
Owns unit, contract, regression, adversarial and integration gates.
Deliverables:
- live-session tests
- UI model tests
- `ui-module` CI gate
- FULL LAB regression remains green

### Team E — Browser QA / AppDeploy
Owns non-canonical browser mirror usable from iPad/Samsung and external end-to-end checks.
Deliverables:
- deterministic and AI interpretation modes
- normalized `SongCommand`
- visible Challenger-equivalent status
- 3–5 E2E workflows including one negative path

### Team F — Music Validation / Midify
Owns disposable musical golden fixtures used to verify that interpreted values are musically coherent before future MIDI generation work.
Current v0.3 role: acceptance fixture only; no canonical project output.

### Team G — Source Governance / Dropbox + GitHub
GitHub is canonical source for code. Dropbox is reference/source material and export target, never a secret source. New material is mapped to one canonical owner or inbox review.

### Team H — Research / Metaplay patterns
Adopts useful platform-agnostic patterns only: layered tests, deterministic shared logic, validation-before-commit, configuration/behavior separation. Metaplay is not added as a runtime dependency.

## Research decisions

1. KORG Gadget 3 supports external MIDI, Bluetooth MIDI, MIDI export, Ableton Project export, iCloud/Dropbox export and Ableton Link. Those are downstream integration seams, not requirements for the v0.3 UI slice.
2. KORG Gadget 3 supports BPM 20–300, while current interpreter intentionally validates 40–240. Keep current Core constraint for v0.3 and open a dedicated contract issue before widening it; do not silently change behavior.
3. KORG Gadget can receive MIDI clock but does not transmit it. Future sync architecture must therefore treat Gadget as follower for MIDI clock, or use Ableton Link where appropriate.
4. SwiftUI is architecture-agnostic. Keep domain logic outside views and expose observable presentation state.
5. Metaplay testing guidance reinforces incremental layered tests plus CI integration; we retain unit/contract/integration/e2e separation.
6. OpenAI Responses API remains the native AI boundary; the browser QA mirror may use AppDeploy structured extraction but must normalize into the exact same visible contract.

## Execution sequence and gates

### M0 — Retrospective + architecture lock
- [x] Q&A completed.
- [x] Team boundaries defined.
- [x] Research constraints documented.
Gate: Core/Elite accepts vertical-slice architecture.

### M1 — Live Core session
1. Add type-erased async provider.
2. Add live interpretation session.
3. Run provider -> Challenger -> report.
4. Add tests for valid complete and incomplete commands.
Gate: new tests green + existing FULL LAB green.

### M2 — SwiftUI state model
1. Add `GadgetBuddyUI` target.
2. Add `SongCommandScreenModel` with deterministic provider and optional AI provider.
3. Reject empty input visibly.
4. Run selected provider through live session.
5. Publish report/error/running state.
Gate: UI model tests green.

### M3 — SwiftUI screen
1. Prompt editor.
2. Provider segmented control.
3. Interpret button.
4. Summary cards: intent, genre, BPM, key.
5. Mood/structure/reference sections.
6. Confidence indicator.
7. Missing-field chips and guidance.
8. Challenger state and trace.
9. Accessibility labels and scalable layout.
Gate: compile on macOS runner and `ui-module` tests green.

### M4 — macOS runnable demo
1. Add `GadgetBuddyDemo` executable target.
2. Launch same screen with deterministic provider.
3. If a host supplies an AI provider, enable AI mode without changing UI code.
Gate: `swift build --product GadgetBuddyDemo` succeeds.

### M5 — Browser QA mirror
1. React/Vite frontend + AppDeploy backend.
2. `POST /api/interpret` supports deterministic and AI modes.
3. AI uses schema-based extraction.
4. Backend recomputes `missingFields` and `confidence`.
5. Frontend shows normalized contract, status, missing fields and trace.
6. E2E covers complete prompt, incomplete prompt, provider switching, empty prompt and backend failure/retry visibility.
Gate: AppDeploy status ready + E2E QA green.

### M6 — Music acceptance fixture
1. Generate one disposable 145 BPM dark warehouse-techno fixture in Midify.
2. Use it only to validate terminology/structure expectations for future Song Spec/MIDI modules.
Gate: no change to `SongCommand` contract required.

### M7 — Integration review
Core/Elite checks:
- schema parity native/browser
- no secret committed
- deployment targets unchanged
- no accidental KORG integration claims
- all CI gates green
- browser QA ready
- PR diff limited to v0.3 scope

### M8 — Final merge
1. Open PR from `feature/song-command-studio-v0.3` to `main`.
2. Require Foundation, AI Provider, FAST, CHALLENGE, FULL LAB and UI Module gates.
3. Resolve any failures with regression coverage.
4. Squash merge with expected head SHA.
5. Verify files on `main` and post-merge CI.

## Final product-module acceptance criteria
A user can enter a prompt, choose an available provider, interpret it, and see a structured `SongCommand` with explicit missing fields, confidence, validation status and execution trace. The browser mirror is usable on mobile now; the same presentation module is reusable by native iPad/macOS hosts. No downstream KORG/MIDI side effect is performed in v0.3.

## Next-after-v0.3
Song Spec Generator -> Gadget Planner -> MIDI Generator -> Controller Mapper -> KORG Gadget export/control adapters, each entering the same sandbox/Challenger pattern before hardware or app side effects.