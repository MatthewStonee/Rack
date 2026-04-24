import SwiftData
import Foundation

enum ExerciseLibrary {
    private static let seededKey = "exerciseLibrarySeeded"

    static func reconcile(context: ModelContext) {
        do {
            var exercises = try context.fetch(FetchDescriptor<Exercise>())
            let plannedExercises = try context.fetch(FetchDescriptor<PlannedExercise>())
            let loggedSets = try context.fetch(FetchDescriptor<LoggedSet>())

            var didChange = false

            for entry in seed {
                let identity = ExerciseIdentity(name: entry.name, muscleGroup: entry.muscleGroup, equipment: entry.equipment)
                let matches = exercises.filter { ExerciseIdentity(exercise: $0) == identity }

                guard !matches.isEmpty else {
                    let exercise = Exercise(name: entry.name, muscleGroup: entry.muscleGroup, equipment: entry.equipment)
                    context.insert(exercise)
                    exercises.append(exercise)
                    didChange = true
                    continue
                }

                let canonical = canonicalExercise(
                    from: matches,
                    plannedExercises: plannedExercises,
                    loggedSets: loggedSets
                )

                if canonical.name != entry.name {
                    canonical.name = entry.name
                    didChange = true
                }
                if canonical.muscleGroup != entry.muscleGroup {
                    canonical.muscleGroup = entry.muscleGroup
                    didChange = true
                }
                if canonical.equipment != entry.equipment {
                    canonical.equipment = entry.equipment
                    didChange = true
                }

                let duplicateIDs = Set(matches.map(\.id)).subtracting([canonical.id])
                guard !duplicateIDs.isEmpty else { continue }

                for plannedExercise in plannedExercises {
                    if let id = plannedExercise.exercise?.id, duplicateIDs.contains(id) {
                        plannedExercise.exercise = canonical
                        didChange = true
                    }
                }

                for loggedSet in loggedSets {
                    if let id = loggedSet.exercise?.id, duplicateIDs.contains(id) {
                        loggedSet.exercise = canonical
                        didChange = true
                    }
                }

                if recalculatePersonalRecords(for: canonical, loggedSets: loggedSets) {
                    didChange = true
                }

                for duplicate in matches where duplicate.id != canonical.id {
                    context.delete(duplicate)
                    exercises.removeAll { $0.id == duplicate.id }
                    didChange = true
                }
            }

            if didChange {
                try context.save()
            }
        } catch {
            return
        }

        UserDefaults.standard.set(true, forKey: seededKey)
    }

    static func normalizedName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func canonicalExercise(
        from exercises: [Exercise],
        plannedExercises: [PlannedExercise],
        loggedSets: [LoggedSet]
    ) -> Exercise {
        exercises.max { lhs, rhs in
            let lhsReferences = referenceCount(for: lhs, plannedExercises: plannedExercises, loggedSets: loggedSets)
            let rhsReferences = referenceCount(for: rhs, plannedExercises: plannedExercises, loggedSets: loggedSets)
            if lhsReferences != rhsReferences {
                return lhsReferences < rhsReferences
            }
            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt > rhs.createdAt
            }
            return lhs.id.uuidString > rhs.id.uuidString
        }!
    }

    private static func referenceCount(
        for exercise: Exercise,
        plannedExercises: [PlannedExercise],
        loggedSets: [LoggedSet]
    ) -> Int {
        plannedExercises.filter { $0.exercise?.id == exercise.id }.count +
            loggedSets.filter { $0.exercise?.id == exercise.id }.count
    }

    private static func recalculatePersonalRecords(for exercise: Exercise, loggedSets: [LoggedSet]) -> Bool {
        let exerciseSets = loggedSets.filter { $0.exercise?.id == exercise.id }
        var didChange = false

        for set in exerciseSets where set.isPersonalRecord {
            set.isPersonalRecord = false
            didChange = true
        }

        let groupedByReps = Dictionary(grouping: exerciseSets) { $0.reps }
        for sets in groupedByReps.values {
            if let best = sets.max(by: { $0.weight < $1.weight }), best.weight > 0 {
                best.isPersonalRecord = true
                didChange = true
            }
        }

        return didChange
    }

    private struct ExerciseIdentity: Hashable {
        let name: String
        let muscleGroup: MuscleGroup
        let equipment: Equipment

        init(name: String, muscleGroup: MuscleGroup, equipment: Equipment) {
            self.name = ExerciseLibrary.normalizedName(name)
            self.muscleGroup = muscleGroup
            self.equipment = equipment
        }

        init(exercise: Exercise) {
            self.init(name: exercise.name, muscleGroup: exercise.muscleGroup, equipment: exercise.equipment)
        }
    }

    static let seed: [(name: String, muscleGroup: MuscleGroup, equipment: Equipment)] = [
        // MARK: Chest
        ("Bench Press",             .chest,      .barbell),
        ("Incline Bench Press",     .chest,      .barbell),
        ("Decline Bench Press",     .chest,      .barbell),
        ("Dumbbell Fly",            .chest,      .dumbbell),
        ("Incline Dumbbell Press",  .chest,      .dumbbell),
        ("Push-Up",                 .chest,      .bodyweight),
        ("Cable Fly",               .chest,      .cable),
        ("Chest Press Machine",     .chest,      .machine),

        // MARK: Back
        ("Deadlift",                .back,       .barbell),
        ("Barbell Row",             .back,       .barbell),
        ("T-Bar Row",               .back,       .barbell),
        ("Pull-Up",                 .back,       .bodyweight),
        ("Lat Pulldown",            .back,       .cable),
        ("Seated Cable Row",        .back,       .cable),
        ("Face Pull",               .back,       .cable),
        ("Dumbbell Row",            .back,       .dumbbell),

        // MARK: Shoulders
        ("Overhead Press",          .shoulders,  .barbell),
        ("Upright Row",             .shoulders,  .barbell),
        ("Dumbbell Shoulder Press", .shoulders,  .dumbbell),
        ("Lateral Raise",           .shoulders,  .dumbbell),
        ("Front Raise",             .shoulders,  .dumbbell),
        ("Arnold Press",            .shoulders,  .dumbbell),
        ("Cable Lateral Raise",     .shoulders,  .cable),
        ("Machine Shoulder Press",  .shoulders,  .machine),

        // MARK: Biceps
        ("Barbell Curl",            .biceps,     .barbell),
        ("Dumbbell Curl",           .biceps,     .dumbbell),
        ("Hammer Curl",             .biceps,     .dumbbell),
        ("Incline Dumbbell Curl",   .biceps,     .dumbbell),
        ("Concentration Curl",      .biceps,     .dumbbell),
        ("Cable Curl",              .biceps,     .cable),
        ("Preacher Curl",           .biceps,     .machine),

        // MARK: Triceps
        ("Close-Grip Bench Press",          .triceps,    .barbell),
        ("Skull Crusher",                   .triceps,    .barbell),
        ("Tricep Dip",                      .triceps,    .bodyweight),
        ("Diamond Push-Up",                 .triceps,    .bodyweight),
        ("Tricep Pushdown",                 .triceps,    .cable),
        ("Cable Overhead Tricep Extension", .triceps,    .cable),
        ("Overhead Tricep Extension",       .triceps,    .dumbbell),

        // MARK: Quads
        ("Squat",                   .quads,      .barbell),
        ("Front Squat",             .quads,      .barbell),
        ("Lunge",                   .quads,      .dumbbell),
        ("Bulgarian Split Squat",   .quads,      .dumbbell),
        ("Goblet Squat",            .quads,      .kettlebell),
        ("Leg Press",               .quads,      .machine),
        ("Leg Extension",           .quads,      .machine),
        ("Hack Squat",              .quads,      .machine),

        // MARK: Hamstrings
        ("Romanian Deadlift",           .hamstrings, .barbell),
        ("Stiff-Leg Deadlift",          .hamstrings, .barbell),
        ("Good Morning",                .hamstrings, .barbell),
        ("Dumbbell Romanian Deadlift",  .hamstrings, .dumbbell),
        ("Nordic Hamstring Curl",       .hamstrings, .bodyweight),
        ("Leg Curl",                    .hamstrings, .machine),

        // MARK: Glutes
        ("Hip Thrust",              .glutes,     .barbell),
        ("Sumo Deadlift",           .glutes,     .barbell),
        ("Step-Up",                 .glutes,     .dumbbell),
        ("Sumo Squat",              .glutes,     .dumbbell),
        ("Cable Kickback",          .glutes,     .cable),
        ("Glute Bridge",            .glutes,     .bodyweight),

        // MARK: Calves
        ("Standing Calf Raise",     .calves,     .machine),
        ("Seated Calf Raise",       .calves,     .machine),
        ("Donkey Calf Raise",       .calves,     .bodyweight),
        ("Single-Leg Calf Raise",   .calves,     .bodyweight),

        // MARK: Core
        ("Plank",                   .core,       .bodyweight),
        ("Side Plank",              .core,       .bodyweight),
        ("Crunch",                  .core,       .bodyweight),
        ("Bicycle Crunch",          .core,       .bodyweight),
        ("Leg Raise",               .core,       .bodyweight),
        ("Hanging Knee Raise",      .core,       .bodyweight),
        ("Dead Bug",                .core,       .bodyweight),
        ("Russian Twist",           .core,       .dumbbell),
        ("Cable Crunch",            .core,       .cable),
        ("Ab Rollout",              .core,       .other),

        // MARK: Full Body
        ("Clean and Jerk",          .fullBody,   .barbell),
        ("Snatch",                  .fullBody,   .barbell),
        ("Thruster",                .fullBody,   .barbell),
        ("Burpee",                  .fullBody,   .bodyweight),
        ("Kettlebell Swing",        .fullBody,   .kettlebell),
        ("Turkish Get-Up",          .fullBody,   .kettlebell),
        ("Man Maker",               .fullBody,   .dumbbell),
    ]
}
