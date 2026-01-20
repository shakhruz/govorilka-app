import SwiftUI

/// Detailed view for a history entry with screenshot
struct HistoryDetailView: View {
    let entry: TranscriptEntry
    let onClose: () -> Void

    @State private var screenshot: NSImage?
    @State private var copiedText = false
    @State private var copiedImage = false

    // Theme colors
    private let pinkColor = Color(hex: "FF69B4")
    private let lightPink = Color(hex: "FFB6C1")
    private let softPink = Color(hex: "FFF5F8")
    private let textColor = Color(hex: "5D4E6D")

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                if entry.isProMode {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .foregroundColor(pinkColor)
                        Text("Pro запись")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(textColor)
                    }
                } else {
                    Text("Подробности записи")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(textColor)
                }

                Spacer()

                Text(entry.formattedTimestamp)
                    .font(.system(size: 12))
                    .foregroundColor(textColor.opacity(0.6))

                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(textColor.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(softPink)

            ScrollView {
                VStack(spacing: 16) {
                    // Screenshot
                    if let screenshot = screenshot {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(pinkColor)
                                    .font(.system(size: 11))
                                Text("Скриншот")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(textColor)

                                Spacer()

                                Button(action: copyScreenshot) {
                                    HStack(spacing: 4) {
                                        Image(systemName: copiedImage ? "checkmark" : "doc.on.doc")
                                            .font(.system(size: 10))
                                        Text(copiedImage ? "Скопировано" : "Копировать")
                                            .font(.system(size: 11, weight: .medium))
                                    }
                                    .foregroundColor(copiedImage ? .white : pinkColor)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(copiedImage ? pinkColor : pinkColor.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                .buttonStyle(.plain)
                            }

                            Image(nsImage: screenshot)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 250)
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
                    }

                    // Transcript
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "text.alignleft")
                                .foregroundColor(pinkColor)
                                .font(.system(size: 11))
                            Text("Транскрипция")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(textColor)

                            Spacer()

                            Button(action: copyText) {
                                HStack(spacing: 4) {
                                    Image(systemName: copiedText ? "checkmark" : "doc.on.doc")
                                        .font(.system(size: 10))
                                    Text(copiedText ? "Скопировано" : "Копировать")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .foregroundColor(copiedText ? .white : pinkColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(copiedText ? pinkColor : pinkColor.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }

                        ScrollView {
                            Text(entry.text)
                                .font(.system(size: 13))
                                .foregroundColor(textColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                        .frame(height: 120)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)

                    // Metadata
                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Image(systemName: "timer")
                                .foregroundColor(pinkColor)
                                .font(.system(size: 11))
                            Text("Длительность: \(entry.formattedDuration)")
                                .font(.system(size: 11))
                                .foregroundColor(textColor.opacity(0.7))
                        }

                        if entry.isProMode {
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(pinkColor)
                                    .font(.system(size: 11))
                                Text("Pro режим")
                                    .font(.system(size: 11))
                                    .foregroundColor(textColor.opacity(0.7))
                            }
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                }
                .padding(16)
            }
        }
        .frame(width: 500, height: 520)
        .background(softPink.opacity(0.3))
        .onAppear {
            loadScreenshot()
        }
    }

    private func loadScreenshot() {
        guard let filename = entry.screenshotFilename else { return }
        screenshot = ScreenshotService.shared.loadScreenshot(filename: filename)
    }

    private func copyText() {
        PasteService.shared.copyToClipboard(entry.text)

        withAnimation(.easeInOut(duration: 0.2)) {
            copiedText = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                copiedText = false
            }
        }
    }

    private func copyScreenshot() {
        guard let image = screenshot else { return }
        PasteService.shared.copyImageToClipboard(image)

        withAnimation(.easeInOut(duration: 0.2)) {
            copiedImage = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                copiedImage = false
            }
        }
    }
}

#Preview {
    HistoryDetailView(
        entry: TranscriptEntry.samplePro,
        onClose: {}
    )
}
