import SwiftUI

struct WorkoutPlanEditView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @Environment(\.dismiss) var dismiss

    private let corner: CGFloat = 12

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let planBinding = Binding($viewModel.editingPlan) {
                    Form {
                        nameSectionView(planBinding: planBinding)
                        daysSectionView(planBinding: planBinding)
                    }
                    .scrollContentBackground(.hidden)
                } else {
                    loadingView
                }
            }
            .navigationTitle("Modifica Scheda")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        viewModel.saveEditingPlan { success in
                            if success {
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                dismiss()
                            }
                        }
                    }
                    .foregroundColor(.acidGreen)
                    .fontWeight(.bold)
                }
            }
        }
    }

    // MARK: - Subviews

    private func nameSectionView(planBinding: Binding<WorkoutPlan>) -> some View {
        Section {
            TextField("Es: Push Pull Legs", text: planBinding.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.vertical, 4)
                .accentColor(.acidGreen)
        } header: {
            HStack {
                Image(systemName: "doc.text").foregroundColor(.acidGreen)
                Text("NOME SCHEDA")
            }
            .font(.caption).fontWeight(.bold).foregroundColor(.gray)
        }
        .listRowBackground(rowBg)
        .listRowSeparator(.hidden)
    }

    private func daysSectionView(planBinding: Binding<WorkoutPlan>) -> some View {
        Section {
            ForEach(planBinding.days) { $day in
                dayRow(day: day, dayBinding: $day)
            }
            .onDelete { offsets in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    viewModel.editingPlan?.days.remove(atOffsets: offsets)
                }
            }

            addDayButton
        } header: {
            HStack {
                Image(systemName: "calendar").foregroundColor(.acidGreen)
                Text("GIORNI DI ALLENAMENTO")
            }
            .font(.caption).fontWeight(.bold).foregroundColor(.gray)
            .padding(.top, 8)
        }
    }

    private func dayRow(day: WorkoutPlanDay, dayBinding: Binding<WorkoutPlanDay>) -> some View {
        let itemCount = day.resolvedItems.count
        let number = dayNumber(for: day.id)
        return NavigationLink(
            destination: DayDetailView(day: dayBinding).environmentObject(viewModel)
        ) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.acidGreen.opacity(0.1))
                        .frame(width: 40, height: 40)
                        .overlay(Circle().strokeBorder(Color.acidGreen.opacity(0.3), lineWidth: 1))
                    Text("\(number)")
                        .font(.headline).fontWeight(.bold)
                        .foregroundColor(.acidGreen)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(day.label)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    HStack(spacing: 4) {
                        Image(systemName: "dumbbell.fill").font(.caption2)
                        Text("\(itemCount) esercizi").font(.caption).fontWeight(.medium)
                    }
                    .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 6)
        }
        .listRowBackground(rowBg)
        .listRowSeparator(.hidden)
    }

    private var addDayButton: some View {
        Button { addDay() } label: {
            HStack {
                Image(systemName: "plus").fontWeight(.bold)
                Text("AGGIUNGI GIORNO").fontWeight(.bold).tracking(1.0)
            }
            .font(.system(size: 15))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: corner).fill(Color.acidGreen))
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .padding(.top, 4)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().tint(.acidGreen)
            Text("Caricamento...")
                .font(.caption).foregroundColor(.gray)
        }
    }

    private var rowBg: some View {
        RoundedRectangle(cornerRadius: corner)
            .fill(Color(UIColor.systemGray6).opacity(0.12))
            .overlay(RoundedRectangle(cornerRadius: corner).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }

    // MARK: - Actions

    private func dayNumber(for dayId: String) -> Int {
        guard let plan = viewModel.editingPlan else { return 0 }
        return (plan.days.firstIndex(where: { $0.id == dayId }) ?? 0) + 1
    }

    private func addDay() {
        guard var plan = viewModel.editingPlan else { return }
        let newDay = WorkoutPlanDay(
            id: UUID().uuidString,
            label: "Giorno \(plan.days.count + 1)",
            items: []
        )
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            plan.days.append(newDay)
            viewModel.editingPlan = plan
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
