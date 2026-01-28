import SwiftUI

struct ExerciseHistoryDetailView: View {
    @EnvironmentObject var viewModel: MainViewModel
    let exerciseName: String

    var exerciseHistory: [(date: Date, exerciseSession: WorkoutExerciseSession, sessionId: String)] {
        var results: [(Date, WorkoutExerciseSession, String)] = []
        for session in viewModel.workoutHistory {
            if let sessionId = session.id, let exercise = session.exercises.first(where: { $0.name.lowercased() == exerciseName.lowercased() }) {
                results.append((session.date, exercise, sessionId))
            }
        }
        return results.sorted { $0.0 > $1.0 }
    }

    var body: some View {
        ZStack {
            Color.customBlack.ignoresSafeArea()
            List {
                ForEach(exerciseHistory, id: \.date) { record in
                    HistoryRowCard(date: record.date, exercise: record.exerciseSession)
                        .listRowBackground(Color.clear).listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { viewModel.deleteSession(id: record.sessionId) } label: { Label("Elimina", systemImage: "trash") }
                        }
                }
            }
            .listStyle(.plain).scrollContentBackground(.hidden)
            .overlay { if exerciseHistory.isEmpty { Text("Nessun dato").foregroundColor(.secondary) } }
        }
        .navigationTitle(exerciseName.uppercased())
    }
}

struct HistoryRowCard: View {
    let date: Date
    let exercise: WorkoutExerciseSession
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(date.formatted(date: .abbreviated, time: .omitted).uppercased()).font(.system(size: 12, weight: .black)).foregroundColor(.acidGreen)
                Spacer(); if exercise.isPR { Image(systemName: "trophy.fill").foregroundColor(.acidGreen) }
            }
            VStack(spacing: 8) {
                ForEach(exercise.sets) { set in
                    HStack {
                        Text("SET \(set.setIndex + 1)").font(.system(size: 10, weight: .bold)).foregroundColor(.deepPurple).frame(width: 40, alignment: .leading)
                        Text("\(set.reps) REPS").font(.system(.body, design: .monospaced)).foregroundColor(.white)
                        if !exercise.isBodyweight { Spacer(); Text("\(set.weight, specifier: "%.1f") KG").font(.system(.body, design: .monospaced)).fontWeight(.bold).foregroundColor(.white) }
                    }
                    .padding(8).background(Color.white.opacity(0.03)).cornerRadius(8)
                }
            }
            if !exercise.exerciseNotes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NOTE").font(.system(size: 8, weight: .bold)).foregroundColor(.acidGreen.opacity(0.7))
                    Text(exercise.exerciseNotes).font(.caption).italic().foregroundColor(.white.opacity(0.7))
                }
                .padding(8).frame(maxWidth: .infinity, alignment: .leading).background(Color.deepPurple.opacity(0.1)).cornerRadius(8)
            }
        }
        .padding().background(Color.white.opacity(0.05)).cornerRadius(16).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.deepPurple.opacity(0.2), lineWidth: 1))
    }
}
