import SwiftUI

struct PlanDetailView: View {
    @EnvironmentObject var viewModel: MainViewModel
    let plan: WorkoutPlan
    @State private var selectedDayId: String?
    @State private var activeSession: WorkoutSession?

    private var selectedDay: WorkoutPlanDay? {
        plan.days.first { $0.id == selectedDayId }
    }

    var body: some View {
        ZStack {
            Color.customBlack.ignoresSafeArea()
            
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("SELEZIONA IL GIORNO")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.acidGreen).tracking(3).padding(.horizontal)

                        ForEach(plan.days) { day in
                            let isSelected = day.id == selectedDayId
                            
                            Button {
                                selectedDayId = day.id
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(day.label.uppercased()).font(.headline).foregroundColor(.white)
                                        Text("\(day.exercises.count) ESERCIZI").font(.caption).foregroundColor(.acidGreen)
                                    }
                                    Spacer()
                                    if isSelected {
                                        Image(systemName: "bolt.fill").foregroundColor(.acidGreen).pulsingNeon()
                                    }
                                }
                                .padding()
                                .glassStyle()
                                .overlay(RoundedRectangle(cornerRadius: 15).stroke(isSelected ? Color.acidGreen : Color.clear, lineWidth: 2))
                            }
                            .buttonStyle(CyberButtonStyle())
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 20)
                }

                // Bottone Start
                Button {
                    if let day = selectedDay {
                        activeSession = viewModel.makeSession(plan: plan, day: day)
                    }
                } label: {
                    Text("INIZIA ALLENAMENTO")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.customBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(selectedDay == nil ? Color.gray.opacity(0.3) : Color.acidGreen)
                        .cornerRadius(15)
                        .pulsingNeon(color: selectedDay == nil ? .clear : .acidGreen)
                }
                .disabled(selectedDay == nil)
                .buttonStyle(CyberButtonStyle())
                .padding(20)
            }
        }
        .navigationTitle(plan.name.uppercased())
        .sheet(item: $activeSession) { session in
            WorkoutSessionView(session: session) { saved in
                viewModel.saveSession(saved) { _ in }
            }
            .environmentObject(viewModel)
        }
    }
}
