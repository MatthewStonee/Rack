import SwiftData

@Observable
final class WorkoutTemplateDetailViewModel {
    func reorderExercises(
        in workout: WorkoutTemplate,
        from source: Int,
        to destination: Int,
        context: ModelContext
    ) {
        var exercises = workout.sortedExercises
        let item = exercises.remove(at: source)
        exercises.insert(item, at: destination)
        for (index, exercise) in exercises.enumerated() {
            exercise.orderIndex = index
        }
        try? context.save()
    }
}
