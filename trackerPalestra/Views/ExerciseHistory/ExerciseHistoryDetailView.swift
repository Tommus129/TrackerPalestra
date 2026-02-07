import SwiftUI
import Charts // Framework necessario per i grafici

struct ExerciseHistoryDetailView: View {
    @EnvironmentObject var viewModel: MainViewModel
    let exerciseName: String

    // Elaborazione dei dati per lo storico (lista)
    var exerciseHistory: [(date: Date, exerciseSession: WorkoutExerciseSession, sessionId: String)] {
        var results: [(Date, WorkoutExerciseSession, String)] = []
        for session in viewModel.workoutHistory {
            // Troviamo l'esercizio all'interno di ogni sessione dello storico
            if let sessionId = session.id,
               let exercise = session.exercises.first(where: { $0.name.lowercased() == exerciseName.lowercased() }) {
                results.append((session.date, exercise, sessionId))
            }
        }
        return results.sorted { $0.0 > $1.0 } // Ordine decrescente per la lista
    }

    // Elaborazione dei dati per il grafico (solo massimali per sessione)
    var chartData: [(date: Date, weight: Double)] {
        exerciseHistory
            .map { record in
                // Prendiamo il peso massimo sollevato in quella specifica sessione
                let maxWeight = record.exerciseSession.sets.map { $0.weight }.max() ?? 0
                return (date: record.date, weight: maxWeight)
            }
            .filter { $0.weight > 0 }
            .sorted { $0.date < $1.date } // Ordine crescente per il grafico (linea del tempo)
    }

    var body: some View {
        ZStack {
            Color.customBlack.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // SEZIONE GRAFICO (Solo se ci sono dati)
                if !chartData.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ANDAMENTO MASSIMALI (KG)")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.acidGreen)
                            .padding(.horizontal, 20)
                            .padding(.top, 15)

                        Chart {
                            ForEach(chartData, id: \.date) { data in
                                // Linea del progresso
                                LineMark(
                                    x: .value("Data", data.date),
                                    y: .value("Peso", data.weight)
                                )
                                .interpolationMethod(.catmullRom) // Rende la linea curva e fluida
                                .foregroundStyle(Color.acidGreen)
                                .lineStyle(StrokeStyle(lineWidth: 3))

                                // Punti sui massimali
                                PointMark(
                                    x: .value("Data", data.date),
                                    y: .value("Peso", data.weight)
                                )
                                .foregroundStyle(Color.acidGreen)
                                .annotation(position: .top) {
                                    Text("\(data.weight, specifier: "%.1f")")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                        }
                        .frame(height: 180)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        // Personalizzazione assi
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(.white.opacity(0.1))
                                AxisValueLabel(format: .dateTime.day().month(), centered: true)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                        .chartYAxis {
                            AxisMarks { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(.white.opacity(0.1))
                                AxisValueLabel().foregroundStyle(.white.opacity(0.5))
                            }
                        }
                    }
                    .background(Color.white.opacity(0.03))
                    .padding(.bottom, 10)
                }

                // LISTA STORICO PESI
                List {
                    Section {
                        ForEach(exerciseHistory, id: \.date) { record in
                            HistoryRowCard(date: record.date, exercise: record.exerciseSession)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        viewModel.deleteSession(id: record.sessionId)
                                    } label: {
                                        Label("Elimina", systemImage: "trash")
                                    }
                                }
                        }
                    } header: {
                        Text("CRONOLOGIA ALLENAMENTI")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .overlay {
                    if exerciseHistory.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.largeTitle)
                            Text("Nessun dato disponibile per questo esercizio")
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle(exerciseName.uppercased())
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Card per la singola riga dello storico
struct HistoryRowCard: View {
    let date: Date
    let exercise: WorkoutExerciseSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(date.formatted(date: .abbreviated, time: .omitted).uppercased())
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(.acidGreen)
                Spacer()
                if exercise.isPR {
                    Label("RECORD", systemImage: "trophy.fill")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(.acidGreen)
                }
            }
            
            VStack(spacing: 8) {
                ForEach(exercise.sets) { set in
                    HStack {
                        Text("SET \(set.setIndex + 1)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.deepPurple)
                            .frame(width: 45, alignment: .leading)
                        
                        Text("\(set.reps) REPS")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.white)
                        
                        if !exercise.isBodyweight {
                            Spacer()
                            Text("\(set.weight, specifier: "%.1f") KG")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(8)
                }
            }
            
            if !exercise.exerciseNotes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NOTE")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.acidGreen.opacity(0.7))
                    Text(exercise.exerciseNotes)
                        .font(.system(size: 11))
                        .italic()
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.deepPurple.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.deepPurple.opacity(0.2), lineWidth: 1))
    }
}
