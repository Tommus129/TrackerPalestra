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

    /// FIX C2: rimosso UserDefaults.synchronize() che bloccava il main thread
    /// e poteva causare watchdog kill su iOS 15+ durante la terminazione dell'app.
    func forceSaveDraft() {
        guard let session = activeSession else { return }
        let hasInputs = session.exercises.flatMap { $0.sets }.contains { $0.weight > 0 || $0.isCompleted }
        guard hasInputs || !session.notes.isEmpty else { return }
        if let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: "workoutDraft")
        }
    }
}
