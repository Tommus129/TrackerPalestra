import SwiftUI

struct ExerciseHistoryListView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var searchText = ""

    // Filtra i nomi degli esercizi in base alla ricerca
    var filteredExercises: [String] {
        if searchText.isEmpty {
            return viewModel.exerciseNames
        } else {
            return viewModel.exerciseNames.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }

    var body: some View {
        ZStack {
            Color.customBlack.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Barra di ricerca
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.acidGreen)
                    TextField("Cerca esercizio...", text: $searchText)
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .padding()

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(filteredExercises, id: \.self) { exerciseName in
                            NavigationLink(destination: ExerciseHistoryDetailView(exerciseName: exerciseName)) {
                                HStack {
                                    Text(exerciseName.uppercased())
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundColor(.acidGreen)
                                }
                                .padding()
                                .background(Color.deepPurple.opacity(0.15))
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.deepPurple.opacity(0.3), lineWidth: 1))
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("ANALISI ESERCIZIO")
        .onAppear {
            viewModel.loadExerciseNames()
        }
    }
}
