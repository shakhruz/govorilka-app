import SwiftUI

/// Pro mode review dialog view
struct ProReviewView: View {
    let data: ProReviewData
    let onSave: (String) -> Void
    let onCancel: () -> Void

    @State private var copiedScreenshot = false
    @State private var copiedText = false
    @State private var exportFolderName: String = ""
    @State private var currentScreenshotIndex = 0

    // AI Touch state
    @State private var currentTranscript: String = ""
    @State private var transcriptHistory: [String] = []
    @State private var isProcessingAI = false
    @State private var aiError: String?

    private let llmService = LLMService.shared

    // Theme colors (use centralized Theme constants)
    private let pinkColor = Theme.pink
    private let lightPink = Theme.lightPink
    private let softPink = Theme.softPink
    private let textColor = Theme.text

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(pinkColor)
                Text("Обратная связь для агента")
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
                    // Screenshot preview with carousel
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .foregroundColor(pinkColor)
                                .font(.system(size: 11))
                            Text("Скриншот")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(textColor)

                            // Screenshot counter (if multiple)
                            if data.screenshots.count > 1 {
                                Text("\(currentScreenshotIndex + 1) / \(data.screenshots.count)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(pinkColor)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(pinkColor.opacity(0.1))
                                    .clipShape(Capsule())
                            }

                            Spacer()

                            // Copy screenshot button
                            Button(action: copyScreenshot) {
                                HStack(spacing: 4) {
                                    Image(systemName: copiedScreenshot ? "checkmark" : "doc.on.doc")
                                        .font(.system(size: 10))
                                    Text(copiedScreenshot ? "Скопировано" : "Копировать")
                                        .font(.system(size: 10, weight: .medium))
                                }
                                .foregroundColor(copiedScreenshot ? .white : pinkColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(copiedScreenshot ? pinkColor : pinkColor.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }

                        // Screenshot with navigation arrows
                        ZStack {
                            Image(nsImage: currentScreenshot)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(pinkColor.opacity(0.3), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                            // Navigation arrows (if multiple screenshots)
                            if data.screenshots.count > 1 {
                                HStack {
                                    // Previous button
                                    Button(action: previousScreenshot) {
                                        Image(systemName: "chevron.left.circle.fill")
                                            .font(.system(size: 28))
                                            .foregroundColor(currentScreenshotIndex > 0 ? pinkColor : pinkColor.opacity(0.3))
                                            .background(Circle().fill(Color.white.opacity(0.9)))
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(currentScreenshotIndex == 0)

                                    Spacer()

                                    // Next button
                                    Button(action: nextScreenshot) {
                                        Image(systemName: "chevron.right.circle.fill")
                                            .font(.system(size: 28))
                                            .foregroundColor(currentScreenshotIndex < data.screenshots.count - 1 ? pinkColor : pinkColor.opacity(0.3))
                                            .background(Circle().fill(Color.white.opacity(0.9)))
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(currentScreenshotIndex >= data.screenshots.count - 1)
                                }
                                .padding(.horizontal, 8)
                            }
                        }

                        // Dots indicator (if multiple screenshots)
                        if data.screenshots.count > 1 {
                            HStack(spacing: 6) {
                                ForEach(0..<data.screenshots.count, id: \.self) { index in
                                    Circle()
                                        .fill(index == currentScreenshotIndex ? pinkColor : pinkColor.opacity(0.3))
                                        .frame(width: 8, height: 8)
                                        .onTapGesture {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                currentScreenshotIndex = index
                                            }
                                        }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)

                    // Transcript preview with copy button and AI Touch
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "text.alignleft")
                                .foregroundColor(pinkColor)
                                .font(.system(size: 11))
                            Text("Транскрипция")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(textColor)

                            Spacer()

                            // Copy text button
                            Button(action: copyText) {
                                HStack(spacing: 4) {
                                    Image(systemName: copiedText ? "checkmark" : "doc.on.doc")
                                        .font(.system(size: 10))
                                    Text(copiedText ? "Скопировано" : "Копировать")
                                        .font(.system(size: 10, weight: .medium))
                                }
                                .foregroundColor(copiedText ? .white : pinkColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(copiedText ? pinkColor : pinkColor.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }

                        ScrollView {
                            Text(currentTranscript)
                                .font(.system(size: 13))
                                .foregroundColor(textColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                        .frame(height: 80)

                        // AI Touch controls
                        HStack(spacing: 8) {
                            // Undo button (if history exists)
                            if !transcriptHistory.isEmpty {
                                Button(action: undoAITouch) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.uturn.backward")
                                            .font(.system(size: 10))
                                        Text("Назад")
                                            .font(.system(size: 10, weight: .medium))
                                    }
                                    .foregroundColor(pinkColor)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(pinkColor.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                .buttonStyle(.plain)
                            }

                            Spacer()

                            // AI Touch button
                            Button(action: performAITouch) {
                                HStack(spacing: 4) {
                                    if isProcessingAI {
                                        ProgressView()
                                            .scaleEffect(0.6)
                                            .frame(width: 12, height: 12)
                                    } else {
                                        Image(systemName: "wand.and.stars")
                                            .font(.system(size: 10))
                                    }
                                    Text(isProcessingAI ? "Улучшаю..." : "AI Touch")
                                        .font(.system(size: 10, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    LinearGradient(
                                        colors: [pinkColor, lightPink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .opacity(isProcessingAI || !StorageService.shared.hasLLMApiKey ? 0.6 : 1)
                            }
                            .buttonStyle(.plain)
                            .disabled(isProcessingAI || !StorageService.shared.hasLLMApiKey)
                        }

                        // Error message
                        if let error = aiError {
                            Text(error)
                                .font(.system(size: 10))
                                .foregroundColor(.red.opacity(0.8))
                        }

                        // Hint for API key
                        if !StorageService.shared.hasLLMApiKey {
                            Text("Добавьте Groq API ключ в настройках")
                                .font(.system(size: 10))
                                .foregroundColor(textColor.opacity(0.5))
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)

                    // Export folder info
                    if !exportFolderName.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "folder.fill")
                                .foregroundColor(pinkColor)
                                .font(.system(size: 12))
                            Text("Сохранится в: \(exportFolderName)")
                                .font(.system(size: 12))
                                .foregroundColor(textColor.opacity(0.7))
                            Spacer()
                        }
                        .padding(12)
                        .background(softPink)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
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

                Button(action: { onSave(currentTranscript) }) {
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
        .frame(width: 500, height: 520)
        .background(softPink.opacity(0.3))
        .preferredColorScheme(.light)
        .onAppear {
            currentTranscript = data.transcript
            checkExportFolder()
        }
    }

    // MARK: - AI Touch Methods

    private func performAITouch() {
        guard !isProcessingAI else { return }

        isProcessingAI = true
        aiError = nil

        // Save current text to history before modification
        transcriptHistory.append(currentTranscript)

        Task {
            do {
                let improvedText = try await llmService.improveText(currentTranscript)
                await MainActor.run {
                    currentTranscript = improvedText
                    isProcessingAI = false
                }
            } catch {
                await MainActor.run {
                    // Restore from history on error
                    if let lastText = transcriptHistory.popLast() {
                        currentTranscript = lastText
                    }
                    aiError = error.localizedDescription
                    isProcessingAI = false
                }
            }
        }
    }

    private func undoAITouch() {
        guard let previousText = transcriptHistory.popLast() else { return }
        currentTranscript = previousText
        aiError = nil
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

    private var currentScreenshot: NSImage {
        guard currentScreenshotIndex < data.screenshots.count else {
            return data.screenshots.first ?? NSImage()
        }
        return data.screenshots[currentScreenshotIndex]
    }

    private func previousScreenshot() {
        withAnimation(.easeInOut(duration: 0.2)) {
            if currentScreenshotIndex > 0 {
                currentScreenshotIndex -= 1
            }
        }
    }

    private func nextScreenshot() {
        withAnimation(.easeInOut(duration: 0.2)) {
            if currentScreenshotIndex < data.screenshots.count - 1 {
                currentScreenshotIndex += 1
            }
        }
    }

    private func checkExportFolder() {
        if let url = StorageService.shared.resolveExportFolder() {
            exportFolderName = url.lastPathComponent
            StorageService.shared.stopAccessingExportFolder(url)
        } else {
            exportFolderName = ""
        }
    }

    private func copyScreenshot() {
        PasteService.shared.copyImageToClipboard(currentScreenshot)

        withAnimation(.easeInOut(duration: 0.2)) {
            copiedScreenshot = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                copiedScreenshot = false
            }
        }
    }

    private func copyText() {
        PasteService.shared.copyToClipboard(currentTranscript)

        withAnimation(.easeInOut(duration: 0.2)) {
            copiedText = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                copiedText = false
            }
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
