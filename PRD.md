# PRD: Clack (macOS Menu Bar App)

## Product Summary
Clack is a minimal, native macOS menu bar app that turns typing into ambient, musical output. When enabled, every keypress plays notes from a chosen scale, creating a soft, spacy atmosphere while users work in any app.

## Goals
- Let users create music while typing without interrupting their workflow.
- Deliver an Apple-quality, minimal UI that feels native.
- Keep setup friction near zero: toggle, select scale, select sound.

## Non-Goals (v1)
- Arpeggio mode (future feature).
- Recording/exporting audio or MIDI.
- Auto-launch on login.
- Advanced synth/editor.

## Target Users
Anyone who wants ambient, musical feedback while typing (writers, coders, designers, students, etc.).

## Core Experience (MVP)
1. User toggles Clack On via menu bar switch or hotkey `⌥⌘M`.
2. Typing in any app generates musical notes.
3. Notes are chosen from a user-selected key + scale.
4. Each word produces a consistent melody (word-based hashing).
5. Sound is a selectable Rhodes-style instrument with delay/reverb.

## Key Features

### 1) Menu Bar App
- No Dock icon, no window by default.
- Menu includes:
  - Toggle On/Off
  - Key selector
  - Scale selector
  - Sound selector
  - Delay Mix slider
  - Reverb Mix slider
  - Shortcut display/edit
  - Quit

### 2) Scale Settings
- Key (root note) selector
- Scale type:
  - Major
  - Minor
  - Major Pentatonic
  - Minor Pentatonic
  - Dorian
  - Mixolydian
  - Blues
- Default: A minor pentatonic

### 3) Word-Based Melody Mapping
- Every word generates a consistent melody.
- Notes are selected by hashing the word into a sequence of notes within the chosen scale.
- Different words yield different melodies, same word yields same melody.

### 4) Expressiveness
- Volume/velocity varies with key repeat speed.
- Faster typing = stronger intensity.

### 5) Sound Engine (v1)
Selectable instruments:
- Spacey Rhodes
  - Longer delay/reverb
  - Ambient wash
- Tight Rhodes
  - Minimal delay
  - Clearer melodic definition

Effects (always on):
- Delay Mix (wet/dry)
- Reverb Mix (wet/dry)

### 6) Privacy & Security
- No keystroke logging or storage.
- Audio is generated locally only.
- Disabled in secure fields (password inputs).

### 7) Distribution
- Target: Mac App Store.

## Performance & Quality Targets
- Latency: imperceptible.
- Stability: no crashes, no UI lag.
- Audio should feel smooth even under fast typing.

## Out of Scope (Future Ideas)
- Arpeggio mode
- Layered instruments
- Sound packs
- Recording/export
- Auto-launch at login
