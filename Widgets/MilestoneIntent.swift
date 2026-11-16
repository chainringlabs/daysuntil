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

    init(_ milestone: Milestone) {
        id = milestone.id
        title = milestone.title
    }
}

struct MilestoneQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [MilestoneEntity] {
        identifiers.compactMap { WidgetStore.milestone(id: $0) }.map(MilestoneEntity.init)
    }

    func suggestedEntities() async throws -> [MilestoneEntity] {
        WidgetStore.milestones().map(MilestoneEntity.init)
    }

    /// A newly added widget starts on the soonest milestone rather than empty.
    func defaultResult() async -> MilestoneEntity? {
        WidgetStore.milestones().first.map(MilestoneEntity.init)
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

    @Parameter(title: "Milestone")
    var milestone: MilestoneEntity?

    @Parameter(title: "Style", default: .number)
    var style: StyleOption
}
