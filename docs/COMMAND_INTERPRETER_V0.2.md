# Command Interpreter v0.2 — AI Provider Layer

## Goal

Add an AI-backed interpretation path without changing the stable `SongCommand` domain contract or weakening the existing Challenger/Test Lab gates.

## Runtime flow

`text / transcript -> OpenAI Responses provider -> extracted DTO -> canonical SongCommand -> Challenger -> downstream`

For sandboxed validation:

`SandboxScenario -> AsyncVirtualSandbox -> provider -> SongCommand -> Challenger -> SandboxReport`

## Provider boundary

`CommandInterpretationProviding` is the asynchronous provider contract. Production and test providers implement the same interface.

- `DeterministicCommandInterpretationProvider` wraps the v0.1 deterministic interpreter.
- `OpenAIResponsesCommandInterpreter` is the production OpenAI Responses API adapter.
- Test Lab injects deterministic fake providers; CI does not call an external model.

## OpenAI adapter

The adapter sends a `POST` request to `/v1/responses` using Structured Outputs through `text.format` with `type: json_schema` and `strict: true`.

Default model: `gpt-5.6-luna`. The model is configurable at initialization.

The model returns an extraction DTO. GadgetBuddy then recomputes core `missingFields` and `confidence` locally so model output cannot bypass those contract rules.

### Extraction rules

- Never invent missing musical facts.
- Supported v0.2 intent is `create_song`; otherwise intent is null.
- BPM outside `40...240` is not accepted as a valid BPM.
- Unknown scalar values are null.
- Unknown lists are empty arrays.
- Unknown structure is null.
- Core missing fields are always recomputed from `intent`, `genre`, `bpm`, and `key`.

## Error handling

The adapter has explicit errors for:

- invalid/blank API key;
- request encoding failure;
- non-2xx HTTP status;
- incomplete/failed/cancelled response;
- model refusal;
- missing output text;
- invalid structured output;
- malformed HTTP response.

Responses may contain non-message output items (for example reasoning items). The parser ignores these and searches for the actual `output_text` or refusal content.

## Security boundary

- No API key is committed to Git.
- No Dropbox secret is read or imported by this implementation.
- The API key must be injected at runtime into `OpenAICommandInterpreterConfiguration` from an approved secure app configuration path.
- CI uses fake transports/providers only and never makes a paid/live OpenAI request.
- Live-provider tests, when added, must be explicit opt-in checks separate from deterministic merge gates.

## Acceptance criteria

- Existing `SongCommand` remains unchanged.
- Provider output is Challenger-validated before normal AI-interpreter use.
- OpenAI request shape is covered by deterministic tests.
- Structured output decoding, HTTP errors, refusals, and reasoning/non-message items are covered by tests.
- Async provider output can run through Test Lab and generate normal `SandboxReport` values.
- Full existing Test Lab suite remains green on GitHub Actions.
