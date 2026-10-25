import SwiftData
import SwiftUI

struct HabitEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let habit: Habit?
    let nextOrder: Int

    @State private var name: String
    @State private var emoji: String
    @State private var colorName: String

    private static let emojis = [
        "💧", "🏃", "📚", "🧘", "💪", "🥗", "😴", "✍️",
        "🎸", "🧹", "💊", "🚭", "🌞", "🧠", "🚶", "📵",
        "🦷", "🙏", "💰", "🎨", "🌱", "🍎", "🚴", "🎯",
    ]

    init(habit: Habit?, nextOrder: Int) {
        self.habit = habit
        self.nextOrder = nextOrder
        _name = State(initialValue: habit?.name ?? "")
        _emoji = State(initialValue: habit?.emoji ?? "🎯")
        _colorName = State(initialValue: habit?.colorName ?? "purple")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        Text(emoji)
                            .font(.largeTitle)
                            .frame(width: 60, height: 60)
                            .background(HabitColor.color(colorName).opacity(0.2), in: .rect(cornerRadius: 16))
                        TextField("Ex : Boire 2L d'eau", text: $name)
                            .font(.title3)
                    }
                }

                Section("Icône") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                        ForEach(Self.emojis, id: \.self) { e in
                            Text(e)
                                .font(.title2)
                                .frame(width: 38, height: 38)
                                .background(e == emoji ? HabitColor.color(colorName).opacity(0.25) : .clear, in: .circle)
                                .onTapGesture { emoji = e }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Couleur") {
                    HStack {
                        ForEach(HabitColor.all, id: \.name) { item in
                            Circle()
                                .fill(item.color)
                                .frame(width: 30, height: 30)
                                .overlay {
                                    if item.name == colorName {
                                        Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .onTapGesture { colorName = item.name }
                        }
                    }
                    .padding(.vertical, 4)
                }

                if let habit {
                    Section {
                        Button("Supprimer l'habitude", role: .destructive) {
                            context.delete(habit)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(habit == nil ? "Nouvelle habitude" : "Modifier")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let habit {
            habit.name = trimmed
            habit.emoji = emoji
            habit.colorName = colorName
        } else {
            context.insert(Habit(name: trimmed, emoji: emoji, colorName: colorName, order: nextOrder))
            Haptics.added()
        }
        dismiss()
    }
}
