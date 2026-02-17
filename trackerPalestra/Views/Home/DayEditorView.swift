import SwiftUI

struct DayEditorView: View {
    @Binding var day: WorkoutPlanDay
    var onDelete: () -> Void

    @State private var newExerciseName: String = ""
    @State private var newExerciseSets: Int = 3
    @State private var newExerciseReps: Int = 8
    @State private var newExerciseIsBodyweight: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header con Nome giorno + elimina
            HStack(spacing: 12) {
                TextField("Nome Giorno", text: $day.label)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )

                Button(role: .destructive) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onDelete()
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.red.opacity(0.8))
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.1))
                        )
                }
            }

            // Lista esercizi
            if day.exercises.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.2))
                        Text("Nessun esercizio")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(.vertical, 30)
                    Spacer()
                }
            } else {
                VStack(spacing: 10) {
                    ForEach($day.exercises) { $exercise in
                        exerciseRow(exercise: $exercise)
                    }
                }
            }

            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.vertical, 8)

            // Sezione Aggiunta Esercizio
            VStack(alignment: .leading, spacing: 16) {
                Text("NUOVO ESERCIZIO")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.acidGreen)
                    .tracking(2)

                // Nome Esercizio
                TextField("Nome esercizio", text: $newExerciseName)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.deepPurple.opacity(0.3), lineWidth: 1)
                            )
                    )

                // Serie e Ripetizioni
                HStack(spacing: 12) {
                    // Serie
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SERIE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(1)
                        
                        HStack {
                            Button {
                                if newExerciseSets > 1 {
                                    newExerciseSets -= 1
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            } label: {
                                Image(systemName: "minus")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.acidGreen)
                                    .frame(width: 36, height: 36)
                                    .background(Circle().fill(Color.deepPurple.opacity(0.5)))
                            }
                            
                            Text("\(newExerciseSets)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(minWidth: 40)
                            
                            Button {
                                if newExerciseSets < 10 {
                                    newExerciseSets += 1
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.acidGreen)
                                    .frame(width: 36, height: 36)
                                    .background(Circle().fill(Color.deepPurple.opacity(0.5)))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.03))
                    )
                    
                    // Ripetizioni
                    VStack(alignment: .leading, spacing: 8) {
                        Text("RIPETIZIONI")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(1)
                        
                        HStack {
                            Button {
                                if newExerciseReps > 1 {
                                    newExerciseReps -= 1
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            } label: {
                                Image(systemName: "minus")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.acidGreen)
                                    .frame(width: 36, height: 36)
                                    .background(Circle().fill(Color.deepPurple.opacity(0.5)))
                            }
                            
                            Text("\(newExerciseReps)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(minWidth: 40)
                            
                            Button {
                                if newExerciseReps < 20 {
                                    newExerciseReps += 1
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.acidGreen)
                                    .frame(width: 36, height: 36)
                                    .background(Circle().fill(Color.deepPurple.opacity(0.5)))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.03))
                    )
                }

                // Toggle Bodyweight
                Button {
                    newExerciseIsBodyweight.toggle()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    HStack {
                        Image(systemName: newExerciseIsBodyweight ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundColor(newExerciseIsBodyweight ? .acidGreen : .white.opacity(0.3))
                        
                        Text("Esercizio a corpo libero")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        if newExerciseIsBodyweight {
                            Text("BW")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.acidGreen))
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(newExerciseIsBodyweight ? Color.acidGreen.opacity(0.1) : Color.white.opacity(0.03))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(newExerciseIsBodyweight ? Color.acidGreen.opacity(0.3) : Color.clear, lineWidth: 1)
                            )
                    )
                }

                // Bottone Aggiungi
                Button {
                    addExercise()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                        Text("AGGIUNGI ESERCIZIO")
                            .font(.system(size: 13, weight: .black))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(newExerciseName.trimmingCharacters(in: .whitespaces).isEmpty 
                                  ? Color.gray.opacity(0.2) 
                                  : Color.acidGreen)
                            .shadow(
                                color: newExerciseName.trimmingCharacters(in: .whitespaces).isEmpty 
                                    ? Color.clear 
                                    : Color.acidGreen.opacity(0.3),
                                radius: 8,
                                y: 4
                            )
                    )
                    .foregroundColor(newExerciseName.trimmingCharacters(in: .whitespaces).isEmpty 
                                     ? .white.opacity(0.3) 
                                     : .black)
                }
                .disabled(newExerciseName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Exercise Row
    @ViewBuilder
    private func exerciseRow(exercise: Binding<WorkoutPlanExercise>) -> some View {
        HStack(spacing: 12) {
            // Info Esercizio
            VStack(alignment: .leading, spacing: 6) {
                TextField("Nome esercizio", text: exercise.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text("\(exercise.wrappedValue.defaultSets)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.acidGreen)
                        Text("serie")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Text("×")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.3))
                    
                    HStack(spacing: 4) {
                        Text("\(exercise.wrappedValue.defaultReps)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.acidGreen)
                        Text("reps")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    if exercise.wrappedValue.isBodyweight {
                        Text("BW")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.acidGreen))
                    }
                }
            }
            
            Spacer()
            
            // Bottone Elimina
            Button(role: .destructive) {
                deleteExercise(exercise.wrappedValue)
            } label: {
                Image(systemName: "trash.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.red.opacity(0.7))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.red.opacity(0.1))
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.deepPurple.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func addExercise() {
        let trimmedName = newExerciseName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let ex = WorkoutPlanExercise(
            id: UUID().uuidString,
            name: trimmedName,
            defaultSets: newExerciseSets,
            defaultReps: newExerciseReps,
            isBodyweight: newExerciseIsBodyweight
        )

        _ = withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            day.exercises.append(ex)
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        // Reset
        newExerciseName = ""
        newExerciseSets = 3
        newExerciseReps = 8
        newExerciseIsBodyweight = false
    }

    private func deleteExercise(_ exercise: WorkoutPlanExercise) {
        if let idx = day.exercises.firstIndex(where: { $0.id == exercise.id }) {
            _ = withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                day.exercises.remove(at: idx)
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
}
