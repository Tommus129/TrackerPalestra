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
    var supersetGroupId: String? = nil
    var supersetName: String? = nil

    // Stored come opzionale per retrocompatibilità Firestore:
    // vecchi documenti senza il campo vengono decodificati come nil
    // senza errori, invece di far saltare l'intera sessione.
    private var _restAfterSeconds: Int?

    /// Recupero effettivo in secondi (default 60 se assente in Firestore).
    var restAfterSeconds: Int {
        get { _restAfterSeconds ?? 60 }
        set { _restAfterSeconds = newValue }
    }

    // Init esplicito con label pubblica restAfterSeconds
    // (evita che Swift generi il memberwise con _restAfterSeconds).
    init(
        id: String = UUID().uuidString,
        exerciseId: String,
        name: String,
        isBodyweight: Bool,
        sets: [WorkoutSet],
        isPR: Bool,
        exerciseNotes: String = "",
        supersetGroupId: String? = nil,
        supersetName: String? = nil,
        restAfterSeconds: Int = 60
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.name = name
        self.isBodyweight = isBodyweight
        self.sets = sets
        self.isPR = isPR
        self.exerciseNotes = exerciseNotes
        self.supersetGroupId = supersetGroupId
        self.supersetName = supersetName
        self._restAfterSeconds = restAfterSeconds
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
