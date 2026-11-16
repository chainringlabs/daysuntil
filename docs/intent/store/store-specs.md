# Store — Specs

Design: `store-design.md`. Prefix: `STORE`.

Markers: `[x]` implemented with a test, `[ ]` active gap, `[D]` deferred. Specs ending
*(by hand)* describe behaviour that depends on signing or the file system and are
verified manually, not by an automated test.

"The store" is the SwiftData store of milestones shared by the app and the widget
extension. A "milestone value" is the `Milestone` struct; a "record" is its persisted
form.

- [x] **STORE-001**: When a record is created from a milestone value and read back, the store shall return a milestone value equal to the original in every field.
- [x] **STORE-002**: When a milestone value is applied to an existing record, the store shall copy every field except `id` and `createdAt`, which shall keep the record's existing values.
- [x] **STORE-003**: When all milestones are read without asking for archived ones, the store shall omit every milestone whose `isArchived` is true.
- [x] **STORE-004**: When all milestones are read, the store shall return them in display order (upcoming soonest first, then past most recent first) for the supplied now.
- [x] **STORE-005**: When one milestone is read by id, the store shall return it whether or not it is archived, and shall return nothing when no record has that id.
- [x] **STORE-006**: Where an in-memory store is requested, the store shall keep nothing on disk.
- [x] **STORE-007**: If the running bundle's Info.plist has no `AppGroupIdentifier` value, then the store shall locate its file at `DaysUntil/Milestones.store` under the user's Application Support directory.
- [x] **STORE-008**: Where the running bundle's Info.plist has an `AppGroupIdentifier` value and the process has that App Group's container, the store shall locate its file at `DaysUntil/Milestones.store` inside that container, so that the app and the widget extension open the same file. *(by hand)*
- [x] **STORE-009**: If the store cannot be opened, then the store shall report the failure to its caller and shall not delete, replace or recreate the store file. *(by hand)*
- [x] **STORE-010**: Each read of the store shall use a new context, so that a long-running process sees changes saved by another process since it started. *(by hand)*
