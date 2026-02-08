import AppKit
import SwiftUI

/// Controller for managing the Permissions onboarding window
@MainActor
final class OnboardingWindowController {
    private var window: NSWindow?

    private let storage = StorageService.shared

    /// Show the onboarding window
    func show() {
        guard window == nil else {
            window?.makeKeyAndOrderFront(nil)
            return
        }

        // If all required permissions are granted, don't show
        if PermissionManager.shared.allRequiredPermissionsGranted {
            return
        }

        let contentView = OnboardingPermissionsView(
            permissionManager: PermissionManager.shared,
            onComplete: { [weak self] in
                self?.complete()
            }
        )
        let hostingView = NSHostingView(rootView: contentView)

        // Create window with modern borderless style
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 640),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.contentView = hostingView
        window.title = ""
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isReleasedWhenClosed = false
        window.level = .modalPanel
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = true

        // Center on screen
        window.center()

        self.window = window

        // Show window with animation
        window.alphaValue = 0
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Fade in animation
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1.0
        }
    }

    /// Hide the onboarding window with animation
    func hide() {
        guard let window = window else { return }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            window.orderOut(nil)
            self?.window = nil
        }
    }

    /// Complete onboarding — mark as done and hide
    private func complete() {
        storage.permissionsOnboardingCompleted = true
        hide()
    }
}
