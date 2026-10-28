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
                        EmojiIcon(emoji: emoji, size: 36)
                            .frame(width: 60, height: 60)
                            .sketchCard(fill: HabitColor.color(colorName), radius: 16)
                        TextField("Ex : Boire 2L d'eau", text: $name)
                            .font(.title3)
                    }
                }

                Section("Icône") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(HabitDoodle.habitIcons, id: \.self) { e in
                            EmojiIcon(emoji: e, size: 26)
                                .frame(width: 44, height: 44)
                                .background(RoundedRectangle(cornerRadius: 10).fill(e == emoji ? HabitColor.color(colorName) : .clear))
                                .overlay {
                                    if e == emoji { RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.line, lineWidth: 2) }
                                }
                                .contentShape(.rect)
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
                                .overlay { Circle().strokeBorder(Theme.line, lineWidth: item.name == colorName ? 3 : 1.5) }
                                .overlay {
                                    if item.name == colorName {
                                        Image(systemName: "checkmark").font(.caption.weight(.heavy)).foregroundStyle(Theme.darkInk)
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
            .scrollContentBackground(.hidden)
            .background(DottedPaper())
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
            Feedback.added()
        }
        dismiss()
    }
}
