import SwiftUI
import SwiftData

@Observable
final class ProgramsViewModel {
    var programToDelete: Program?
    var showingDeleteAlert = false

    func deleteProgram(_ program: Program, context: ModelContext) {
        context.delete(program)
        try? context.save()
    }

    func setActive(_ program: Program, allPrograms: [Program], context: ModelContext) {
        for p in allPrograms {
            p.isActive = false
        }
        program.isActive = true
        try? context.save()
    }
}
