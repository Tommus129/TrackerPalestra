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

    // MARK: - CodingKeys
    enum CodingKeys: String, CodingKey {
        case id, label, items, exercises
    }

    // Decodifica robusta: tolera documenti vecchi senza il campo "items"
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id        = try c.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        label     = try c.decodeIfPresent(String.self, forKey: .label) ?? ""
        items     = try c.decodeIfPresent([WorkoutPlanItem].self, forKey: .items) ?? []
        exercises = try c.decodeIfPresent([WorkoutPlanExercise].self, forKey: .exercises)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,        forKey: .id)
        try c.encode(label,     forKey: .label)
        try c.encode(items,     forKey: .items)
        try c.encodeIfPresent(exercises, forKey: .exercises)
    }

    // Memberwise init per uso in-app
    init(id: String = UUID().uuidString,
         label: String,
         items: [WorkoutPlanItem] = [],
         exercises: [WorkoutPlanExercise]? = nil) {
        self.id = id
        self.label = label
        self.items = items
        self.exercises = exercises
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

    var repsDisplay: String {
        repsBySet.map { String($0) }.joined(separator: " ")
    }

    func reps(forSet index: Int) -> Int {
        if repsBySet.count == 1 { return repsBySet[0] }
        return repsBySet[min(index, repsBySet.count - 1)]
    }

    // MARK: Inits

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
            let s = try c.decodeIfPresent(Int.self, forKey: .defaultSets) ?? (try c.decodeIfPresent(Int.self, forKey: .sets) ?? 3)
            let r = try c.decodeIfPresent(Int.self, forKey: .defaultReps) ?? 8
            sets = s
            repsBySet = [r]
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,          forKey: .id)
        try c.encode(name,        forKey: .name)
        try c.encode(sets,        forKey: .sets)
        try c.encode(repsBySet,   forKey: .repsBySet)
        try c.encode(isBodyweight, forKey: .isBodyweight)
        try c.encode(notes,       forKey: .notes)
    }
}
