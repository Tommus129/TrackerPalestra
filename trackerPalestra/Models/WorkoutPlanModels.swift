import Foundation
import FirebaseFirestore

// MARK: - Scheda (piano teorico)

struct WorkoutPlanDay: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var label: String
    var exercises: [WorkoutPlanExercise]
}

struct WorkoutPlanExercise: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString

    // Core
    var name: String

    // Legacy (retrocompatibilità UI/DB esistenti)
    var defaultSets: Int
    var defaultReps: Int
    var isBodyweight: Bool
    var notes: String = ""

    // New (per schema reps variabile + recupero + super serie)
    var repScheme: [Int]? = nil            // es. [10, 9, 9, 8]
    var restSeconds: Int = 90              // es. 120 = 2'
    var superSetGroupID: String? = nil     // stesso ID => super serie

    // Helpers
    var effectiveRepScheme: [Int] {
        if let repScheme, !repScheme.isEmpty { return repScheme }
        return Array(repeating: defaultReps, count: max(1, defaultSets))
    }

    var effectiveSetsCount: Int { effectiveRepScheme.count }
}

struct WorkoutPlan: Identifiable, Codable, Hashable {
    @DocumentID var id: String?

    var userId: String
    var name: String
    var days: [WorkoutPlanDay]
    var createdAt: Date
    var order: Int? = 0
}
