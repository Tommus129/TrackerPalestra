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
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.acidGreen)
                    TextField("Cerca esercizio...", text: $searchText).foregroundColor(.white)
                }
                .padding().background(Color.white.opacity(0.05)).cornerRadius(12).padding()

                List {
                    ForEach(filteredExercises, id: \.self) { exerciseName in
                        NavigationLink(destination: ExerciseHistoryDetailView(exerciseName: exerciseName)) {
                            Text(exerciseName.uppercased()).font(.headline).foregroundColor(.white)
                        }
                        .listRowBackground(Color.deepPurple.opacity(0.15))
                    }
                    .onDelete(perform: viewModel.deleteExerciseName)
                }
                .listStyle(.plain).scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("ANALISI").onAppear { viewModel.loadExerciseNames() }
    }
}
