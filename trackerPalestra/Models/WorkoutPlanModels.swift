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
    var name: String
    var defaultSets: Int
    var defaultReps: Int
    var isBodyweight: Bool
    var notes: String = ""
}




struct WorkoutPlan: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var userId: String
    var name: String
    var days: [WorkoutPlanDay]
    var createdAt: Date
    var order: Int? = 0
}

