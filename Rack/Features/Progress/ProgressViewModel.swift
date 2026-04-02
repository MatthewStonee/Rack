import SwiftUI
import SwiftData

@Observable
final class ProgressViewModel {
    var selectedExercise: Exercise?
    var timeRange: TimeRange = .threeMonths

    enum TimeRange: String, CaseIterable {
        case oneMonth = "1M"
        case threeMonths = "3M"
        case sixMonths = "6M"
        case oneYear = "1Y"
        case allTime = "All"

        var days: Int? {
            switch self {
            case .oneMonth: return 30
            case .threeMonths: return 90
            case .sixMonths: return 180
            case .oneYear: return 365
            case .allTime: return nil
            }
        }
    }

    func filteredSets(_ sets: [LoggedSet], for timeRange: TimeRange) -> [LoggedSet] {
        guard let days = timeRange.days else { return sets }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return sets.filter { $0.completedAt >= cutoff }
    }

    func maxWeightPoints(for sets: [LoggedSet]) -> [(Date, Double)] {
        let grouped = Dictionary(grouping: sets) { set in
            Calendar.current.startOfDay(for: set.completedAt)
        }
        return grouped.map { (date, daySets) in
            (date, daySets.map(\.weight).max() ?? 0)
        }
        .sorted { $0.0 < $1.0 }
    }

    func personalRecord(for sets: [LoggedSet]) -> LoggedSet? {
        sets.max(by: { $0.weight < $1.weight })
    }

    func totalVolume(for sets: [LoggedSet]) -> Double {
        sets.reduce(0) { $0 + $1.volume }
    }
}
