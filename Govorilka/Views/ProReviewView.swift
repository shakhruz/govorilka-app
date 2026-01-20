import SwiftUI

/// Pro mode review dialog view
struct ProReviewView: View {
    let data: ProReviewData
    let onSave: (Bool) -> Void
    let onCancel: () -> Void

    @State private var exportToFolder = false
    @State private var hasExportFolder = false

    // Theme colors
    private let pinkColor = Color(hex: "FF69B4")
    private let lightPink = Color(hex: "FFB6C1")
    private let softPink = Color(hex: "FFF5F8")
    private let textColor = Color(hex: "5D4E6D")

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(pinkColor)
                Text("Pro режим")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(textColor)
                Spacer()
                Text(formattedDuration)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(textColor.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(softPink)

            ScrollView {
                VStack(spacing: 16) {
                    // Screenshot preview
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .foregroundColor(pinkColor)
                                .font(.system(size: 11))
                            Text("Скриншот")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(textColor)
                        }

                        Image(nsImage: data.screenshot)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(pinkColor.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)

                    // Transcript preview
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "text.alignleft")
                                .foregroundColor(pinkColor)
                                .font(.system(size: 11))
                            Text("Транскрипция")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(textColor)
                        }

                        ScrollView {
                            Text(data.transcript)
                                .font(.system(size: 13))
                                .foregroundColor(textColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(height: 80)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)

                    // Export toggle
                    if hasExportFolder {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(isOn: $exportToFolder) {
                                HStack(spacing: 8) {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(pinkColor)
                                        .font(.system(size: 11))
                                    Text("Экспортировать в папку")
                                        .font(.system(size: 13))
                                        .foregroundColor(textColor)
                                }
                            }
                            .toggleStyle(.switch)
                            .tint(pinkColor)

                            if exportToFolder {
                                Text("PNG и MD файлы будут сохранены в выбранную папку")
                                    .font(.system(size: 10))
                                    .foregroundColor(textColor.opacity(0.5))
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                    }
                }
                .padding(16)
            }

            // Buttons
            HStack(spacing: 12) {
                Button(action: onCancel) {
                    Text("Отмена")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(textColor)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])

                Spacer()

                Button(action: { onSave(exportToFolder) }) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                        Text("Сохранить")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [pinkColor, lightPink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.return, modifiers: [])
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(softPink.opacity(0.5))
        }
        .frame(width: 500, height: 480)
        .background(softPink.opacity(0.3))
        .onAppear {
            checkExportFolder()
        }
    }

    private var formattedDuration: String {
        let minutes = Int(data.duration) / 60
        let seconds = Int(data.duration) % 60

        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", seconds))"
        } else {
            return "\(seconds) сек"
        }
    }

    private func checkExportFolder() {
        if let url = StorageService.shared.resolveExportFolder() {
            hasExportFolder = true
            StorageService.shared.stopAccessingExportFolder(url)
        } else {
            hasExportFolder = false
        }
    }
}

#Preview {
    ProReviewView(
        data: ProReviewData(
            screenshot: NSImage(systemSymbolName: "photo", accessibilityDescription: nil)!,
            transcript: "Это тестовая транскрипция для предпросмотра диалога Pro режима.",
            duration: 15.5,
            timestamp: Date()
        ),
        onSave: { _ in },
        onCancel: {}
    )
}
