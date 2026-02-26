# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added

- Initial SwiftPM macOS app scaffold (`Core + App + Tests`)
- Menu bar app skeleton and packaging scripts
- PRD preserved at `docs/PRD.md`
- Camera permission + camera capture + Vision hand pose pipeline
- Head gesture detection (`nod` / `shake`) based on face motion trajectory
- Timestamped runtime logging with in-app log viewer and "Open Log File" action
- Chinese README (`README.zh-CN.md`), `AGENT.md`, and `CLAUDE.md`
- GitHub Actions workflow for date-based release packaging, tagging, and GitHub Release publishing

### Changed

- Permissions actions moved from top-level menu into `Open Settings...`
- Menu and settings permission summaries refresh in real time
- Runtime logs now use per-session files under `~/Library/Logs/VibePilot/Sessions/`
- Existing saved bindings are merged with new defaults so newly added gestures receive default bindings
