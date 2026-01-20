import AppKit
import SwiftUI

/// Data passed to the Pro review window
struct ProReviewData {
    let screenshot: NSImage
    let transcript: String
    let duration: TimeInterval
    let timestamp: Date
}

/// Controller for managing the Pro mode review window
@MainActor
final class ProReviewWindowController: NSObject, ObservableObject {
    private var window: NSWindow?
    private var hostingView: NSHostingView<AnyView>?

    @Published var isVisible = false

    // Callbacks
    var onSave: ((ProReviewData) -> Void)?
    var onCancel: (() -> Void)?

    /// Show the review window with screenshot and transcript
    func show(
        screenshot: NSImage,
        transcript: String,
        duration: TimeInterval,
        onSave: @escaping (ProReviewData) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.onSave = onSave
        self.onCancel = onCancel

        let data = ProReviewData(
            screenshot: screenshot,
            transcript: transcript,
            duration: duration,
            timestamp: Date()
        )

        if let existingWindow = window {
            updateContent(data: data)
            existingWindow.orderFrontRegardless()
            isVisible = true
            return
        }

        let contentView = ProReviewView(
            data: data,
            onSave: { [weak self] in
                self?.handleSave(data: data)
            },
            onCancel: { [weak self] in
                self?.handleCancel()
            }
        )

        let hostingView = NSHostingView(rootView: AnyView(contentView))
        self.hostingView = hostingView

        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 480),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.contentView = hostingView
        window.title = "Обратная связь для агента"
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

    /// Hide the review window
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

    /// Update the content view with new data
    private func updateContent(data: ProReviewData) {
        guard let hostingView = hostingView else { return }

        let contentView = ProReviewView(
            data: data,
            onSave: { [weak self] in
                self?.handleSave(data: data)
            },
            onCancel: { [weak self] in
                self?.handleCancel()
            }
        )

        hostingView.rootView = AnyView(contentView)
    }

    private func handleSave(data: ProReviewData) {
        onSave?(data)
        hide()
    }

    private func handleCancel() {
        onCancel?()
        hide()
    }
}

// MARK: - NSWindowDelegate

extension ProReviewWindowController: NSWindowDelegate {
    nonisolated func windowWillClose(_ notification: Notification) {
        Task { @MainActor in
            self.handleCancel()
        }
    }
}
