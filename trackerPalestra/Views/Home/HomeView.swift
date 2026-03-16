import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var showingPlanEditor = false
    @State private var editMode: EditMode = .inactive
    @State private var showingProfile = false

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
                    List {
                        // MARK: Schede
                        Section {
                            if viewModel.plans.isEmpty {
                                emptyStateView
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                            } else {
                                ForEach(viewModel.plans) { plan in
                                    NavigationLink(destination: PlanDetailView(plan: plan).environmentObject(viewModel)) {
                                        PlanHomeCard(plan: plan)
                                    }
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .buttonStyle(CyberButtonStyle())
                                }
                                .onDelete(perform: viewModel.deletePlan)
                                .onMove(perform: viewModel.movePlan)
                            }
                        } header: {
                            HStack {
                                Text("LE TUE SCHEDE")
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundColor(.acidGreen)
                                    .tracking(3)
                                Spacer()
                                Button {
                                    withAnimation {
                                        editMode = (editMode == .active) ? .inactive : .active
                                    }
                                } label: {
                                    Text(editMode == .active ? "FATTO" : "MODIFICA")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.acidGreen)
                                        .padding(6)
                                        .background(Color.acidGreen.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                            .padding(.top, 8)
                        }

                        // MARK: Strumenti
                        Section {
                            NavigationLink(destination: WorkoutCalendarView().environmentObject(viewModel)) {
                                ToolRow(icon: "calendar", title: "CALENDARIO ALLENAMENTI")
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .buttonStyle(CyberButtonStyle())

                            NavigationLink(destination: ExerciseHistoryListView().environmentObject(viewModel)) {
                                ToolRow(icon: "chart.bar.xaxis", title: "ANALISI PROGRESSI")
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .buttonStyle(CyberButtonStyle())
                        } header: {
                            Text("STRUMENTI")
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(.acidGreen)
                                .tracking(3)
                        }

                        Color.clear.frame(height: 80)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .environment(\.editMode, $editMode)
                    .scrollContentBackground(.hidden)

                    // MARK: Bottone fisso — .subtleGlow() invece di .pulsingNeon()
                    // .pulsingNeon aveva 2 shadow animate in repeatForever sul main thread.
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
                        .subtleGlow(color: .acidGreen)
                    }
                    .buttonStyle(CyberButtonStyle())
                    .padding(20)
                }
            }
            .navigationTitle("TRACKER")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingProfile = true } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(.acidGreen)
                    }
                }
            }
            .preferredColorScheme(.dark)
            .sheet(isPresented: $showingPlanEditor) {
                WorkoutPlanEditView().environmentObject(viewModel)
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView().environmentObject(viewModel)
            }
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

// MARK: - PlanHomeCard
// .animatedBorder() → .staticBorder(): eliminata l'animazione
// .repeatForever per ogni card (era N animazioni GPU in parallelo).
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
        .staticBorder()
    }
}

// MARK: - ToolRow
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
