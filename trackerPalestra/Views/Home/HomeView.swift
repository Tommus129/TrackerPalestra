import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: MainViewModel

    @State private var showingPlanEditor = false

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.plans.isEmpty {
                    VStack(spacing: 12) {
                        Text("Nessuna scheda ancora")
                            .font(.headline)
                        Text("Crea la tua prima scheda allenamento.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    List {
                        Section("Le tue schede") {
                            ForEach(viewModel.plans) { plan in
                                NavigationLink {
                                    PlanDetailView(plan: plan)
                                        .environmentObject(viewModel)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(plan.name)
                                                .font(.headline)
                                            Text("\(plan.days.count) giorni")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .onDelete(perform: viewModel.deletePlan) 
                        }

                        Section("Storico") {
                            NavigationLink {
                                WorkoutCalendarView()
                                    .environmentObject(viewModel)
                            } label: {
                                HStack {
                                    Image(systemName: "calendar")
                                    Text("Calendario allenamenti")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }

                Spacer()

                Button {
                    viewModel.prepareNewPlan()
                    showingPlanEditor = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Nuova scheda")
                    }
                    .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 16)
            }
            .padding(.horizontal)
            .navigationTitle("Tracker Palestra")
            .sheet(isPresented: $showingPlanEditor) {
                WorkoutPlanEditView()
                    .environmentObject(viewModel)
            }
        }
    }
}
