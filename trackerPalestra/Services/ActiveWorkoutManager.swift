import SwiftUI
import Combine

// Un EnvironmentObject o un singleton globale per tenere traccia
// della sessione attiva in modo che il ciclo di vita dell'App possa salvarla
class ActiveWorkoutManager: ObservableObject {
    static let shared = ActiveWorkoutManager()
    
    @Published var activeSession: WorkoutSession? = nil
    var currentUserId: String? = nil
    
    func register(_ session: WorkoutSession) {
        self.activeSession = session
    }
    
    func clear() {
        self.activeSession = nil
    }
    
    // Funzione chiamata brutalmente dall'AppDelegate quando l'app viene killata
    func forceSaveDraft() {
        guard let session = activeSession, let userId = currentUserId else { return }
        
        let hasInputs = session.exercises.flatMap { $0.sets }.contains { $0.weight > 0 || $0.isCompleted }
        if hasInputs || !session.notes.isEmpty {
            // Salvataggio sincrono in UserDefaults (unico che sopravvive all'app kill)
            let tempViewModel = MainViewModel(userId: userId)
            tempViewModel.saveDraft(session)
            print("💾 BOZZA SALVATA DALL'APP DELEGATE!")
        }
    }
}
