# DaysUntil

A native macOS app for keeping track of milestones: things you are counting down to
and things you are counting up from. Each milestone can sit on the desktop as a widget,
drawn as a big number, a progress bar, a ring, or a grid of dots.

Everything is stored locally. The app has no network access, no account and no sync.

## Requirements

- macOS 27 and Xcode 27
- `brew install xcodegen swiftlint swiftformat`
- An Apple Development signing certificate in your keychain (a free Apple ID in
  Xcode's Accounts settings is enough to create one)

## Getting started

```sh
make run        # build and launch the debug app
make install    # build Release and sync it into /Applications
```

The Xcode project is generated from `project.yml` and is not committed. Run
`make generate` and open `DaysUntil.xcodeproj` if you want to work in Xcode.

To add a widget: launch the app once, right-click the desktop, choose
**Edit Widgets**, and find DaysUntil. Right-click a placed widget and choose
**Edit "DaysUntil"** to pick its milestone and style.

## Commands

| Command | What it does |
|---|---|
| `make build` | Debug build of the app and widget extension |
| `make test` | Unit and render tests for the Swift package |
| `make lint` | SwiftFormat and SwiftLint, without changing files |
| `make format` | Apply SwiftFormat |
| `make check` | Lint, test and build: everything CI runs |
| `make gallery` | Render every style and size to PNGs in `.build/gallery` |
| `make icon` | Regenerate the app icon |

## Signing

The project signs with the local **Apple Development** certificate, manual style,
with **no provisioning profile**:

- Nothing expires after 7 days. That limit belongs to provisioning profiles, and the
  app uses no entitlement that needs one: just the sandbox and a team-ID-prefixed App
  Group, which macOS accepts without a profile.
- Xcode does not contact the developer portal at build time.
- The sandbox has no network entitlement, so the app cannot make connections.

To build under a different Apple ID, change `DEVELOPMENT_TEAM` in `project.yml` to
your team ID. The App Group identifier is derived from it.

This setup is for running on your own Macs. Distributing to other people needs
Developer ID signing and notarization, which requires the paid developer program.

## Layout

```
project.yml                  XcodeGen project definition
App/                         macOS app: window, grid, editor
Widgets/                     WidgetKit extension: intent, providers, widget views
Packages/DaysUntilCore/
  Sources/DaysUntilCore/     model, SwiftData store, date math, themes (no UI)
  Sources/DaysUntilUI/       SwiftUI faces shared by the app and the widgets
  Tests/                     Swift Testing suites
scripts/make-icon.swift      draws the app icon
```

The app and the widget extension share one SwiftData store in the App Group
container. The app writes it and reloads widget timelines after every change; the
extension only reads.
