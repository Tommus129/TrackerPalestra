import SwiftUI

struct WorkoutCalendarView: View {
    @EnvironmentObject var viewModel: MainViewModel

    @State private var currentMonth: Date = Date()
    @State private var selectedDay: Date?

    var body: some View {
        NavigationStack {
            VStack {
                // Header mese
                HStack {
                    Button("<") { changeMonth(by: -1) }
                    Spacer()
                    Text(monthYearString(currentMonth))
                        .font(.headline)
                    Spacer()
                    Button(">") { changeMonth(by: 1) }
                }
                .padding(.horizontal)

                let days = daysInMonth(for: currentMonth)

                // Griglia giorni
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible()), count: 7),
                    spacing: 8
                ) {
                    ForEach(days, id: \.self) { day in
                        let hasSessions = (viewModel.sessionsByDay[day]?.isEmpty == false)

                        VStack {
                            Text("\(Calendar.current.component(.day, from: day))")
                                .font(.subheadline)
                                .foregroundColor(hasSessions ? .primary : .secondary)

                            if hasSessions {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selectedDay == day ? Color.blue.opacity(0.4) : Color.clear)
                        )
                        .onTapGesture {
                            selectedDay = day
                        }
                    }
                }
                .padding(.horizontal)

                // Lista sessioni del giorno selezionato (solo riassunto)
                if let day = selectedDay,
                   let sessions: [WorkoutSession] = viewModel.sessionsByDay[day],
                   !sessions.isEmpty {

                    List(sessions) { session in
                        sessionSummaryCard(session)
                    }

                } else {
                    Text("Seleziona un giorno per vedere gli allenamenti")
                        .foregroundColor(.secondary)
                        .padding()
                }

            }
            .navigationTitle("Calendario")
            .onAppear {
                viewModel.fetchWorkoutHistory()
            }
        }
    }

    // MARK: - Card di riassunto sessione (senza esercizi)

    private func sessionSummaryCard(_ session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(formatDate(session.date))
                .font(.headline)

            // piano + giorno risolti se possibile
            let info = viewModel.resolvePlanAndDay(for: session)
            Text("\(info.planName) • \(info.dayLabel)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if !session.notes.isEmpty {
                Text(session.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Text("\(session.exercises.count) esercizi")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func monthYearString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func changeMonth(by offset: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: offset, to: currentMonth) {
            currentMonth = newDate
            selectedDay = nil
        }
    }

    private func daysInMonth(for date: Date) -> [Date] {
        let calendar = Calendar.current

        guard
            let range = calendar.range(of: .day, in: .month, for: date),
            let firstOfMonth = calendar.date(
                from: calendar.dateComponents([.year, .month], from: date)
            )
        else { return [] }

        var days: [Date] = []

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }

        return days
    }
}
