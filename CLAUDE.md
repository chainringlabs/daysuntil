# DaysUntil

## Overview

Native macOS app for tracking countdown and count-up milestones, each placeable on the
desktop as a WidgetKit widget (number, bar, ring or dot-grid style). Local-only: no
network, no sync. The spec and roadmap live in
`~/code/greco-specs/daysuntil/`, not in this repo.

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
  and only the store layer and the app's `MilestoneEditing` touch it. `Countdown` holds
  all date and progress math; `DotGrid` buckets long spans; `RefreshSchedule` says when
  widget timelines need new entries.
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
- All-day milestones count calendar days from start-of-day, never 24-hour blocks.
- Signing is manual, Apple Development certificate, no provisioning profile. Do not add
  entitlements that need a profile (iCloud, push, `group.`-prefixed App Groups) without
  discussing it first; see README "Signing".
- Themes must pass the contrast test in `StoreAndOrderingTests` (ink 4.5:1, accent 3:1).
- Files stay under 300 lines, functions under 50 (SwiftLint enforces both).

## Environment Variables

None are required. `DAYSUNTIL_RENDER_DIR` is optional: when set, the render tests write
PNGs of every face to that directory (`make gallery` sets it).
