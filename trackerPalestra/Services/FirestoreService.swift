import Foundation
import FirebaseFirestore

final class FirestoreService {
    static let shared = FirestoreService()
    private init() {}

    private let db = Firestore.firestore()

    // MARK: - Piani (schede)

    func fetchPlans(for userId: String, completion: @escaping ([WorkoutPlan]) -> Void) {
        db.collection("workoutPlans")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                guard let docs = snapshot?.documents, error == nil else {
                    completion([])
                    return
                }
                let plans: [WorkoutPlan] = docs.compactMap { try? $0.data(as: WorkoutPlan.self) }
                completion(plans)
            }
    }

    func savePlan(_ plan: WorkoutPlan, completion: @escaping (Bool) -> Void) {
        do {
            let _ = try db.collection("workoutPlans").addDocument(from: plan)
            completion(true)
        } catch {
            completion(false)
        }
    }

    // MARK: - Sessioni

    func fetchSessions(for userId: String,
                       from start: Date,
                       to end: Date,
                       completion: @escaping ([WorkoutSession]) -> Void) {
        db.collection("workoutSessions")
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: start)
            .whereField("date", isLessThanOrEqualTo: end)
            .order(by: "date", descending: true)
            .getDocuments { snapshot, error in
                guard let docs = snapshot?.documents, error == nil else {
                    completion([])
                    return
                }
                let sessions: [WorkoutSession] = docs.compactMap { try? $0.data(as: WorkoutSession.self) }
                completion(sessions)
            }
    }

    func saveSession(_ session: WorkoutSession, completion: @escaping (Bool) -> Void) {
        do {
            if let id = session.id {
                try db.collection("workoutSessions")
                    .document(id)
                    .setData(from: session, merge: true)
            } else {
                let _ = try db.collection("workoutSessions").addDocument(from: session)
            }
            completion(true)
        } catch {
            completion(false)
        }
    }
    func testWrite() {
        let db = Firestore.firestore()
        db.collection("test").addDocument(data: ["createdAt": Date(), "message": "Hello Gym"]) { error in
            if let error = error {
                print("Error testWrite: \(error)")
            } else {
                print("Test write OK")
            }
        }
    }

    // MARK: - Libreria nomi esercizi

    func fetchExerciseNames(completion: @escaping ([String]) -> Void) {
        db.collection("exerciseNames")
            .getDocuments { snapshot, error in
                guard let docs = snapshot?.documents, error == nil else {
                    completion([])
                    return
                }
                let names: [String] = docs.compactMap { $0.data()["name"] as? String }
                completion(Array(Set(names)).sorted())
            }
    }

    func saveExerciseName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let docId = trimmed.lowercased() // 1 documento per nome, niente duplicati

        db.collection("exerciseNames")
            .document(docId)
            .setData(["name": trimmed], merge: true)
    }


    
}
