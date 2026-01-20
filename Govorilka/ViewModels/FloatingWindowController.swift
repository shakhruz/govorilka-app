import AppKit
import SwiftUI

/// Controller for managing the floating recorder window
@MainActor
final class FloatingWindowController: ObservableObject {
    private var window: NSWindow?
    private var hostingView: NSHostingView<AnyView>?

    @Published var isVisible = false

    /// Show the floating window at screen center
    func show(appState: AppState, audioLevel: Binding<Float>) {
        guard window == nil else {
            window?.orderFrontRegardless()
            isVisible = true
            return
        }

        let contentView = FloatingRecorderView(
            appState: appState,
            audioLevel: audioLevel,
            onClose: { [weak self] in
                self?.hide()
            }
        )

        let hostingView = NSHostingView(rootView: AnyView(contentView))
        self.hostingView = hostingView

        // Create window
        let window = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 280),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        window.contentView = hostingView
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        window.animationBehavior = .utilityWindow

        // Center on screen
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let windowSize = window.frame.size
            let x = screenRect.midX - windowSize.width / 2
            let y = screenRect.midY - windowSize.height / 2
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        self.window = window

        // Show with animation (use orderFront to avoid stealing focus)
        window.alphaValue = 0
        window.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
        }

        isVisible = true
    }

    /// Hide the floating window
    func hide() {
        guard let window = window else { return }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            self?.window?.orderOut(nil)
            self?.window = nil
            self?.hostingView = nil
            self?.isVisible = false
        }
    }

    /// Update the audio level binding
    func updateContent(appState: AppState, audioLevel: Binding<Float>) {
        guard let hostingView = hostingView else { return }

        let contentView = FloatingRecorderView(
            appState: appState,
            audioLevel: audioLevel,
            onClose: { [weak self] in
                self?.hide()
            }
        )

        hostingView.rootView = AnyView(contentView)
    }
}

// MARK: - Floating Panel (Non-activating window)

/// A custom NSPanel that doesn't steal focus from other apps
class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool {
        return false  // Never steal keyboard focus
    }

    override var canBecomeMain: Bool {
        return false
    }

    override func resignKey() {
        super.resignKey()
        // Keep window visible when it loses focus
    }

    // Allow clicking through to other windows
    override func mouseDown(with event: NSEvent) {
        // Handle drag
        if event.locationInWindow.y > frame.height - 50 {
            performDrag(with: event)
        } else {
            super.mouseDown(with: event)
        }
    }
}
