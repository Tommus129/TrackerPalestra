import Foundation
import FirebaseFirestore

// MARK: - Sessione reale

struct WorkoutSet: Identifiable, Codable {
    var id: String = UUID().uuidString
    var setIndex: Int
    var reps: Int
    var weight: Double
    var setNotes: String?
    var isPR: Bool
    var isCompleted: Bool = false
    
}

struct WorkoutExerciseSession: Identifiable, Codable {
    var id: String = UUID().uuidString
    var exerciseId: String      // id dalla scheda; per extra un nuovo UUID
    var name: String
    var isBodyweight: Bool
    var sets: [WorkoutSet]
    var isPR: Bool
    var exerciseNotes: String // note specifiche per l'esercizio
}

struct WorkoutSession: Identifiable, Codable {
    @DocumentID var id: String?

    var userId: String
    var planId: String
    var dayId: String

    var date: Date
    var notes: String
    var exercises: [WorkoutExerciseSession]
}
