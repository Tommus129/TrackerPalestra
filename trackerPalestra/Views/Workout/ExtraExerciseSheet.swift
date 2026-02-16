import SwiftUI

struct ExtraExerciseSheet: View {
    let allNames: [String]
    var onSelect: (String) -> Void

    @State private var searchText: String = ""
    @State private var customName: String = ""

    private var filteredNames: [String] {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return allNames
        }
        return allNames.filter {
            $0.lowercased().contains(trimmed.lowercased())
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                TextField("Cerca esercizio", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding()

                List {
                    if !filteredNames.isEmpty {
                        Section("Esistenti") {
                            ForEach(filteredNames, id: \.self) { name in
                                Button {
                                    onSelect(name)
                                } label: {
                                    Text(name)
                                }
                            }
                        }
                    }

                    Section("Nuovo esercizio") {
                        TextField("Nome nuovo esercizio", text: $customName)

                        Button("Usa questo nome") {
                            let trimmed = customName.trimmingCharacters(in: .whitespaces)
                            guard !trimmed.isEmpty else { return }
                            onSelect(trimmed)
                        }
                        .disabled(customName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .navigationTitle("Esercizio extra")
        }
    }
}
