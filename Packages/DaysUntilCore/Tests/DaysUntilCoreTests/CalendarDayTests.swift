@testable import DaysUntilCore
import Foundation
import Testing

@Suite("Calendar days")
struct CalendarDayTests {
    /// @spec COUNT-DAY-001
    @Test("A stored instant is read as its UTC year, month and day, whatever its time", arguments: [0, 5, 23])
    func readsUTCDay(hour: Int) {
        let stored = Fixture.date(2026, 12, 9, hour, 30, in: Fixture.utc)
        #expect(CalendarDay(storedInstant: stored) == CalendarDay(year: 2026, month: 12, day: 9))
    }

    /// @spec COUNT-DAY-002
    @Test("An all-day milestone is the same number of days away in every time zone")
    func sameDayEverywhere() {
        let milestone = Fixture.milestone(target: Fixture.day(2026, 12, 9))
        for calendar in [Fixture.losAngeles, Fixture.calendar, Fixture.tokyo] {
            let noon = Fixture.date(2026, 12, 7, 12, 0, in: calendar)
            #expect(Fixture.countdown(milestone, now: noon, calendar: calendar).days == 2)
            let onTheDay = Fixture.date(2026, 12, 9, 23, 0, in: calendar)
            #expect(Fixture.countdown(milestone, now: onTheDay, calendar: calendar).phase == .today)
        }
    }

    /// @spec COUNT-DAY-002
    @Test("A calendar day starts at local midnight of the same date in the supplied calendar")
    func startsAtLocalMidnight() {
        let day = CalendarDay(year: 2026, month: 12, day: 9)
        #expect(day.start(in: Fixture.losAngeles) == Fixture.date(2026, 12, 9, in: Fixture.losAngeles))
        #expect(day.start(in: Fixture.tokyo) == Fixture.date(2026, 12, 9, in: Fixture.tokyo))
    }

    /// @spec COUNT-DAY-003
    @Test("A calendar day is stored as 00:00 UTC of that day")
    func storesMidnightUTC() {
        #expect(CalendarDay(year: 2026, month: 12, day: 9).storedInstant == Fixture.day(2026, 12, 9))
    }

    /// @spec COUNT-DAY-004
    @Test("Converting to timed keeps the day and sets the given time, for target and start")
    func toTimed() {
        let allDay = Fixture.milestone(target: Fixture.day(2026, 12, 9), start: Fixture.day(2026, 11, 1))
        let timed = allDay.convertedToTimed(hour: 9, minute: 0, calendar: Fixture.tokyo)
        #expect(timed.includesTime)
        #expect(timed.targetDate == Fixture.date(2026, 12, 9, 9, 0, in: Fixture.tokyo))
        #expect(timed.startDate == Fixture.date(2026, 11, 1, 9, 0, in: Fixture.tokyo))
    }

    /// @spec COUNT-DAY-005
    @Test("Converting to all-day keeps the local day each date falls on, for target and start")
    func toAllDay() {
        // 22:00 on 9 Dec in New York is already 10 Dec in UTC; the day must stay the 9th.
        let timed = Fixture.milestone(
            target: Fixture.date(2026, 12, 9, 22, 0), timed: true, start: Fixture.date(2026, 11, 1, 23, 0)
        )
        let allDay = timed.convertedToAllDay(calendar: Fixture.calendar)
        #expect(!allDay.includesTime)
        #expect(allDay.targetDate == Fixture.day(2026, 12, 9))
        #expect(allDay.startDate == Fixture.day(2026, 11, 1))
    }

    /// @spec COUNT-DAY-002, COUNT-DAY-003
    @Test("A stored day is shown at local midnight, and a picked local date is stored as its day")
    func localAndStored() {
        let allDay = Fixture.milestone(target: Fixture.day(2026, 12, 9))
        let local = allDay.localDate(for: allDay.targetDate, calendar: Fixture.tokyo)
        #expect(local == Fixture.date(2026, 12, 9, in: Fixture.tokyo))
        let picked = Fixture.date(2026, 12, 10, 14, 0, in: Fixture.tokyo)
        #expect(allDay.storedDate(forLocal: picked, calendar: Fixture.tokyo) == Fixture.day(2026, 12, 10))
        // A timed milestone's dates are instants and pass through unchanged.
        let timed = Fixture.milestone(target: picked, timed: true)
        #expect(timed.localDate(for: picked, calendar: Fixture.tokyo) == picked)
        #expect(timed.storedDate(forLocal: picked, calendar: Fixture.tokyo) == picked)
    }
}
