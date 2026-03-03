import Foundation
import FirebaseFirestore

// MARK: - WorkoutPlan

struct WorkoutPlan: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var userId: String
    var name: String
    var days: [WorkoutPlanDay]
    var createdAt: Date
    var order: Int? = 0
}

// MARK: - WorkoutPlanDay

struct WorkoutPlanDay: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var label: String

    // Nuova struttura (source of truth)
    var items: [WorkoutPlanItem] = []

    // Legacy – usato solo per migrazione da vecchi documenti Firestore
    var exercises: [WorkoutPlanExercise]?

    /// Restituisce sempre la lista di items, convertendo legacy se necessario.
    var resolvedItems: [WorkoutPlanItem] {
        if !items.isEmpty { return items }
        return (exercises ?? []).map { WorkoutPlanItem(kind: .exercise, exercise: $0) }
    }
}

// MARK: - WorkoutPlanItem

struct WorkoutPlanItem: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var kind: Kind
    var exercise: WorkoutPlanExercise?
    var superset: WorkoutPlanSuperset?

    enum Kind: String, Codable {
        case exercise
        case superset
    }
}

// MARK: - WorkoutPlanSuperset

struct WorkoutPlanSuperset: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var name: String = "Superset"
    var exercises: [WorkoutPlanExercise] = []
    var restAfterSeconds: Int = 60
}

// MARK: - WorkoutPlanExercise

struct WorkoutPlanExercise: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var sets: Int

    /// Se count == 1 → reps uniformi per tutte le serie.
    /// Se count == sets → reps diverse per ogni serie (es. [10,9,9,8]).
    var repsBySet: [Int]

    var isBodyweight: Bool
    var notes: String = ""

    // MARK: Helpers

    /// Reps da mostrare in formato leggibile: "10 9 9 8" o "8"
    var repsDisplay: String {
        repsBySet.map { String($0) }.joined(separator: " ")
    }

    /// Reps per la serie n (0-indexed). Fallback all'ultimo valore.
    func reps(forSet index: Int) -> Int {
        if repsBySet.count == 1 { return repsBySet[0] }
        return repsBySet[min(index, repsBySet.count - 1)]
    }

    // MARK: Legacy convenience init (backward compat)
    init(id: String = UUID().uuidString,
         name: String,
         sets: Int,
         repsBySet: [Int],
         isBodyweight: Bool,
         notes: String = "") {
        self.id = id
        self.name = name
        self.sets = sets
        self.repsBySet = repsBySet
        self.isBodyweight = isBodyweight
        self.notes = notes
    }

    // MARK: Old-style init (defaultSets/defaultReps) – usato da codice legacy
    init(id: String = UUID().uuidString,
         name: String,
         defaultSets: Int,
         defaultReps: Int,
         isBodyweight: Bool,
         notes: String = "") {
        self.id = id
        self.name = name
        self.sets = defaultSets
        self.repsBySet = [defaultReps]
        self.isBodyweight = isBodyweight
        self.notes = notes
    }

    // Firestore può salvare il vecchio formato; supportiamo la decodifica
    enum CodingKeys: String, CodingKey {
        case id, name, sets, repsBySet, isBodyweight, notes
        case defaultSets, defaultReps
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        name = try c.decode(String.self, forKey: .name)
        isBodyweight = try c.decodeIfPresent(Bool.self, forKey: .isBodyweight) ?? false
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""

        if let rbs = try c.decodeIfPresent([Int].self, forKey: .repsBySet), !rbs.isEmpty {
            repsBySet = rbs
            sets = try c.decodeIfPresent(Int.self, forKey: .sets) ?? rbs.count
        } else {
            // legacy
            let s = try c.decodeIfPresent(Int.self, forKey: .defaultSets) ?? (try c.decodeIfPresent(Int.self, forKey: .sets) ?? 3)
            let r = try c.decodeIfPresent(Int.self, forKey: .defaultReps) ?? 8
            sets = s
            repsBySet = [r]
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(sets, forKey: .sets)
        try c.encode(repsBySet, forKey: .repsBySet)
        try c.encode(isBodyweight, forKey: .isBodyweight)
        try c.encode(notes, forKey: .notes)
    }
}
