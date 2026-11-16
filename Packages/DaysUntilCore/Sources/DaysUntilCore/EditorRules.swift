import Foundation

/// The line under the editor's progress toggle.
public enum ProgressNote: Hashable, Sendable {
    /// No start date, and there is progress: it runs from the day added.
    case fromDayAdded
    /// No start date and no progress: the date is not after the day added.
    case noneWithoutStart
    /// A start date, and there is progress.
    case fromStartDate
    /// A start date that is not before the target, so no progress.
    case startNotBeforeTarget
}

/// The editor's rules that are plain logic, kept out of the views so they
/// can be tested.
public enum EditorRules {
    /// The hour a date gets when "Include a time" is turned on.
    public static let defaultHour = 9
    /// How far ahead a new milestone's date starts.
    public static let defaultDaysAhead = 30

    /// @spec APP-ACT-002
    public static func newDraft(now: Date = .now, calendar: Calendar = .current) -> Milestone {
        let target = CalendarDay(containing: now, in: calendar).adding(days: defaultDaysAhead)
        return Milestone(title: "", targetDate: target.storedInstant, createdAt: now)
    }

    /// @spec APP-ACT-004
    public static func duplicate(_ milestone: Milestone) -> Milestone {
        var copy = milestone
        copy.id = UUID()
        copy.title = "\(milestone.title) copy"
        return copy
    }

    /// @spec APP-EDIT-001
    public static func canSave(title: String) -> Bool {
        !cleanedTitle(title).isEmpty
    }

    public static func cleanedTitle(_ title: String) -> String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Switches between all-day and timed, keeping the calendar day.
    /// @spec APP-EDIT-002
    public static func setIncludesTime(
        _ includesTime: Bool,
        on milestone: Milestone,
        calendar: Calendar = .current
    ) -> Milestone {
        includesTime
            ? milestone.convertedToTimed(hour: defaultHour, minute: 0, calendar: calendar)
            : milestone.convertedToAllDay(calendar: calendar)
    }

    /// Adds or removes the start date. A new start is the earlier of the day
    /// the milestone was added and its target.
    /// @spec APP-EDIT-003
    public static func setTracksStart(
        _ tracksStart: Bool,
        on milestone: Milestone,
        calendar: Calendar = .current
    ) -> Milestone {
        var copy = milestone
        guard tracksStart else {
            copy.startDate = nil
            return copy
        }
        guard milestone.startDate == nil else { return milestone }
        if milestone.includesTime {
            copy.startDate = min(milestone.createdAt, milestone.targetDate)
        } else {
            let added = CalendarDay(containing: milestone.createdAt, in: calendar)
            let target = CalendarDay(storedInstant: milestone.targetDate)
            copy.startDate = min(added, target).storedInstant
        }
        return copy
    }

    /// @spec APP-EDIT-004
    public static func progressNote(
        for milestone: Milestone,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> ProgressNote {
        let hasProgress = milestone.countdown(now: now, calendar: calendar).progress != nil
        if milestone.startDate == nil {
            return hasProgress ? .fromDayAdded : .noneWithoutStart
        }
        return hasProgress ? .fromStartDate : .startNotBeforeTarget
    }
}
