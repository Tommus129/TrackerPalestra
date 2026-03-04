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

    // Campi superset — opzionali per retrocompatibilità con sessioni
    // salvate prima dell'introduzione dei superset (campo assente in Firestore
    // = nil, non errore di decodifica).
    var supersetGroupId: String? = nil
    var supersetName: String? = nil

    // Int? invece di Int: i vecchi documenti Firestore non hanno questo campo,
    // quindi il decoder non trova nulla e assegna nil senza lanciare errori.
    // La computed property restAfterSeconds fornisce il fallback a 60s.
    var _restAfterSeconds: Int?

    /// Recupero effettivo in secondi. Usa il valore salvato se presente, 60 altrimenti.
    var restAfterSeconds: Int {
        get { _restAfterSeconds ?? 60 }
        set { _restAfterSeconds = newValue }
    }

    // MARK: Codable
    enum CodingKeys: String, CodingKey {
        case id, exerciseId, name, isBodyweight, sets, isPR, exerciseNotes
        case supersetGroupId, supersetName
        case _restAfterSeconds = "restAfterSeconds"
    }
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
