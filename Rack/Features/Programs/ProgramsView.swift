import SwiftUI
import SwiftData

struct ProgramsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Program.createdAt, order: .reverse) private var programs: [Program]
    @State private var viewModel = ProgramsViewModel()
    @State private var showingCreateProgram = false

    var body: some View {
        NavigationStack {
            Group {
                if programs.isEmpty {
                    emptyState
                } else {
                    programList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { backgroundGradient }
            .navigationTitle("Programs")
            .titleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateProgram = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateProgram) {
            CreateProgramView()
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.04, green: 0.06, blue: 0.18),
                Color.black
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var programList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(programs) { program in
                    NavigationLink(destination: ProgramDetailView(program: program)) {
                        ProgramRow(program: program) {
                            viewModel.setActive(program, allPrograms: programs, context: context)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 64))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.blue)

            VStack(spacing: 8) {
                Text("No Programs Yet")
                    .font(.title2.bold())
                Text("Create a training program to organize\nyour workouts and track progress.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showingCreateProgram = true
            } label: {
                Label("Create Program", systemImage: "plus")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.blue, in: Capsule())
                    .foregroundStyle(.white)
            }
        }
        .padding(32)
    }
}

struct ProgramRow: View {
    let program: Program
    let onSetActive: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        if program.isActive {
                            Text("ACTIVE")
                                .font(.caption2.bold())
                                .tracking(1)
                                .foregroundStyle(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(.green.opacity(0.15), in: Capsule())
                        }
                    }
                    Text(program.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if !program.programDescription.isEmpty {
                        Text(program.programDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            HStack(spacing: 8) {
                StatBadge(
                    value: "\(program.workouts.count)",
                    label: program.workouts.count == 1 ? "Workout" : "Workouts"
                )
                StatBadge(
                    value: "\(totalExercises(program))",
                    label: "Exercises"
                )
                if !program.isActive {
                    Button {
                        onSetActive()
                    } label: {
                        Text("Set Active")
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(.blue.opacity(0.2), in: RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .glassBackground()
    }

    private func totalExercises(_ program: Program) -> Int {
        program.workouts.reduce(0) { $0 + $1.plannedExercises.count }
    }
}
