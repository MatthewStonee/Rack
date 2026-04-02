import SwiftUI
import SwiftData

struct ProgramDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var program: Program
    @State private var showingAddWorkout = false
    @State private var editingWorkoutName: WorkoutTemplate?
    @State private var newWorkoutName = ""
    @State private var editingTitle = false
    @State private var draftName = ""
    @State private var confirmingDelete = false

    private var gradient: some View {
        LinearGradient(
            colors: [Color(red: 0.04, green: 0.06, blue: 0.18), Color.black],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                programHeader

                if program.sortedWorkouts.isEmpty {
                    emptyWorkoutsState
                } else {
                    ForEach(program.sortedWorkouts) { workout in
                        NavigationLink(destination: WorkoutTemplateDetailView(workout: workout)) {
                            WorkoutTemplateRow(workout: workout)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button {
                    showingAddWorkout = true
                } label: {
                    Label("Add Workout Day", systemImage: "plus")
                        .font(.subheadline.bold())
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(.blue.opacity(0.3), lineWidth: 0.5)
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .navigationTitle(program.name)
        .titleDisplayMode(.large)
        .background { gradient }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        draftName = program.name
                        editingTitle = true
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        confirmingDelete = true
                    } label: {
                        Label("Delete Program", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .fontWeight(.semibold)
                }
            }
        }
        .alert("Rename Program", isPresented: $editingTitle) {
            TextField("Program name", text: $draftName)
            Button("Save") {
                let trimmed = draftName.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    program.name = trimmed
                    try? context.save()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete Program", isPresented: $confirmingDelete) {
            Button("Delete", role: .destructive) { deleteProgram() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\"\(program.name)\" and all its workout days will be permanently removed.")
        }
        .alert("Add Workout Day", isPresented: $showingAddWorkout) {
            TextField("e.g. Push Day, Day 1", text: $newWorkoutName)
            Button("Add") { addWorkout() }
            Button("Cancel", role: .cancel) { newWorkoutName = "" }
        } message: {
            Text("Name this workout day")
        }
    }

    private var programHeader: some View {
        GlassCard {
            HStack(spacing: 12) {
                StatBadge(value: "\(program.workouts.count)", label: "Days")
                StatBadge(
                    value: "\(program.workouts.reduce(0) { $0 + $1.plannedExercises.count })",
                    label: "Exercises"
                )
                StatBadge(
                    value: program.isActive ? "Active" : "Inactive",
                    label: "Status"
                )
            }
        }
    }

    private var emptyWorkoutsState: some View {
        GlassCard {
            VStack(spacing: 12) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 40))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.blue)
                Text("No workout days yet")
                    .font(.subheadline.bold())
                Text("Add workout days to build your program structure.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    private func deleteProgram() {
        context.delete(program)
        try? context.save()
        dismiss()
    }

    private func addWorkout() {
        let trimmed = newWorkoutName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let workout = WorkoutTemplate(name: trimmed, orderIndex: program.workouts.count)
        workout.program = program
        program.workouts.append(workout)
        context.insert(workout)
        try? context.save()
        newWorkoutName = ""
    }
}

struct WorkoutTemplateRow: View {
    let workout: WorkoutTemplate

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.15))
                    .frame(width: 44, height: 44)
                Text("\(workout.orderIndex + 1)")
                    .font(.headline.bold())
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("\(workout.plannedExercises.count) \(workout.plannedExercises.count == 1 ? "exercise" : "exercises")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .glassBackground()
    }
}
