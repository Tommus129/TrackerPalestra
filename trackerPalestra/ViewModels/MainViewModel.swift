import Foundation
import Combine
import Firebase
import FirebaseFirestore

final class MainViewModel: ObservableObject {
    @Published var plans: [WorkoutPlan] = []
    @Published var currentSession: WorkoutSession?
    @Published var userId: String?              // opzionale
    @Published var workoutHistory: [WorkoutSession] = []

    // Libreria globale di nomi esercizi (tutti quelli mai usati)
    @Published var exerciseNames: [String] = []

    // piano in creazione/modifica
    @Published var editingPlan: WorkoutPlan?
    @Published var selectedPlanForWorkout: WorkoutPlan?

    private var cancellables = Set<AnyCancellable>()

    init(userId: String) {
        self.userId = userId
        loadPlans()
        loadExerciseNames()
    }

    // MARK: - Schede

    func loadPlans() {
        guard let userId = userId else { return }

        FirestoreService.shared.fetchPlans(for: userId) { [weak self] plans in
            DispatchQueue.main.async {
                print("DEBUG loadPlans for userId=\(self?.userId ?? "") -> \(plans.count) schede")
                self?.plans = plans
            }
        }
    }

    // MARK: - Libreria nomi esercizi

    func loadExerciseNames() {
        FirestoreService.shared.fetchExerciseNames { [weak self] names in
            DispatchQueue.main.async {
                print("DEBUG exerciseNames:", names)
                self?.exerciseNames = names
            }
        }
    }

    // MARK: - Gestione schede

    func prepareNewPlan() {
        let emptyDay = WorkoutPlanDay(
            id: UUID().uuidString,
            label: "Day A",
            exercises: []
        )

        editingPlan = WorkoutPlan(
            id: nil,
            userId: userId ?? "",
            name: "Nuova scheda",
            days: [emptyDay],
            createdAt: Date()
        )
    }

    func saveEditingPlan(completion: @escaping (Bool) -> Void) {
        guard let plan = editingPlan else {
            completion(false)
            return
        }
        FirestoreService.shared.savePlan(plan) { [weak self] success in
            print("DEBUG saveEditingPlan success:", success)
            if success {
                // aggiorna schede
                self?.loadPlans()

                // raccogli tutti i nomi esercizi della scheda
                let names = Set(
                    plan.days.flatMap { day in
                        day.exercises.map { $0.name }
                    }
                )
                // salva i nomi nella libreria globale
                names.forEach { FirestoreService.shared.saveExerciseName($0) }

                // ricarica la libreria in memoria
                self?.loadExerciseNames()
            }
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }

    // MARK: - Creazione sessione

    func makeSession(plan: WorkoutPlan, day: WorkoutPlanDay, date: Date = Date()) -> WorkoutSession {
        let exercises = day.exercises.map { ex in
            WorkoutExerciseSession(
                exerciseId: ex.id,
                name: ex.name,
                isBodyweight: ex.isBodyweight,
                sets: (0..<ex.defaultSets).map { setIndex in
                    WorkoutSet(
                        id: UUID().uuidString,
                        setIndex: setIndex,
                        reps: ex.defaultReps,
                        weight: 0,
                        setNotes: nil,
                        isPR: false
                    )
                },
                isPR: false,
                exerciseNotes: ""
            )
        }

        return WorkoutSession(
            id: nil,
            userId: userId ?? "",
            planId: plan.id ?? "",
            dayId: day.id,
            date: date,
            notes: "",
            exercises: exercises
        )
    }

    // MARK: - Salvataggio sessione

    func saveSession(_ session: WorkoutSession, completion: @escaping (Bool) -> Void) {
        FirestoreService.shared.saveSession(session) { success in
            DispatchQueue.main.async {
                if success {
                    self.loadPlans()
                    let names = Set(session.exercises.map { $0.name })
                    names.forEach { FirestoreService.shared.saveExerciseName($0) }
                    self.loadExerciseNames()
                }
                completion(success)
            }
        }
    }

    // MARK: - Storico sessioni

    func fetchWorkoutHistory(completion: @escaping (Error?) -> Void = { _ in }) {
        guard let userId = self.userId else {
            completion(nil)
            return
        }

        Firestore.firestore()
            .collection("workoutSessions")
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("DEBUG fetchWorkoutHistory error:", error)
                    completion(error)
                    return
                }

                let sessions: [WorkoutSession] = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: WorkoutSession.self)
                } ?? []

                Task { @MainActor in
                    self?.workoutHistory = sessions
                    completion(nil)
                }
            }
    }

    func deletePlan(at offsets: IndexSet) {
        let plansToDelete = offsets.map { plans[$0] }

        for plan in plansToDelete {
            guard let id = plan.id else { continue }

            Firestore.firestore()
                .collection("workoutPlans")   // usa il nome della tua collezione schede
                .document(id)
                .delete { [weak self] error in
                    if let error = error {
                        print("DEBUG deletePlan error:", error)
                        return
                    }
                    DispatchQueue.main.async {
                        self?.plans.removeAll { $0.id == plan.id }
                    }
                }
        }
    }



}

extension MainViewModel {
    var sessionsByDay: [Date: [WorkoutSession]] {
        let cal = Calendar.current
        var dict: [Date: [WorkoutSession]] = [:]

        for session in workoutHistory {
            let comps = cal.dateComponents([.year, .month, .day], from: session.date)
            if let day = cal.date(from: comps) {
                dict[day, default: []].append(session)
                print("DEBUG sessionsByDay day=\(day) count=\(dict[day]!.count)")
            }
        }
        return dict
    }
}

extension MainViewModel {
    // Restituisce nome piano e label del giorno partendo da una WorkoutSession
    func resolvePlanAndDay(for session: WorkoutSession) -> (planName: String, dayLabel: String) {
        // trova il piano con id == session.planId
        guard let plan = plans.first(where: { $0.id == session.planId }) else {
            return (planName: session.planId, dayLabel: session.dayId) // fallback: mostra gli id
        }

        // trova il day con id == session.dayId
        if let day = plan.days.first(where: { $0.id == session.dayId }) {
            return (planName: plan.name, dayLabel: day.label)
        } else {
            return (planName: plan.name, dayLabel: session.dayId)
        }
    }
}
