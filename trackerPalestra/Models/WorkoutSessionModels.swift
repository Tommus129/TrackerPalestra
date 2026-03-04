import Foundation
import FirebaseFirestore

// MARK: - WorkoutSet

struct WorkoutSet: Identifiable, Codable {
    var id: String = UUID().uuidString
    var setIndex: Int
    var reps: Int
    var weight: Double
    var setNotes: String?
    var isPR: Bool
    var isCompleted: Bool = false
}

// MARK: - WorkoutExerciseSession

struct WorkoutExerciseSession: Identifiable, Codable {
    var id: String = UUID().uuidString
    var exerciseId: String
    var name: String
    var isBodyweight: Bool
    var sets: [WorkoutSet]
    var isPR: Bool
    var exerciseNotes: String
    /// Se l'esercizio appartiene a un superset, tutti gli esercizi del blocco
    /// condividono lo stesso valore. nil = esercizio normale.
    var supersetGroupId: String? = nil
    /// Nome del superset (es. "A1/A2") mostrato nell'header del blocco.
    var supersetName: String? = nil
    /// Recupero in secondi configurato nella scheda.
    var restAfterSeconds: Int = 60
}

// MARK: - WorkoutSession

struct WorkoutSession: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var planId: String
    var dayId: String
    var date: Date
    var notes: String
    var exercises: [WorkoutExerciseSession]
}
