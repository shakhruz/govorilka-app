import SwiftUI

/// Beautiful history list view with pink theme
struct HistoryView: View {
    @ObservedObject var appState: AppState

    @State private var copiedEntryId: UUID?
    @State private var showClearConfirmation = false

    // Theme colors
    private let pinkColor = Color(hex: "FF69B4")
    private let lightPink = Color(hex: "FFB6C1")
    private let softPink = Color(hex: "FFF5F8")
    private let textColor = Color(hex: "5D4E6D")

    var body: some View {
        VStack(spacing: 0) {
            if appState.history.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(softPink)
                            .frame(width: 80, height: 80)

                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 32))
                            .foregroundColor(pinkColor.opacity(0.6))
                    }

                    VStack(spacing: 6) {
                        Text("Пока пусто")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(textColor)

                        Text("Записи появятся здесь\nпосле транскрибации")
                            .font(.system(size: 13))
                            .foregroundColor(textColor.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                // History list
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(appState.history) { entry in
                            HistoryRow(
                                entry: entry,
                                isCopied: copiedEntryId == entry.id,
                                pinkColor: pinkColor,
                                textColor: textColor
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                copyEntry(entry)
                            }
                            .contextMenu {
                                Button {
                                    copyEntry(entry)
                                } label: {
                                    Label("Копировать", systemImage: "doc.on.doc")
                                }

                                Divider()

                                Button(role: .destructive) {
                                    appState.deleteEntry(entry)
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }

                // Actions bar
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 10))
                            .foregroundColor(pinkColor)
                        Text("\(appState.history.count) записей")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(textColor.opacity(0.6))
                    }

                    Spacer()

                    Button {
                        showClearConfirmation = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 10))
                            Text("Очистить")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(textColor.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(softPink.opacity(0.5))
            }
        }
        .alert("Очистить историю?", isPresented: $showClearConfirmation) {
            Button("Отмена", role: .cancel) {}
            Button("Очистить", role: .destructive) {
                appState.clearHistory()
            }
        } message: {
            Text("Все записи будут удалены")
        }
    }

    private func copyEntry(_ entry: TranscriptEntry) {
        appState.copyEntry(entry)

        withAnimation(.easeInOut(duration: 0.2)) {
            copiedEntryId = entry.id
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                if copiedEntryId == entry.id {
                    copiedEntryId = nil
                }
            }
        }
    }
}

/// Beautiful history row
struct HistoryRow: View {
    let entry: TranscriptEntry
    let isCopied: Bool
    let pinkColor: Color
    let textColor: Color

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.preview)
                    .font(.system(size: 13))
                    .foregroundColor(textColor)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 9))
                        Text(entry.formattedTimestamp)
                            .font(.system(size: 10))
                    }
                    .foregroundColor(textColor.opacity(0.5))

                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 9))
                        Text(entry.formattedDuration)
                            .font(.system(size: 10))
                    }
                    .foregroundColor(textColor.opacity(0.5))
                }
            }

            Spacer()

            if isCopied {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                    Text("Скопировано")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(pinkColor)
                .clipShape(Capsule())
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCopied ? pinkColor.opacity(0.1) : Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCopied ? pinkColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isCopied)
    }
}

#Preview("With History") {
    HistoryView(appState: {
        let state = AppState()
        return state
    }())
    .frame(width: 320, height: 300)
}

#Preview("Empty") {
    HistoryView(appState: AppState())
        .frame(width: 320, height: 300)
}
