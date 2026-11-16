# DaysUntil

## Overview

Native macOS app for tracking countdown and count-up milestones, each placeable on the
desktop as a WidgetKit widget (number, bar, ring or dot-grid style). Local-only: no
network, no sync. Design intent lives in `docs/` (see Linked-Intent Development below).

## Tech Stack

- Language: Swift 6 (strict concurrency)
- UI: SwiftUI, WidgetKit, App Intents (widget configuration)
- Storage: SwiftData, in the App Group container shared by app and widget extension
- Project: XcodeGen (`project.yml`); the `.xcodeproj` is generated and git-ignored
- Tests: Swift Testing, in the local package
- Target: macOS 27, Xcode 27

## Commands

- `make run` — build and launch the debug app
- `make build` — debug build of app + widget extension (regenerates the project)
- `make test` — package tests (date math, store, render smoke tests)
- `make lint` / `make format` — SwiftFormat + SwiftLint
- `make check` — lint, test, build; run before every commit
- `make gallery` — render all styles and sizes to `.build/gallery` for a visual check
- `make install` — release build synced into /Applications

## Architecture

- `Packages/DaysUntilCore/Sources/DaysUntilCore` — no UI imports. `Milestone` is the
  plain `Sendable` value everything works on; `MilestoneRecord` is its SwiftData form
  and only the store layer and the app's `MilestoneEditing` touch it. `CalendarDay` is
  what an all-day date is; `Countdown` holds all date and progress math; `DotGrid`
  buckets long spans; `RefreshSchedule` says when widget timelines need new entries.
- `Packages/DaysUntilCore/Sources/DaysUntilUI` — `MilestoneFace` draws a milestone in a
  `FaceStyle` at a `FaceSize` with no background; widgets put it over a container
  background, the app wraps it in `MilestoneCard`. Faces read `widgetRenderingMode`
  and fall back to `primary` colours when the system tints or dims a widget.
- `App/` — single `Window`. `MilestoneGridView` queries records and shows cards;
  `MilestoneEditor` is the add/edit sheet with a live preview. Every write goes through
  `MilestoneEditing`, which saves and calls `WidgetCenter.reloadAllTimelines()`.
- `Widgets/` — `MilestoneWidget` (configurable via `MilestoneWidgetIntent`: milestone
  and style) and `UpcomingWidget` (list). `WidgetStore` is the extension's read-only
  access to the shared store.

## Conventions

- New files must be added nowhere by hand: XcodeGen picks up everything under `App/`
  and `Widgets/`. Run `make generate` (or any build target) after adding files.
- `App/Info.plist`, `Widgets/Info.plist` and the `.entitlements` files are written by
  XcodeGen from `project.yml`. Edit `project.yml`, not those files.
- Date logic goes in `DaysUntilCore` with a test using `Fixture.calendar` (fixed time
  zone); never call `Calendar.current` inside a test.
- An all-day milestone's dates are calendar days: stored as 00:00 UTC of the day, read
  back by UTC year-month-day (`CalendarDay`), and counted in whole calendar days. Never
  write a local instant into an all-day date; go through `Milestone.storedDate(forLocal:)`.
- Decisions that views would otherwise make live in Core where they are tested:
  `WidgetContent` / `UpcomingContent` (what a widget shows), `EditorRules` (the editor).
- Signing is manual, Apple Development certificate, no provisioning profile. Do not add
  entitlements that need a profile (iCloud, push, `group.`-prefixed App Groups) without
  discussing it first; see README "Signing".
- Themes must pass the contrast tests in `MilestoneAndThemeTests` (ink 4.5:1, ink at
  `Theme.secondaryTextOpacity` 4.5:1, accent 3:1). Dimmed text uses that one opacity only.
- Files stay under 300 lines, functions under 50 (SwiftLint enforces both).

## Environment Variables

None are required. `DAYSUNTIL_RENDER_DIR` is optional: when set, the render tests write
PNGs of every face to that directory (`make gallery` sets it).

## LID
- Mode: Full
- Version: 1.3.0

## Linked-Intent Development (MANDATORY)

**Consult the `linked-intent-dev` skill for ALL code changes.** All changes flow through the arrow of intent in one direction:

```
HLD → LLDs → EARS → Tests → Code
```

- **New features and refactors**: full six-phase workflow (HLD check → LLD check/draft → EARS → intent-narrowing edge audit → tests-first → code).
- **Bug fixes**: walk the arrow like any other change — find where behavior diverged from intent and cascade from there. No short-circuit.
- **If unsure**: use the full workflow.

Stop after each phase for user review. **Docs carry current intent, written to be read cold** — write each doc as if authored fresh today, from current intent alone: no narration of how it changed, no meaning that needs the conversation that produced it, no rebuttals to questions only a past discussion raised. Rationale, considered alternatives, and constraints a fresh author would independently write stay; record rejected alternatives and why in the LLD's Decisions & Alternatives table, not as asides in body prose.

**Memory vs. intent.** Before saving durable project knowledge to agent or tool memory, test whether it is project *intent* — would a fresh agent, in any tool, next session, need it to build this system correctly? If yes, record it in the arrow (HLD / LLD / EARS / decision doc), which travels and cascades — not in private, per-tool memory, where intent escapes the arrow. Knowledge about the user or how they like to work stays in memory.

### Navigation

| What you need | Where to look |
|---|---|
| High-level design | `docs/high-level-design.md` |
| Design tree (sub-HLDs, LLDs, their specs) | `docs/intent/` — one folder per node |
| EARS specs | beside each design doc as `{node}-specs.md` in the node's folder under `docs/intent/` |
| Decision docs | `docs/decisions/` (project-level) and `docs/intent/<segment>/decisions/` |

### Terminology

- **HLD**: High-Level Design — single project-level doc at `docs/high-level-design.md`.
- **LLD**: Low-Level Design — detailed component design doc in `docs/intent/`. The design layer is a recursive tree: the root is the HLD, leaf LLDs own EARS, and a component deep enough to outgrow one doc becomes a sub-HLD (HLD-shaped, owns no EARS) with children beneath it. "HLD" and "LLD" are roles by position; depth-2 (one HLD over flat leaf LLDs) is the default.
- **EARS**: Easy Approach to Requirements Syntax — structured one-line requirements beside each design doc as `{node}-specs.md` in the node's folder under `docs/intent/`. IDs are path-concatenated — the root-to-leaf path of the owning segment plus a number — so a prefix grep gathers a subtree. Markers: `[x]` implemented, `[ ]` active gap, `[D]` deferred.
- **Arrow**: the unidirectional chain from vision to code (HLD → LLDs → EARS → Tests → Code). Strictly a DAG of intent.
- **Arrow segment**: the territory owned by one leaf LLD — the LLD itself plus the specs, tests, and code that cite its EARS IDs. The boundary is the leaf prefix. Within-segment cascade is free; across-segment cascade pauses.
- **Cascade**: propagating a change downstream through the arrow so adjacent levels stay coherent.

### Code annotations

Annotate code and tests with `@spec` comments citing EARS IDs:

```
// @spec AUTH-UI-001, AUTH-UI-002
```

Place the annotation at the *entry point of the behavior's implementation graph* — the topmost function or module owning the specified behavior, not every helper. When a behavior spans multiple subsystems (UI + API + database, for example), annotate at the entry point in each subsystem. Tests follow the same rule: annotate the test that directly exercises the spec, not every inner assertion.
