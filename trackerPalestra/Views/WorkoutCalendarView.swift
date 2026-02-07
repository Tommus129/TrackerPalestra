import SwiftUI

struct WorkoutCalendarView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var currentMonth: Date = Date()
    @State private var selectedDay: Date?

    var body: some View {
        ZStack {
            Color.customBlack.ignoresSafeArea()
            
            // Effetto bagliore ambientale
            Circle()
                .fill(Color.deepPurple.opacity(0.1))
                .frame(width: 300)
                .blur(radius: 60)
                .offset(x: 100, y: -150)

            VStack(spacing: 0) {
                // MARK: - Header Calendario
                HStack {
                    Button(action: { changeMonth(by: -1) }) {
                        Image(systemName: "chevron.left.square.fill")
                            .foregroundColor(.acidGreen)
                            .font(.title2)
                    }
                    Spacer()
                    Text(monthYearString(currentMonth).uppercased())
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.white)
                        .tracking(3)
                    Spacer()
                    Button(action: { changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right.square.fill")
                            .foregroundColor(.acidGreen)
                            .font(.title2)
                    }
                }
                .padding(.horizontal, 25)
                .padding(.vertical, 15)

                // MARK: - Griglia Giorni
                let days = daysInMonth(for: currentMonth)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                    ForEach(days, id: \.self) { day in
                        let isSelected = selectedDay == day
                        let hasSessions = !(viewModel.sessionsByDay[day]?.isEmpty ?? true)
                        let isToday = Calendar.current.isDateInToday(day)
                        
                        VStack(spacing: 4) {
                            Text("\(Calendar.current.component(.day, from: day))")
                                .font(.system(size: 12, weight: isSelected ? .black : .bold, design: .monospaced))
                                .foregroundColor(isSelected ? .customBlack : (hasSessions ? .white : .white.opacity(0.2)))
                            
                            Circle()
                                .fill(isSelected ? .customBlack : (isToday ? Color.white : Color.acidGreen))
                                .frame(width: 4, height: 4)
                                .opacity(hasSessions || isToday ? 1 : 0)
                        }
                        .frame(maxWidth: .infinity, minHeight: 45)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isSelected ? Color.acidGreen : (hasSessions ? Color.deepPurple.opacity(0.25) : Color.clear))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isToday && !isSelected ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                        .onTapGesture {
                            selectedDay = day
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                }
                .padding(.horizontal)
                
                // MARK: - Lista Sessioni
                VStack(alignment: .leading, spacing: 15) {
                    Text("DETTAGLIO ATTIVITÀ")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.acidGreen)
                        .tracking(2)
                        .padding(.horizontal, 25)
                        .padding(.top, 20)

                    if let day = selectedDay,
                       let sessions = viewModel.sessionsByDay[day],
                       !sessions.isEmpty {
                        List {
                            ForEach(sessions) { session in
                                CalendarExerciseCard(session: session)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .padding(.vertical, 6)
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
                        VStack(spacing: 15) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.05))
                            Text("NESSUNA SESSIONE")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.white.opacity(0.1))
                                .tracking(4)
                        }
                        .frame(maxWidth: .infinity)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("DIARIO")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.fetchWorkoutHistory() }
    }

    // MARK: - Helpers
    private func monthYearString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }
    
    private func changeMonth(by offset: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: offset, to: currentMonth) {
            withAnimation {
                currentMonth = newDate
                selectedDay = nil
            }
        }
    }
    
    private func daysInMonth(for date: Date) -> [Date] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: date),
              let first = cal.date(from: cal.dateComponents([.year, .month], from: date)) else { return [] }
        return range.compactMap { cal.date(byAdding: .day, value: $0 - 1, to: first) }
    }
}

// MARK: - Card Dettaglio Completa (Senza Orario)
struct CalendarExerciseCard: View {
    @EnvironmentObject var viewModel: MainViewModel
    let session: WorkoutSession
    
    private var planInfo: (title: String, day: String) {
        let plan = viewModel.plans.first(where: { $0.id == session.planId })
        let day = plan?.days.first(where: { $0.id == session.dayId })
        return (plan?.name.uppercased() ?? "SCHEDA", day?.label.uppercased() ?? "GIORNO")
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Indicatore laterale verde acido
            Rectangle()
                .fill(Color.acidGreen)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 15) {
                // Header della Card con Badge
                HStack(spacing: 12) {
                    HStack(spacing: 5) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 8))
                        Text(planInfo.title)
                            .font(.system(size: 9, weight: .black))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.acidGreen)
                    .foregroundColor(.customBlack)
                    .cornerRadius(4)

                    Text(planInfo.day)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                }

                // Lista Integrale degli Esercizi (Mostra tutti)
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(session.exercises) { ex in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.acidGreen.opacity(0.6))
                                .padding(.top, 2)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(ex.name.uppercased())
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundColor(.white)
                                
                                // Dettaglio set eseguiti
                                Text(ex.sets.map { "\($0.reps)\(ex.isBodyweight ? "" : "x\($0.weight)kg")" }.joined(separator: " • "))
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                }

                // Note della sessione se presenti
                if !session.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Divider().background(Color.white.opacity(0.05))
                        HStack {
                            Image(systemName: "pencil.line")
                                .font(.system(size: 9))
                            Text(session.notes)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.top, 4)
                    }
                }
            }
            .padding(15)
        }
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}
