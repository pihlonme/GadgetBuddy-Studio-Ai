# ChatGPT Project Instructions Proposal — GadgetBuddy Studio AI

**Date:** 2026-08-30  
**Status:** Proposed update for the ChatGPT project; repository state remains authoritative.

Use the following as the project-level ChatGPT instruction layer.

```text
# GADGETBUDDY STUDIO AI — PROJECT INSTRUCTIONS

## SOURCE OF TRUTH

GitHub repository `pihlonme/GadgetBuddy-Studio-Ai` is the implementation source-of-truth.

Before coding, planning a new milestone or reporting current implementation state:
1. inspect the current repository state and branch/PRs;
2. read current README and relevant docs/specs/test status;
3. verify merged versus planned functionality;
4. prefer current repository evidence over chat history or HQ summaries.

Do not restart or redesign the project from memory when current state can be verified.

## PRODUCT PURPOSE

GadgetBuddy Studio AI is AI-assisted workflow tooling for KORG Gadget-oriented music creation. Its current stable domain starts with natural-language/transcript interpretation into structured product contracts rather than direct uncontrolled DAW mutation.

## STABLE DOMAIN CONTRACT

Preserve the `SongCommand` boundary unless an explicit reviewed contract change replaces it.

Core semantics include:
- intent;
- genre;
- bpm;
- key;
- mood;
- structure;
- references;
- confidence;
- missingFields.

Do not invent missing musical facts. Represent missing/uncertain information explicitly.

## AI PROVIDER BOUNDARY

- Keep model/provider implementations behind a domain interface such as `CommandInterpretationProviding` or its reviewed successor.
- Use Structured Outputs/schema validation for shape where appropriate.
- Do not treat schema conformance as semantic truth.
- Recompute or validate product-critical invariants deterministically in GadgetBuddy-owned code.
- Keep provider/model choice replaceable.
- Keep API credentials runtime-configured; never commit secrets or require live paid-provider access for deterministic CI.

## TEST LAB / CHALLENGER

Preserve provider-independent evidence through deterministic tests and fixtures.

Use the established Test Lab roles/patterns where relevant:
- Contract Guard;
- Challenger;
- Red Team;
- Regression Guard;
- Integration Tester;
- deterministic fuzz/chaos corpus.

A model response that parses successfully is not sufficient evidence. Test domain invariants, missing fields, contradictory prompts, Unicode/mixed-language cases, provider errors/refusals and regression scenarios.

## DEVELOPMENT WORKFLOW

Build module-by-module through explicit contracts.

For every new product module:
1. verify the current active milestone;
2. define input/output schema and ownership;
3. define missing/error/conflict states;
4. add deterministic acceptance/regression tests;
5. implement the smallest correct vertical slice;
6. update durable documentation after verification.

Do not expand the project into a full DAW merely because external research describes DAW architecture.

## POST-V0.3 SEQUENCE

Product Module v0.3 delivered the visual Song Command Studio/live-session surface.

The documented downstream sequence is:
`Song Spec Generator -> Gadget Planner -> MIDI Generator -> Controller Mapper -> KORG adapters`.

Treat this as a dependency/order reference, not automatic permission to implement the next item. Explicitly select and specify the next active milestone first.

## KORG / MIDI / CONTROLLER BOUNDARIES

Keep generic song-intent/domain logic independent from specific Gadget/controller execution details.

Future MIDI/controller/device mappings should use explicit validated descriptors/adapters rather than hardcoding physical device assumptions into `SongCommand` interpretation.

## RESEARCH APPLICATION

New HQ/external research is advisory until compared with current repository state.

Current direction:
- structured AI contracts + deterministic semantic validation: ADOPT;
- provider abstraction + deterministic CI: ADOPT;
- module-by-module contract-first development: ADOPT;
- reusable MIDI/controller descriptor schemas: INVESTIGATE when downstream milestone becomes active;
- realtime audio engine/DSP graph: OUT OF CURRENT SCOPE;
- VST3/CLAP/AU hosting: OUT OF CURRENT SCOPE;
- Tauri/React or Rust/C++ rewrite: REJECT for current scope;
- microservices as default AI topology: REJECT AS GLOBAL RULE.

## REALTIME SAFETY

If a future downstream integration reaches a hard-realtime audio path, AI inference/network/provider calls must remain outside it. This repository currently does not require introducing a realtime DAW engine.

## CONTINUITY

After substantial work leave durable repository evidence:
- completed;
- tests/verification run;
- current product state;
- current milestone;
- open blockers;
- decisions made;
- exact next action;
- branch/PR/commit references.

Reconcile README/roadmap wording when merged implementation makes an old milestone statement stale.

## HQ RELATIONSHIP

Pihlonme Project HQ may provide cross-project research and architecture recommendations, but this repository remains the source-of-truth for GadgetBuddy Studio AI implementation and project-specific contracts.
```

## Why this update

The proposal strengthens source-of-truth discipline, preserves the existing `SongCommand`/provider/Test Lab architecture and prevents generic DAW research from causing unrelated stack or scope expansion. It also corrects the planning model after Product Module v0.3 by requiring explicit next-milestone selection.
