import Foundation
import FirebaseFirestore

final class FirestoreService {
    static let shared = FirestoreService()
    private init() {}

    private let db = Firestore.firestore()

    // MARK: - Piani (Schede)
    func fetchPlans(for userId: String, completion: @escaping @Sendable ([WorkoutPlan]) -> Void) {
        db.collection("workoutPlans")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, _ in
                Task { @MainActor in
                    let plans = snapshot?.documents.compactMap { doc -> WorkoutPlan? in
                        try? doc.data(as: WorkoutPlan.self)
                    } ?? []
                    completion(plans)
                }
            }
    }

    func savePlan(_ plan: WorkoutPlan, completion: @escaping (Bool) -> Void) {
        do {
            if let id = plan.id {
                try db.collection("workoutPlans").document(id).setData(from: plan, merge: true)
            } else {
                let _ = try db.collection("workoutPlans").addDocument(from: plan)
            }
            completion(true)
        } catch {
            print("Error saving plan: \(error)")
            completion(false)
        }
    }

    func updatePlanOrder(planId: String, newOrder: Int) {
        db.collection("workoutPlans").document(planId).updateData(["order": newOrder])
    }

    func deletePlan(id: String, completion: @escaping (Bool) -> Void) {
        db.collection("workoutPlans").document(id).delete { error in
            completion(error == nil)
        }
    }

    // MARK: - Sessioni (Allenamenti)
    func saveSession(_ session: WorkoutSession, completion: @escaping (Bool) -> Void) {
        do {
            if let id = session.id {
                try db.collection("workoutSessions").document(id).setData(from: session, merge: true)
            } else {
                let _ = try db.collection("workoutSessions").addDocument(from: session)
            }
            completion(true)
        } catch {
            print("Error saving session: \(error)")
            completion(false)
        }
    }

    func deleteWorkoutSession(id: String, completion: @escaping (Bool) -> Void) {
        db.collection("workoutSessions").document(id).delete { error in
            completion(error == nil)
        }
    }

    // MARK: - Libreria esercizi per utente
    func fetchExerciseLibrary(for userId: String, completion: @escaping @Sendable ([ExerciseLibraryItem]) -> Void) {
        db.collection("exerciseLibrary")
            .whereField("userId", isEqualTo: userId)
            .order(by: "name")
            .getDocuments { snapshot, error in
                Task { @MainActor in
                    if let error = error {
                        print("Error fetching exercises: \(error)")
                        completion([])
                        return
                    }
                    let exercises = snapshot?.documents.compactMap { doc -> ExerciseLibraryItem? in
                        try? doc.data(as: ExerciseLibraryItem.self)
                    } ?? []
                    completion(exercises)
                }
            }
    }
    
    func saveExerciseToLibrary(_ exercise: ExerciseLibraryItem, completion: @escaping (Bool) -> Void) {
        do {
            if let id = exercise.id {  // ← exercise.id è Optional
                try db.collection("exerciseLibrary").document(id).setData(from: exercise, merge: true)
            } else {
                let _ = try db.collection("exerciseLibrary").addDocument(from: exercise)
            }
            completion(true)
        } catch {
            print("Error saving exercise: \(error)")
            completion(false)
        }
    }

    
    func deleteExerciseFromLibrary(id: String, completion: @escaping (Bool) -> Void) {
        db.collection("exerciseLibrary").document(id).delete { error in
            completion(error == nil)
        }
    }

    // MARK: - Libreria nomi globali (opzionale, per suggerimenti)
    func fetchExerciseNames(completion: @escaping ([String]) -> Void) {
        db.collection("exerciseNames").getDocuments { snapshot, _ in
            let names = snapshot?.documents.compactMap { $0.data()["name"] as? String } ?? []
            completion(Array(Set(names)).sorted())
        }
    }

    func saveExerciseName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let safeDocId = trimmed.lowercased().replacingOccurrences(of: "/", with: "-")
        db.collection("exerciseNames").document(safeDocId).setData(["name": trimmed], merge: true)
    }

    func deleteExerciseName(name: String, completion: @escaping (Bool) -> Void) {
        let safeDocId = name.lowercased().replacingOccurrences(of: "/", with: "-")
        db.collection("exerciseNames").document(safeDocId).delete { error in
            completion(error == nil)
        }
    }
}
