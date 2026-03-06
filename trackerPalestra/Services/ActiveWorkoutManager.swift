import SwiftUI
import Combine

// Un EnvironmentObject o un singleton globale per tenere traccia
// della sessione attiva in modo che il ciclo di vita dell'App possa salvarla
class ActiveWorkoutManager: ObservableObject {
    static let shared = ActiveWorkoutManager()
    
    @Published var activeSession: WorkoutSession? = nil
    
    func register(_ session: WorkoutSession) {
        self.activeSession = session
    }
    
    func clear() {
        self.activeSession = nil
    }
}
