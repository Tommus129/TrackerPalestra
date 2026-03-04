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

    init(userId: String) {
        self.userId = userId
        loadPlans()
        loadExerciseNames()
        fetchWorkoutHistory()
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
