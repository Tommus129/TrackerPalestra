import Foundation
import Combine
import Firebase
import FirebaseFirestore

final class MainViewModel: ObservableObject {
    @Published var plans: [WorkoutPlan] = []
    @Published var workoutHistory: [WorkoutSession] = []
    @Published var userId: String?
    @Published var exerciseNames: [String] = [] // Libreria globale per esercizi extra
    @Published var editingPlan: WorkoutPlan?

    init(userId: String) {
        self.userId = userId
        loadPlans()
        loadExerciseNames()
        fetchWorkoutHistory()
    }

    // MARK: - Utility
    
    // Normalizza i nomi (es: " panca piana " -> "Panca Piana") per evitare duplicati nel dataset
    func normalizeName(_ name: String) -> String {
        return name.trimmingCharacters(in: .whitespacesAndNewlines).capitalized
    }

    // MARK: - Caricamento Dati

    func loadPlans() {
        guard let userId = userId else { return }
        FirestoreService.shared.fetchPlans(for: userId) { [weak self] plans in
            DispatchQueue.main.async { self?.plans = plans }
        }
    }

    func loadExerciseNames() {
        FirestoreService.shared.fetchExerciseNames { [weak self] names in
            DispatchQueue.main.async { self?.exerciseNames = names }
        }
    }

    func fetchWorkoutHistory() {
        guard let userId = userId else { return }
        Firestore.firestore()
            .collection("workoutSessions")
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .getDocuments { [weak self] snapshot, _ in
                let sessions = snapshot?.documents.compactMap { try? $0.data(as: WorkoutSession.self) } ?? []
                DispatchQueue.main.async { self?.workoutHistory = sessions }
            }
    }

    // MARK: - Eliminazione

    func deletePlan(at offsets: IndexSet) {
        offsets.forEach { index in
            let plan = plans[index]
            if let id = plan.id {
                FirestoreService.shared.deletePlan(id: id) { success in
                    if success {
                        DispatchQueue.main.async { self.plans.remove(at: index) }
                    }
                }
            }
        }
    }

    func deleteSession(id: String) {
        FirestoreService.shared.deleteWorkoutSession(id: id) { [weak self] success in
            if success {
                DispatchQueue.main.async { self?.fetchWorkoutHistory() }
            }
        }
    }

    func deleteExerciseName(at offsets: IndexSet) {
        offsets.forEach { index in
            let name = exerciseNames[index]
            FirestoreService.shared.deleteExerciseName(name: name) { success in
                if success {
                    DispatchQueue.main.async { self.exerciseNames.remove(at: index) }
                }
            }
        }
    }

    // MARK: - Gestione Schede (Piani)

    func prepareNewPlan() {
        editingPlan = WorkoutPlan(
            id: nil,
            userId: userId ?? "",
            name: "Nuova scheda",
            days: [WorkoutPlanDay(id: UUID().uuidString, label: "Giorno A", exercises: [])],
            createdAt: Date()
        )
    }

    func saveEditingPlan(completion: @escaping (Bool) -> Void) {
        guard var plan = editingPlan else { return }
        
        // 1. Normalizza i nomi di tutti gli esercizi della scheda prima di salvare
        for i in plan.days.indices {
            for j in plan.days[i].exercises.indices {
                plan.days[i].exercises[j].name = normalizeName(plan.days[i].exercises[j].name)
            }
        }
        
        FirestoreService.shared.savePlan(plan) { [weak self] success in
            if success {
                self?.loadPlans()
                
                // 2. AGGIORNAMENTO DATASET: Estrae i nomi singoli e li salva nella libreria globale
                let names = Set(plan.days.flatMap { $0.exercises.map { $0.name } })
                names.forEach { FirestoreService.shared.saveExerciseName($0) }
                
                self?.loadExerciseNames()
            }
            DispatchQueue.main.async { completion(success) }
        }
    }

    // MARK: - Gestione Sessioni (Allenamenti)

    func makeSession(plan: WorkoutPlan, day: WorkoutPlanDay) -> WorkoutSession {
            let exercises = day.exercises.map { ex in
                WorkoutExerciseSession(
                    exerciseId: ex.id,
                    name: ex.name,
                    isBodyweight: ex.isBodyweight,
                    sets: (0..<ex.defaultSets).map { idx in
                        WorkoutSet(
                            id: UUID().uuidString,
                            setIndex: idx,
                            reps: ex.defaultReps,
                            weight: 0,
                            isPR: false
                        )
                    },
                    isPR: false,
                    exerciseNotes: ex.notes
                )
            }
            
            // AGGIUNTO: id: UUID().uuidString per rendere l'oggetto identificabile da SwiftUI immediatamente
            return WorkoutSession(
                id: UUID().uuidString,
                userId: userId ?? "",
                planId: plan.id ?? "",
                dayId: day.id,
                date: Date(),
                notes: "",
                exercises: exercises
            )
        }

    func saveSession(_ session: WorkoutSession, completion: @escaping (Bool) -> Void) {
        var normalizedSession = session
        
        // Normalizza i nomi degli esercizi nella sessione
        for i in normalizedSession.exercises.indices {
            normalizedSession.exercises[i].name = normalizeName(normalizedSession.exercises[i].name)
        }

        FirestoreService.shared.saveSession(normalizedSession) { [weak self] success in
            if success {
                self?.fetchWorkoutHistory()
                
                // Aggiorna libreria nomi anche durante la sessione (per catturare extra nuovi)
                normalizedSession.exercises.forEach { FirestoreService.shared.saveExerciseName($0.name) }
                
                self?.loadExerciseNames()
            }
            DispatchQueue.main.async { completion(success) }
        }
    }
    
    // Aggiungi questo metodo all'interno della classe MainViewModel
    func getLastMaxWeight(for exerciseName: String) -> Double? {
        let targetName = normalizeName(exerciseName)
        
        // workoutHistory è già ordinato per data decrescente
        for session in workoutHistory {
            if let exercise = session.exercises.first(where: { normalizeName($0.name) == targetName }) {
                // Troviamo il peso massimo tra i set di quell'esercizio in quella sessione
                let maxWeight = exercise.sets.map { $0.weight }.max()
                if let max = maxWeight, max > 0 {
                    return max
                }
            }
        }
        return nil
    }
    
    // Aggiungi questo in MainViewModel.swift

    /// Recupera l'ultima esecuzione completa di un determinato esercizio per mostrare i Ghost Sets
    func getLastExerciseSession(for name: String) -> WorkoutExerciseSession? {
        let targetName = normalizeName(name)
        // Cerca nella storia la prima sessione che contiene l'esercizio
        for session in workoutHistory {
            if let exercise = session.exercises.first(where: { normalizeName($0.name) == targetName }) {
                return exercise
            }
        }
        return nil
    }
}

// MARK: - Computed Properties

extension MainViewModel {
    var sessionsByDay: [Date: [WorkoutSession]] {
        let cal = Calendar.current
        var dict: [Date: [WorkoutSession]] = [:]
        for session in workoutHistory {
            let comps = cal.dateComponents([.year, .month, .day], from: session.date)
            if let day = cal.date(from: comps) {
                dict[day, default: []].append(session)
            }
        }
        return dict
    }
}
