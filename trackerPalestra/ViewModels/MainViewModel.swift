import Foundation
import Combine
import Firebase
import FirebaseFirestore
import SwiftUI // Necessario per .move(fromOffsets:toOffset:) e IndexSet

final class MainViewModel: ObservableObject {
    @Published var plans: [WorkoutPlan] = []
    @Published var workoutHistory: [WorkoutSession] = []
    @Published var userId: String?
    @Published var exerciseNames: [String] = [] // Libreria globale per suggerimenti esercizi
    @Published var editingPlan: WorkoutPlan?

    init(userId: String) {
        self.userId = userId
        loadPlans()
        loadExerciseNames()
        fetchWorkoutHistory()
    }

    // MARK: - Utility
    
    /// Normalizza i nomi (es: " panca piana " -> "Panca Piana") per evitare duplicati nel dataset
    func normalizeName(_ name: String) -> String {
        return name.trimmingCharacters(in: .whitespacesAndNewlines).capitalized
    }

    // MARK: - Caricamento Dati

    func loadPlans() {
        guard let userId = userId else { return }
        FirestoreService.shared.fetchPlans(for: userId) { [weak self] plans in
            DispatchQueue.main.async {
                // Ordiniamo localmente: se l'ordine è nil (scheda vecchia), usiamo 0
                // Questo garantisce che le schede appaiano sempre nell'ordine scelto dall'utente
                self?.plans = plans.sorted(by: { ($0.order ?? 0) < ($1.order ?? 0) })
            }
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
                Task { @MainActor in  // ← AGGIUNGI QUESTO
                    let sessions = snapshot?.documents.compactMap { doc -> WorkoutSession? in
                        try? doc.data(as: WorkoutSession.self)
                    } ?? []
                    self?.workoutHistory = sessions
                }
            }
    }

    // MARK: - Ordinamento (Drag & Drop)
    
    /// Gestisce lo spostamento delle schede nella Home e salva l'ordine su Firestore
    func movePlan(from source: IndexSet, to destination: Int) {
        plans.move(fromOffsets: source, toOffset: destination)
        
        // Aggiorna l'indice 'order' per ogni piano e sincronizza con il database
        for index in plans.indices {
            plans[index].order = index
            if let planId = plans[index].id {
                FirestoreService.shared.updatePlanOrder(planId: planId, newOrder: index)
            }
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

    func deleteExerciseName(name: String) {
        FirestoreService.shared.deleteExerciseName(name: name) { [weak self] success in
            if success {
                self?.loadExerciseNames()
            }
        }
    }

    // MARK: - Gestione Schede (Piani)

    func prepareNewPlan() {
        guard let userId = userId, !userId.isEmpty else {
            print("❌ Errore: userId non disponibile")
            return
        }
        
        editingPlan = WorkoutPlan(
            id: nil,
            userId: userId,
            name: "Nuova scheda",
            days: [WorkoutPlanDay(id: UUID().uuidString, label: "Giorno A", exercises: [])],
            createdAt: Date(),
            order: plans.count
        )
        
        print("✅ Nuova scheda preparata per userId: \(userId)")
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
                
                // 2. AGGIORNAMENTO DATASET: Salva i nomi nella libreria globale per i suggerimenti futuri
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
        
        // Normalizza i nomi prima del salvataggio
        for i in normalizedSession.exercises.indices {
            normalizedSession.exercises[i].name = normalizeName(normalizedSession.exercises[i].name)
        }

        FirestoreService.shared.saveSession(normalizedSession) { [weak self] success in
            if success {
                self?.fetchWorkoutHistory()
                // Aggiorna libreria nomi con eventuali nuovi esercizi extra aggiunti durante la sessione
                normalizedSession.exercises.forEach { FirestoreService.shared.saveExerciseName($0.name) }
                self?.loadExerciseNames()
            }
            DispatchQueue.main.async { completion(success) }
        }
    }
    
    // MARK: - Analisi e Ghost Sets
    
    /// Recupera il peso massimo mai sollevato per un esercizio specifico
    func getLastMaxWeight(for exerciseName: String) -> Double? {
        let targetName = normalizeName(exerciseName)
        for session in workoutHistory {
            if let exercise = session.exercises.first(where: { normalizeName($0.name) == targetName }) {
                let maxWeight = exercise.sets.map { $0.weight }.max()
                if let max = maxWeight, max > 0 {
                    return max
                }
            }
        }
        return nil
    }
    
    /// Recupera l'ultima esecuzione completa di un esercizio per mostrare i Ghost Sets (serie per serie)
    func getLastExerciseSession(for name: String) -> WorkoutExerciseSession? {
        let targetName = normalizeName(name)
        // workoutHistory è già ordinato per data decrescente, quindi il primo match è il più recente
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
    /// Raggruppa le sessioni di allenamento per giorno per la visualizzazione nel Calendario
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
