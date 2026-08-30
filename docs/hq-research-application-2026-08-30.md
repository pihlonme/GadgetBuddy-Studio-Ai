# HQ Research Application — 2026-08-30

**Project:** GadgetBuddy Studio AI  
**Source baseline:** `main`  
**Status:** Project-specific research translation; documentation only  
**Authority:** This document does not override current repository contracts, tests or approved module plans.

## Current verified product architecture

GadgetBuddy Studio AI uses a contract-first music workflow architecture centered on `SongCommand`:

`free text / transcript -> Command Interpreter -> SongCommand -> Challenger / Test Lab`

The AI provider path sits behind the same domain contract as deterministic providers. Structured provider output is treated as an input to product validation rather than semantic truth: critical fields such as `missingFields` and `confidence` are recomputed or checked locally before Challenger validation.

Product Module v0.3 delivered the first visual Song Command Studio/live-session surface on top of this domain and Test Lab foundation.

## Research conclusion

The reviewed DAW/AI research is useful primarily for **contract discipline, validation, modular delivery and separation of concerns**. It does not justify adding a DAW audio engine, plugin host or new desktop stack to this project.

## ADOPT now

### 1. Structured AI boundaries

- Keep model/provider details behind explicit interfaces.
- Use structured output/schema enforcement for response shape where appropriate.
- Continue deterministic semantic validation in GadgetBuddy-owned code.
- Preserve explicit uncertainty and missing-data semantics.
- Never allow a provider response envelope to become the product-domain API.

### 2. No invented musical facts

The existing `SongCommand` rule remains correct: missing musical facts are represented explicitly rather than guessed. Confidence is product data, not model authority.

### 3. Deterministic provider-independent testing

Continue using deterministic/fake providers and committed fixtures in CI. Preserve Challenger, contract, regression, integration and adversarial/chaos-style roles as evidence for domain behavior independent of a live model.

### 4. Module-by-module product expansion

Use the stable contract as the boundary for the next module. Define each new module's input/output schema, invariants, error states and acceptance tests before implementation.

### 5. AI is not realtime or canonical truth

If later modules emit MIDI/controller plans, AI may generate structured plans on a non-realtime path. Downstream execution must still validate ranges, identifiers, missing fields and device/project capabilities deterministically.

## INVESTIGATE at the correct milestone

### Song Spec contract

The documented post-v0.3 sequence begins with Song Spec Generator, followed by Gadget Planner, MIDI Generator, Controller Mapper and KORG adapters. This is a useful dependency order, but the next active milestone should be selected explicitly before coding.

If Song Spec Generator is selected, first define:
- versioned `SongSpec` schema;
- mapping from `SongCommand`;
- required versus optional fields;
- provenance/confidence rules;
- deterministic validation;
- missing/conflicting-data behavior;
- regression fixtures.

### Shared MIDI/controller descriptors

Before Controller Mapper/MIDI Generator work becomes active, investigate reusable versioned descriptors for:
- controller identity/capabilities;
- control types and MIDI transport;
- target Gadget parameters/actions;
- ranges, curves and modes;
- validation and unsupported capability reporting.

Do not hardcode a physical controller into generic song-domain logic.

### Provider portability

Keep provider/model selection replaceable. If additional providers are introduced, add adapter contract tests rather than branching product logic throughout the domain.

## DEFER / REJECT FOR CURRENT SCOPE

- hard-realtime audio engine;
- directed DSP/audio graph;
- audio callback/thread architecture;
- VST3, CLAP or AU plugin hosting;
- Tauri/React migration;
- Rust/C++ engine rewrite;
- microservices as a default AI topology;
- full DAW timeline/mixer/session implementation.

These findings become relevant only if the product scope explicitly changes.

## Documentation discrepancy found

The repository README still describes building the first visual Song Command screen as the next milestone. Product Module v0.3 already delivered that surface, so the README milestone statement is stale and should be reconciled before it is used for future planning.

## Project-specific application of HQ principles

### GLOBAL PRINCIPLE
AI output should be structured, replaceable and independently validated.

### PROJECT-SPECIFIC APPLICATION
`SongCommand` and future GadgetBuddy domain objects remain the stable contracts. Provider output is normalized into those contracts and Challenger/Test Lab provides deterministic product evidence.

### PROJECT-SPECIFIC EXCEPTION
DAW realtime/plugin architecture recommendations do not apply merely because GadgetBuddy ultimately controls music creation. This repository currently owns AI-assisted KORG Gadget workflow planning, not a general-purpose realtime DAW engine.

## Recommended next verified action

1. Reconcile README current-state/next-milestone wording with merged Product Module v0.3.
2. Explicitly select the next product module from the documented sequence.
3. Write its contract/spec and acceptance tests before implementation.
4. Keep KORG/device-specific execution behind downstream adapters rather than coupling it into `SongCommand` parsing.

## Source notes

Relevant cross-project research is maintained in the Pihlonme OS HQ Research Ledger. OpenAI Structured Outputs can enforce supported JSON Schema structure, but schema conformance remains separate from GadgetBuddy's domain-semantic validation.

Reference: https://platform.openai.com/docs/guides/structured-outputs
