import SwiftUI

struct ExerciseHistoryListView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var searchText = ""

    var filteredExercises: [String] {
        if searchText.isEmpty { return viewModel.exerciseNames }
        return viewModel.exerciseNames.filter { $0.lowercased().contains(searchText.lowercased()) }
    }

    var body: some View {
        ZStack {
            Color.customBlack.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Barra di ricerca Glass
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.acidGreen)
                    TextField("Cerca esercizio...", text: $searchText).foregroundColor(.white)
                }
                .padding()
                .glassStyle()
                .padding()

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(filteredExercises, id: \.self) { exerciseName in
                            NavigationLink(destination: ExerciseHistoryDetailView(exerciseName: exerciseName)) {
                                HStack {
                                    Text(exerciseName.uppercased())
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chart.xyaxis.line")
                                        .foregroundColor(.acidGreen)
                                }
                                .padding()
                                .glassStyle()
                            }
                            .buttonStyle(CyberButtonStyle()) // Punto 6
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("ANALISI")
        .onAppear { viewModel.loadExerciseNames() }
    }
}
