import DaysUntilCore
import SwiftUI

/// Asks before deleting a milestone, naming it by its stored title. Used by
/// the grid and, over the open sheet, by the editor.
/// @spec APP-ACT-006
struct DeleteConfirmation: ViewModifier {
    /// The stored milestone awaiting confirmation, or `nil` when not asking.
    @Binding var pending: Milestone?
    let onConfirm: (Milestone) -> Void

    func body(content: Content) -> some View {
        content.confirmationDialog(
            "Delete “\(pending?.title ?? "")”?",
            isPresented: Binding(get: { pending != nil }, set: { isShown in
                if !isShown {
                    pending = nil
                }
            }),
            presenting: pending
        ) { milestone in
            Button("Delete", role: .destructive) { onConfirm(milestone) }
        } message: { _ in
            Text("Widgets showing this milestone will ask you to pick another.")
        }
    }
}

extension View {
    func deleteConfirmation(for pending: Binding<Milestone?>, onConfirm: @escaping (Milestone) -> Void) -> some View {
        modifier(DeleteConfirmation(pending: pending, onConfirm: onConfirm))
    }
}
