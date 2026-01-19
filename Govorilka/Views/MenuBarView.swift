import SwiftUI

/// Beautiful main popover content for menu bar with stats
struct MenuBarView: View {
    @ObservedObject var appState: AppState

    @State private var selectedTab = 0

    // Theme colors
    private let pinkColor = Color(hex: "FF69B4")
    private let lightPink = Color(hex: "FFB6C1")
    private let softPink = Color(hex: "FFF0F5")
    private let textColor = Color(hex: "5D4E6D")
    private let purpleAccent = Color(hex: "9B6BFF")
    private let coralAccent = Color(hex: "FF7B7B")

    var body: some View {
        VStack(spacing: 0) {
            // Header with mini stats
            headerSection

            // Recording section
            RecordingView(appState: appState)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            // Pretty tab selection
            HStack(spacing: 0) {
                TabButton(
                    title: "История",
                    icon: "clock.fill",
                    isSelected: selectedTab == 0,
                    color: pinkColor
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = 0
                    }
                }

                TabButton(
                    title: "Настройки",
                    icon: "gearshape.fill",
                    isSelected: selectedTab == 1,
                    color: pinkColor
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = 1
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white)

            Divider()
                .background(lightPink.opacity(0.3))

            // Tab content
            Group {
                if selectedTab == 0 {
                    HistoryView(appState: appState)
                } else {
                    SettingsView(appState: appState)
                }
            }

            // Pretty footer
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 8))
                        .foregroundColor(pinkColor)
                    Text("Говорилка v1.0")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(textColor.opacity(0.5))
                }

                Spacer()

                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack(spacing: 4) {
                        Text("Выход")
                            .font(.system(size: 11, weight: .medium))
                        Image(systemName: "arrow.right.circle")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(textColor.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(softPink.opacity(0.5))
        }
        .frame(width: 360, height: 620)
        .background(Color.white)
        .alert("Ошибка", isPresented: $appState.showError) {
            Button("OK") {
                appState.showError = false
            }
        } message: {
            Text(appState.errorMessage ?? "Неизвестная ошибка")
        }
    }

    // MARK: - Header with Stats

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Gradient banner
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Сэкономлено времени")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))

                    Text(formattedTimeSaved)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                // Cute cloud icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: "waveform")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [pinkColor, purpleAccent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: pinkColor.opacity(0.3), radius: 10, x: 0, y: 5)

            // Mini stat cards
            HStack(spacing: 10) {
                MiniStatCard(
                    icon: "mic.fill",
                    value: "\(appState.history.count)",
                    label: "записей",
                    color: pinkColor
                )

                MiniStatCard(
                    icon: "text.quote",
                    value: formatNumber(totalWords),
                    label: "слов",
                    color: purpleAccent
                )

                MiniStatCard(
                    icon: "keyboard",
                    value: formatNumber(keystrokesSaved),
                    label: "нажатий",
                    color: coralAccent
                )
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [softPink, Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Computed Stats

    private var totalWords: Int {
        appState.history.reduce(0) { count, entry in
            count + entry.text.split(separator: " ").count
        }
    }

    private var totalDuration: TimeInterval {
        appState.history.reduce(0) { total, entry in
            total + entry.duration
        }
    }

    private var keystrokesSaved: Int {
        // Approximate: each word is about 5 keystrokes
        totalWords * 5
    }

    private var formattedTimeSaved: String {
        let minutes = Int(totalDuration) / 60
        let seconds = Int(totalDuration) % 60

        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours) ч \(mins) мин"
        } else if minutes > 0 {
            return "\(minutes) мин \(seconds) сек"
        } else {
            return "\(seconds) сек"
        }
    }

    private func formatNumber(_ num: Int) -> String {
        if num >= 1000 {
            return String(format: "%.1fK", Double(num) / 1000)
        }
        return "\(num)"
    }
}

// MARK: - Mini Stat Card

struct MiniStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "5D4E6D"))
            }

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(Color(hex: "5D4E6D").opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : Color(hex: "5D4E6D").opacity(0.6))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? color : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MenuBarView(appState: AppState())
}
