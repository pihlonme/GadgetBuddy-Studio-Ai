# GadgetBuddy Mobile Studio Alpha 0.1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a reproducible, installable Android Alpha 0.1 that runs a stable low-latency four-voice drum machine with a 16-step sequencer, mixer controls, crash-safe local save/load, and measurable performance diagnostics on the Samsung Galaxy A54.

**Architecture:** Native Android application code is Kotlin + Jetpack Compose. Real-time scheduling, sample playback and mixing live in C++ and are connected through a deliberately narrow JNI boundary to an `AudioEngine` Kotlin interface. Musical state is immutable and command-driven; the native engine receives compact snapshots/commands and never calls UI, file, network or AI code from its audio callback.

**Tech Stack:** Android Gradle Plugin 9.3.0; Gradle 9.5.0; JDK 17; Kotlin 2.3.21; compileSdk 37; targetSdk 36; minSdk 29; NDK 29.0.14206865; CMake 3.22.1; Jetpack Compose BOM 2026.08.00; AndroidX Activity Compose 1.13.0; AndroidX Core KTX 1.19.0; Lifecycle 2.11.0; kotlinx.coroutines 1.11.0; kotlinx.serialization 1.11.0; Oboe 1.10.0 via Google Maven Prefab.

**Spec:** `docs/superpowers/specs/2026-08-29-gadgetbuddy-mobile-studio-design.md`

## Global Constraints

- Android-first; optimize the first release for Samsung Galaxy A54.
- Zero-cost development from project start until commercial publication.
- Offline-first; Alpha 0.1 must not require internet access at runtime.
- No paid DSP, cloud, backend, AI or sync dependency.
- Ableton Link is not part of Alpha 0.1.
- Real-time callback must not perform file I/O, networking, blocking synchronization, UI work, AI inference or unbounded allocation.
- One output stream; all voices are mixed in the native engine.
- Musical time uses PPQ = 960 and is converted to absolute sample positions.
- Persistent project schema starts at version 1 and must be recoverable after interrupted writes.
- Implementation target repository: `pihlonme/GadgetBuddy-Mobile-Studio`.

## Execution Precondition

The implementation repository must exist before production code starts. Create an empty **private** GitHub repository named `GadgetBuddy-Mobile-Studio` under `pihlonme`, with no generated README, license or `.gitignore`. The current ChatGPT GitHub connector can write to repositories but cannot create a new repository; this is the only manual repository-creation step.

## Locked File Structure

```text
GadgetBuddy-Mobile-Studio/
├── .github/workflows/android-ci.yml
├── .gitignore
├── README.md
├── settings.gradle.kts
├── build.gradle.kts
├── gradle.properties
├── gradle/libs.versions.toml
├── gradle/wrapper/gradle-wrapper.properties
├── app/
│   ├── build.gradle.kts
│   └── src/main/java/com/pihlonme/gadgetbuddy/mobilestudio/
│       ├── GadgetBuddyApplication.kt
│       ├── MainActivity.kt
│       └── StudioApp.kt
├── domain-music/
│   └── src/main/kotlin/com/pihlonme/gadgetbuddy/domain/
│       ├── MusicalTime.kt
│       ├── ProjectState.kt
│       ├── DrumPattern.kt
│       ├── MixerState.kt
│       └── ProjectCommand.kt
├── engine-api/
│   └── src/main/kotlin/com/pihlonme/gadgetbuddy/engine/api/
│       ├── AudioEngine.kt
│       ├── EngineModels.kt
│       └── EngineSnapshots.kt
├── engine-native/
│   ├── build.gradle.kts
│   └── src/main/cpp/
│       ├── CMakeLists.txt
│       ├── JniBridge.cpp
│       ├── OboeAudioEngine.cpp
│       └── OboeAudioEngine.h
├── native/
│   ├── CMakeLists.txt
│   ├── core/include/gadgetbuddy/
│   │   ├── MusicalClock.h
│   │   ├── DrumPattern.h
│   │   ├── SampleBank.h
│   │   └── Mixer.h
│   ├── core/src/
│   │   ├── MusicalClock.cpp
│   │   ├── SampleBank.cpp
│   │   └── Mixer.cpp
│   └── tests/
│       ├── MusicalClockTest.cpp
│       ├── SampleBankTest.cpp
│       └── MixerTest.cpp
├── storage/
│   └── src/main/kotlin/com/pihlonme/gadgetbuddy/storage/
│       ├── ProjectFileV1.kt
│       └── ProjectStore.kt
├── feature-studio/
│   └── src/main/kotlin/com/pihlonme/gadgetbuddy/studio/
│       ├── StudioViewModel.kt
│       ├── StudioScreen.kt
│       ├── StepGrid.kt
│       ├── MixerPanel.kt
│       └── DiagnosticsPanel.kt
├── ui-core/
│   └── src/main/kotlin/com/pihlonme/gadgetbuddy/ui/
│       └── GadgetBuddyTheme.kt
└── docs/
    └── alpha-0.1-a54-test-protocol.md
```

---

### Task 1: Bootstrap the dedicated Android repository and CI skeleton

**Files:**
- Create: root Gradle files, version catalog, wrapper configuration, `.gitignore`, `README.md`
- Create: `app`, `domain-music`, `engine-api`, `engine-native`, `storage`, `feature-studio`, `ui-core` module build files
- Create: `.github/workflows/android-ci.yml`

**Interfaces:**
- Produces: a buildable empty Android application with package `com.pihlonme.gadgetbuddy.mobilestudio` and all Alpha 0.1 modules wired.
- Produces: `./gradlew :app:assembleDebug` as the canonical APK build command.

- [ ] **Step 1: Add version catalog and root plugin declarations**

Create `gradle/libs.versions.toml` with these exact pins:

```toml
[versions]
agp = "9.3.0"
kotlin = "2.3.21"
composeBom = "2026.08.00"
activityCompose = "1.13.0"
coreKtx = "1.19.0"
lifecycle = "2.11.0"
coroutines = "1.11.0"
serialization = "1.11.0"
oboe = "1.10.0"

[libraries]
androidx-core-ktx = { module = "androidx.core:core-ktx", version.ref = "coreKtx" }
androidx-activity-compose = { module = "androidx.activity:activity-compose", version.ref = "activityCompose" }
androidx-lifecycle-runtime-compose = { module = "androidx.lifecycle:lifecycle-runtime-compose", version.ref = "lifecycle" }
androidx-lifecycle-viewmodel-compose = { module = "androidx.lifecycle:lifecycle-viewmodel-compose", version.ref = "lifecycle" }
compose-bom = { module = "androidx.compose:compose-bom", version.ref = "composeBom" }
compose-ui = { module = "androidx.compose.ui:ui" }
compose-ui-tooling-preview = { module = "androidx.compose.ui:ui-tooling-preview" }
compose-material3 = { module = "androidx.compose.material3:material3" }
compose-ui-test-junit4 = { module = "androidx.compose.ui:ui-test-junit4" }
compose-ui-tooling = { module = "androidx.compose.ui:ui-tooling" }
coroutines-core = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-core", version.ref = "coroutines" }
coroutines-android = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-android", version.ref = "coroutines" }
serialization-json = { module = "org.jetbrains.kotlinx:kotlinx-serialization-json", version.ref = "serialization" }
oboe = { module = "com.google.oboe:oboe", version.ref = "oboe" }

[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }
android-library = { id = "com.android.library", version.ref = "agp" }
kotlin-android = { id = "org.jetbrains.kotlin.android", version.ref = "kotlin" }
kotlin-jvm = { id = "org.jetbrains.kotlin.jvm", version.ref = "kotlin" }
kotlin-serialization = { id = "org.jetbrains.kotlin.plugin.serialization", version.ref = "kotlin" }
compose-compiler = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }
```

- [ ] **Step 2: Configure Android build constants**

Use `compileSdk = 37`, `targetSdk = 36`, `minSdk = 29`, `ndkVersion = "29.0.14206865"`, `cmake.version = "3.22.1"`, Java/Kotlin JVM target 17, and `-DANDROID_STL=c++_shared` in `engine-native`.

`engine-native/build.gradle.kts` must enable Prefab and link Oboe:

```kotlin
android {
    namespace = "com.pihlonme.gadgetbuddy.engine.nativeimpl"
    compileSdk = 37
    ndkVersion = "29.0.14206865"
    buildFeatures { prefab = true }
    defaultConfig {
        minSdk = 29
        externalNativeBuild {
            cmake { arguments("-DANDROID_STL=c++_shared") }
        }
    }
    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }
}

dependencies {
    implementation(project(":engine-api"))
    implementation(libs.oboe)
}
```

- [ ] **Step 3: Add the minimal app and prove Gradle configuration**

Create `MainActivity.kt`:

```kotlin
package com.pihlonme.gadgetbuddy.mobilestudio

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.Text

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { Text("GadgetBuddy Mobile Studio") }
    }
}
```

- [ ] **Step 4: Run the first build**

Run:

```bash
./gradlew :app:assembleDebug
```

Expected: `app/build/outputs/apk/debug/app-debug.apk` exists and the build is green.

- [ ] **Step 5: Commit**

```bash
git add .
git commit -m "build: bootstrap GadgetBuddy Mobile Studio Android project"
```

---

### Task 2: Implement canonical musical time, project state and drum pattern contracts

**Files:**
- Create: `domain-music/src/main/kotlin/com/pihlonme/gadgetbuddy/domain/MusicalTime.kt`
- Create: `ProjectState.kt`, `DrumPattern.kt`, `MixerState.kt`
- Create tests under `domain-music/src/test/kotlin/com/pihlonme/gadgetbuddy/domain/`

**Interfaces:**
- Produces: `const val PPQ: Long = 960`
- Produces: `fun tickToSample(tick: Long, bpm: Double, sampleRate: Int): Long`
- Produces: immutable `ProjectState`, `DrumPattern`, `Step`, `MixerState`, `ChannelMix`.

- [ ] **Step 1: Write failing musical-time tests**

```kotlin
@Test
fun quarterNoteAt120Bpm48kIs24000Samples() {
    assertEquals(24_000L, tickToSample(PPQ, 120.0, 48_000))
}

@Test
fun sixteenthStepIs240Ticks() {
    assertEquals(240L, ticksPerSixteenth())
}
```

- [ ] **Step 2: Run tests and confirm failure**

```bash
./gradlew :domain-music:test
```

Expected: compilation/test failure because the timing API does not exist.

- [ ] **Step 3: Implement the minimal timing model**

```kotlin
package com.pihlonme.gadgetbuddy.domain

import kotlin.math.roundToLong

const val PPQ: Long = 960

fun ticksPerSixteenth(): Long = PPQ / 4

fun tickToSample(tick: Long, bpm: Double, sampleRate: Int): Long {
    require(bpm in 20.0..300.0)
    require(sampleRate > 0)
    val quarterNotes = tick.toDouble() / PPQ.toDouble()
    val seconds = quarterNotes * (60.0 / bpm)
    return (seconds * sampleRate).roundToLong()
}
```

Define four drum lanes and 16 steps:

```kotlin
enum class DrumLane { KICK, SNARE, CLOSED_HAT, OPEN_HAT }

data class Step(val enabled: Boolean = false, val velocity: Int = 100) {
    init { require(velocity in 0..127) }
}

data class DrumPattern(
    val lanes: Map<DrumLane, List<Step>> = DrumLane.entries.associateWith { List(16) { Step() } }
)
```

- [ ] **Step 4: Add invariants for tempo, mixer values and fixed 16-step lanes, then rerun tests**

Run:

```bash
./gradlew :domain-music:test
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add domain-music
git commit -m "feat: define Alpha musical domain model"
```

---

### Task 3: Add command-driven state reduction and engine snapshots

**Files:**
- Create: `domain-music/.../ProjectCommand.kt`
- Create: `engine-api/.../EngineSnapshots.kt`
- Create: `engine-api/.../EngineModels.kt`
- Create: `engine-api/.../AudioEngine.kt`
- Add tests in `domain-music` and `engine-api`

**Interfaces:**
- Consumes: `ProjectState`, `DrumPattern`, `MixerState` from Task 2.
- Produces: `fun ProjectState.reduce(command: ProjectCommand): ProjectState`.
- Produces: `AudioEngine` contract used by JNI and UI.

- [ ] **Step 1: Write reducer tests**

```kotlin
@Test
fun toggleStepChangesOnlyRequestedStep() {
    val before = ProjectState.initial()
    val after = before.reduce(ProjectCommand.ToggleStep(DrumLane.KICK, 4))
    assertTrue(after.pattern.lanes.getValue(DrumLane.KICK)[4].enabled)
    assertFalse(after.pattern.lanes.getValue(DrumLane.SNARE)[4].enabled)
}

@Test
fun setTempoRejectsOutOfRangeValues() {
    assertFailsWith<IllegalArgumentException> {
        ProjectState.initial().reduce(ProjectCommand.SetTempo(500.0))
    }
}
```

- [ ] **Step 2: Confirm tests fail**

```bash
./gradlew :domain-music:test
```

- [ ] **Step 3: Implement commands and reducer**

```kotlin
sealed interface ProjectCommand {
    data class ToggleStep(val lane: DrumLane, val stepIndex: Int) : ProjectCommand
    data class SetStepVelocity(val lane: DrumLane, val stepIndex: Int, val velocity: Int) : ProjectCommand
    data class SetTempo(val bpm: Double) : ProjectCommand
    data class SetChannelLevel(val lane: DrumLane, val level: Float) : ProjectCommand
    data class SetChannelPan(val lane: DrumLane, val pan: Float) : ProjectCommand
    data class SetChannelMute(val lane: DrumLane, val muted: Boolean) : ProjectCommand
    data class SetChannelSolo(val lane: DrumLane, val solo: Boolean) : ProjectCommand
}
```

Reducer requirements: step index `0..15`; BPM `20.0..300.0`; level `0f..1f`; pan `-1f..1f`; velocity `0..127`; return a new immutable state.

- [ ] **Step 4: Define the engine boundary**

```kotlin
interface AudioEngine {
    fun start(): EngineStartResult
    fun stop()
    fun setPlaying(playing: Boolean)
    fun setTempo(bpm: Double)
    fun submitPattern(pattern: DrumPatternSnapshot)
    fun submitMixer(mixer: MixerSnapshot)
    fun loadSample(lane: Int, samples: FloatArray)
    fun metrics(): EngineMetrics
}
```

`EngineMetrics` must contain `sampleRate`, `framesPerBurst`, `bufferSizeInFrames`, `bufferCapacityInFrames`, `xRunCount`, `callbackCount`, and `maxCallbackMicros`.

- [ ] **Step 5: Run tests and commit**

```bash
./gradlew :domain-music:test :engine-api:test
git add domain-music engine-api
git commit -m "feat: add command state model and audio engine contract"
```

---

### Task 4: Build and host-test the sample-accurate native scheduler

**Files:**
- Create: `native/core/include/gadgetbuddy/MusicalClock.h`
- Create: `native/core/src/MusicalClock.cpp`
- Create: `native/tests/MusicalClockTest.cpp`
- Create: `native/CMakeLists.txt`

**Interfaces:**
- Consumes: PPQ = 960 contract.
- Produces: C++ `MusicalClock` that maps ticks/16th steps to absolute sample positions and supports tempo changes without resetting the transport sample counter.

- [ ] **Step 1: Write the failing native timing test**

```cpp
TEST(MusicalClockTest, QuarterNotesAt120Bpm48kAreExact) {
    MusicalClock clock(48000.0, 120.0, 960);
    EXPECT_EQ(clock.sampleForTick(0), 0);
    EXPECT_EQ(clock.sampleForTick(960), 24000);
    EXPECT_EQ(clock.sampleForTick(1920), 48000);
    EXPECT_EQ(clock.sampleForTick(2880), 72000);
}
```

- [ ] **Step 2: Configure host CMake and confirm failure**

Run:

```bash
cmake -S native -B build/native-tests -DGADGETBUDDY_BUILD_TESTS=ON
cmake --build build/native-tests
ctest --test-dir build/native-tests --output-on-failure
```

Expected: compile failure because `MusicalClock` is absent.

- [ ] **Step 3: Implement deterministic conversion**

Core formula:

```cpp
int64_t MusicalClock::sampleForTick(int64_t tick) const {
    const double quarterNotes = static_cast<double>(tick) / static_cast<double>(ppq_);
    const double seconds = quarterNotes * (60.0 / bpm_);
    return static_cast<int64_t>(std::llround(seconds * sampleRate_));
}
```

Add `setTempo(double bpm)` with the same `20..300 BPM` invariant.

- [ ] **Step 4: Add 16th-step and tempo-change tests**

Verify step 0/4/8/12 at 120 BPM map to exact beat boundaries and changing BPM affects future scheduling without changing the current absolute sample position.

Run CTest again; expected PASS.

- [ ] **Step 5: Commit**

```bash
git add native
git commit -m "feat: add sample-accurate native musical clock"
```

---

### Task 5: Integrate Oboe, single-stream callback and JNI bridge

**Files:**
- Create: `engine-native/src/main/cpp/OboeAudioEngine.h`
- Create: `OboeAudioEngine.cpp`, `JniBridge.cpp`, `CMakeLists.txt`
- Create: Kotlin implementation `engine-native/src/main/java/.../NativeAudioEngine.kt`
- Add an Android instrumented JNI smoke test.

**Interfaces:**
- Consumes: `AudioEngine` contract and native `MusicalClock`.
- Produces: a single low-latency stereo output stream with Float PCM callback and no Java/Kotlin calls from `onAudioReady`.

- [ ] **Step 1: Add a failing JNI smoke test**

```kotlin
@Test
fun nativeLibraryLoadsAndMetricsAreReadable() {
    val engine = NativeAudioEngine()
    val result = engine.start()
    assertTrue(result is EngineStartResult.Success)
    val metrics = engine.metrics()
    assertTrue(metrics.sampleRate > 0)
    engine.stop()
}
```

- [ ] **Step 2: Configure Oboe Prefab linking**

`engine-native/src/main/cpp/CMakeLists.txt` must contain:

```cmake
cmake_minimum_required(VERSION 3.22.1)
project(gadgetbuddy_engine)

find_package(oboe REQUIRED CONFIG)
add_library(gadgetbuddy_engine SHARED
    JniBridge.cpp
    OboeAudioEngine.cpp
    ${CMAKE_CURRENT_LIST_DIR}/../../../../../native/core/src/MusicalClock.cpp
    ${CMAKE_CURRENT_LIST_DIR}/../../../../../native/core/src/SampleBank.cpp
    ${CMAKE_CURRENT_LIST_DIR}/../../../../../native/core/src/Mixer.cpp
)
target_include_directories(gadgetbuddy_engine PRIVATE
    ${CMAKE_CURRENT_LIST_DIR}/../../../../../native/core/include
)
target_link_libraries(gadgetbuddy_engine PRIVATE oboe::oboe log android)
```

- [ ] **Step 3: Open one low-latency callback stream**

Required builder configuration:

```cpp
oboe::AudioStreamBuilder builder;
builder.setDirection(oboe::Direction::Output)
       ->setPerformanceMode(oboe::PerformanceMode::LowLatency)
       ->setSharingMode(oboe::SharingMode::Exclusive)
       ->setFormat(oboe::AudioFormat::Float)
       ->setChannelCount(oboe::ChannelCount::Stereo)
       ->setDataCallback(this)
       ->setErrorCallback(this);
```

If Exclusive fails, retry Shared without failing the app. Do not force a non-native sample rate; read the stream's actual `getSampleRate()` and `getFramesPerBurst()` after open.

- [ ] **Step 4: Add metrics and latency tuning**

Construct `oboe::LatencyTuner` after stream creation. Call `tuner->tune()` immediately before returning from each data callback. Track callback count, `getXRunCount()`, current buffer size, buffer capacity, and maximum callback duration using atomics.

- [ ] **Step 5: Build native debug APK, run smoke test on an emulator/device when available, and commit**

```bash
./gradlew :engine-native:assembleDebug :app:assembleDebug
git add engine-native
git commit -m "feat: integrate Oboe audio stream and JNI bridge"
```

---

### Task 6: Add four sample voices and the native mixer

**Files:**
- Create: `native/core/include/gadgetbuddy/SampleBank.h`, `Mixer.h`
- Create: corresponding `.cpp` and tests
- Create: `feature-studio/.../AlphaSampleFactory.kt`
- Connect `NativeAudioEngine.loadSample` JNI method.

**Interfaces:**
- Produces: four in-memory mono Float PCM buffers, one per `DrumLane`.
- Produces: mixer level/pan/mute/solo for four channels plus master level.

- [ ] **Step 1: Write failing native mixer tests**

```cpp
TEST(MixerTest, MutedChannelProducesSilence) {
    Mixer mixer(1);
    mixer.setChannelMute(0, true);
    float left = 1.0f, right = 1.0f;
    mixer.applyChannel(0, left, right);
    EXPECT_FLOAT_EQ(left, 0.0f);
    EXPECT_FLOAT_EQ(right, 0.0f);
}
```

Add tests for level `0.5`, pan `-1/0/+1`, solo priority and master level.

- [ ] **Step 2: Implement `SampleBank` without allocation in the callback**

Samples are copied into owned buffers only from the control thread. Playback state is preallocated per lane before `requestStart()`.

- [ ] **Step 3: Generate zero-license Alpha sounds in Kotlin at the actual stream sample rate**

`AlphaSampleFactory` must generate buffers once at engine startup; the audio callback only reads them. Use deterministic math, for example kick pitch decay:

```kotlin
fun kick(sampleRate: Int): FloatArray {
    val length = sampleRate / 2
    return FloatArray(length) { i ->
        val t = i.toDouble() / sampleRate
        val freq = 45.0 + 95.0 * kotlin.math.exp(-t * 22.0)
        val env = kotlin.math.exp(-t * 10.0)
        (kotlin.math.sin(2.0 * Math.PI * freq * t) * env).toFloat()
    }
}
```

Snare and hats use deterministic seeded noise plus envelopes so builds and tests remain reproducible.

- [ ] **Step 4: Schedule pattern triggers sample-accurately**

For every callback buffer `[startSample, endSample)`, compute which enabled steps have a target sample inside the buffer. Start the corresponding preallocated voice at the exact frame offset, then mix all four channels into the same stereo output buffer.

- [ ] **Step 5: Run native tests and commit**

```bash
cmake -S native -B build/native-tests -DGADGETBUDDY_BUILD_TESTS=ON
cmake --build build/native-tests
ctest --test-dir build/native-tests --output-on-failure
./gradlew :app:assembleDebug
git add native feature-studio engine-native
git commit -m "feat: add four-voice drum sampler and mixer"
```

---

### Task 7: Implement versioned crash-safe local project persistence

**Files:**
- Create: `storage/.../ProjectFileV1.kt`
- Create: `storage/.../ProjectStore.kt`
- Create tests under `storage/src/test/...`

**Interfaces:**
- Consumes: `ProjectState`.
- Produces: `suspend fun save(projectId: String, state: ProjectState)` and `suspend fun load(projectId: String): ProjectState`.
- Produces: files `project.gbuddy`, `project.gbuddy.previous`, `project.gbuddy.tmp` under app-private storage.

- [ ] **Step 1: Write round-trip and interrupted-write tests**

```kotlin
@Test
fun saveLoadRoundTripPreservesPatternAndMixer() = runTest {
    val store = ProjectStore(tempDir)
    val expected = ProjectState.initial().reduce(ProjectCommand.ToggleStep(DrumLane.KICK, 0))
    store.save("alpha", expected)
    assertEquals(expected, store.load("alpha"))
}
```

Add a test where a valid `project.gbuddy` exists and an invalid `.tmp` exists; `load` must return the valid project.

- [ ] **Step 2: Define schema version 1 using kotlinx.serialization**

```kotlin
@Serializable
data class ProjectFileV1(
    val schemaVersion: Int = 1,
    val tempoBpm: Double,
    val pattern: DrumPatternFileV1,
    val mixer: MixerFileV1
)
```

Configure `Json { prettyPrint = false; ignoreUnknownKeys = false; encodeDefaults = true }`.

- [ ] **Step 3: Implement atomic save**

Algorithm: encode -> write `.tmp` -> fsync/close -> validate by decoding `.tmp` -> move existing current to `.previous` -> atomically replace current when supported -> delete stale `.tmp`. On any exception, keep the previous valid current intact.

- [ ] **Step 4: Run storage tests**

```bash
./gradlew :storage:test
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add storage
git commit -m "feat: add crash-safe versioned local project storage"
```

---

### Task 8: Build the playable Compose studio screen and connect state to audio

**Files:**
- Create: `feature-studio/.../StudioViewModel.kt`, `StudioScreen.kt`, `StepGrid.kt`, `MixerPanel.kt`, `DiagnosticsPanel.kt`
- Create Compose UI tests.
- Update `app/StudioApp.kt` and `MainActivity.kt`.

**Interfaces:**
- Consumes: reducer, `AudioEngine`, `ProjectStore`.
- Produces: one-screen Alpha UI with BPM, Play/Stop, 4x16 step grid, channel mixer and diagnostics.

- [ ] **Step 1: Write ViewModel test using a fake engine**

```kotlin
@Test
fun tappingKickStepUpdatesStateAndSubmitsPattern() {
    val fakeEngine = FakeAudioEngine()
    val vm = StudioViewModel(fakeEngine, FakeProjectStore())
    vm.dispatch(ProjectCommand.ToggleStep(DrumLane.KICK, 0))
    assertTrue(vm.state.value.pattern.lanes.getValue(DrumLane.KICK)[0].enabled)
    assertEquals(1, fakeEngine.submittedPatterns.size)
}
```

- [ ] **Step 2: Implement `StudioViewModel`**

`dispatch(command)` must reduce state first, then send only the affected compact snapshot to the engine. Save operations run on `Dispatchers.IO`; no save runs from the audio thread.

- [ ] **Step 3: Implement stable UI semantics**

Every step button must expose test tag `step-<lane>-<index>`, e.g. `step-KICK-0`. Transport buttons use `transport-play` and `transport-stop`. Mixer controls use `mixer-KICK-level`, etc.

- [ ] **Step 4: Add Compose test**

```kotlin
@Test
fun kickStepZeroCanBeEnabled() {
    composeRule.setContent { StudioScreen(state = ProjectState.initial(), onCommand = commands::add) }
    composeRule.onNodeWithTag("step-KICK-0").performClick()
    assertEquals(ProjectCommand.ToggleStep(DrumLane.KICK, 0), commands.single())
}
```

- [ ] **Step 5: Run tests, build APK and commit**

```bash
./gradlew testDebugUnitTest :app:assembleDebug
git add feature-studio app ui-core
git commit -m "feat: add playable Alpha studio UI"
```

---

### Task 9: Add Galaxy A54 diagnostics, soak test and recovery behavior

**Files:**
- Extend: engine metrics and diagnostics UI
- Create: `docs/alpha-0.1-a54-test-protocol.md`
- Add Android device capability reader in `feature-studio` or `app`.

**Interfaces:**
- Produces: `DeviceProfile` containing sample rate, frames per burst, current/capacity buffer frames, xrun count, low-latency feature flags, CPU ABI and memory class.
- Produces: an in-app 10-minute soak test state with pass/fail summary.

- [ ] **Step 1: Write JVM tests for capability-model formatting and soak-test verdict rules**

Pass rule: runtime >= 600 seconds, engine error count = 0, xrun delta = 0 after latency tuner has stabilized for the first 60 seconds. Record a warning rather than fail if Android package feature flags disagree with the actual stream performance mode.

- [ ] **Step 2: Read Android capability hints**

Use `AudioManager.PROPERTY_OUTPUT_SAMPLE_RATE`, `PROPERTY_OUTPUT_FRAMES_PER_BUFFER`, `PackageManager.FEATURE_AUDIO_LOW_LATENCY`, `FEATURE_AUDIO_PRO`, `Build.SUPPORTED_ABIS`, and `ActivityManager.memoryClass`. Treat these as diagnostics only; the active Oboe stream remains the source of truth for actual sample rate and buffer metrics.

- [ ] **Step 3: Implement soak mode**

When started, load a fixed four-lane test pattern, start transport, poll `AudioEngine.metrics()` once per second from a coroutine, and append only bounded summary statistics. Stop automatically at 600 seconds and persist the final diagnostic report locally as JSON.

- [ ] **Step 4: Write the exact physical-device protocol**

`docs/alpha-0.1-a54-test-protocol.md` must require:

```text
1. Install the CI-produced debug APK on Galaxy A54.
2. Disable Bluetooth audio and use phone speaker or wired/USB output for the baseline.
3. Open Diagnostics and record DeviceProfile.
4. Start the default pattern and verify audible kick/snare/closed-hat/open-hat.
5. Change BPM 120 -> 145 -> 90 while playing; playback must not restart.
6. Toggle at least eight steps while playing; no crash or audible stream restart.
7. Move all four channel levels and pans; controls must affect only intended channels.
8. Save project, force-close app, reopen, and verify pattern/BPM/mixer restore exactly.
9. Run 10-minute soak test.
10. Record xrun delta, stable buffer frames, max callback time and any audible glitch.
```

- [ ] **Step 5: Commit**

```bash
git add feature-studio engine-api engine-native docs
git commit -m "feat: add A54 performance diagnostics and soak test"
```

---

### Task 10: Finalize zero-cost CI, APK artifact delivery and Alpha 0.1 acceptance gate

**Files:**
- Finalize: `.github/workflows/android-ci.yml`
- Update: `README.md`
- Add: `docs/alpha-0.1-release-checklist.md`

**Interfaces:**
- Produces: downloadable `gadgetbuddy-mobile-studio-alpha-debug.apk` artifact from GitHub Actions.
- Produces: one binary acceptance decision: Alpha 0.1 passes or remains blocked.

- [ ] **Step 1: Configure CI to minimize free-minute usage**

Workflow triggers: pull requests to `main`, manual `workflow_dispatch`, and pushes to `main`. Use only `ubuntu-latest`, concurrency cancellation for superseded PR runs, Gradle cache, and one job.

Core workflow steps:

```yaml
- uses: actions/checkout@v4
- uses: actions/setup-java@v4
  with:
    distribution: temurin
    java-version: '17'
- uses: android-actions/setup-android@v3
- run: sdkmanager "platforms;android-37" "build-tools;36.0.0" "ndk;29.0.14206865" "cmake;3.22.1"
- uses: gradle/actions/setup-gradle@v4
- run: ./gradlew testDebugUnitTest :app:assembleDebug
- run: cmake -S native -B build/native-tests -DGADGETBUDDY_BUILD_TESTS=ON && cmake --build build/native-tests && ctest --test-dir build/native-tests --output-on-failure
- uses: actions/upload-artifact@v4
  with:
    name: gadgetbuddy-mobile-studio-alpha-debug
    path: app/build/outputs/apk/debug/app-debug.apk
```

- [ ] **Step 2: Verify clean CI from an empty runner cache**

Expected: Gradle tests PASS, native CTest PASS, debug APK artifact uploaded.

- [ ] **Step 3: Run the Galaxy A54 protocol using the CI artifact**

No emulator result can substitute for the physical A54 soak test. Record the report produced in Task 9.

- [ ] **Step 4: Apply the Alpha 0.1 release gate**

Alpha 0.1 is accepted only if all are true:

```text
[PASS] APK installs and launches on Galaxy A54.
[PASS] One Oboe output stream opens and reports real device metrics.
[PASS] Four audible drum voices play through one native mixer.
[PASS] 16-step scheduling is sample-accurate in native tests.
[PASS] BPM changes during playback without stream restart.
[PASS] Mixer level/pan/mute/solo operate correctly.
[PASS] Save/load restores exact state after force-close.
[PASS] 10-minute device soak completes with no engine error and no post-stabilization xrun increase.
[PASS] App core works with airplane mode enabled.
[PASS] No paid service, paid library or commercial license is required.
```

- [ ] **Step 5: Commit the release evidence**

```bash
git add .github README.md docs
git commit -m "ci: finalize Alpha 0.1 APK and acceptance gate"
```

## Plan Self-Review Result

- **Spec coverage:** Alpha 0.1 audio foundation, transport, four-voice drums, 16-step grid, mixer, save/load, recovery, A54 metrics, low-latency tuning, offline operation and reproducible CI are each assigned to explicit tasks.
- **Deferred by design:** piano roll, user sample import, MIDI, synth, controller mapping, scenes, local song generation, arrangement, effects, Ableton Link and commercial release work are not part of Alpha 0.1 and therefore do not appear as implementation tasks here.
- **Type consistency:** Kotlin domain -> engine snapshot -> JNI -> native scheduler naming is fixed by Tasks 2–5; later tasks consume those exact interfaces.
- **Cost check:** every listed dependency is free/open-source for the development/private-beta path; CI uses standard GitHub-hosted Linux runners and is deliberately minimized.
- **Physical-device boundary:** automated tests establish deterministic correctness; only the Galaxy A54 can establish real low-latency stability and therefore remains the final acceptance gate.
