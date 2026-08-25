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

## Run tests

```bash
swift test
```

## Next milestone

Replace the deterministic v0.1 extraction layer with an AI-backed interpreter behind the same stable domain contract, then add the first visual Song Command UI.
