import SwiftUI

/// History list view
struct HistoryView: View {
    @ObservedObject var appState: AppState

    @State private var selectedEntry: TranscriptEntry?
    @State private var showClearConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            if appState.history.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)

                    Text("История пуста")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Записи будут появляться здесь после транскрибации")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                // History list
                List(appState.history) { entry in
                    HistoryRow(entry: entry, isSelected: selectedEntry?.id == entry.id)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedEntry = entry
                        }
                        .contextMenu {
                            Button("Копировать") {
                                appState.copyEntry(entry)
                            }

                            Divider()

                            Button("Удалить", role: .destructive) {
                                appState.deleteEntry(entry)
                            }
                        }
                }
                .listStyle(.plain)

                Divider()

                // Actions bar
                HStack {
                    Text("\(appState.history.count) записей")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Очистить") {
                        showClearConfirmation = true
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
            }
        }
        .confirmationDialog(
            "Очистить историю?",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Очистить", role: .destructive) {
                appState.clearHistory()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Все записи будут удалены. Это действие нельзя отменить.")
        }
    }
}

/// Single history row
struct HistoryRow: View {
    let entry: TranscriptEntry
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Preview text
            Text(entry.preview)
                .font(.body)
                .lineLimit(2)

            // Metadata
            HStack {
                Text(entry.formattedTimestamp)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(entry.formattedDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
    }
}

#Preview("With History") {
    HistoryView(appState: {
        let state = AppState()
        // Sample data would be loaded here
        return state
    }())
    .frame(width: 300, height: 300)
}

#Preview("Empty") {
    HistoryView(appState: AppState())
        .frame(width: 300, height: 300)
}
