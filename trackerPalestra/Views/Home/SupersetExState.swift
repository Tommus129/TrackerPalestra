import Foundation

/// Stato locale di un singolo esercizio all'interno di EditSupersetView.
struct SupersetExState {
    var name: String = ""
    var sets: Int = 3
    var uniformReps: Int = 10
    var variableReps: Bool = false
    var repsPerSet: [Int] = Array(repeating: 10, count: 3)

    /// Sincronizza l'array repsPerSet quando cambia il numero di serie.
    mutating func syncRepsArray() {
        if variableReps {
            if repsPerSet.count < sets {
                repsPerSet.append(contentsOf: Array(repeating: repsPerSet.last ?? uniformReps, count: sets - repsPerSet.count))
            } else if repsPerSet.count > sets {
                repsPerSet = Array(repsPerSet.prefix(sets))
            }
        }
    }

    /// Reps finali da passare al modello.
    var resolvedReps: [Int] {
        variableReps ? Array(repsPerSet.prefix(sets)) : [uniformReps]
    }
}
