import AppKit
import SwiftUI

/// Controller for managing the Accessibility onboarding window
@MainActor
final class OnboardingWindowController {
    private var window: NSWindow?
    private var viewModel: OnboardingViewModel?

    private let pasteService = PasteService.shared
    private let storage = StorageService.shared

    /// Show the onboarding window
    func show() {
        guard window == nil else {
            window?.makeKeyAndOrderFront(nil)
            return
        }

        // If already has permission, don't show
        if pasteService.hasAccessibilityPermission() {
            return
        }

        // Create view model
        let viewModel = OnboardingViewModel()
        viewModel.onOpenSettings = { [weak self] in
            self?.openSettings()
        }
        viewModel.onSkip = { [weak self] in
            self?.skip()
        }
        self.viewModel = viewModel

        let contentView = AccessibilityOnboardingWrapperView(viewModel: viewModel)
        let hostingView = NSHostingView(rootView: contentView)

        // Create window with modern borderless style
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 540),
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
            self?.viewModel = nil
        }
    }

    /// Open System Settings > Accessibility
    private func openSettings() {
        pasteService.openAccessibilitySettings()
    }

    /// Skip onboarding
    private func skip() {
        if viewModel?.dontShowAgain == true {
            storage.accessibilityOnboardingSkipped = true
        }
        hide()
    }
}

// MARK: - View Model

/// Observable view model for the onboarding view
@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var dontShowAgain = false

    var onOpenSettings: (() -> Void)?
    var onSkip: (() -> Void)?
}

// MARK: - Wrapper View

/// Wrapper view that observes the view model
struct AccessibilityOnboardingWrapperView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        AccessibilityOnboardingView(
            dontShowAgain: $viewModel.dontShowAgain,
            onOpenSettings: { viewModel.onOpenSettings?() },
            onSkip: { viewModel.onSkip?() }
        )
    }
}
