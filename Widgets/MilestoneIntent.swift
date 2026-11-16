import AppIntents
import DaysUntilCore
import WidgetKit

/// A milestone as it appears in the widget's "Edit Widget" picker.
struct MilestoneEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Milestone"
    static let defaultQuery = MilestoneQuery()

    let id: UUID
    let title: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }

    init(_ choice: MilestoneChoice) {
        id = choice.id
        title = choice.title
    }
}

/// The list a widget's milestone choice is picked from and resolved against.
///
/// There is deliberately no default result: a new widget has no milestone
/// chosen and follows the next one.
struct MilestoneQuery: EntityQuery {
    /// Answers for every id asked about. An id with no milestone (deleted, or
    /// the store unreadable just now) gets a stand-in, because the system
    /// forgets a choice it cannot look up and the widget would then switch to
    /// another milestone instead of saying this one was removed.
    /// @spec WIDGET-CONFIG-003
    func entities(for identifiers: [UUID]) async throws -> [MilestoneEntity] {
        MilestoneChoice.resolve(ids: identifiers, in: WidgetStore.allMilestones() ?? []).map(MilestoneEntity.init)
    }

    /// Every non-archived milestone, in display order.
    /// @spec WIDGET-CONFIG-001
    func suggestedEntities() async throws -> [MilestoneEntity] {
        (WidgetStore.allMilestones() ?? [])
            .filter { !$0.isArchived }
            .map { MilestoneEntity(MilestoneChoice(id: $0.id, title: $0.title)) }
    }
}

/// `FaceStyle` as a widget configuration option.
enum StyleOption: String, AppEnum {
    case number
    case bar
    case ring
    case dots

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Style"
    static let caseDisplayRepresentations: [StyleOption: DisplayRepresentation] = [
        .number: "Number",
        .bar: "Bar",
        .ring: "Ring",
        .dots: "Dots",
    ]

    var faceStyle: FaceStyle {
        FaceStyle(rawValue: rawValue) ?? .number
    }
}

struct MilestoneWidgetIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Milestone"
    static let description = IntentDescription("Choose a milestone and how it is drawn.")

    /// @spec WIDGET-CONFIG-002
    @Parameter(title: "Milestone")
    var milestone: MilestoneEntity?

    @Parameter(title: "Style", default: .number)
    var style: StyleOption
}
