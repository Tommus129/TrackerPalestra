import Foundation
import Combine
import Firebase
import FirebaseFirestore
import SwiftUI

final class MainViewModel: ObservableObject {
    @Published var plans: [WorkoutPlan] = []
    @Published var workoutHistory: [WorkoutSession] = []
    @Published var userId: String?
    @Published var exerciseNames: [String] = []
    @Published var editingPlan: WorkoutPlan?
    @Published var activeDraft: WorkoutSession? = nil

    /// Numero massimo di sessioni caricate in memoria per evitare uso eccessivo di RAM.
    private let historyFetchLimit = 50

    init(userId: String) {
        self.userId = userId
        loadPlans()
        loadExerciseNames()
        fetchWorkoutHistory()
        loadDraft()
    }

    // MARK: - Utility

    func normalizeName(_ name: String) -> String {
        return name.trimmingCharacters(in: .whitespacesAndNewlines).capitalized
    }

    // MARK: - Caricamento Dati

    func loadPlans() {
        guard let userId = userId else { return }
        FirestoreService.shared.fetchPlans(for: userId) { [weak self] plans in
            DispatchQueue.main.async {
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
            .limit(to: historyFetchLimit)
            .getDocuments { [weak self] snapshot, _ in
                Task { @MainActor in
                    let sessions = snapshot?.documents.compactMap { doc -> WorkoutSession? in
                        try? doc.data(as: WorkoutSession.self)
                    } ?? []
                    self?.workoutHistory = sessions
                }
            }
    }

    // MARK: - Ordinamento

    func movePlan(from source: IndexSet, to destination: Int) {
        plans.move(fromOffsets: source, toOffset: destination)
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
            if success { self?.loadExerciseNames() }
        }
    }

    // MARK: - Gestione Schede

    func prepareNewPlan() {
        guard let userId = userId, !userId.isEmpty else { return }
        editingPlan = WorkoutPlan(
            id: nil, userId: userId, name: "Nuova scheda",
            days: [WorkoutPlanDay(id: UUID().uuidString, label: "Giorno A", items: [])],
            createdAt: Date(), order: plans.count
        )
    }

    func prepareEditPlan(_ plan: WorkoutPlan) {
        editingPlan = plan
    }

    func saveEditingPlan(completion: @escaping (Bool) -> Void) {
        guard var plan = editingPlan else { return }
        for i in plan.days.indices {
            for j in plan.days[i].items.indices {
                switch plan.days[i].items[j].kind {
                case .exercise:
                    if var ex = plan.days[i].items[j].exercise {
                        ex.name = normalizeName(ex.name)
                        plan.days[i].items[j].exercise = ex
                    }
                case .superset:
                    if var ss = plan.days[i].items[j].superset {
                        for k in ss.exercises.indices { ss.exercises[k].name = normalizeName(ss.exercises[k].name) }
                        plan.days[i].items[j].superset = ss
                    }
                }
            }
        }
        FirestoreService.shared.savePlan(plan) { [weak self] success in
            if success {
                self?.loadPlans()
                let names = Set(plan.days.flatMap { day -> [String] in
                    day.items.flatMap { item -> [String] in
                        switch item.kind {
                        case .exercise: return [item.exercise?.name].compactMap { $0 }
                        case .superset: return item.superset?.exercises.map { $0.name } ?? []
                        }
                    }
                })
                names.forEach { FirestoreService.shared.saveExerciseName($0) }
                self?.loadExerciseNames()
            }
            DispatchQueue.main.async { completion(success) }
        }
    }

    // MARK: - Bozza Allenamento

    func loadDraft() {
        if let data = UserDefaults.standard.data(forKey: "workoutDraft"),
           let draft = try? JSONDecoder().decode(WorkoutSession.self, from: data) {
            self.activeDraft = draft
        }
    }

    /// Salva la bozza in modo asincrono su un thread di background per non bloccare la UI.
    func saveDraft(_ session: WorkoutSession) {
        self.activeDraft = session
        Task.detached(priority: .utility) {
            if let data = try? JSONEncoder().encode(session) {
                UserDefaults.standard.set(data, forKey: "workoutDraft")
            }
        }
    }

    /// Salvataggio sincrono e immediato: da usare SOLO quando l'app va in background.
    func saveDraftImmediately(_ session: WorkoutSession) {
        self.activeDraft = session
        if let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: "workoutDraft")
            UserDefaults.standard.synchronize()
        }
    }

    func clearDraft() {
        UserDefaults.standard.removeObject(forKey: "workoutDraft")
        self.activeDraft = nil
    }

    // MARK: - Sessioni

    func makeSession(plan: WorkoutPlan, day: WorkoutPlanDay) -> WorkoutSession {
        var exercises: [WorkoutExerciseSession] = []

        for item in day.resolvedItems {
            switch item.kind {
            case .exercise:
                guard let ex = item.exercise else { continue }
                exercises.append(WorkoutExerciseSession(
                    exerciseId: ex.id,
                    name: ex.name,
                    isBodyweight: ex.isBodyweight,
                    sets: (0..<ex.sets).map { idx in
                        WorkoutSet(id: UUID().uuidString, setIndex: idx,
                                   reps: ex.reps(forSet: idx), weight: 0, isPR: false)
                    },
                    isPR: false,
                    exerciseNotes: ex.notes,
                    supersetGroupId: nil,
                    supersetName: nil,
                    isCircuit: nil,
                    restAfterSeconds: ex.restAfterSeconds
                ))
            case .superset:
                guard let ss = item.superset else { continue }
                let groupId = UUID().uuidString
                for ex in ss.exercises {
                    exercises.append(WorkoutExerciseSession(
                        exerciseId: ex.id,
                        name: ex.name,
                        isBodyweight: ex.isBodyweight,
                        sets: (0..<ex.sets).map { idx in
                            WorkoutSet(id: UUID().uuidString, setIndex: idx,
                                       reps: ex.reps(forSet: idx), weight: 0, isPR: false)
                        },
                        isPR: false,
                        exerciseNotes: ex.notes,
                        supersetGroupId: groupId,
                        supersetName: ss.name,
                        isCircuit: ss.isCircuit,
                        restAfterSeconds: ss.restAfterSeconds
                    ))
                }
            }
        }

        return WorkoutSession(
            id: UUID().uuidString, userId: userId ?? "",
            planId: plan.id ?? "", dayId: day.id,
            date: Date(), notes: "", exercises: exercises
        )
    }

    func saveSession(_ session: WorkoutSession, completion: @escaping (Bool) -> Void) {
        var normalizedSession = session
        for i in normalizedSession.exercises.indices {
            normalizedSession.exercises[i].name = normalizeName(normalizedSession.exercises[i].name)
        }
        FirestoreService.shared.saveSession(normalizedSession) { [weak self] success in
            if success {
                self?.fetchWorkoutHistory()
                normalizedSession.exercises.forEach { FirestoreService.shared.saveExerciseName($0.name) }
                self?.loadExerciseNames()
            }
            DispatchQueue.main.async { completion(success) }
        }
    }

    func updateSession(_ session: WorkoutSession, completion: @escaping (Bool) -> Void) {
        guard let sessionId = session.id, !sessionId.isEmpty else {
            saveSession(session, completion: completion)
            return
        }
        var normalizedSession = session
        for i in normalizedSession.exercises.indices {
            normalizedSession.exercises[i].name = normalizeName(normalizedSession.exercises[i].name)
        }
        let db = Firestore.firestore()
        do {
            try db.collection("workoutSessions").document(sessionId).setData(from: normalizedSession) { [weak self] error in
                let success = error == nil
                if success {
                    self?.fetchWorkoutHistory()
                    normalizedSession.exercises.forEach { FirestoreService.shared.saveExerciseName($0.name) }
                    self?.loadExerciseNames()
                }
                DispatchQueue.main.async { completion(success) }
            }
        } catch {
            DispatchQueue.main.async { completion(false) }
        }
    }

    // MARK: - Analisi

    func getLastMaxWeight(for exerciseName: String) -> Double? {
        let targetName = normalizeName(exerciseName)
        for session in workoutHistory {
            if let exercise = session.exercises.first(where: { normalizeName($0.name) == targetName }) {
                let maxWeight = exercise.sets.map { $0.weight }.max()
                if let max = maxWeight, max > 0 { return max }
            }
        }
        return nil
    }

    func getLastExerciseSession(for name: String) -> WorkoutExerciseSession? {
        let targetName = normalizeName(name)
        for session in workoutHistory {
            if let exercise = session.exercises.first(where: { normalizeName($0.name) == targetName }) {
                return exercise
            }
        }
        return nil
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
            }
        }
        return dict
    }
}
