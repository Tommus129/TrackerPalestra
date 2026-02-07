import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var showingPlanEditor = false
    @State private var editMode: EditMode = .inactive // Gestisce la modalità riordinamento

    var body: some View {
        NavigationStack {
            ZStack {
                Color.customBlack.ignoresSafeArea()
                
                Circle()
                    .fill(Color.deepPurple.opacity(0.15))
                    .frame(width: 400)
                    .blur(radius: 80)
                    .offset(x: -150, y: -200)

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            // Header con tasto Modifica
                            HStack {
                                Text("LE TUE SCHEDE")
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundColor(.acidGreen)
                                    .tracking(3)
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation {
                                        editMode = (editMode == .active) ? .inactive : .active
                                    }
                                }) {
                                    Text(editMode == .active ? "FATTO" : "MODIFICA")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.acidGreen)
                                        .padding(6)
                                        .background(Color.acidGreen.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)

                            if viewModel.plans.isEmpty {
                                emptyStateView
                            } else {
                                // List stilizzata per permettere onMove e onDelete correttamente
                                List {
                                    ForEach(viewModel.plans) { plan in
                                        NavigationLink(destination: PlanDetailView(plan: plan).environmentObject(viewModel)) {
                                            PlanHomeCard(plan: plan)
                                        }
                                        .listRowBackground(Color.clear)
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                        .buttonStyle(CyberButtonStyle())
                                    }
                                    .onDelete(perform: viewModel.deletePlan)
                                    .onMove(perform: viewModel.movePlan)
                                }
                                .listStyle(.plain)
                                .environment(\.editMode, $editMode)
                                // Altezza dinamica basata sul numero di schede per non bloccare lo scroll della ScrollView esterna
                                .frame(height: CGFloat(viewModel.plans.count) * 105 + 20)
                                .scrollDisabled(true)
                            }

                            Text("STRUMENTI")
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(.acidGreen)
                                .tracking(3)
                                .padding(.horizontal)
                                .padding(.top, 20)

                            VStack(spacing: 12) {
                                NavigationLink(destination: WorkoutCalendarView().environmentObject(viewModel)) {
                                    ToolRow(icon: "calendar", title: "CALENDARIO ALLENAMENTI")
                                }
                                .buttonStyle(CyberButtonStyle())

                                NavigationLink(destination: ExerciseHistoryListView().environmentObject(viewModel)) {
                                    ToolRow(icon: "chart.bar.xaxis", title: "ANALISI PROGRESSI")
                                }
                                .buttonStyle(CyberButtonStyle())
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 100)
                        }
                    }

                    // Bottone Cyber-Action fisso in basso
                    Button {
                        viewModel.prepareNewPlan()
                        showingPlanEditor = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.square.fill.on.square.fill")
                            Text("NUOVA SCHEDA").fontWeight(.black)
                        }
                        .foregroundColor(.customBlack)
                        .padding(.vertical, 18)
                        .frame(maxWidth: .infinity)
                        .background(Color.acidGreen)
                        .cornerRadius(12)
                        .pulsingNeon(color: .acidGreen)
                    }
                    .buttonStyle(CyberButtonStyle())
                    .padding(20)
                }
            }
            .navigationTitle("TRACKER")
            .preferredColorScheme(.dark)
            .sheet(isPresented: $showingPlanEditor) { WorkoutPlanEditView().environmentObject(viewModel) }
        }
    }

    var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "dumbbell.fill").font(.largeTitle).foregroundColor(.deepPurple.opacity(0.4))
            Text("Nessuna scheda creata").font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .glassStyle()
        .padding(.horizontal)
    }
}

// PlanHomeCard e ToolRow rimangono invariati...
struct PlanHomeCard: View {
    let plan: WorkoutPlan
    var body: some View {
        HStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 6) {
                Text(plan.name.uppercased())
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack {
                    Image(systemName: "calendar.day.timeline.left")
                    Text("\(plan.days.count) GIORNI")
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.acidGreen.opacity(0.7))
            }
            Spacer()
            Image(systemName: "bolt.fill")
                .font(.title2)
                .foregroundColor(.acidGreen)
        }
        .padding()
        .glassStyle()
        .animatedBorder()
    }
}

struct ToolRow: View {
    let icon: String
    let title: String
    var body: some View {
        HStack {
            ZStack {
                Circle().fill(Color.acidGreen.opacity(0.1)).frame(width: 35, height: 35)
                Image(systemName: icon).foregroundColor(.acidGreen).font(.system(size: 14, weight: .bold))
            }
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.deepPurple)
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }
}
