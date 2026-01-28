import SwiftUI

struct WorkoutCalendarView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var currentMonth: Date = Date()
    @State private var selectedDay: Date?

    var body: some View {
        ZStack {
            Color.customBlack.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header compattato
                HStack {
                    Button(action: { changeMonth(by: -1) }) {
                        Image(systemName: "arrow.left.square.fill")
                            .foregroundColor(.acidGreen)
                            .font(.title3)
                    }
                    Spacer()
                    Text(monthYearString(currentMonth).uppercased())
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.white)
                        .tracking(3)
                    Spacer()
                    Button(action: { changeMonth(by: 1) }) {
                        Image(systemName: "arrow.right.square.fill")
                            .foregroundColor(.acidGreen)
                            .font(.title3)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10) // Ridotto padding verticale

                // Griglia del calendario più piccola
                let days = daysInMonth(for: currentMonth)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) { // Spaziatura ridotta
                    ForEach(days, id: \.self) { day in
                        let isSelected = selectedDay == day
                        let hasSessions = !(viewModel.sessionsByDay[day]?.isEmpty ?? true)
                        
                        VStack(spacing: 2) {
                            Text("\(Calendar.current.component(.day, from: day))")
                                .font(.system(size: 11, weight: isSelected ? .black : .bold, design: .monospaced)) // Font ridotto
                                .foregroundColor(isSelected ? .customBlack : (hasSessions ? .white : .white.opacity(0.2)))
                            
                            if hasSessions {
                                Circle()
                                    .fill(isSelected ? .customBlack : Color.acidGreen)
                                    .frame(width: 3, height: 3) // Punto più piccolo
                            } else {
                                Circle().fill(Color.clear).frame(width: 3, height: 3)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 38) // Altezza cella ridotta (da 50 a 38)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isSelected ? Color.acidGreen : (hasSessions ? Color.deepPurple.opacity(0.3) : Color.clear))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? Color.acidGreen : Color.clear, lineWidth: 1.5)
                                .blur(radius: isSelected ? 3 : 0)
                        )
                        .onTapGesture {
                            selectedDay = day
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        }
                    }
                }
                .padding(.horizontal)
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.vertical, 10)

                // Lista allenamenti (ora ha molto più spazio)
                if let day = selectedDay,
                   let sessions = viewModel.sessionsByDay[day],
                   !sessions.isEmpty {
                    List {
                        ForEach(sessions) { session in
                            CalendarExerciseCard(session: session)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .padding(.vertical, 4)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        if let id = session.id { viewModel.deleteSession(id: id) }
                                    } label: {
                                        Label("Elimina", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                } else {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "bolt.horizontal.circle")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.1))
                        Text("NESSUN ALLENAMENTO")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.white.opacity(0.2))
                            .tracking(5)
                    }
                    Spacer()
                }
            }
        }
        .navigationTitle("CALENDARIO")
        .onAppear { viewModel.fetchWorkoutHistory() }
    }

    // MARK: - Funzioni Helper
    private func monthYearString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }
    
    private func changeMonth(by offset: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: offset, to: currentMonth) {
            currentMonth = newDate
            selectedDay = nil
        }
    }
    
    private func daysInMonth(for date: Date) -> [Date] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: date),
              let first = cal.date(from: cal.dateComponents([.year, .month], from: date)) else { return [] }
        return range.compactMap { cal.date(byAdding: .day, value: $0 - 1, to: first) }
    }
}

// MARK: - Card Dettaglio Allenamento
struct CalendarExerciseCard: View {
    let session: WorkoutSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(session.exercises) { ex in
                VStack(alignment: .leading, spacing: 4) {
                    Text(ex.name.uppercased())
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.acidGreen)
                    
                    Text(ex.sets.map { "\($0.reps)\(ex.isBodyweight ? "" : "x\($0.weight)kg")" }.joined(separator: " • "))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                    
                    if !ex.exerciseNotes.isEmpty {
                        Text(ex.exerciseNotes)
                            .font(.system(size: 10))
                            .italic()
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.leading, 8)
                            .overlay(
                                Rectangle()
                                    .fill(Color.acidGreen.opacity(0.3))
                                    .frame(width: 2),
                                alignment: .leading
                            )
                    }
                }
            }
            
            if !session.notes.isEmpty {
                Text("NOTE: \(session.notes)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.top, 5)
            }
        }
        .padding(15)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.deepPurple.opacity(0.2), lineWidth: 1)
        )
    }
}
