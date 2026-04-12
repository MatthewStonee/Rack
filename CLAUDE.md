# Rack — Claude Code Instructions

## Project Overview
iOS fitness and workout programming app built with SwiftUI. Helps users track programs, 
exercises, sets, reps, and progress over time.

## Architecture
- SwiftUI for all UI
- SwiftData for local persistence
- MVVM pattern — ViewModels handle all business logic, Views are dumb
- No logic in View files

## Core Data Models
- `Exercise` — name, muscle group, equipment type
- `WorkoutSet` — reps, weight, linked to Exercise + Workout
- `Program` — collection of workouts forming a weekly plan

## Key Features (build in this order)
1. Program/routine builder
2. Add exercises and sets to a workout
3. Progress charts per exercise (weight over time)

## Rules
- NEVER modify .pbxproj files — create Swift files, I'll add them to 
  Xcode manually
- Always use SwiftData for persistence, no CoreData or UserDefaults 
  for model storage
- All new views go in /Features/<FeatureName>/
- Always build and test in simulator after changes

## UI/UX Guidelines
- Dark mode first
- SF Symbols for all icons
- Liquid Glass UI elements.
- Follow Apple HIG — no custom nav patterns
- Fitness-friendly: large tap targets, easy one-handed use

## Build Configuration
- Scheme: Rack
- Target simulator: iPhone 17 Pro (iOS 26.x)
- Build command: use XcodeBuildMCP tools, never raw xcodebuild shell commands

## What NOT to do
- Don't add third-party dependencies without asking
- Don't use UIKit unless SwiftUI can't do it
- Don't hard-code any exercise names or data


### Data Models
- `Exercise` — name, `MuscleGroup` enum (with `.color` + `.sfSymbol`), `Equipment` enum
- `Program` → `WorkoutTemplate` → `PlannedExercise` (cascade delete)
- `WorkoutSession` + `LoggedSet` — `LoggedSet.session` is optional to support Quick Log without a session

### Features Built
- **Programs tab** — list, create, rename, delete program; program detail with workout days; workout day detail with planned exercises (add, edit sets/reps/weight, rename day, delete day)
- **Progress tab** — exercise list with PR + set count; per-exercise detail with Swift Charts line chart, 5 time-range filters, recent sets log; Quick Log FAB to log a set without a workout session; edit/delete logged sets via tap or context menu
- **Shared** — `ExercisePickerView` with muscle group filter chips and inline exercise creation


### Gotchas
- Custom `ProgressView` struct shadows SwiftUI built-in — our type is `ProgressTabView`
- `Button(_:systemImage:role:)` shorthand hits SwiftUI overload resolution bugs — always use explicit label form
- Curly quotes in Swift string literals cause parse errors — use `\"`
- `.glassEffect(.regular.interactive())` on a Button label intercepts taps and breaks the button action — do NOT use `.interactive()` on label content inside a `Button`; use a `ButtonStyle` instead
- FABs via `safeAreaInset(edge: .bottom)` are unreliable on iOS 26 — system gesture gate at the bottom edge causes "Gesture: System gesture gate timed out" and dropped taps. Use toolbar buttons instead.
- Sheet presentation state (`isPresented`) must be plain `@State Bool` on the view — do NOT store it in an `@Observable` ViewModel. After sheet dismissal, the binding chain through `@Observable` can silently fail to re-enable the triggering control.


### Open To-Dos
- Tracked in Notion: https://www.notion.so/33def31f82228136a7fbe2bb7b7262e6
