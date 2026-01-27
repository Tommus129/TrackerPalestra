import SwiftUI

struct WorkoutCalendarView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var currentMonth: Date = Date()
    @State private var selectedDay: Date?

    var body: some View {
        ZStack {
            Color.customBlack.ignoresSafeArea()
            VStack {
                HStack {
                    Button(action: { changeMonth(by: -1) }) { Image(systemName: "chevron.left").foregroundColor(.acidGreen).padding() }
                    Spacer()
                    Text(monthYearString(currentMonth).uppercased()).font(.headline).foregroundColor(.white).tracking(2)
                    Spacer()
                    Button(action: { changeMonth(by: 1) }) { Image(systemName: "chevron.right").foregroundColor(.acidGreen).padding() }
                }

                let days = daysInMonth(for: currentMonth)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                    ForEach(days, id: \.self) { day in
                        let isSelected = selectedDay == day
                        let hasSessions = !(viewModel.sessionsByDay[day]?.isEmpty ?? true)
                        VStack {
                            Text("\(Calendar.current.component(.day, from: day))")
                                .font(.system(size: 14, weight: isSelected ? .black : .medium))
                                .foregroundColor(isSelected ? .customBlack : (hasSessions ? .white : .secondary))
                            if hasSessions { Circle().fill(isSelected ? .customBlack : Color.acidGreen).frame(width: 4, height: 4) }
                        }
                        .frame(maxWidth: .infinity, minHeight: 45)
                        .background(RoundedRectangle(cornerRadius: 10).fill(isSelected ? Color.acidGreen : (hasSessions ? Color.deepPurple.opacity(0.3) : Color.clear)))
                        .onTapGesture { selectedDay = day; UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
                    }
                }
                .padding(.horizontal)

                if let day = selectedDay, let sessions = viewModel.sessionsByDay[day], !sessions.isEmpty {
                    List {
                        ForEach(sessions) { session in
                            CalendarExerciseCard(session: session)
                                .listRowBackground(Color.clear).listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) { if let id = session.id { viewModel.deleteSession(id: id) } } label: { Label("Elimina", systemImage: "trash") }
                                }
                        }
                    }
                    .listStyle(.plain).scrollContentBackground(.hidden)
                } else {
                    Spacer(); Text("SELEZIONA UN GIORNO").font(.caption).foregroundColor(.secondary).tracking(3); Spacer()
                }
            }
        }
        .navigationTitle("CALENDARIO").onAppear { viewModel.fetchWorkoutHistory() }
    }

    private func monthYearString(_ date: Date) -> String { let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f.string(from: date) }
    private func changeMonth(by offset: Int) { if let newDate = Calendar.current.date(byAdding: .month, value: offset, to: currentMonth) { currentMonth = newDate; selectedDay = nil } }
    private func daysInMonth(for date: Date) -> [Date] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: date), let first = cal.date(from: cal.dateComponents([.year, .month], from: date)) else { return [] }
        return range.compactMap { cal.date(byAdding: .day, value: $0 - 1, to: first) }
    }
}

struct CalendarExerciseCard: View {
    let session: WorkoutSession
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(session.exercises) { ex in
                VStack(alignment: .leading, spacing: 4) {
                    Text(ex.name.uppercased()).font(.system(size: 14, weight: .bold)).foregroundColor(.acidGreen)
                    Text(ex.sets.map { "\($0.reps)\(ex.isBodyweight ? "" : "x\($0.weight)kg")" }.joined(separator: " • "))
                        .font(.system(size: 12, design: .monospaced)).foregroundColor(.white.opacity(0.8))
                    if !ex.exerciseNotes.isEmpty {
                        Text(ex.exerciseNotes).font(.system(size: 11)).italic().foregroundColor(.white.opacity(0.6))
                            .padding(.leading, 8).overlay(Rectangle().fill(Color.acidGreen.opacity(0.4)).frame(width: 2), alignment: .leading)
                    }
                }
            }
            if !session.notes.isEmpty { Divider().background(Color.white.opacity(0.1)); Text("Note: \(session.notes)").font(.caption).foregroundColor(.secondary) }
        }
        .padding().background(Color.white.opacity(0.05)).cornerRadius(15).overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.deepPurple.opacity(0.2), lineWidth: 1))
    }
}
