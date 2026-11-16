import DaysUntilCore
import DaysUntilUI
import SwiftUI

/// The editable fields of a milestone.
struct MilestoneForm: View {
    @Binding var milestone: Milestone

    var body: some View {
        Form {
            Section {
                TextField("Title", text: $milestone.title, prompt: Text("Trip, deadline, anniversary…"))
                DatePicker("Date", selection: $milestone.targetDate, displayedComponents: dateComponents)
                Toggle("Include a time", isOn: $milestone.includesTime)
            }
            Section {
                Toggle("Track progress from a start date", isOn: hasStartDate)
                if milestone.startDate != nil {
                    DatePicker("Start", selection: startDate, displayedComponents: dateComponents)
                }
            } footer: {
                Text(progressNote).font(.caption).foregroundStyle(.secondary)
            }
            Section("Symbol") {
                SymbolPicker(symbol: $milestone.symbol)
            }
            Section("Theme") {
                ThemePicker(themeID: $milestone.themeID)
            }
        }
        .formStyle(.grouped)
    }

    private var dateComponents: DatePickerComponents {
        milestone.includesTime ? [.date, .hourAndMinute] : [.date]
    }

    private var hasStartDate: Binding<Bool> {
        Binding(
            get: { milestone.startDate != nil },
            set: { milestone.startDate = $0 ? min(milestone.createdAt, milestone.targetDate) : nil }
        )
    }

    private var startDate: Binding<Date> {
        Binding(
            get: { milestone.startDate ?? milestone.createdAt },
            set: { milestone.startDate = $0 }
        )
    }

    private var progressNote: String {
        if let start = milestone.startDate, start >= milestone.targetDate {
            return "The start date has to be before the target date for progress to show."
        }
        if milestone.startDate == nil {
            return "Without a start date, progress runs from the day you added this milestone."
        }
        return "Progress runs from the start date to the target date."
    }
}

/// A grid of suggested SF Symbols plus a field for typing an emoji instead.
struct SymbolPicker: View {
    @Binding var symbol: String

    static let suggestions = [
        "flag.fill", "star.fill", "heart.fill", "airplane", "house.fill", "gift.fill",
        "birthday.cake.fill", "graduationcap.fill", "briefcase.fill", "book.closed.fill",
        "figure.run", "trophy.fill", "sun.max.fill", "snowflake", "leaf.fill", "car.fill",
        "music.note", "camera.fill", "pawprint.fill", "sparkles", "hourglass", "calendar",
        "dollarsign.circle.fill", "cross.case.fill",
    ]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 8), spacing: 6) {
            ForEach(Self.suggestions, id: \.self) { name in
                Button { symbol = name } label: {
                    Image(systemName: name)
                        .frame(width: 30, height: 30)
                        .background(symbol == name ? AnyShapeStyle(.tint.opacity(0.25)) : AnyShapeStyle(.clear))
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(name)
                .accessibilityAddTraits(symbol == name ? .isSelected : [])
            }
        }
        TextField("Or an emoji", text: emoji, prompt: Text("🎂"))
    }

    /// Shows the current symbol only when it is an emoji, and keeps just the
    /// last character typed so the field always holds a single emoji.
    private var emoji: Binding<String> {
        Binding(
            get: { symbol.allSatisfy(\.isASCII) ? "" : symbol },
            set: { typed in
                if let last = typed.last, !last.isASCII {
                    symbol = String(last)
                } else if typed.isEmpty, !symbol.allSatisfy(\.isASCII) {
                    symbol = Self.suggestions[0]
                }
            }
        )
    }
}

/// A row of swatches, one per built-in theme.
struct ThemePicker: View {
    @Binding var themeID: String

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Theme.all) { theme in
                Button { themeID = theme.id } label: {
                    Circle()
                        .fill(theme.background)
                        .overlay { Circle().fill(theme.accentColor).frame(width: 9, height: 9) }
                        .frame(width: 30, height: 30)
                        .padding(3)
                        .overlay {
                            Circle().strokeBorder(.tint, lineWidth: themeID == theme.id ? 2.5 : 0)
                        }
                }
                .buttonStyle(.plain)
                .help(theme.name)
                .accessibilityLabel(theme.name)
                .accessibilityAddTraits(themeID == theme.id ? .isSelected : [])
            }
        }
    }
}
