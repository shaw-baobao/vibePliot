# VibePilot

[English](README.md) | [简体中文](README.zh-CN.md)

VibePilot is a macOS menu bar app for `vibe coding`: it detects hand gestures with the camera and maps them to keyboard/mouse actions for hands-free control.

This repository is organized as an open-source SwiftPM project (inspired by the structure of [`dorso`](https://github.com/tldev/dorso)):

- SwiftPM project layout (`Core + App + Tests`)
- Menu bar app entry point
- Camera permission + camera capture + Vision hand pose pipeline
- Gesture recognition pipeline (`OK` / `Fist` / `OpenPalm`) with debounce/cooldown
- Input injection (`CGEvent`) for keyboard/mouse actions
- Packaging scripts in `Scripts/` (build a `.app`)
- Basic OSS docs (`PRIVACY.md`, `CHANGELOG.md`, `LICENSE`)

## Quick Start

### Requirements

- macOS 13+
- Xcode Command Line Tools (`xcode-select --install`)

### Run Locally

```bash
swift build
swift test
Scripts/dev.sh
```

### Package `.app`

```bash
Scripts/package_app.sh
open build/VibePilot.app
```

Note: this is a menu bar app, so launching it will not show a Dock icon by default.

## Permissions

VibePilot uses:

- `Camera` (required for gesture detection)
- `Accessibility` (required for keyboard/mouse event injection)

It does **not** require screen recording permission for the current MVP path.

## Project Structure

```text
vibePilot/
├── Package.swift
├── README.md
├── README.zh-CN.md
├── docs/
│   └── PRD.md
├── Scripts/
│   ├── dev.sh
│   ├── package_app.sh
│   ├── release.sh
│   └── version.env
├── Sources/
│   ├── App/
│   │   ├── VibePilotMain.swift
│   │   └── AppDelegate.swift
│   └── VibePilotCore/
│       ├── Shared/
│       ├── Camera/
│       ├── Vision/
│       ├── Gesture/
│       ├── Binding/
│       ├── Input/
│       ├── Permissions/
│       ├── Persistence/
│       ├── MenuBar/
│       └── UI/
└── Tests/
    └── VibePilotCoreTests/
```

## Current Status

- Working MVP pipeline: camera permission -> camera frames -> Vision hand pose -> gesture classification -> optional input injection
- Menu bar status and permission summaries are visible in the app menu
- Settings UI is still a lightweight scaffold (display-first, not a full editor yet)

## Documentation

- PRD: `docs/PRD.md`
- Privacy: `PRIVACY.md`

## License

MIT (see `LICENSE`)
