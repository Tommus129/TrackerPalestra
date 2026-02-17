import SwiftUI
import UniformTypeIdentifiers

struct WorkoutPlanEditView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @Environment(\.dismiss) var dismiss
    @State private var expandedDayIds: Set<String> = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color.customBlack.ignoresSafeArea()
                
                if let planBinding = Binding($viewModel.editingPlan) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Header: Nome Scheda
                            VStack(alignment: .leading, spacing: 12) {
                                Text("NOME SCHEDA")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.acidGreen)
                                    .tracking(2)
                                
                                TextField("Es: Push Pull Legs", text: planBinding.name)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white.opacity(0.05))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.deepPurple.opacity(0.3), lineWidth: 2)
                                            )
                                    )
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Stats Rapide
                            HStack(spacing: 12) {
                                statsCard(
                                    icon: "calendar",
                                    value: "\(planBinding.wrappedValue.days.count)",
                                    label: "GIORNI"
                                )
                                
                                statsCard(
                                    icon: "figure.strengthtraining.traditional",
                                    value: "\(totalExercises(plan: planBinding.wrappedValue))",
                                    label: "ESERCIZI"
                                )
                            }
                            .padding(.horizontal, 20)
                            
                            // Section Header
                            HStack {
                                Text("GIORNI ALLENAMENTO")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.acidGreen)
                                    .tracking(2)
                                Spacer()
                                Text("Tieni premuto per riordinare")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.white.opacity(0.4))
                                    .italic()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                            
                            // Lista Giorni con Drag & Drop
                            ForEach(Array(planBinding.wrappedValue.days.enumerated()), id: \.element.id) { index, day in
                                DayCardView(
                                    day: planBinding.days[index],
                                    dayNumber: index + 1,
                                    isExpanded: expandedDayIds.contains(day.id),
                                    onToggleExpand: {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                            if expandedDayIds.contains(day.id) {
                                                expandedDayIds.remove(day.id)
                                            } else {
                                                expandedDayIds.insert(day.id)
                                            }
                                        }
                                    },
                                    onDelete: {
                                        withAnimation {
                                            viewModel.editingPlan?.days.remove(at: index)
                                        }
                                    },
                                    onDuplicate: {
                                        duplicateDay(at: index)
                                    }
                                )
                                .onDrag {
                                    return NSItemProvider(object: String(index) as NSString)
                                }
                                .onDrop(of: [UTType.text], delegate: DayDropDelegate(
                                    days: planBinding.days,
                                    draggedIndex: index
                                ))
                                .environmentObject(viewModel)
                            }
                            .padding(.horizontal, 20)
                            
                            // Bottone Aggiungi Giorno
                            Button {
                                addDay()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20))
                                    Text("AGGIUNGI GIORNO")
                                        .font(.system(size: 13, weight: .black))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.acidGreen.opacity(0.4), lineWidth: 2)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.acidGreen.opacity(0.05))
                                        )
                                )
                                .foregroundColor(.acidGreen)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(.acidGreen)
                        Text("Caricamento...")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .navigationTitle("MODIFICA SCHEDA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        viewModel.saveEditingPlan { success in
                            if success {
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                dismiss()
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("SALVA")
                                .fontWeight(.black)
                        }
                        .foregroundColor(.acidGreen)
                    }
                }
            }
        }
    }
    
    // MARK: - Stats Card
    @ViewBuilder
    private func statsCard(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.acidGreen)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.acidGreen.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(1)
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.deepPurple.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Helper Functions
    private func totalExercises(plan: WorkoutPlan) -> Int {
        return plan.days.reduce(0) { $0 + $1.exercises.count }
    }

    private func addDay() {
        guard var plan = viewModel.editingPlan else { return }
        let dayLetter = Character(UnicodeScalar(65 + plan.days.count)!)
        let newDay = WorkoutPlanDay(
            id: UUID().uuidString,
            label: "Day \(dayLetter)",
            exercises: []
        )
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            plan.days.append(newDay)
            viewModel.editingPlan = plan
            expandedDayIds.insert(newDay.id)
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    private func duplicateDay(at index: Int) {
        guard var plan = viewModel.editingPlan, index < plan.days.count else { return }
        var duplicatedDay = plan.days[index]
        duplicatedDay.id = UUID().uuidString
        duplicatedDay.label = "\(duplicatedDay.label) (Copia)"
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            plan.days.insert(duplicatedDay, at: index + 1)
            viewModel.editingPlan = plan
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

// MARK: - Day Card View
struct DayCardView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @Binding var day: WorkoutPlanDay
    let dayNumber: Int
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void
    
    private var accentColor: Color {
        let colors: [Color] = [.acidGreen, .purple, .orange, .blue, .pink, .cyan]
        return colors[dayNumber % colors.count]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Card
            Button {
                onToggleExpand()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                HStack(spacing: 16) {
                    // Day Number Badge
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.15))
                        Text("\(dayNumber)")
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(accentColor)
                    }
                    .frame(width: 48, height: 48)
                    
                    // Day Info
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Nome Giorno", text: $day.label)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "figure.run")
                                .font(.system(size: 10))
                            Text("\(day.exercises.count) esercizi")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    // Expand Icon
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                        .font(.system(size: 24))
                        .foregroundColor(accentColor.opacity(isExpanded ? 1 : 0.4))
                        .rotationEffect(.degrees(isExpanded ? 0 : 0))
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: isExpanded ? 20 : 18)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: isExpanded ? 20 : 18)
                                .stroke(accentColor.opacity(isExpanded ? 0.4 : 0.2), lineWidth: isExpanded ? 2 : 1)
                        )
                        .shadow(color: isExpanded ? accentColor.opacity(0.15) : Color.clear, radius: 12, y: 6)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded Content
            if isExpanded {
                VStack(spacing: 16) {
                    Divider()
                        .background(accentColor.opacity(0.2))
                        .padding(.horizontal, 20)
                    
                    // Lista Esercizi
                    if day.exercises.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "figure.run.square.stack")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.2))
                            Text("Nessun esercizio")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(day.exercises) { exercise in
                                exerciseRow(exercise: exercise)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        // Modifica Giorno
                        NavigationLink(destination: DayDetailView(day: $day).environmentObject(viewModel)) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("MODIFICA")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(accentColor.opacity(0.15))
                            .foregroundColor(accentColor)
                            .cornerRadius(12)
                        }
                        
                        // Duplica
                        Button {
                            onDuplicate()
                        } label: {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                Text("DUPLICA")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.05))
                            .foregroundColor(.white.opacity(0.7))
                            .cornerRadius(12)
                        }
                        
                        // Elimina
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.red.opacity(0.8))
                                .frame(width: 44, height: 44)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.02))
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    @ViewBuilder
    private func exerciseRow(exercise: WorkoutPlanExercise) -> some View {
        HStack(spacing: 12) {
            Image(systemName: exercise.isBodyweight ? "figure.flexibility" : "dumbbell.fill")
                .font(.system(size: 14))
                .foregroundColor(accentColor)
                .frame(width: 32, height: 32)
                .background(Circle().fill(accentColor.opacity(0.1)))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                HStack(spacing: 4) {
                    Text("\(exercise.defaultSets)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(accentColor)
                    Text("×")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.3))
                    Text("\(exercise.defaultReps)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(accentColor)
                }
            }
            
            Spacer()
            
            if exercise.isBodyweight {
                Text("BW")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(accentColor))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
        )
    }
}

// MARK: - Drag & Drop Delegate
struct DayDropDelegate: DropDelegate {
    @Binding var days: [WorkoutPlanDay]
    let draggedIndex: Int
    
    func performDrop(info: DropInfo) -> Bool {
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let itemProvider = info.itemProviders(for: [UTType.text]).first else { return }
        
        itemProvider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { (item, error) in
            guard let data = item as? Data,
                  let sourceIndexString = String(data: data, encoding: .utf8),
                  let sourceIndex = Int(sourceIndexString),
                  sourceIndex != draggedIndex else { return }
            
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    let sourceDay = days[sourceIndex]
                    days.remove(at: sourceIndex)
                    
                    let destinationIndex = sourceIndex < draggedIndex ? draggedIndex - 1 : draggedIndex
                    days.insert(sourceDay, at: destinationIndex)
                    
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
        }
    }
}
