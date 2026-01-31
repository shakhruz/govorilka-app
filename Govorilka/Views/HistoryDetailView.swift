import SwiftUI

/// Detailed view for a history entry with screenshot
struct HistoryDetailView: View {
    let entry: TranscriptEntry
    let onClose: () -> Void

    @State private var screenshots: [NSImage] = []
    @State private var currentScreenshotIndex: Int = 0
    @State private var copiedText = false
    @State private var copiedImage = false
    @State private var savedToFolder = false
    @State private var exportFolderName: String = ""
    @State private var saveError: String?

    // Theme colors (use centralized Theme constants)
    private let pinkColor = Theme.pink
    private let lightPink = Theme.lightPink
    private let softPink = Theme.softPink
    private let textColor = Theme.text

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
                    // Screenshots gallery
                    if !screenshots.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(pinkColor)
                                    .font(.system(size: 11))
                                Text(screenshots.count > 1 ? "Скриншоты" : "Скриншот")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(textColor)

                                // Screenshot counter (if multiple)
                                if screenshots.count > 1 {
                                    Text("\(currentScreenshotIndex + 1)/\(screenshots.count)")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(pinkColor)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(pinkColor.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }

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

                            // Screenshot with navigation
                            ZStack {
                                Image(nsImage: screenshots[currentScreenshotIndex])
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 250)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(pinkColor.opacity(0.3), lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                                // Navigation arrows (if multiple screenshots)
                                if screenshots.count > 1 {
                                    HStack {
                                        // Left arrow
                                        Button(action: previousScreenshot) {
                                            Image(systemName: "chevron.left.circle.fill")
                                                .font(.system(size: 28))
                                                .foregroundColor(currentScreenshotIndex > 0 ? pinkColor : pinkColor.opacity(0.3))
                                                .shadow(color: Color.black.opacity(0.2), radius: 2)
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(currentScreenshotIndex == 0)

                                        Spacer()

                                        // Right arrow
                                        Button(action: nextScreenshot) {
                                            Image(systemName: "chevron.right.circle.fill")
                                                .font(.system(size: 28))
                                                .foregroundColor(currentScreenshotIndex < screenshots.count - 1 ? pinkColor : pinkColor.opacity(0.3))
                                                .shadow(color: Color.black.opacity(0.2), radius: 2)
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(currentScreenshotIndex >= screenshots.count - 1)
                                    }
                                    .padding(.horizontal, 8)
                                }
                            }

                            // Dot indicators (if multiple screenshots)
                            if screenshots.count > 1 {
                                HStack(spacing: 6) {
                                    Spacer()
                                    ForEach(0..<screenshots.count, id: \.self) { index in
                                        Circle()
                                            .fill(index == currentScreenshotIndex ? pinkColor : pinkColor.opacity(0.3))
                                            .frame(width: 6, height: 6)
                                            .onTapGesture {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    currentScreenshotIndex = index
                                                }
                                            }
                                    }
                                    Spacer()
                                }
                                .padding(.top, 4)
                            }
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

            // Bottom bar with save button (always visible)
            VStack(spacing: 8) {
                // Error message if any
                if let error = saveError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 11))
                        Text(error)
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                    }
                }

                HStack {
                    if !exportFolderName.isEmpty {
                        // Folder info
                        HStack(spacing: 6) {
                            Image(systemName: "folder.fill")
                                .foregroundColor(pinkColor)
                                .font(.system(size: 11))
                            Text(exportFolderName)
                                .font(.system(size: 11))
                                .foregroundColor(textColor.opacity(0.7))
                                .lineLimit(1)
                        }

                        Spacer()

                        // Save button
                        Button(action: saveToFolder) {
                            HStack(spacing: 6) {
                                Image(systemName: savedToFolder ? "checkmark" : "square.and.arrow.down")
                                    .font(.system(size: 11, weight: .medium))
                                Text(savedToFolder ? "Сохранено!" : "Сохранить")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(savedToFolder ? .white : pinkColor)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(savedToFolder ? pinkColor : pinkColor.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .disabled(savedToFolder)
                    } else {
                        // No folder selected - show select button
                        Text("Выберите папку для сохранения")
                            .font(.system(size: 11))
                            .foregroundColor(textColor.opacity(0.6))

                        Spacer()

                        Button(action: selectExportFolder) {
                            HStack(spacing: 6) {
                                Image(systemName: "folder.badge.plus")
                                    .font(.system(size: 11, weight: .medium))
                                Text("Выбрать папку")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(pinkColor)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(softPink.opacity(0.5))
        }
        .frame(width: 500, height: 570)
        .background(softPink.opacity(0.3))
        .onAppear {
            loadScreenshots()
            checkExportFolder()
        }
    }

    private func loadScreenshots() {
        let filenames = entry.allScreenshotFilenames
        screenshots = filenames.compactMap { filename in
            ScreenshotService.shared.loadScreenshot(filename: filename)
        }
        currentScreenshotIndex = 0
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
            if currentScreenshotIndex < screenshots.count - 1 {
                currentScreenshotIndex += 1
            }
        }
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
        guard !screenshots.isEmpty else { return }
        let image = screenshots[currentScreenshotIndex]
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

    private func checkExportFolder() {
        if let url = StorageService.shared.resolveExportFolder() {
            exportFolderName = url.lastPathComponent
            StorageService.shared.stopAccessingExportFolder(url)
        } else {
            exportFolderName = ""
        }
    }

    private func selectExportFolder() {
        let panel = NSOpenPanel()
        panel.title = "Выберите папку для экспорта"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            StorageService.shared.saveExportFolder(url)
            exportFolderName = url.lastPathComponent
        }
    }

    private func saveToFolder() {
        guard let folderURL = StorageService.shared.resolveExportFolder() else {
            saveError = "Папка недоступна"
            return
        }

        defer {
            StorageService.shared.stopAccessingExportFolder(folderURL)
        }

        saveError = nil

        // Generate base filename from timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let baseName = "govorilka_\(dateFormatter.string(from: entry.timestamp))"

        // Save all screenshots with numbering
        if !screenshots.isEmpty {
            for (index, image) in screenshots.enumerated() {
                let suffix = screenshots.count > 1 ? "_\(index + 1)" : ""
                let imageURL = folderURL.appendingPathComponent("\(baseName)\(suffix).png")

                if let tiffData = image.tiffRepresentation,
                   let bitmapRep = NSBitmapImageRep(data: tiffData),
                   let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                    do {
                        try pngData.write(to: imageURL)
                        print("[HistoryDetailView] Screenshot \(index + 1) saved: \(imageURL.path)")
                    } catch {
                        print("[HistoryDetailView] Failed to save screenshot \(index + 1): \(error)")
                        saveError = "Ошибка сохранения скриншота \(index + 1)"
                        return
                    }
                }
            }
        }

        // Save text
        let textURL = folderURL.appendingPathComponent("\(baseName).txt")
        do {
            try entry.text.write(to: textURL, atomically: true, encoding: .utf8)
            print("[HistoryDetailView] Text saved: \(textURL.path)")
        } catch {
            print("[HistoryDetailView] Failed to save text: \(error)")
            saveError = "Ошибка сохранения текста"
            return
        }

        // Success
        withAnimation(.easeInOut(duration: 0.2)) {
            savedToFolder = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.2)) {
                savedToFolder = false
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
