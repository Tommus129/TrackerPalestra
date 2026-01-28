import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var showingPlanEditor = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.customBlack.ignoresSafeArea()
                
                // Effetto bagliore soffuso sullo sfondo
                Circle()
                    .fill(Color.deepPurple.opacity(0.15))
                    .frame(width: 400)
                    .blur(radius: 80)
                    .offset(x: -150, y: -200)

                VStack(spacing: 0) {
                    List {
                        Section {
                            if viewModel.plans.isEmpty {
                                emptyStateView
                            } else {
                                ForEach(viewModel.plans) { plan in
                                    NavigationLink(destination: PlanDetailView(plan: plan).environmentObject(viewModel)) {
                                        PlanHomeCard(plan: plan)
                                    }
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                                }
                                .onDelete(perform: viewModel.deletePlan)
                            }
                        } header: {
                            Text("LE TUE SCHEDE").font(.system(size: 12, weight: .black)).foregroundColor(.acidGreen).tracking(3)
                        }

                        Section {
                            NavigationLink(destination: WorkoutCalendarView().environmentObject(viewModel)) {
                                ToolRow(icon: "calendar", title: "CALENDARIO ALLENAMENTI")
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                            NavigationLink(destination: ExerciseHistoryListView().environmentObject(viewModel)) {
                                ToolRow(icon: "chart.bar.xaxis", title: "ANALISI PROGRESSI")
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        } header: {
                            Text("STRUMENTI").font(.system(size: 12, weight: .black)).foregroundColor(.acidGreen).tracking(3)
                        }
                    }
                    .listStyle(.grouped)
                    .scrollContentBackground(.hidden)

                    // Bottone Neon
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
                        .shadow(color: .acidGreen.opacity(0.4), radius: 15, x: 0, y: 0)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("TRACKER")
            .preferredColorScheme(.dark)
            .sheet(isPresented: $showingPlanEditor) { WorkoutPlanEditView().environmentObject(viewModel) }
        }
    }

    var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "dumbbell.fill").font(.largeTitle).foregroundColor(.deepPurple.opacity(0.5))
            Text("Nessuna scheda creata").font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .listRowBackground(Color.clear)
    }
}

struct PlanHomeCard: View {
    let plan: WorkoutPlan
    var body: some View {
        HStack(spacing: 15) {
            // Indicatore laterale colorato
            Rectangle()
                .fill(Color.acidGreen)
                .frame(width: 4)
                .cornerRadius(2)
            
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
            Image(systemName: "arrow.right.square.fill")
                .font(.title2)
                .foregroundColor(.deepPurple)
        }
        .padding()
        .background(Color.cardGradient)
        .cornerRadius(15)
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.1), lineWidth: 1))
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
