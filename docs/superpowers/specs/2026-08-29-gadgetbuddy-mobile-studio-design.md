# GadgetBuddy Mobile Studio — Design Specification

Date: 2026-08-29
Status: Approved design sections 1–4; implementation not started
Target: Samsung Galaxy A54 first
Product: Android-first offline music production workstation

## 1. Product goals and fixed constraints

GadgetBuddy Mobile Studio is a standalone Android music creation environment inspired by fast pattern-based workflows, but it is not dependent on KORG Gadget. The Android app must create, play, edit, save, reopen and export projects on-device.

Fixed constraints:

- Android-first; optimize the first release for Samsung Galaxy A54.
- Native Android architecture rather than React Native as the primary runtime.
- Zero-cost development from project start until commercial publication.
- Offline-first: core music creation must work without internet access.
- No paid DSP, cloud, backend, AI or sync dependency in the development/private-beta phase.
- Ableton Link is explicitly deferred. The architecture reserves a sync-provider boundary so Link can be added later without rewriting the sequencer.
- The app must remain usable if optional AI, MIDI, storage or future network integrations fail.

## 2. Technical architecture

The primary stack is:

- Kotlin for Android application/domain code.
- Jetpack Compose for the UI.
- C++ through the Android NDK for real-time audio processing.
- Oboe/AAudio for low-latency output.
- Android MIDI APIs for USB, BLE and virtual MIDI.
- Local storage and Storage Access Framework for project import/export.

The system is modular:

- `:app` — lifecycle, navigation and dependency wiring.
- `:ui-core` — Compose design primitives.
- `:feature-sequencer`
- `:feature-drum-machine`
- `:feature-mixer`
- `:feature-projects`
- `:feature-settings`
- `:domain-music` — project, song, track, clip, note and musical-time contracts.
- `:engine-api` — Kotlin-facing audio-engine contract.
- `:engine-native` — C++, Oboe, scheduler, instruments, mixer and DSP.
- `:midi`
- `:storage`
- `:ai-core`
- `:controller-mapping`
- `:testlab`

The UI and business layers must never perform work directly on the real-time audio callback. Commands cross a bounded queue into the native engine.

## 3. Real-time audio foundation

The native engine uses one output stream and performs its own mixing. The real-time callback must not perform file I/O, networking, blocking synchronization, UI work, AI inference or unbounded allocation.

The initial engine contains:

- master audio callback;
- sample-accurate transport clock;
- sequencer scheduler;
- voice manager;
- drum sample playback;
- mixer;
- offline rendering boundary reserved for later work.

Two explicit time domains are maintained:

1. Musical time: bars, beats and ticks, with PPQ = 960.
2. Audio time: absolute sample positions at the active sample rate.

A central `TempoMap` converts musical positions to exact sample positions. This contract is required for future automation, tempo changes, MIDI clock and external sync.

## 4. Galaxy A54 performance profile

Galaxy A54 is the first reference device. On first diagnostic run, the app records a `DeviceProfile` containing:

- native sample rate;
- frames per burst;
- buffer capacity;
- smallest measured stable buffer;
- low-latency capability flags;
- CPU architecture/core information;
- memory class;
- callback timing and xrun/underrun statistics.

No latency or voice-count values are hard-coded as facts before measurement. Alpha testing determines the stable operating profile on the physical device.

## 5. DAW domain model

Canonical hierarchy:

`Project -> Song -> Tracks / Scenes / Clips / Mixer / Automation / ControllerMappings`

Initial track types:

- Drum Track
- Sampler Track
- Synth Track
- MIDI Track

Step sequencer and piano roll are different editors over the same event model rather than independent sequencers.

Core note representation includes:

- note;
- velocity;
- startTick;
- durationTicks;
- probability;
- microOffset;
- MIDI channel.

Every persistent entity uses stable identifiers so undo/redo, AI editing, project interchange and future collaboration can operate safely.

## 6. Command/state model

`ProjectState` is the single source of truth. UI, AI and MIDI do not mutate project state through separate mechanisms.

All edits are expressed as domain commands such as:

- `AddTrack`
- `DeleteTrack`
- `SetTempo`
- `SetStep`
- `MoveNote`
- `ChangeVelocity`
- `SetMixerGain`
- `LoadSample`

The same command boundary is used by manual UI edits, controller mappings and AI-generated changes. This permits deterministic undo/redo and prevents AI from bypassing project validation.

AI changes follow `propose -> preview -> apply`, and an applied AI edit must be undoable.

## 7. Alpha 0.1 scope

Alpha 0.1 is deliberately narrow and must be a real playable instrument.

It contains:

- low-latency native audio foundation;
- internal transport and BPM control;
- four-voice drum machine: kick, snare, closed hat and open hat;
- 16-step pattern editor;
- per-step on/off and velocity;
- simple mixer with channel volume, pan, mute, solo and master level as implementation progresses within the milestone;
- local project save/load;
- crash-safe save/recovery foundation;
- performance diagnostics for the Galaxy A54.

The first technical checkpoint must:

1. detect the actual device audio capabilities;
2. open a stable Oboe/AAudio stream;
3. schedule a 16-step pattern sample-accurately;
4. change tempo during playback without restarting the engine;
5. report xrun/underrun and callback metrics;
6. determine a stable buffer profile;
7. run a sustained playback test on-device;
8. save and reopen the same pattern;
9. work without network access or paid dependencies;
10. build reproducibly through CI for APK installation on the reference phone.

## 8. Drum machine, sampler, synth and mixer evolution

Drum machine baseline:

- 16 pads/voices in the full model;
- sample assignment;
- level, pan, pitch, envelope and filter boundaries;
- choke groups reserved for subsequent milestones;
- later probability, ratchets, microtiming, swing and accent.

Sampler progression:

- sample playback;
- root note/pitch;
- ADSR;
- filter;
- later key zones, velocity layers, slicing, reverse and time-stretch.

Synth progression begins with a lightweight two-oscillator subtractive synth using sine, saw, square and triangle waveforms, oscillator mixing, filter, amp envelope and LFO. Voice count and DSP complexity are increased only after A54 performance measurements.

Mixer progression begins with level, pan, mute, solo and master output. Inserts, sends, EQ, compression, delay, reverb and automation follow after the core engine is stable.

## 9. Pattern, scenes and arrangement workflow

Scene mode is implemented before a full arrangement timeline because it delivers a fast electronic-music workflow with lower complexity.

A scene references one clip/pattern per participating track. Multiple scenes allow A/B/C variations and live launching. Arrangement mode later places scenes/clips on a timeline without replacing the underlying event model.

## 10. MIDI and controller mapping

MIDI is a first-class subsystem rather than a late integration. The MIDI router supports notes, CC, pitch bend, aftertouch, program change and transport/sync messages as milestones require.

Controller mapping flow:

`Device detected -> known profile? -> load default map OR MIDI Learn -> ready`

A `ControllerProfile` records manufacturer/model identity, input/output capabilities, default mappings and user overrides.

The design supports layered mappings so the same controller can switch among synth, drum, mixer and scene roles. MIDI Learn binds a selected software parameter to the next recognized physical control event.

Initial hardware profiles are expected later for controllers already relevant to the GadgetBuddy ecosystem, but Alpha 0.1 is not blocked on those profiles.

## 11. Offline-first AI and composition

The core product must not require a paid or cloud LLM.

`SongGenerationProvider` is an abstraction with an always-available local path. The offline composition engine is deterministic/generative music logic containing:

- rhythm generator;
- bass generator;
- melody generator;
- chord/harmony generator;
- arrangement generator;
- variation engine;
- humanization engine.

Natural-language support starts with a deterministic parser for common music concepts such as BPM, key, genre, mood and operation verbs. More advanced local models or cloud providers may be added later as optional providers, but project creation remains functional without them.

The existing GadgetBuddy `SongCommand`/Command Interpreter/Challenger concepts are treated as prior-art contracts to adapt, not as a requirement to retain the Swift implementation inside Android.

## 12. Sync strategy

The sequencer depends on a `SyncProvider` interface rather than a specific external technology.

Planned providers:

- `InternalClock` — V1;
- `MIDIClock` — later milestone;
- `AbletonLink` — future optional integration.

Ableton Link is not part of Alpha or initial zero-cost development requirements.

## 13. Persistence and project interchange

Working state is saved locally first. Saves must be crash-safe through temporary-file write, validation and atomic replacement where supported. Recovery keeps at least a current, previous and recoverable state strategy.

The canonical portable project format is `.gbuddy`, versioned from its first release. Conceptual package contents:

- `manifest.json`
- `project.json`
- `assets/`
- `presets/`
- `metadata/`

Projects can later export:

- MIDI;
- WAV mixdown;
- WAV stems;
- portable `.gbuddy` package.

The format is platform-independent so future macOS/iPad clients can exchange projects over files, USB, LAN or optional cloud without changing the Android project model.

KORG Gadget, Ableton Live and other DAWs are future export/integration destinations, not dependencies of the core Android product.

## 14. Reliability and failure isolation

A subsystem failure must not destroy the session.

Expected behavior examples:

- audio route loss -> stop/recover engine cleanly;
- missing sample -> mark affected asset/track unavailable while opening the project;
- unsupported sample -> reject the sample without corrupting the project;
- AI generation failure -> leave current song untouched;
- MIDI disconnect -> playback continues.

## 15. Test Lab and quality gates

Android Test Lab carries forward the existing GadgetBuddy philosophy of deterministic evidence and adversarial validation.

Required suites:

- domain contract tests;
- sequencer/musical-time tests;
- sample-accuracy timing tests;
- DSP/native tests;
- persistence/recovery tests;
- JNI/engine API contract tests;
- Compose UI tests;
- regression fixtures;
- physical-device performance benchmark.

A representative timing invariant at 48 kHz and 120 BPM is that quarter-note boundaries occur exactly every 24,000 samples when tempo is constant. Equivalent tests are generated across supported tempos and buffer sizes.

## 16. Release progression

Planned progression:

- Alpha 0.1 — audio, drum machine, 16-step sequencer, mixer foundation, save/load.
- Alpha 0.2 — piano roll, sampler, MIDI.
- Alpha 0.3 — synth, controller mapper, MIDI Learn.
- Alpha 0.4 — scenes, local composition engine, AI command layer.
- Alpha 0.5 — arrangement, automation, effects.
- Beta 0.8 — export, project packaging, stability/performance pass.
- Beta 0.9 — full A54 QA, UX polish, recovery, battery and thermal testing.
- 1.0 candidate — commercial-readiness review.

Commercial publication is the first stage where project policy permits unavoidable publication costs or optional paid services to be evaluated.

## 17. Repository strategy

The intended implementation repository is a separate project named `GadgetBuddy-Mobile-Studio`.

The current `GadgetBuddy-Studio-Ai` repository remains the Swift/KORG-assistant codebase and source of proven Command Interpreter, Challenger and Test Lab concepts. This design specification is temporarily stored here so the architecture can be reviewed and versioned before implementation begins. The Android implementation should move to its dedicated repository before production coding.

## 18. Architecture ownership boundaries

Specialist ownership is divided across:

- Product/Architecture
- Android Platform
- Realtime Audio/DSP
- Sequencer/Musical Time
- Instruments
- MIDI/Hardware
- AI/Composition
- Storage/Interchange
- UX/Compose
- Performance
- Test Lab/Challenger
- Release/Security

The audio-thread contract, project schema, musical-time model and command model are architecture-level interfaces. Changes to them require explicit architecture review because multiple subsystems depend on them.

## 19. Definition of design completion

The design is complete when the approved architecture, Alpha 0.1 scope, offline/zero-cost constraints, persistence model, timing model, subsystem boundaries, project interchange and release progression are all explicit enough to create an implementation plan without inventing product requirements.
