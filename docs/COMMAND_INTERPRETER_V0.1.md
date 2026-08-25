# Command Interpreter v0.1

## Purpose
Translate a free-form music request or voice transcript into a structured `SongCommand` for downstream GadgetBuddy modules.

## Rules
1. Do not invent missing musical facts.
2. Missing core fields must be listed in `missingFields`.
3. `confidence` must remain in the range `0...1`.
4. BPM values outside `40...240` are rejected by the deterministic extractor.
5. Challenger validation must pass before downstream modules consume the result.

## Definition of Done
- Accepts text input.
- Produces a structured `SongCommand`.
- Identifies missing core fields.
- Passes normal, incomplete, and validation-focused Challenger tests.
