import AppKit
import SwiftUI

/// Controller for managing the History Detail window as a standalone floating window
@MainActor
final class HistoryDetailWindowController: NSObject, ObservableObject {
    private var window: NSWindow?
    private var hostingView: NSHostingView<AnyView>?

    @Published var isVisible = false

    /// Show the detail window for a history entry
    func show(entry: TranscriptEntry) {
        if let existingWindow = window {
            updateContent(entry: entry)
            existingWindow.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
            isVisible = true
            return
        }

        let contentView = HistoryDetailView(
            entry: entry,
            onClose: { [weak self] in
                self?.hide()
            }
        )

        let hostingView = NSHostingView(rootView: AnyView(contentView))
        self.hostingView = hostingView

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 570),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.contentView = hostingView
        window.title = "Подробности записи"
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces]
        window.delegate = self

        // Center on screen
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let windowSize = window.frame.size
            let x = screenRect.midX - windowSize.width / 2
            let y = screenRect.midY - windowSize.height / 2
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        self.window = window

        // Show with animation
        window.alphaValue = 0
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
        }

        isVisible = true
    }

    /// Hide the detail window
    func hide() {
        guard let window = window else { return }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: {
            Task { @MainActor [weak self] in
                self?.window?.orderOut(nil)
                self?.window = nil
                self?.hostingView = nil
                self?.isVisible = false
            }
        }
    }

    /// Update the content view with a new entry
    private func updateContent(entry: TranscriptEntry) {
        guard let hostingView = hostingView else { return }

        let contentView = HistoryDetailView(
            entry: entry,
            onClose: { [weak self] in
                self?.hide()
            }
        )

        hostingView.rootView = AnyView(contentView)
    }
}

// MARK: - NSWindowDelegate

extension HistoryDetailWindowController: NSWindowDelegate {
    nonisolated func windowWillClose(_ notification: Notification) {
        Task { @MainActor in
            self.window = nil
            self.hostingView = nil
            self.isVisible = false
        }
    }
}
