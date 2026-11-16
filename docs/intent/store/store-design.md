---
parent: high-level-design
prefix: STORE
---

# Store

## Context and Design Philosophy

The store is where milestones live between launches, and the one thing the app process
and the widget extension process have in common at runtime. Its job is narrow: persist
milestones, and hand them back as `Milestone` values. It knows nothing about counting or
drawing.

Two rules shape it. The store is the **only** place the persisted form of a milestone is
visible; everything else works on values. And there is **one writer**: the app. The
widget extension reads.

Code: `Packages/DaysUntilCore/Sources/DaysUntilCore/MilestoneRecord.swift` and
`MilestoneStore.swift`.

## Persisted form

`MilestoneRecord` is a SwiftData model with the same fields as the `Milestone` value.
`id` is unique in the store.

- A record is created from a value.
- A record yields a value (`snapshot`).
- A record can **apply** a value: every editable field is copied from it. `id` and
  `createdAt` are identity and are never changed by applying, whatever the value says.

## Location

The store is a single file, `DaysUntil/Milestones.store`, inside the **App Group
container** named by the `AppGroupIdentifier` key in the running bundle's Info.plist.
Both the app and the widget extension carry that key with the same value and the
matching App Group entitlement, so both resolve to the same file.

When the process has no App Group container (an unsigned build, or the package's own
test runner), the store falls back to the same relative path under Application Support.
That keeps development and test builds working; such a build's app and widgets would not
share data, which is acceptable because unsigned builds are not installed.

An in-memory store is available for tests.

## Reading

- **All milestones**: every record as a value, in display order (see Counting), with
  archived milestones left out unless asked for.
- **One milestone by id**: the value, or nothing. This does not filter archived
  milestones; callers decide what an archived result means.

Each read uses a fresh context on the shared container, so a long-lived process (the
widget extension) sees what the app has saved since the process started.

## Writing

Writing is done by the app window through SwiftData's model context: insert a record,
apply a value to a record, delete a record, then save. The store component defines the
record and its apply rule; the sequence of writes belongs to the App window.

## Failure

Opening the store can fail (unreadable file, no disk space, incompatible schema).
The store reports the failure to its caller and does not retry, delete or recreate
anything. Each caller decides what to show: the app window shows an error in place of
its grid; widgets show a message that milestones could not be loaded.

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|----------|--------|------------------------|-----------|
| Persistence technology | SwiftData | A JSON file in the container; Core Data directly; UserDefaults in the App Group | Gives the app live queries for its grid and a schema with a migration path, for a handful of fields. A JSON file would be simpler for the reader but would need its own change notification and write coordination. |
| What crosses the boundary | `Milestone` values | The SwiftData record | Records are bound to a context and are not `Sendable`; values can be handed to widget timelines and tests freely. |
| Identity under edit | Applying never changes `id` or `createdAt` | Copy every field | A widget's configuration points at the id, and progress falls back to `createdAt`; an edit must not silently retarget either. |
| Sharing between processes | One file in the App Group container, extension read-only | The app exporting a snapshot for the extension | A single file cannot disagree with itself, and a single writer removes concurrent-write questions. |
| No-container fallback | Application Support | Fail to open | Lets tests and unsigned compile checks run without signing. |
| Failure handling | Report to caller, change nothing | Delete and recreate the store | Silently discarding someone's milestones is worse than an error screen. |

## Open Questions & Future Decisions

### Deferred

1. There is one schema version and no migration plan. The first change to the record's
   fields needs a decision on how existing stores are migrated, and on which process
   performs it.
2. There is no export, import or backup of milestones. A person moving to a new Mac
   brings them only if the App Group container is migrated with their account.
3. "One writer" is a rule the widget extension follows, not one the store enforces: both
   processes open the file read-write, and whichever runs first creates it.
4. The Application Support fallback is known to apply when the bundle has no
   `AppGroupIdentifier` key (the package's test runner). Whether macOS reports "no
   container" for a signed build whose entitlement does not grant the group, or returns a
   path that then fails to open, has not been established.
5. Inserting a record whose `id` already exists has no defined behaviour here. The app
   never does it: edits apply to the existing record and duplicates get a new id.
6. That a fresh context in the extension sees the app's latest save has been confirmed by
   use, not by a test; the only automated store test is in-memory and single-process.

## References

- `docs/high-level-design.md` — key decisions on the shared store and signing.
- `project.yml` — the App Group identifier and entitlements for both targets.
