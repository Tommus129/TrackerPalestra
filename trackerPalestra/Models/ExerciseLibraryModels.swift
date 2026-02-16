import Foundation
import FirebaseFirestore

struct ExerciseLibraryItem: Identifiable, Codable, Hashable {
    @DocumentID var id: String?  // ← DEVE essere Optional con @DocumentID
    var userId: String
    var name: String
    var createdAt: Date = Date()
    
    // Inizializzatore per creare nuovi esercizi
    init(id: String? = nil, userId: String, name: String, createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.name = name
        self.createdAt = createdAt
    }
}
