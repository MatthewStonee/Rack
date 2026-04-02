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

## Simulator
- Default: iPhone 17 Pro Max
- Scheme: Rack

## What NOT to do
- Don't add third-party dependencies without asking
- Don't use UIKit unless SwiftUI can't do it
- Don't hard-code any exercise names or data



## Current Status (last updated April 2, session 3 — full summary below)

App is a 2-tab SwiftUI/SwiftData app (Programs + Progress). All files building cleanly.

### Data Models
- `Exercise` — name, `MuscleGroup` enum (with `.color` + `.sfSymbol`), `Equipment` enum
- `Program` → `WorkoutTemplate` → `PlannedExercise` (cascade delete)
- `WorkoutSession` + `LoggedSet` — `LoggedSet.session` is optional to support Quick Log without a session

### Features Built
- **Programs tab** — list, create, rename, delete program; program detail with workout days; workout day detail with planned exercises (add, edit sets/reps/weight, rename day, delete day)
- **Progress tab** — exercise list with PR + set count; per-exercise detail with Swift Charts line chart, 5 time-range filters, recent sets log; Quick Log FAB to log a set without a workout session; edit/delete logged sets via tap or context menu
- **Shared** — `ExercisePickerView` with muscle group filter chips and inline exercise creation

### UI Conventions
- All backgrounds: `LinearGradient([Color(0.04,0.06,0.18), .black])` applied inside NavigationStack on content (not on NavigationStack itself — iOS 26 overrides it)
- "Create" actions use a `+` toolbar button (`.primaryAction`) — do NOT use FABs via `safeAreaInset`; iOS 26 system gesture gate at the bottom edge makes them unreliable
- Rename + Delete actions share an `ellipsis.circle` toolbar menu (see `ProgramDetailView`, `WorkoutTemplateDetailView`)
- Exercise rows use a 4pt colored left bar (`MuscleGroup.color`) instead of SF Symbol icons
- Reusable components in `Shared/GlassCard.swift`: `GlassCard`, `GlassButton`, `PrimaryButton`, `StatBadge`, `FABButtonStyle`, `.glassBackground()`, cross-platform stubs (`titleDisplayMode`, `keyboardType`, `fullScreenCover`)
- `Button(_:systemImage:role:)` shorthand causes overload errors — use explicit `Button(role:) { } label: { Label(...) }` form
- All glass components use `.glassEffect(.regular, in: ...)` (iOS 26 native API) — no more `.ultraThinMaterial` or manual stroke overlays

### Gotchas
- Custom `ProgressView` struct shadows SwiftUI built-in — our type is `ProgressTabView`
- `Button(_:systemImage:role:)` shorthand hits SwiftUI overload resolution bugs — always use explicit label form
- Curly quotes in Swift string literals cause parse errors — use `\"`
- `.glassEffect(.regular.interactive())` on a Button label intercepts taps and breaks the button action — do NOT use `.interactive()` on label content inside a `Button`; use a `ButtonStyle` instead
- FABs via `safeAreaInset(edge: .bottom)` are unreliable on iOS 26 — system gesture gate at the bottom edge causes "Gesture: System gesture gate timed out" and dropped taps. Use toolbar buttons instead.
- Sheet presentation state (`isPresented`) must be plain `@State Bool` on the view — do NOT store it in an `@Observable` ViewModel. After sheet dismissal, the binding chain through `@Observable` can silently fail to re-enable the triggering control.

## Session 3 — April 2

### What was done
- **Fixed Programs tab FAB** — investigated and resolved through several iterations:
  - Moved `.glassEffect` out of Button label and into `FABButtonStyle` (label was intercepting taps)
  - Moved `.sheet` outside `NavigationStack` to fix "works once then stops" after dismissal
  - Moved `showingCreateProgram` from `@Observable` ViewModel to `@State` on the view (Observable binding chain was silently failing after sheet dismiss)
  - Switched from `DragGesture(minimumDistance: 0)` to toolbar button after diagnosing "System gesture gate timed out" log — iOS 26 system gesture zone at the bottom edge makes `safeAreaInset` FABs unreliable
  - Final solution: standard `+` toolbar button (`.primaryAction`), matching Apple HIG
- **Added delete program** — `ProgramDetailView` toolbar button replaced with `ellipsis.circle` menu containing Rename + Delete Program, matching the pattern already used in `WorkoutTemplateDetailView`. Includes confirmation alert and dismiss-on-delete.

### Open To-Dos
- None — all known issues resolved this session.
