import SwiftUI

struct DayEditorView: View {
    @Binding var day: WorkoutPlanDay
    var onDelete: () -> Void

    private let corner: CGFloat = 12

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: nome giorno + trash
            HStack(spacing: 12) {
                TextField("Nome Giorno", text: $day.label)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: corner).fill(Color.white.opacity(0.05)))

                Button(role: .destructive) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onDelete()
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.red.opacity(0.8))
                        .frame(width: 44, height: 44)
                        .background(RoundedRectangle(cornerRadius: corner).fill(Color.red.opacity(0.1)))
                }
            }

            // Lista items
            let resolved = day.resolvedItems
            if resolved.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.2))
                        Text("Nessun esercizio")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(.vertical, 30)
                    Spacer()
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(resolved) { item in
                        itemPreviewRow(item: item)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func itemPreviewRow(item: WorkoutPlanItem) -> some View {
        switch item.kind {
        case .exercise:
            if let ex = item.exercise { exerciseRow(ex) }
        case .superset:
            if let ss = item.superset { supersetRow(ss) }
        }
    }

    private func exerciseRow(_ ex: WorkoutPlanExercise) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(ex.name)
                    .font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                HStack(spacing: 6) {
                    Text("\(ex.sets) ×")
                        .font(.system(size: 13, weight: .bold)).foregroundColor(.white.opacity(0.5))
                    Text(ex.repsDisplay)
                        .font(.system(size: 13, weight: .bold)).foregroundColor(.acidGreen)
                    if ex.isBodyweight {
                        Text("BW")
                            .font(.system(size: 9, weight: .black)).foregroundColor(.black)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(Color.acidGreen))
                    }
                }
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: corner)
                .fill(Color.white.opacity(0.03))
                .overlay(RoundedRectangle(cornerRadius: corner).stroke(Color.deepPurple.opacity(0.2), lineWidth: 1))
        )
    }

    private func supersetRow(_ ss: WorkoutPlanSuperset) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(ss.name, systemImage: "link")
                .font(.system(size: 12, weight: .bold)).foregroundColor(.orange)
            ForEach(ss.exercises.indices, id: \.self) { i in
                let ex = ss.exercises[i]
                Text("\(i+1). \(ex.name)  \(ex.sets) × \(ex.repsDisplay)")
                    .font(.system(size: 13)).foregroundColor(.white.opacity(0.75))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: corner)
                .fill(Color.orange.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: corner).stroke(Color.orange.opacity(0.2), lineWidth: 1))
        )
    }
}
