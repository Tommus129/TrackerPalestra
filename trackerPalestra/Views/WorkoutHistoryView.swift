import SwiftUI

struct WorkoutHistoryView: View {
    @EnvironmentObject var viewModel: MainViewModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.workoutHistory) { session in
                    NavigationLink {
                        WorkoutSessionDetailView(session: session)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(formatDate(session.date))
                                .font(.headline)

                            Text("Piano: \(session.planId) • Giorno: \(session.dayId)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            if !session.notes.isEmpty {
                                Text(session.notes)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Storico")
            .onAppear {
                viewModel.fetchWorkoutHistory()
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
