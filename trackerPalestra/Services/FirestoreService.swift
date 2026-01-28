import Foundation
import FirebaseFirestore

final class FirestoreService {
    static let shared = FirestoreService()
    private init() {}

    private let db = Firestore.firestore()

    // MARK: - Piani (Schede)
    func fetchPlans(for userId: String, completion: @escaping ([WorkoutPlan]) -> Void) {
        db.collection("workoutPlans").whereField("userId", isEqualTo: userId).getDocuments { snapshot, _ in
            let plans = snapshot?.documents.compactMap { try? $0.data(as: WorkoutPlan.self) } ?? []
            completion(plans)
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
        } catch { completion(false) }
    }

    func deletePlan(id: String, completion: @escaping (Bool) -> Void) {
        db.collection("workoutPlans").document(id).delete { error in completion(error == nil) }
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
        } catch { completion(false) }
    }

    // RISOLVE: Value of type 'FirestoreService' has no member 'deleteWorkoutSession'
    func deleteWorkoutSession(id: String, completion: @escaping (Bool) -> Void) {
        db.collection("workoutSessions").document(id).delete { error in
            completion(error == nil)
        }
    }

    // MARK: - Libreria nomi (Dataset)
    func fetchExerciseNames(completion: @escaping ([String]) -> Void) {
        db.collection("exerciseNames").getDocuments { snapshot, _ in
            let names = snapshot?.documents.compactMap { $0.data()["name"] as? String } ?? []
            completion(Array(Set(names)).sorted())
        }
    }

    func saveExerciseName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return }
        // FIX CRASH: Trasformiamo "/" in "-" per l'ID del documento
        let safeDocId = trimmed.lowercased().replacingOccurrences(of: "/", with: "-")
        db.collection("exerciseNames").document(safeDocId).setData(["name": trimmed], merge: true)
    }

    // RISOLVE: Value of type 'FirestoreService' has no member 'deleteExerciseName'
    func deleteExerciseName(name: String, completion: @escaping (Bool) -> Void) {
        let safeDocId = name.lowercased().replacingOccurrences(of: "/", with: "-")
        db.collection("exerciseNames").document(safeDocId).delete { error in
            completion(error == nil)
        }
    }
}
