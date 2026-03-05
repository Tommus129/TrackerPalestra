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
    // isCircuit: nil = esercizio normale / superset precedenti; false = superset; true = circuito
    var isCircuit: Bool? = nil

    private var _restAfterSeconds: Int?
    var restAfterSeconds: Int {
        get { _restAfterSeconds ?? 60 }
        set { _restAfterSeconds = newValue }
    }

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
        isCircuit: Bool? = nil,
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
        self.isCircuit = isCircuit
        self._restAfterSeconds = restAfterSeconds
    }

    enum CodingKeys: String, CodingKey {
        case id, exerciseId, name, isBodyweight, sets, isPR, exerciseNotes
        case supersetGroupId, supersetName, isCircuit
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
