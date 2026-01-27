import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var showingPlanEditor = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.customBlack.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    List {
                        Section {
                            if viewModel.plans.isEmpty {
                                Text("Nessuna scheda creata").font(.caption).foregroundColor(.secondary).listRowBackground(Color.clear)
                            } else {
                                ForEach(viewModel.plans) { plan in
                                    NavigationLink(destination: PlanDetailView(plan: plan).environmentObject(viewModel)) {
                                        PlanHomeCard(plan: plan)
                                    }
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                }
                                .onDelete(perform: viewModel.deletePlan)
                            }
                        } header: {
                            Text("LE TUE SCHEDE").font(.system(size: 12, weight: .bold)).foregroundColor(.acidGreen).tracking(2)
                        }

                        Section {
                            NavigationLink(destination: WorkoutCalendarView().environmentObject(viewModel)) {
                                ToolRow(icon: "calendar", title: "CALENDARIO ALLENAMENTI")
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                            NavigationLink(destination: ExerciseHistoryListView().environmentObject(viewModel)) {
                                ToolRow(icon: "line.diagonal.arrow.up.circle", title: "ANALISI PROGRESSI")
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        } header: {
                            Text("STRUMENTI").font(.system(size: 12, weight: .bold)).foregroundColor(.acidGreen).tracking(2)
                        }
                    }
                    .listStyle(.grouped)
                    .scrollContentBackground(.hidden)

                    Button {
                        viewModel.prepareNewPlan()
                        showingPlanEditor = true
                    } label: {
                        HStack { Image(systemName: "plus.circle.fill"); Text("NUOVA SCHEDA").fontWeight(.black) }
                        .foregroundColor(.customBlack).padding().frame(maxWidth: .infinity).background(Color.acidGreen).cornerRadius(15).shadow(color: .acidGreen.opacity(0.3), radius: 10)
                    }
                    .padding(.horizontal).padding(.bottom, 16)
                }
            }
            .navigationTitle("TRACKER").preferredColorScheme(.dark)
            .sheet(isPresented: $showingPlanEditor) { WorkoutPlanEditView().environmentObject(viewModel) }
        }
    }
}

struct PlanHomeCard: View {
    let plan: WorkoutPlan
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.name.uppercased()).font(.headline).foregroundColor(.white)
                Text("\(plan.days.count) GIORNI").font(.system(size: 10, weight: .bold)).foregroundColor(.acidGreen.opacity(0.8))
            }
            Spacer(); Image(systemName: "chevron.right").foregroundColor(.deepPurple)
        }
        .padding().background(Color.deepPurple.opacity(0.1)).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.deepPurple.opacity(0.3), lineWidth: 1))
    }
}

struct ToolRow: View {
    let icon: String
    let title: String
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.acidGreen).font(.title3).frame(width: 30)
            Text(title).font(.system(.body, design: .rounded)).fontWeight(.bold).foregroundColor(.white)
            Spacer(); Image(systemName: "chevron.right").foregroundColor(.deepPurple)
        }
        .padding().background(Color.white.opacity(0.05)).cornerRadius(12)
    }
}
