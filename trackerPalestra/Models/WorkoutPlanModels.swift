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
    var items: [WorkoutPlanItem] = []
    var exercises: [WorkoutPlanExercise]?

    var resolvedItems: [WorkoutPlanItem] {
        if !items.isEmpty { return items }
        return (exercises ?? []).map { WorkoutPlanItem(kind: .exercise, exercise: $0) }
    }

    enum CodingKeys: String, CodingKey { case id, label, items, exercises }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id        = try c.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        label     = try c.decodeIfPresent(String.self, forKey: .label) ?? ""
        items     = try c.decodeIfPresent([WorkoutPlanItem].self, forKey: .items) ?? []
        exercises = try c.decodeIfPresent([WorkoutPlanExercise].self, forKey: .exercises)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,    forKey: .id)
        try c.encode(label, forKey: .label)
        try c.encode(items, forKey: .items)
        try c.encodeIfPresent(exercises, forKey: .exercises)
    }

    init(id: String = UUID().uuidString, label: String,
         items: [WorkoutPlanItem] = [], exercises: [WorkoutPlanExercise]? = nil) {
        self.id = id; self.label = label; self.items = items; self.exercises = exercises
    }
}

// MARK: - WorkoutPlanItem

struct WorkoutPlanItem: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var kind: Kind
    var exercise: WorkoutPlanExercise?
    var superset: WorkoutPlanSuperset?

    enum Kind: String, Codable { case exercise, superset }
}

// MARK: - WorkoutPlanSuperset
// isCircuit = true → comportamento circuito (timer parte dopo l'ultimo esercizio del giro,
// colore cyan nell'UI, label "CIRCUITO" invece di "SUPERSET")

struct WorkoutPlanSuperset: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var name: String = "Superset"
    var exercises: [WorkoutPlanExercise] = []
    var restAfterSeconds: Int = 60
    var isCircuit: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, name, exercises, restAfterSeconds, isCircuit
    }

    init(id: String = UUID().uuidString, name: String = "Superset",
         exercises: [WorkoutPlanExercise] = [], restAfterSeconds: Int = 60, isCircuit: Bool = false) {
        self.id = id; self.name = name; self.exercises = exercises
        self.restAfterSeconds = restAfterSeconds; self.isCircuit = isCircuit
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id               = try c.decodeIfPresent(String.self,              forKey: .id)               ?? UUID().uuidString
        name             = try c.decodeIfPresent(String.self,              forKey: .name)             ?? "Superset"
        exercises        = try c.decodeIfPresent([WorkoutPlanExercise].self, forKey: .exercises)      ?? []
        restAfterSeconds = try c.decodeIfPresent(Int.self,                 forKey: .restAfterSeconds) ?? 60
        isCircuit        = try c.decodeIfPresent(Bool.self,                forKey: .isCircuit)        ?? false
    }
}

// MARK: - WorkoutPlanExercise

struct WorkoutPlanExercise: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var sets: Int
    var repsBySet: [Int]
    var isBodyweight: Bool
    var notes: String = ""
    var restAfterSeconds: Int = 60

    var repsDisplay: String { repsBySet.map { String($0) }.joined(separator: " ") }

    func reps(forSet index: Int) -> Int {
        if repsBySet.count == 1 { return repsBySet[0] }
        return repsBySet[min(index, repsBySet.count - 1)]
    }

    init(id: String = UUID().uuidString, name: String, sets: Int, repsBySet: [Int],
         isBodyweight: Bool, notes: String = "", restAfterSeconds: Int = 60) {
        self.id = id; self.name = name; self.sets = sets; self.repsBySet = repsBySet
        self.isBodyweight = isBodyweight; self.notes = notes; self.restAfterSeconds = restAfterSeconds
    }

    init(id: String = UUID().uuidString, name: String, defaultSets: Int, defaultReps: Int,
         isBodyweight: Bool, notes: String = "") {
        self.id = id; self.name = name; self.sets = defaultSets; self.repsBySet = [defaultReps]
        self.isBodyweight = isBodyweight; self.notes = notes; self.restAfterSeconds = 60
    }

    enum CodingKeys: String, CodingKey {
        case id, name, sets, repsBySet, isBodyweight, notes, restAfterSeconds
        case defaultSets, defaultReps
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id           = try c.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        name         = try c.decode(String.self, forKey: .name)
        isBodyweight = try c.decodeIfPresent(Bool.self, forKey: .isBodyweight) ?? false
        notes        = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        restAfterSeconds = try c.decodeIfPresent(Int.self, forKey: .restAfterSeconds) ?? 60
        if let rbs = try c.decodeIfPresent([Int].self, forKey: .repsBySet), !rbs.isEmpty {
            repsBySet = rbs
            sets = try c.decodeIfPresent(Int.self, forKey: .sets) ?? rbs.count
        } else {
            let s = try c.decodeIfPresent(Int.self, forKey: .defaultSets) ?? (try c.decodeIfPresent(Int.self, forKey: .sets) ?? 3)
            let r = try c.decodeIfPresent(Int.self, forKey: .defaultReps) ?? 8
            sets = s; repsBySet = [r]
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
        try c.encode(restAfterSeconds, forKey: .restAfterSeconds)
    }
}
