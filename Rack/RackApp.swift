import SwiftUI
import SwiftData

@main
struct RackApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            Program.self,
            WorkoutTemplate.self,
            PlannedExercise.self,
            Exercise.self,
            WorkoutSession.self,
            LoggedSet.self
        ])
        do {
            let config = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            // CloudKit unavailable (simulator not signed into iCloud, container not yet initialized, etc.)
            // Fall back to local-only storage so the app stays usable.
            guard let local = try? ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema)) else {
                fatalError("SwiftData ModelContainer failed: \(error.localizedDescription)")
            }
            container = local
        }
        ExerciseLibrary.seedIfNeeded(context: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .preferredColorScheme(.dark)
        }
    }
}
