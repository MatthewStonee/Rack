import SwiftData

@Observable
final class ProgramDetailViewModel {
    func reorderWorkouts(
        in program: Program,
        from source: Int,
        to destination: Int,
        context: ModelContext
    ) {
        var workouts = program.sortedWorkouts
        let item = workouts.remove(at: source)
        workouts.insert(item, at: destination)
        for (index, workout) in workouts.enumerated() {
            workout.orderIndex = index
        }
        try? context.save()
    }
}
