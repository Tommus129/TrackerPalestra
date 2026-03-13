import SwiftUI
import Combine

/// Singleton leggero che tiene in memoria la sessione attiva.
/// NON crea mai un MainViewModel — scrive direttamente su UserDefaults.
class ActiveWorkoutManager: ObservableObject {
    static let shared = ActiveWorkoutManager()

    @Published var activeSession: WorkoutSession? = nil
    var currentUserId: String? = nil

    func register(_ session: WorkoutSession) {
        activeSession = session
    }

    func clear() {
        activeSession = nil
    }

    /// Salvataggio sincrono diretto su UserDefaults, senza creare ViewModel o chiamate Firestore.
    /// Chiamato dall'AppDelegate quando l'app viene sospesa/terminata.
    func forceSaveDraft() {
        guard let session = activeSession else { return }
        let hasInputs = session.exercises.flatMap { $0.sets }.contains { $0.weight > 0 || $0.isCompleted }
        guard hasInputs || !session.notes.isEmpty else { return }
        if let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: "workoutDraft")
            UserDefaults.standard.synchronize()
        }
    }
}
